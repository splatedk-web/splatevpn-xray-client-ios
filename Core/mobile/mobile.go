// Package mobile exposes a gomobile-compatible API for Swift (iOS App & PacketTunnelProvider).
package mobile

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/xtls/xray-core/core"
	"splatevpn.dev/ios/core/backup"
	"splatevpn.dev/ios/core/engine"
	"splatevpn.dev/ios/core/imports"
)

type subscriptionLinkDTO struct {
	URL  string `json:"url"`
	Name string `json:"name"`
}

type serverProfileDTO struct {
	Protocol       string `json:"protocol"`
	Name           string `json:"name"`
	Description    string `json:"description"`
	Address        string `json:"address"`
	Port           int    `json:"port"`
	Username       string `json:"username"`
	Password       string `json:"password"`
	ID             string `json:"id"`
	Flow           string `json:"flow"`
	Encryption     string `json:"encryption"`
	Network        string `json:"network"`
	Security       string `json:"security"`
	SNI            string `json:"sni"`
	Fingerprint    string `json:"fingerprint"`
	PublicKey      string `json:"publicKey"`
	ShortID        string `json:"shortId"`
	SpiderX        string `json:"spiderX"`
	Path           string `json:"path"`
	Host           string `json:"host"`
	Mode           string `json:"mode"`
	Padding        string `json:"padding"`
	RawLink        string `json:"rawLink"`
	FullConfigJSON string `json:"fullConfigJson"`
}

type trafficStatsDTO struct {
	Uplink   int64 `json:"uplink"`
	Downlink int64 `json:"downlink"`
}

type tunnelOptionsDTO struct {
	MTU                 int      `json:"mtu"`
	RoutingMode         string   `json:"routingMode"`
	DNSServer           string   `json:"dnsServer"`
	Sniffing            bool     `json:"sniffing"`
	BlockQUIC           bool     `json:"blockQuic"`
	EnableAdBlock       bool     `json:"enableAdBlock"`
	EnableTLSFragment   bool     `json:"enableTlsFragment"`
	EnableIPv6          bool     `json:"enableIpv6"`
	EnableAiSmartDNS    bool     `json:"enableAiSmartDns"`
	AiDNSProvider       string   `json:"aiDnsProvider"`
	ShareLanProxy       bool     `json:"shareLanProxy"`
	LanProxyPort        int      `json:"lanProxyPort"`
	LanProxyUser        string   `json:"lanProxyUser"`
	LanProxyPass        string   `json:"lanProxyPass"`
	AssetsDir           string   `json:"assetsDir"`
	CustomDirectDomains []string `json:"customDirectDomains"`
	CustomProxyDomains  []string `json:"customProxyDomains"`
	CustomBlockDomains  []string `json:"customBlockDomains"`
}

func CoreVersion() string {
	return core.Version()
}

func ApplyMemoryLimit(limitMB int64) {
	engine.ApplyExtensionMemoryLimit(limitMB)
}

func ParseSubscriptionLink(raw string) (string, error) {
	parsed, err := imports.ParseSubscriptionLink(raw)
	if err != nil {
		return "", err
	}
	encoded, err := json.Marshal(subscriptionLinkDTO{URL: parsed.URL, Name: parsed.Name})
	if err != nil {
		return "", fmt.Errorf("encode subscription link: %w", err)
	}
	return string(encoded), nil
}

func ParseServerLink(raw string) (string, error) {
	profile, err := imports.ParseServerLink(raw)
	if err != nil {
		return "", err
	}
	encoded, err := json.Marshal(toDTO(profile))
	if err != nil {
		return "", fmt.Errorf("encode server profile: %w", err)
	}
	return string(encoded), nil
}

func ParseServerSubscription(raw string) (string, error) {
	profiles, err := imports.ParseServerSubscription(raw)
	if err != nil {
		return "", err
	}
	dtos := make([]serverProfileDTO, 0, len(profiles))
	for _, p := range profiles {
		dtos = append(dtos, toDTO(p))
	}
	encoded, err := json.Marshal(dtos)
	if err != nil {
		return "", fmt.Errorf("encode server subscription: %w", err)
	}
	return string(encoded), nil
}

// MeasureTCPDelay measures TCP handshake latency to host:port in milliseconds.
func MeasureTCPDelay(address string, port int, timeoutMs int) (int64, error) {
	return engine.MeasureTCPDelay(address, port, timeoutMs)
}

// MeasureURLDelay measures real HTTP latency through an in-memory Xray instance.
func MeasureURLDelay(link, fullConfigJSON, targetURL string, timeoutMs int) (int64, error) {
	return engine.MeasureURLDelay(link, fullConfigJSON, targetURL, timeoutMs)
}

