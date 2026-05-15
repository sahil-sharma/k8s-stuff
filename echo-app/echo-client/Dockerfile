FROM golang:1.26-alpine AS build
WORKDIR /src
COPY main.go .
RUN go mod init echo-client && CGO_ENABLED=0 go build -o /out/echo-client main.go

FROM alpine:latest
COPY --from=build /out/echo-client /usr/local/bin/echo-client
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/echo-client"]