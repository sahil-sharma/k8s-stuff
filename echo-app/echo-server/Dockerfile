FROM golang:1.26-alpine AS build
WORKDIR /src
COPY main.go .
RUN go mod init echo-server && CGO_ENABLED=0 go build -o /out/echo-server main.go

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=build /out/echo-server /usr/local/bin/echo-server
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/echo-server"]