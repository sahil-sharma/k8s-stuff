package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"

	// REMOVE: "kafka-go-app/internal/auth"   ← no longer needed
	"kafka-go-app/internal/health"
	"kafka-go-app/internal/logger"
)

// ── Prometheus metrics ────────────────────────────────────────────────────────
var (
	msgProduced = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "kafka_producer_messages_total",
		Help: "Total messages produced",
	}, []string{"topic", "status"})

	msgLatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "kafka_producer_message_latency_ms",
		Help:    "Producer message delivery latency in ms",
		Buckets: []float64{5, 10, 25, 50, 100, 250, 500, 1000},
	}, []string{"topic"})
)

func mustEnv(log *logrus.Logger, key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.WithField("env_var", key).Fatal("required environment variable is not set")
	}
	return v
}

func main() {
	log := logger.New("producer")
	log.Info("producer starting up")

	// ── Env vars ──────────────────────────────────────────────────────────────
	bootstrapServers := mustEnv(log, "KAFKA_BOOTSTRAP_SERVERS")
	topic            := mustEnv(log, "KAFKA_TOPIC")
	kafkaUsername    := mustEnv(log, "KAFKA_USERNAME")       // replaces KEYCLOAK_CLIENT_ID
	kafkaPassword    := mustEnv(log, "KAFKA_PASSWORD")       // replaces KEYCLOAK_CLIENT_SECRET
	healthAddr       := envOr("HEALTH_ADDR", ":8081")
	// REMOVE: ssoURL, clientID, clientSecret, audience
	// ─────────────────────────────────────────────────────────────────────────

	log.WithFields(logrus.Fields{
		"bootstrap_servers": bootstrapServers,
		"topic":             topic,
		"kafka_username":    kafkaUsername,
		"health_addr":       healthAddr,
	}).Info("configuration loaded")

	// ── Health status + server ────────────────────────────────────────────────
	status := health.NewStatus()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	healthSrv := health.NewServer(healthAddr, status, log)
	healthSrv.Start(ctx)

	// ── Graceful shutdown ─────────────────────────────────────────────────────
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		sig := <-sigs
		log.WithField("signal", sig.String()).Warn("shutdown signal received")
		status.SetReady(false)
		cancel()
	}()

	// ── Confluent producer (SCRAM replaces OAUTHBEARER) ───────────────────────
	producer, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": bootstrapServers,
		"security.protocol": "SASL_PLAINTEXT",
		"sasl.mechanism":    "SCRAM-SHA-512",
		"sasl.username":     kafkaUsername,
		"sasl.password":     kafkaPassword,

		// lz4 — fastest compression, minimal CPU overhead
		"compression.type": "lz4",

		// Reliability
		"acks":               "all",
		"enable.idempotence": true,
		"max.in.flight.requests.per.connection": 5,
		"retries":            5,
		"retry.backoff.ms":   200,

		// Batching
		"linger.ms":  5,
		"batch.size": 65536,
	})
	if err != nil {
		log.WithError(err).Fatal("failed to create Kafka producer")
	}
	defer func() {
		log.Info("flushing producer before shutdown")
		remaining := producer.Flush(10000)
		log.WithField("unflushed", remaining).Info("producer flushed")
		producer.Close()
	}()

	// REMOVE: kc.OnRefresh, SetOAuthBearerToken, kc.StartRefreshLoop
	// SCRAM credentials are static — no token refresh loop needed

	// ── Event handler (delivery reports only — no OAuth events) ───────────────
	go handleEvents(ctx, log, producer, topic)

	// ── Mark ready ───────────────────────────────────────────────────────────
	status.SetReady(true)
	log.WithFields(logrus.Fields{
		"topic":             topic,
		"bootstrap_servers": bootstrapServers,
		"kafka_username":    kafkaUsername,
		"compression":       "lz4",
	}).Info("producer ready — starting produce loop")

	// ── Produce loop ──────────────────────────────────────────────────────────
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	i := 0

	for {
		select {
		case <-ctx.Done():
			log.Info("produce loop stopping")
			return

		case <-ticker.C:
			i++
			correlationID := uuid.New().String()
			payload := fmt.Sprintf("message-%d at %s", i, time.Now().Format(time.RFC3339))
			start := time.Now()

			err := producer.Produce(&kafka.Message{
				TopicPartition: kafka.TopicPartition{
					Topic:     &topic,
					Partition: kafka.PartitionAny,
				},
				Value: []byte(payload),
				Headers: []kafka.Header{
					{Key: "correlation-id", Value: []byte(correlationID)},
					{Key: "producer-client-id", Value: []byte(kafkaUsername)}, // was clientID
					{Key: "produced-at", Value: []byte(time.Now().UTC().Format(time.RFC3339))},
				},
			}, nil)

			elapsed := time.Since(start)

			if err != nil {
				msgProduced.WithLabelValues(topic, "error").Inc()
				log.WithFields(logrus.Fields{
					"topic":          topic,
					"message_no":     i,
					"correlation_id": correlationID,
				}).WithError(err).Error("failed to enqueue message")
			} else {
				msgLatency.WithLabelValues(topic).Observe(float64(elapsed.Milliseconds()))
				log.WithFields(logrus.Fields{
					"topic":          topic,
					"message_no":     i,
					"correlation_id": correlationID,
					"payload_size":   len(payload),
				}).Debug("message enqueued")
			}
		}
	}
}

// REMOVE: kc *auth.KeycloakClient and clientID params — no longer needed
func handleEvents(
	ctx context.Context,
	log *logrus.Logger,
	p *kafka.Producer,
	topic string,
) {
	for {
		select {
		case <-ctx.Done():
			return
		case e, ok := <-p.Events():
			if !ok {
				return
			}
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					msgProduced.WithLabelValues(topic, "error").Inc()
					log.WithFields(logrus.Fields{
						"topic":     *ev.TopicPartition.Topic,
						"partition": ev.TopicPartition.Partition,
						"error":     ev.TopicPartition.Error,
					}).Error("message delivery failed")
				} else {
					msgProduced.WithLabelValues(topic, "success").Inc()
					log.WithFields(logrus.Fields{
						"topic":     *ev.TopicPartition.Topic,
						"partition": ev.TopicPartition.Partition,
						"offset":    ev.TopicPartition.Offset,
					}).Info("message delivered")
				}

			// REMOVE: kafka.OAuthBearerTokenRefresh case — not needed with SCRAM

			case kafka.Error:
				log.WithFields(logrus.Fields{
					"code":  ev.Code(),
					"error": ev.Error(),
				}).Error("Kafka producer error")
			}
		}
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}