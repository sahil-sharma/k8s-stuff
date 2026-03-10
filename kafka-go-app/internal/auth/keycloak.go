package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

const refreshBuffer = 30 * time.Second // refresh this long before expiry

type tokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"` // seconds
}

// Token holds the current access token and when it expires.
type Token struct {
	AccessToken string
	ExpiresAt   time.Time
}

// KeycloakClient fetches and proactively refreshes UMA tokens.
type KeycloakClient struct {
	ssoURL       string
	clientID     string
	clientSecret string
	audience     string
	httpClient   *http.Client
	log          *logrus.Logger

	mu      sync.RWMutex
	current *Token

	// OnRefresh is called after every successful token refresh.
	// Producer/consumer registers here to push the new token into librdkafka.
	OnRefresh func(tok Token)
}

func NewKeycloakClient(
	ssoURL, clientID, clientSecret, audience string,
	log *logrus.Logger,
) *KeycloakClient {
	return &KeycloakClient{
		ssoURL:       ssoURL,
		clientID:     clientID,
		clientSecret: clientSecret,
		audience:     audience,
		httpClient:   &http.Client{Timeout: 10 * time.Second},
		log:          log,
	}
}

// FetchUMAToken does a one-shot fetch and caches the result. Call once at startup.
func (k *KeycloakClient) FetchUMAToken() (Token, error) {
	return k.doRefresh()
}

// Current returns the cached token (safe for concurrent reads).
func (k *KeycloakClient) Current() Token {
	k.mu.RLock()
	defer k.mu.RUnlock()
	if k.current == nil {
		return Token{}
	}
	return *k.current
}

// StartRefreshLoop runs a background goroutine that proactively refreshes
// the token 30 seconds before expiry. Stops when ctx is cancelled.
// Must be called after a successful FetchUMAToken.
func (k *KeycloakClient) StartRefreshLoop(ctx context.Context) {
	go func() {
		for {
			sleep := k.sleepDuration()
			k.log.WithField("next_refresh_in", sleep.Round(time.Second).String()).
				Debug("token refresh loop sleeping")

			select {
			case <-ctx.Done():
				k.log.Info("token refresh loop stopped")
				return
			case <-time.After(sleep):
			}

			k.log.Info("proactively refreshing Keycloak token")
			tok, err := k.doRefresh()
			if err != nil {
				// On failure retry every 5s — don't crash the process
				k.log.WithError(err).Error("token refresh failed — retrying in 5s")
				select {
				case <-ctx.Done():
					return
				case <-time.After(5 * time.Second):
					continue
				}
			}

			if k.OnRefresh != nil {
				k.OnRefresh(tok)
			}
		}
	}()
}

// ── private helpers ───────────────────────────────────────────────────────────

// doRefresh runs the full two-step Keycloak flow and updates the cache.
func (k *KeycloakClient) doRefresh() (Token, error) {
	// Step 1 — client_credentials → base access token
	baseToken, err := k.fetchBaseToken()
	if err != nil {
		return Token{}, err
	}

	// Step 2 — UMA ticket exchange → kafka-authorized token
	tok, err := k.exchangeUMA(baseToken)
	if err != nil {
		return Token{}, err
	}

	k.mu.Lock()
	k.current = &tok
	k.mu.Unlock()

	k.log.WithFields(logrus.Fields{
		"client_id":      k.clientID,
		"audience":       k.audience,
		"expires_at":     tok.ExpiresAt.Format(time.RFC3339),
		"refresh_buffer": refreshBuffer.String(),
	}).Info("Keycloak token refreshed successfully")

	return tok, nil
}

func (k *KeycloakClient) sleepDuration() time.Duration {
	k.mu.RLock()
	defer k.mu.RUnlock()
	if k.current == nil {
		return 0
	}
	d := time.Until(k.current.ExpiresAt) - refreshBuffer
	if d < 0 {
		return 0
	}
	return d
}

func (k *KeycloakClient) fetchBaseToken() (string, error) {
	k.log.WithFields(logrus.Fields{
		"client_id": k.clientID,
		"grant":     "client_credentials",
	}).Debug("fetching base access token from Keycloak")

	form := url.Values{}
	form.Set("client_id", k.clientID)
	form.Set("client_secret", k.clientSecret)
	form.Set("grant_type", "client_credentials")

	resp, err := k.httpClient.Post(
		k.ssoURL,
		"application/x-www-form-urlencoded",
		strings.NewReader(form.Encode()),
	)
	if err != nil {
		return "", fmt.Errorf("client_credentials POST failed: %w", err)
	}
	defer resp.Body.Close()

	tr, err := k.readTokenResponse(resp)
	if err != nil {
		return "", fmt.Errorf("base token: %w", err)
	}

	k.log.WithField("expires_in_sec", tr.ExpiresIn).
		Debug("base access token obtained")

	return tr.AccessToken, nil
}

func (k *KeycloakClient) exchangeUMA(baseToken string) (Token, error) {
	k.log.WithFields(logrus.Fields{
		"audience": k.audience,
		"grant":    "uma-ticket",
	}).Debug("exchanging base token for UMA ticket")

	form := url.Values{}
	form.Set("grant_type", "urn:ietf:params:oauth:grant-type:uma-ticket")
	form.Set("audience", k.audience)

	req, err := http.NewRequest(http.MethodPost, k.ssoURL, strings.NewReader(form.Encode()))
	if err != nil {
		return Token{}, fmt.Errorf("build UMA request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Authorization", "Bearer "+baseToken)

	resp, err := k.httpClient.Do(req)
	if err != nil {
		return Token{}, fmt.Errorf("UMA POST failed: %w", err)
	}
	defer resp.Body.Close()

	tr, err := k.readTokenResponse(resp)
	if err != nil {
		return Token{}, fmt.Errorf("UMA token: %w", err)
	}

	k.log.WithField("expires_in_sec", tr.ExpiresIn).
		Debug("UMA ticket obtained")

	return Token{
		AccessToken: tr.AccessToken,
		ExpiresAt:   time.Now().Add(time.Duration(tr.ExpiresIn) * time.Second),
	}, nil
}

// readTokenResponse reads, checks status, and unmarshals a Keycloak token response.
func (k *KeycloakClient) readTokenResponse(resp *http.Response) (*tokenResponse, error) {
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response body: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		k.log.WithFields(logrus.Fields{
			"status_code": resp.StatusCode,
			"body":        string(body),
		}).Error("Keycloak returned non-200")
		return nil, fmt.Errorf("keycloak HTTP %d: %s", resp.StatusCode, string(body))
	}
	var tr tokenResponse
	if err := json.Unmarshal(body, &tr); err != nil {
		return nil, fmt.Errorf("unmarshal token response: %w", err)
	}
	return &tr, nil
}