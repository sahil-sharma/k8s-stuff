package health

import (
	"context"
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"
)

// Status holds the current health and readiness state.
// Both producer and consumer embed this and update it.
type Status struct {
	ready   atomic.Bool // flipped to true once connected to Kafka
	healthy atomic.Bool // flipped to false on fatal errors
}

func NewStatus() *Status {
	s := &Status{}
	s.healthy.Store(true)  // healthy by default
	s.ready.Store(false)   // not ready until Kafka connected
	return s
}

func (s *Status) SetReady(v bool)   { s.ready.Store(v) }
func (s *Status) SetHealthy(v bool) { s.healthy.Store(v) }
func (s *Status) IsReady() bool     { return s.ready.Load() }
func (s *Status) IsHealthy() bool   { return s.healthy.Load() }

// Server exposes /health, /ready and /metrics on a dedicated port.
// This keeps Kafka traffic and observability traffic on separate ports.
type Server struct {
	addr   string
	status *Status
	log    *logrus.Logger
	srv    *http.Server
}

func NewServer(addr string, status *Status, log *logrus.Logger) *Server {
	return &Server{addr: addr, status: status, log: log}
}

// Start runs the HTTP server in a goroutine. Stops when ctx is cancelled.
func (s *Server) Start(ctx context.Context) {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/ready", s.handleReady)
	mux.Handle("/metrics", promhttp.Handler()) // Prometheus scrape endpoint

	s.srv = &http.Server{
		Addr:         s.addr,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
	}

	go func() {
		s.log.WithField("addr", s.addr).Info("health server listening")
		if err := s.srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.log.WithError(err).Error("health server error")
		}
	}()

	go func() {
		<-ctx.Done()
		shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = s.srv.Shutdown(shutCtx)
		s.log.Info("health server stopped")
	}()
}

// ── handlers ─────────────────────────────────────────────────────────────────

type response struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if !s.status.IsHealthy() {
		w.WriteHeader(http.StatusServiceUnavailable)
		_ = json.NewEncoder(w).Encode(response{Status: "unhealthy"})
		return
	}
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response{Status: "healthy"})
}

func (s *Server) handleReady(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if !s.status.IsReady() {
		w.WriteHeader(http.StatusServiceUnavailable)
		_ = json.NewEncoder(w).Encode(response{
			Status:  "not_ready",
			Message: "waiting for Kafka connection",
		})
		return
	}
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response{Status: "ready"})
}