// EncryptBackup encrypts a JSON backup with the Android-compatible AES-256-GCM envelope.
func EncryptBackup(plaintextJSON, password string) (string, error) {
	return backup.Encrypt(plaintextJSON, password)
}

// DecryptBackup decrypts an encrypted SplateVPN backup envelope or returns plain JSON unchanged.
func DecryptBackup(document, password string) (string, error) {
	return backup.DecryptIfNeeded(document, password)
}

// BuildTunnelConfigJSON builds a validated Xray JSON config from JSON-encoded TunnelOptions.
func BuildTunnelConfigJSON(link, fullConfigJSON, optionsJSON string) (string, error) {
	opts, err := decodeTunnelOptions(optionsJSON)
	if err != nil {
		return "", err
	}
	return engine.PacketTunnelConfigurationWithOptions(link, fullConfigJSON, opts)
}

type TunnelEngine struct {
	inner *engine.Engine
}

func NewTunnelEngine() *TunnelEngine {
	return &TunnelEngine{inner: engine.NewEngine()}
}

func (t *TunnelEngine) StartWithOptionsJSON(link, fullConfigJSON string, fd int, optionsJSON string) error {
	opts, err := decodeTunnelOptions(optionsJSON)
	if err != nil {
		return err
	}
	return t.inner.StartPacketTunnelWithOptions(link, fullConfigJSON, fd, opts)
}

func (t *TunnelEngine) StartRawJSON(configJSON string) error {
	return t.inner.Start(configJSON)
}

func (t *TunnelEngine) Stop() error {
	return t.inner.Stop()
}

func (t *TunnelEngine) IsRunning() bool {
	return t.inner.IsRunning()
}

func (t *TunnelEngine) TrafficStatsJSON() string {
	up, down := t.inner.TrafficStats()
	encoded, err := json.Marshal(trafficStatsDTO{Uplink: up, Downlink: down})
	if err != nil {
		return `{"uplink":0,"downlink":0}`
	}
	return string(encoded)
}

func decodeTunnelOptions(optionsJSON string) (engine.TunnelOptions, error) {
	opts := engine.DefaultTunnelOptions()
	if strings.TrimSpace(optionsJSON) == "" {
		return opts, nil
	}
	var dto tunnelOptionsDTO
	if err := json.Unmarshal([]byte(optionsJSON), &dto); err != nil {
		return opts, fmt.Errorf("decode tunnel options: %w", err)
	}
	if dto.MTU > 0 {
		opts.MTU = dto.MTU
	}
	if dto.RoutingMode != "" {
		opts.RoutingMode = dto.RoutingMode
	}
	if dto.DNSServer != "" {
		opts.DNSServer = dto.DNSServer
	}
	opts.Sniffing = dto.Sniffing
	opts.BlockQUIC = dto.BlockQUIC
	opts.EnableAdBlock = dto.EnableAdBlock
	opts.EnableTLSFragment = dto.EnableTLSFragment
	opts.EnableIPv6 = dto.EnableIPv6
	opts.EnableAiSmartDNS = dto.EnableAiSmartDNS
	opts.AiDNSProvider = dto.AiDNSProvider
	opts.ShareLanProxy = dto.ShareLanProxy
	opts.LanProxyPort = dto.LanProxyPort
	opts.LanProxyUser = dto.LanProxyUser
	opts.LanProxyPass = dto.LanProxyPass
	opts.AssetsDir = dto.AssetsDir
	opts.CustomDirectDomains = dto.CustomDirectDomains
	opts.CustomProxyDomains = dto.CustomProxyDomains
	opts.CustomBlockDomains = dto.CustomBlockDomains
	return opts, nil
}

func toDTO(p imports.ServerProfile) serverProfileDTO {
	return serverProfileDTO{
		Protocol:       string(p.Protocol),
		Name:           p.Name,
		Description:    p.Description,
		Address:        p.Address,
		Port:           p.Port,
		Username:       p.Username,
		Password:       p.Password,
		ID:             p.ID,
		Flow:           p.Flow,
		Encryption:     p.Encryption,
		Network:        p.Network,
		Security:       p.Security,
		SNI:            p.SNI,
		Fingerprint:    p.Fingerprint,
		PublicKey:      p.PublicKey,
		ShortID:        p.ShortID,
		SpiderX:        p.SpiderX,
		Path:           p.Path,
		Host:           p.Host,
		Mode:           p.Mode,
		Padding:        p.Padding,
		RawLink:        p.RawLink,
		FullConfigJSON: p.FullConfigJSON,
	}
}
