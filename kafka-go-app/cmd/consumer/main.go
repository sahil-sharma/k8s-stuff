package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"

	"kafka-go-app/internal/auth"
	"kafka-go-app/internal/dlq"
	"kafka-go-app/internal/health"
	"kafka-go-app/internal/logger"
	"kafka-go-app/internal/middleware"
)

// ── Prometheus metrics ────────────────────────────────────────────────────────
var (
	msgProcessed = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "kafka_consumer_messages_total",
		Help: "Total messages processed",
	}, []string{"topic", "status"}) // status: success | retry | dlq

	msgProcessingDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "kafka_consumer_processing_duration_ms",
		Help:    "Message processing duration in ms",
		Buckets: []float64{10, 50, 100, 250, 500, 1000, 2000, 5000},
	}, []string{"topic"})

	dlqTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "kafka_consumer_dlq_total",
		Help: "Total messages sent to DLQ",
	}, []string{"topic"})
)

func mustEnv(log *logrus.Logger, key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.WithField("env_var", key).Fatal("required environment variable is not set")
	}
	return v
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func main() {
	log := logger.New("consumer")
	log.Info("consumer starting up")

	// ── Env vars ──────────────────────────────────────────────────────────────
	bootstrapServers  := mustEnv(log, "KAFKA_BOOTSTRAP_SERVERS")
	topic             := mustEnv(log, "KAFKA_TOPIC")
	consumerGroup     := mustEnv(log, "KAFKA_CONSUMER_GROUP")
	dlqTopic          := envOr("KAFKA_DLQ_TOPIC", topic+".dlq")
	ssoURL            := mustEnv(log, "KEYCLOAK_SSO_URL")
	clientID          := mustEnv(log, "KEYCLOAK_CLIENT_ID")
	clientSecret      := mustEnv(log, "KEYCLOAK_CLIENT_SECRET")
	audience          := mustEnv(log, "KEYCLOAK_AUDIENCE")
	healthAddr        := envOr("HEALTH_ADDR", ":8081")
	processingDelayMs := envOr("PROCESSING_DELAY_MS", "0")
	processingTimeout := envOrDuration("PROCESSING_TIMEOUT", 30*time.Second)
	// ─────────────────────────────────────────────────────────────────────────

	log.WithFields(logrus.Fields{
		"bootstrap_servers":  bootstrapServers,
		"topic":              topic,
		"dlq_topic":          dlqTopic,
		"consumer_group":     consumerGroup,
		"client_id":          clientID,
		"health_addr":        healthAddr,
		"processing_timeout": processingTimeout,
	}).Info("configuration loaded")

	// ── Context + shutdown ────────────────────────────────────────────────────
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		sig := <-sigs
		log.WithField("signal", sig.String()).Warn("shutdown signal — draining consumer")
		cancel()
	}()

	// ── Health server ─────────────────────────────────────────────────────────
	status := health.NewStatus()
	healthSrv := health.NewServer(healthAddr, status, log)
	healthSrv.Start(ctx)

	// ── Keycloak token ────────────────────────────────────────────────────────
	kc := auth.NewKeycloakClient(ssoURL, clientID, clientSecret, audience, log)
	initialTok, err := kc.FetchUMAToken()
	if err != nil {
		log.WithError(err).Fatal("failed to obtain initial Keycloak UMA token")
	}

	// ── DLQ publisher ─────────────────────────────────────────────────────────
	dlqPub, err := dlq.NewPublisher(bootstrapServers, dlqTopic, initialTok.AccessToken, clientID, log)
	if err != nil {
		log.WithError(err).Fatal("failed to create DLQ publisher")
	}
	defer dlqPub.Close()

	// ── Confluent consumer ────────────────────────────────────────────────────
	consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":        bootstrapServers,
		"group.id":                 consumerGroup,
		"security.protocol":        "SASL_PLAINTEXT",
		"sasl.mechanism":           "OAUTHBEARER",
		"sasl.oauthbearer.config":  fmt.Sprintf("token=%s", initialTok.AccessToken),
		"auto.offset.reset":        "latest",
		"enable.auto.commit":       false, // manual commit after processing
		"max.poll.interval.ms":     300000,
		"session.timeout.ms":       45000,
	})
	if err != nil {
		log.WithError(err).Fatal("failed to create Kafka consumer")
	}
	defer consumer.Close()

	// ── Wire token refresh ────────────────────────────────────────────────────
	kc.OnRefresh = func(tok auth.Token) {
		oauthTok := kafka.OAuthBearerToken{
			TokenValue: tok.AccessToken,
			Expiration: tok.ExpiresAt,
			Principal:  clientID,
		}
		if err := consumer.SetOAuthBearerToken(oauthTok); err != nil {
			log.WithError(err).Error("failed to set refreshed token on consumer")
			_ = consumer.SetOAuthBearerTokenFailure(err.Error())
		}
		// Also refresh DLQ producer token
		if err := dlqPub.UpdateToken(oauthTok); err != nil {
			log.WithError(err).Warn("failed to refresh DLQ producer token")
		}
	}

	if err := consumer.SetOAuthBearerToken(kafka.OAuthBearerToken{
		TokenValue: initialTok.AccessToken,
		Expiration: initialTok.ExpiresAt,
		Principal:  clientID,
	}); err != nil {
		log.WithError(err).Fatal("failed to set initial OAuth token on consumer")
	}

	kc.StartRefreshLoop(ctx)

	// ── Subscribe ─────────────────────────────────────────────────────────────
	if err := consumer.Subscribe(topic, rebalanceCb(log, status)); err != nil {
		log.WithError(err).Fatal("failed to subscribe to topic")
	}

	retryCfg := middleware.DefaultRetryConfig()

	// ── Mark ready ───────────────────────────────────────────────────────────
	status.SetReady(true)
	log.WithFields(logrus.Fields{
		"topic":          topic,
		"consumer_group": consumerGroup,
		"dlq_topic":      dlqTopic,
	}).Info("consumer ready — entering consume loop")

	// ── Consume loop ──────────────────────────────────────────────────────────
	for {
		select {
		case <-ctx.Done():
			log.Info("consume loop stopping cleanly")
			return
		default:
		}

		ev := consumer.Poll(200)
		if ev == nil {
			continue
		}

		switch e := ev.(type) {

		case *kafka.Message:
			correlationID := extractHeader(e, "correlation-id")
			msgID := fmt.Sprintf("%s/%d/%d", *e.TopicPartition.Topic, e.TopicPartition.Partition, e.TopicPartition.Offset)

			log.WithFields(logrus.Fields{
				"topic":          *e.TopicPartition.Topic,
				"partition":      e.TopicPartition.Partition,
				"offset":         e.TopicPartition.Offset,
				"correlation_id": correlationID,
				"payload_size":   len(e.Value),
				"lag":            "unknown", // kafka-exporter handles this
			}).Info("message received")

			// Simulate slow processing if configured
			if ms, _ := strconv.Atoi(processingDelayMs); ms > 0 {
				time.Sleep(time.Duration(ms) * time.Millisecond)
			}

			// ── Retry with backoff ────────────────────────────────────────────
			start := time.Now()
			result := middleware.WithRetry(ctx, retryCfg, log, msgID, func(retryCtx context.Context) error {
				// Processing timeout per attempt
				procCtx, procCancel := context.WithTimeout(retryCtx, processingTimeout)
				defer procCancel()

				return processMessage(procCtx, e, correlationID, log)
			})
			elapsed := time.Since(start)
			msgProcessingDuration.WithLabelValues(*e.TopicPartition.Topic).Observe(float64(elapsed.Milliseconds()))

			if result.Err != nil {
				// All retries exhausted → DLQ
				msgProcessed.WithLabelValues(*e.TopicPartition.Topic, "dlq").Inc()
				dlqTotal.WithLabelValues(*e.TopicPartition.Topic).Inc()
				dlqPub.Publish(e, result.Err, result.Attempts)
			} else {
				msgProcessed.WithLabelValues(*e.TopicPartition.Topic, "success").Inc()
				log.WithFields(logrus.Fields{
					"topic":          *e.TopicPartition.Topic,
					"partition":      e.TopicPartition.Partition,
					"offset":         e.TopicPartition.Offset,
					"correlation_id": correlationID,
					"attempts":       result.Attempts,
					"process_ms":     elapsed.Milliseconds(),
				}).Info("message processed successfully")
			}

			// Commit offset regardless of success/DLQ
			// (DLQ'd messages are still "handled" — don't reprocess them)
			if _, err := consumer.CommitMessage(e); err != nil {
				log.WithFields(logrus.Fields{
					"topic":     *e.TopicPartition.Topic,
					"partition": e.TopicPartition.Partition,
					"offset":    e.TopicPartition.Offset,
				}).WithError(err).Error("failed to commit offset")
			}

		case kafka.OAuthBearerTokenRefresh:
			log.Info("librdkafka requested token refresh (consumer)")
			tok, err := kc.FetchUMAToken()
			if err != nil {
				log.WithError(err).Error("on-demand token refresh failed")
				_ = consumer.SetOAuthBearerTokenFailure(err.Error())
				continue
			}
			_ = consumer.SetOAuthBearerToken(kafka.OAuthBearerToken{
				TokenValue: tok.AccessToken,
				Expiration: tok.ExpiresAt,
				Principal:  clientID,
			})

		case kafka.Error:
			log.WithFields(logrus.Fields{
				"code":  e.Code(),
				"error": e.Error(),
			}).Error("Kafka consumer error")
			if e.Code() == kafka.ErrAllBrokersDown {
				status.SetHealthy(false)
				log.Fatal("all brokers down — exiting for pod restart")
			}
		}
	}
}

