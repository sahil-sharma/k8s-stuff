# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM golang:1.26-alpine AS builder

# confluent-kafka-go needs gcc + librdkafka headers
RUN apk add --no-cache \
    gcc \
    g++ \
    musl-dev \
    librdkafka-dev \
    pkgconf \
    make

WORKDIR /build

# Cache dependencies first — only re-downloads when go.mod/go.sum change
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build both binaries
# -tags musl         → links librdkafka statically against musl (required for Alpine)
# CGO_ENABLED=1      → confluent-kafka-go requires cgo
# -ldflags="-s -w"   → strip debug info, reduces binary size
RUN CGO_ENABLED=1 GOOS=linux go build \
        -tags musl \
        -ldflags="-s -w -linkmode external -extldflags '-static'" \
        -o /out/producer \
        ./cmd/producer

RUN CGO_ENABLED=1 GOOS=linux go build \
        -tags musl \
        -ldflags="-s -w -linkmode external -extldflags '-static'" \
        -o /out/consumer \
        ./cmd/consumer

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM alpine:3.21

# ca-certificates → needed for HTTPS calls to Keycloak
# librdkafka      → shared library needed at runtime
RUN apk add --no-cache \
    ca-certificates

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy both binaries from builder
COPY --from=builder /out/producer .
COPY --from=builder /out/consumer .

# Ownership
RUN chown -R appuser:appgroup /app

USER appuser

# No default CMD — we override per Deployment in Kubernetes
# e.g. command: ["./producer"] or command: ["./consumer"]
