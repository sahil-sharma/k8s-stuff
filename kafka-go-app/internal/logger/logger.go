package logger

import (
	"os"
	"strings"

	"github.com/sirupsen/logrus"
)

// New creates a JSON-formatted logrus logger.
// Log level is driven by the LOG_LEVEL env var (default: info).
// Valid values: trace, debug, info, warn, error, fatal, panic
func New(component string) *logrus.Logger {
	log := logrus.New()

	log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02T15:04:05.000Z07:00",
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "level",
			logrus.FieldKeyMsg:   "message",
		},
	})

	log.SetOutput(os.Stdout)
	log.SetLevel(parseLevel(os.Getenv("LOG_LEVEL")))
	log.AddHook(&componentHook{component: component})

	return log
}

func parseLevel(lvl string) logrus.Level {
	switch strings.ToLower(strings.TrimSpace(lvl)) {
	case "trace":
		return logrus.TraceLevel
	case "debug":
		return logrus.DebugLevel
	case "warn", "warning":
		return logrus.WarnLevel
	case "error":
		return logrus.ErrorLevel
	case "fatal":
		return logrus.FatalLevel
	case "panic":
		return logrus.PanicLevel
	default:
		return logrus.InfoLevel
	}
}

// componentHook injects a "component" field into every log entry.
type componentHook struct{ component string }

func (h *componentHook) Levels() []logrus.Level { return logrus.AllLevels }
func (h *componentHook) Fire(e *logrus.Entry) error {
	e.Data["component"] = h.component
	return nil
}