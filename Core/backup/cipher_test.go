package backup

import (
	"strings"
	"testing"
)

func TestBackupEncryptDecryptRoundTrip(t *testing.T) {
	const payload = `{"servers":[{"name":"DE-1","protocol":"vless"}]}`
	const pass = "splate-strong-passphrase"

	encrypted, err := Encrypt(payload, pass)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(encrypted, `"SplateVPN-Encrypted"`) {
		t.Fatalf("missing envelope header: %s", encrypted)
	}

	decrypted, err := DecryptIfNeeded(encrypted, pass)
	if err != nil {
		t.Fatal(err)
	}
	if decrypted != payload {
		t.Fatalf("round-trip mismatch: got %q, want %q", decrypted, payload)
	}

	if _, err := DecryptIfNeeded(encrypted, "wrong-password"); err == nil {
		t.Fatal("wrong password succeeded")
	}
	if _, err := Encrypt(payload, "short"); err == nil {
		t.Fatal("short password (<8 chars) was accepted")
	}

	plainPassThrough, err := DecryptIfNeeded(payload, "")
	if err != nil || plainPassThrough != payload {
		t.Fatalf("unencrypted JSON should pass through: %q, %v", plainPassThrough, err)
	}
}
