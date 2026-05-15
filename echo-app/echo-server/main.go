package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

const (
	certPath = "/etc/tls/tls.crt"
	keyPath  = "/etc/tls/tls.key"
)

func handler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()

	// Read the cert and parse it for display
	certPEM, err := os.ReadFile(certPath)
	if err != nil {
		http.Error(w, "could not read cert", http.StatusInternalServerError)
		return
	}
	block, _ := pem.Decode(certPEM)
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		http.Error(w, "could not parse cert", http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "hello from %s over TLS\n", hostname)
	fmt.Fprintf(w, "cert subject:    %s\n", cert.Subject)
	fmt.Fprintf(w, "cert issuer:     %s\n", cert.Issuer)
	fmt.Fprintf(w, "cert valid from: %s\n", cert.NotBefore.Format(time.RFC3339))
	fmt.Fprintf(w, "cert valid to:   %s\n", cert.NotAfter.Format(time.RFC3339))
	fmt.Fprintf(w, "time on server:  %s\n", time.Now().UTC().Format(time.RFC3339))
}

func main() {
	srv := &http.Server{
		Addr:    ":8443",
		Handler: http.HandlerFunc(handler),
		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
	}

	log.Printf("starting echo-server on :8443")
	if err := srv.ListenAndServeTLS(certPath, keyPath); err != nil {
		log.Fatal(err)
	}
}