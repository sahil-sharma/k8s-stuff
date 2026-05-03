package middleware

import (
	"context"
	"time"

	"github.com/sirupsen/logrus"
)

// RetryConfig defines retry behaviour before sending to DLQ.
type RetryConfig struct {
	MaxAttempts int           // total attempts including the first one
	InitialWait time.Duration // wait before 2nd attempt
	MaxWait     time.Duration // cap on backoff duration
	Multiplier  float64       // backoff multiplier per attempt
}

func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxAttempts: 3,
		InitialWait: 500 * time.Millisecond,
		MaxWait:     10 * time.Second,
		Multiplier:  2.0, // 500ms → 1s → 2s
	}
}

// ProcessFunc is the business logic to retry.
// Return nil on success, error on failure.
type ProcessFunc func(ctx context.Context) error

// Result is returned by WithRetry.
type Result struct {
	Attempts int
	Err      error // nil if succeeded
}

// WithRetry runs fn up to cfg.MaxAttempts times with exponential backoff.
// If ctx is cancelled it stops early and returns the last error.
func WithRetry(
	ctx context.Context,
	cfg RetryConfig,
	log *logrus.Logger,
	msgID string, // for logging — e.g. "topic/partition/offset"
	fn ProcessFunc,
) Result {
	wait := cfg.InitialWait
	var lastErr error

	for attempt := 1; attempt <= cfg.MaxAttempts; attempt++ {
		lastErr = fn(ctx)
		if lastErr == nil {
			return Result{Attempts: attempt}
		}

		log.WithFields(logrus.Fields{
			"message_id": msgID,
			"attempt":    attempt,
			"max":        cfg.MaxAttempts,
			"error":      lastErr.Error(),
		}).Warn("message processing failed — will retry")

		if attempt == cfg.MaxAttempts {
			break
		}

		// Check context before sleeping
		select {
		case <-ctx.Done():
			log.WithField("message_id", msgID).
				Warn("context cancelled during retry backoff")
			return Result{Attempts: attempt, Err: ctx.Err()}
		case <-time.After(wait):
		}

		// Exponential backoff with cap
		wait = time.Duration(float64(wait) * cfg.Multiplier)
		if wait > cfg.MaxWait {
			wait = cfg.MaxWait
		}
	}

	log.WithFields(logrus.Fields{
		"message_id":   msgID,
		"total_attempts": cfg.MaxAttempts,
		"error":        lastErr.Error(),
	}).Error("all retry attempts exhausted — sending to DLQ")

	return Result{Attempts: cfg.MaxAttempts, Err: lastErr}
}