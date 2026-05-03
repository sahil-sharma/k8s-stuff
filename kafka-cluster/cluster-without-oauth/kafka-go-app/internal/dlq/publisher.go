package dlq

import (
	"fmt"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"github.com/sirupsen/logrus"
)

// Publisher sends failed messages to a Dead Letter Queue topic.
// Uses SCRAM-SHA-512 authentication.
type Publisher struct {
	producer *kafka.Producer
	topic    string
	log      *logrus.Logger
}

func NewPublisher(
	bootstrapServers string,
	topic string,
	username string,  // was: initialToken string
	password string,  // was: clientID string
	log *logrus.Logger,
) (*Publisher, error) {
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": bootstrapServers,
		"security.protocol": "SASL_PLAINTEXT",
		"sasl.mechanism":    "SCRAM-SHA-512",  // replaces OAUTHBEARER
		"sasl.username":     username,
		"sasl.password":     password,
		// REMOVE: sasl.oauthbearer.config

		// DLQ messages are small — no compression needed
		"compression.type": "none",

		// DLQ must be durable
		"acks":             "all",
		"retries":          3,
		"retry.backoff.ms": 500,
	})
	if err != nil {
		return nil, fmt.Errorf("create DLQ producer: %w", err)
	}

	// Drain delivery reports in background
	go func() {
		for e := range p.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					log.WithFields(logrus.Fields{
						"topic": *ev.TopicPartition.Topic,
						"error": ev.TopicPartition.Error,
					}).Error("DLQ delivery failed")
				} else {
					log.WithFields(logrus.Fields{
						"topic":     *ev.TopicPartition.Topic,
						"partition": ev.TopicPartition.Partition,
						"offset":    ev.TopicPartition.Offset,
					}).Debug("DLQ message delivered")
				}
			}
		}
	}()

	return &Publisher{producer: p, topic: topic, log: log}, nil
}

// Publish sends a failed message to the DLQ with error metadata in headers.
func (d *Publisher) Publish(
	originalMsg *kafka.Message,
	err error,
	attempt int,
) {
	headers := append(originalMsg.Headers,
		kafka.Header{Key: "dlq.error", Value: []byte(err.Error())},
		kafka.Header{Key: "dlq.original.topic", Value: []byte(*originalMsg.TopicPartition.Topic)},
		kafka.Header{Key: "dlq.original.partition", Value: []byte(fmt.Sprintf("%d", originalMsg.TopicPartition.Partition))},
		kafka.Header{Key: "dlq.original.offset", Value: []byte(fmt.Sprintf("%d", originalMsg.TopicPartition.Offset))},
		kafka.Header{Key: "dlq.attempts", Value: []byte(fmt.Sprintf("%d", attempt))},
		kafka.Header{Key: "dlq.timestamp", Value: []byte(time.Now().UTC().Format(time.RFC3339))},
	)

	dlqMsg := &kafka.Message{
		TopicPartition: kafka.TopicPartition{
			Topic:     &d.topic,
			Partition: kafka.PartitionAny,
		},
		Key:     originalMsg.Key,
		Value:   originalMsg.Value,
		Headers: headers,
	}

	if err := d.producer.Produce(dlqMsg, nil); err != nil {
		d.log.WithFields(logrus.Fields{
			"dlq_topic":       d.topic,
			"original_topic":  *originalMsg.TopicPartition.Topic,
			"original_offset": originalMsg.TopicPartition.Offset,
		}).WithError(err).Error("failed to publish to DLQ")
		return
	}

	d.log.WithFields(logrus.Fields{
		"dlq_topic":       d.topic,
		"original_topic":  *originalMsg.TopicPartition.Topic,
		"original_offset": originalMsg.TopicPartition.Offset,
		"attempts":        attempt,
		"error":           err.Error(),
	}).Warn("message sent to DLQ")
}

// REMOVE: UpdateToken — no OAuth tokens with SCRAM, nothing to refresh
func (d *Publisher) Close() {
	d.producer.Flush(5000)
	d.producer.Close()
}