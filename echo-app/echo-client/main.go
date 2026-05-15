package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

const (
	caBundlePath = "/etc/trust/ca.crt"
)

func main() {
	target := os.Getenv("TARGET")
	if target == "" {
		log.Fatal("TARGET env var required")
	}

	caPEM, err := os.ReadFile(caBundlePath)
	if err != nil {
		log.Fatalf("could not read CA bundle: %v", err)
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(caPEM) {
		log.Fatal("could not parse CA bundle")
	}

	client := &http.Client{
		Timeout: 5 * time.Second,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: pool,
			},
		},
	}

	for {
		resp, err := client.Get(target)
		ts := time.Now().UTC().Format(time.RFC3339)
		if err != nil {
			fmt.Printf("[%s] FAIL: %v\n", ts, err)
		} else {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			fmt.Printf("[%s] OK: %d bytes\n%s\n---\n", ts, len(body), string(body))
		}
		time.Sleep(5 * time.Second)
	}
}