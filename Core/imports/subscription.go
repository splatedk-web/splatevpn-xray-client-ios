package imports

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/url"
	"regexp"
	"strings"
	"unicode"
)

const (
	maxSubscriptionSize = 8 * 1024 * 1024
	incyPrefix          = "incy://crypt1/"
	maxIncyLinkSize     = 65536
)

var (
	errInvalidURL    = errors.New("invalid subscription URL")
	errInvalidIncy   = errors.New("invalid INCY crypt1 link")
	errEncryptedHapp = errors.New("unsupported encrypted Happ link")
	encryptedHapp    = regexp.MustCompile(`(?i)^happ://(?:crypto|crypt[0-9]*)(?:/|$)`)
	encodedHTTP      = regexp.MustCompile(`(?i)^https?%3a%2f%2f`)
	incyPayload      = regexp.MustCompile(`^[A-Za-z0-9_-]+={0,2}$`)
)

type SubscriptionLink struct {
	URL  string
	Name string
}

// ParseSubscriptionLink resolves a direct URL or an Android-compatible import link.
func ParseSubscriptionLink(raw string) (SubscriptionLink, error) {
	raw = strings.TrimSpace(raw)
	lower := strings.ToLower(raw)
	if strings.HasPrefix(lower, incyPrefix) {
		return decodeIncy(raw)
	}
	if encryptedHapp.MatchString(raw) {
		return SubscriptionLink{}, errEncryptedHapp
	}
	for _, prefix := range []string{"happ://add/", "incy://import/", "incy://add/"} {
		if strings.HasPrefix(lower, prefix) {
			raw = strings.TrimSpace(raw[len(prefix):])
			if encodedHTTP.MatchString(raw) {
				raw = unescape(raw)
			}
			break
		}
	}
	if !isHTTPURL(raw) {
		return SubscriptionLink{}, errInvalidURL
	}
	return SubscriptionLink{URL: raw}, nil
}

func isHTTPURL(raw string) bool {
	parsed, err := url.Parse(raw)
	return err == nil && parsed.Hostname() != "" &&
		(parsed.Scheme == "http" || parsed.Scheme == "https")
}

func decodeIncy(raw string) (SubscriptionLink, error) {
	if len(raw) > maxIncyLinkSize {
		return SubscriptionLink{}, errInvalidIncy
	}
	encoded := strings.TrimRight(raw[len(incyPrefix):], "/")
	if !incyPayload.MatchString(encoded) {
		return SubscriptionLink{}, errInvalidIncy
	}
	encoding := base64.RawURLEncoding
	if strings.HasSuffix(encoded, "=") {
		encoding = base64.URLEncoding
	}
	wire, err := encoding.DecodeString(encoded)
	if err != nil || len(wire) < 29 {
		return SubscriptionLink{}, errInvalidIncy
	}

	// Public K1 from INCY's MIT-licensed link encoder, also used by Android.
	key, err := base64.StdEncoding.DecodeString("9tQOoMioiZ18aC0Jug1BZd/is91F5rs+JcsjPPAMJGI=")
	if err != nil {
		return SubscriptionLink{}, errInvalidIncy
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return SubscriptionLink{}, errInvalidIncy
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return SubscriptionLink{}, errInvalidIncy
	}
	nonceSize := aead.NonceSize()
	plain, err := aead.Open(nil, wire[:nonceSize], wire[nonceSize:], nil)
	if err != nil {
		return SubscriptionLink{}, errInvalidIncy
	}
	var payload struct {
		Version int             `json:"v"`
		URL     string          `json:"url"`
		Name    json.RawMessage `json:"n"`
	}
	if err := json.Unmarshal(plain, &payload); err != nil || payload.Version != 1 || !isHTTPURL(payload.URL) {
		return SubscriptionLink{}, errInvalidIncy
	}
	var name string
	if err := json.Unmarshal(payload.Name, &name); err == nil {
		runes := []rune(strings.TrimSpace(name))
		name = string(runes[:min(len(runes), 128)])
	}
	return SubscriptionLink{URL: payload.URL, Name: name}, nil
}

// DecodeSubscriptionBody unwraps plain and Base64 text before profile parsing.
func DecodeSubscriptionBody(raw string) (string, error) {
	if len(raw) > maxSubscriptionSize {
		return "", errors.New("subscription exceeds 8 MB")
	}
	body := trimSubscription(raw)
	if header, payload, found := strings.Cut(body, ";base64,"); found &&
		strings.HasPrefix(strings.ToLower(header), "data:") {
		body = trimSubscription(payload)
	}
	for range 2 {
		if looksLikeProfileText(body) {
			break
		}
		decoded := trimSubscription(decodeBase64(body))
		if decoded == "" || strings.ContainsRune(decoded, 0) {
			break
		}
		if !looksLikeProfileText(decoded) && strings.IndexFunc(decoded, func(r rune) bool {
			return unicode.IsLetter(r) || unicode.IsDigit(r)
		}) < 0 {
			break
		}
		body = decoded
	}
	return body, nil
}

func trimSubscription(value string) string {
	return strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(value), "\uFEFF"))
}

func looksLikeProfileText(value string) bool {
	return strings.Contains(value, "://") || strings.HasPrefix(value, "{") ||
		strings.HasPrefix(value, "[") || strings.Contains(value, "proxies:") ||
		strings.Contains(value, "proxy-groups:") || strings.Contains(value, "rules:")
}

func decodeBase64(value string) string {
	replacer := strings.NewReplacer("-", "+", "_", "/")
	normalized := replacer.Replace(strings.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			return -1
		}
		return r
	}, value))
	encoding := base64.RawStdEncoding
	if strings.HasSuffix(normalized, "=") {
		encoding = base64.StdEncoding
	}
	decoded, err := encoding.DecodeString(normalized)
	if err != nil {
		return ""
	}
	return string(decoded)
}

func unescape(value string) string {
	decoded, err := url.PathUnescape(value)
	if err != nil {
		return value
	}
	return decoded
}