// processMessage is where your real business logic goes.
func processMessage(ctx context.Context, msg *kafka.Message, correlationID string, log *logrus.Logger) error {
	// Check context timeout before doing work
	select {
	case <-ctx.Done():
		return fmt.Errorf("processing timeout: %w", ctx.Err())
	default:
	}

	// ── DLQ TEST: intentional failure ─────────────────────────────────────────
	// Set FORCE_FAIL_RATIO=0.5 to fail 50% of messages → they land in DLQ
	// Remove this block in production
	if ratio := os.Getenv("FORCE_FAIL_RATIO"); ratio != "" {
		if r, err := strconv.ParseFloat(ratio, 64); err == nil {
			if rand.Float64() < r {
				log.WithField("correlation_id", correlationID).
					Warn("intentional failure triggered for DLQ testing")
				return fmt.Errorf("intentional failure for DLQ testing (correlation_id=%s)", correlationID)
			}
		}
	}
	// ─────────────────────────────────────────────────────────────────────────

	// ── YOUR BUSINESS LOGIC HERE ──────────────────────────────────────────────
	log.WithFields(logrus.Fields{
		"value":          string(msg.Value),
		"correlation_id": correlationID,
	}).Debug("processing message")
	// ─────────────────────────────────────────────────────────────────────────

	return nil
}

// rebalanceCb logs partition assignment/revocation and updates readiness.
func rebalanceCb(log *logrus.Logger, status *health.Status) kafka.RebalanceCb {
	return func(c *kafka.Consumer, ev kafka.Event) error {
		switch e := ev.(type) {
		case kafka.AssignedPartitions:
			log.WithField("partitions", e.Partitions).Info("partitions assigned")
			status.SetReady(true)
			return c.Assign(e.Partitions)
		case kafka.RevokedPartitions:
			log.WithField("partitions", e.Partitions).Info("partitions revoked")
			status.SetReady(false) // not ready during rebalance
			return c.Unassign()
		}
		return nil
	}
}

// extractHeader pulls a header value by key from a Kafka message.
func extractHeader(msg *kafka.Message, key string) string {
	for _, h := range msg.Headers {
		if h.Key == key {
			return string(h.Value)
		}
	}
	return ""
}

// envOrDuration reads a duration from env or returns fallback.
func envOrDuration(key string, fallback time.Duration) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return fallback
	}
	return d
}