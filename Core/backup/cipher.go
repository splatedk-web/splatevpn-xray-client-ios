// Package backup implements the Android-compatible SplateVPN encrypted backup format
// (PBKDF2-HMAC-SHA256 310,000 iterations + AES-256-GCM with AAD).
package backup

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"

	"golang.org/x/crypto/pbkdf2"
)

const (
	iterations = 310_000
	maxBytes   = 16 * 1024 * 1024
	kind       = "SplateVPN-Encrypted"
)

var aad = []byte("SplateVPN-Encrypted/1/PBKDF2-HMAC-SHA256/310000/AES-256-GCM")

type envelope struct {
	App        string `json:"app"`
	Version    int    `json:"version"`
	Iterations int    `json:"iterations"`
	Salt       string `json:"salt"`
	Nonce      string `json:"nonce"`
	Ciphertext string `json:"ciphertext"`
}

// Encrypt wraps a UTF-8 JSON backup document in an authenticated AES-256-GCM envelope.
func Encrypt(plaintextJSON, password string) (string, error) {
	if len(password) < 8 || len(password) > 1024 {
		return "", errors.New("password must be between 8 and 1024 characters")
	}
	plain := []byte(plaintextJSON)
	if len(plain) > maxBytes {
		return "", errors.New("backup payload exceeds 16 MB")
	}

	salt := make([]byte, 16)
	if _, err := io.ReadFull(rand.Reader, salt); err != nil {
		return "", fmt.Errorf("generate salt: %w", err)
	}
	nonce := make([]byte, 12)
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("generate nonce: %w", err)
	}

	key := pbkdf2.Key([]byte(password), salt, iterations, 32, sha256.New)
	defer zeroBytes(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	ciphertext := gcm.Seal(nil, nonce, plain, aad)

	doc := envelope{
		App:        kind,
		Version:    1,
		Iterations: iterations,
		Salt:       base64.StdEncoding.EncodeToString(salt),
		Nonce:      base64.StdEncoding.EncodeToString(nonce),
		Ciphertext: base64.StdEncoding.EncodeToString(ciphertext),
	}
	encoded, err := json.Marshal(doc)
	if err != nil {
		return "", err
	}
	return string(encoded), nil
}

// DecryptIfNeeded returns the original document if unencrypted, or decrypts an encrypted SplateVPN envelope.
func DecryptIfNeeded(document, password string) (string, error) {
	if len(document) > maxBytes*2 {
		return "", errors.New("backup is too large")
	}
	var env envelope
	if err := json.Unmarshal([]byte(document), &env); err != nil {
		return "", errors.New("invalid backup JSON")
	}
	if env.App != kind {
		return document, nil
	}
	if len(password) == 0 {
		return "", errors.New("this backup requires a password")
	}
	if len(password) > 1024 {
		return "", errors.New("password is too long")
	}
	if env.Version != 1 || env.Iterations != iterations {
		return "", errors.New("unsupported encrypted backup version")
	}

	salt, err := base64.StdEncoding.DecodeString(env.Salt)
	if err != nil || len(salt) != 16 {
		return "", errors.New("invalid backup salt")
	}
	nonce, err := base64.StdEncoding.DecodeString(env.Nonce)
	if err != nil || len(nonce) != 12 {
		return "", errors.New("invalid backup nonce")
	}
	ciphertext, err := base64.StdEncoding.DecodeString(env.Ciphertext)
	if err != nil || len(ciphertext) < 16 || len(ciphertext) > maxBytes+16 {
		return "", errors.New("invalid backup ciphertext")
	}

	key := pbkdf2.Key([]byte(password), salt, iterations, 32, sha256.New)
	defer zeroBytes(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	plain, err := gcm.Open(nil, nonce, ciphertext, aad)
	if err != nil {
		return "", errors.New("incorrect password or damaged backup")
	}
	return string(plain), nil
}

func zeroBytes(b []byte) {
	for i := range b {
		b[i] = 0
	}
}
