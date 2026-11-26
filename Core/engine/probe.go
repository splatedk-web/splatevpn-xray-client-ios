package engine

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/xtls/xray-core/core"
	xraynet "github.com/xtls/xray-core/common/net"
	"splatevpn.dev/ios/core/imports"
)

// MeasureTCPDelay measures TCP handshake latency to host:port in milliseconds.
func MeasureTCPDelay(address string, port int, timeoutMs int) (int64, error) {
	if strings.TrimSpace(address) == "" || port < 1 || port > 65535 {
		return -1, errors.New("invalid server endpoint")
	}
	if timeoutMs <= 0 {
		timeoutMs = 3000
	}
	timeout := time.Duration(timeoutMs) * time.Millisecond
	target := net.JoinHostPort(address, strconv.Itoa(port))
	start := time.Now()
	conn, err := net.DialTimeout("tcp", target, timeout)
	if err != nil {
		return -1, err
	}
	_ = conn.Close()
	return max(time.Since(start).Milliseconds(), 1), nil
}

// MeasureURLDelay performs a real HTTP request through an in-memory Xray instance
// (no local listening port needed) and returns latency in milliseconds.
func MeasureURLDelay(link, fullConfigJSON, targetURL string, timeoutMs int) (int64, error) {
	if strings.TrimSpace(targetURL) == "" {
		targetURL = "http://www.gstatic.com/generate_204"
	}
	if timeoutMs <= 0 {
		timeoutMs = 5000
	}

	outbounds, serverHost, err := buildOutbounds(link, fullConfigJSON)
	if err != nil {
		return -1, err
	}

	cfg := object{
		"log":       object{"loglevel": "none"},
		"dns":       buildDNS(DefaultTunnelOptions(), serverHost),
		"inbounds":  []object{},
		"outbounds": outbounds,
	}
	rawJSON, err := marshalObject(cfg)
	if err != nil {
		return -1, err
	}

	parsed, err := core.LoadConfig("json", bytes.NewBufferString(rawJSON))
	if err != nil {
		return -1, fmt.Errorf("load probe Xray config: %w", err)
	}
	instance, err := core.New(parsed)
	if err != nil {
		return -1, fmt.Errorf("create probe Xray instance: %w", err)
	}
	if err := instance.Start(); err != nil {
		_ = instance.Close()
		return -1, fmt.Errorf("start probe Xray instance: %w", err)
	}
	defer func() { _ = instance.Close() }()

	timeout := time.Duration(timeoutMs) * time.Millisecond
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	transport := &http.Transport{
		DisableKeepAlives: true,
		DialContext: func(dialCtx context.Context, network, addr string) (net.Conn, error) {
			dest, err := xraynet.ParseDestination(network + ":" + addr)
			if err != nil {
				return nil, err
			}
			return core.Dial(dialCtx, instance, dest)
		},
	}
	defer transport.CloseIdleConnections()

	client := &http.Client{
		Transport: transport,
		Timeout:   timeout,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, targetURL, nil)
	if err != nil {
		return -1, err
	}
	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return -1, err
	}
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	_ = resp.Body.Close()
	if resp.StatusCode >= 500 {
		return -1, fmt.Errorf("upstream HTTP %d", resp.StatusCode)
	}
	return max(time.Since(start).Milliseconds(), 1), nil
}

// MeasureLinkTCPDelay extracts endpoint from a link and measures TCP handshake delay.
func MeasureLinkTCPDelay(link string, timeoutMs int) (int64, error) {
	profile, err := imports.ParseServerLink(link)
	if err != nil {
		return -1, err
	}
	return MeasureTCPDelay(profile.Address, profile.Port, timeoutMs)
}
