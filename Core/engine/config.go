package engine

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"

	"splatevpn.dev/ios/core/imports"
)

type object = map[string]any

// SOCKSConfiguration creates a loopback-only Xray listener for a server link.
func SOCKSConfiguration(link string, port int) (string, error) {
	if port < 1 || port > 65535 {
		return "", errors.New("invalid local SOCKS port")
	}
	return coreConfiguration(link, object{
		"listen": "127.0.0.1", "port": port, "protocol": "socks",
		"settings": object{"auth": "noauth", "udp": true},
	})
}

func packetTunnelConfiguration(link string, mtu int) (string, error) {
	if mtu < 1280 || mtu > 9000 {
		return "", errors.New("invalid packet tunnel MTU")
	}
	return coreConfiguration(link, object{
		"tag": "packet-tunnel", "protocol": "tun",
		"settings": object{"name": "splate-tunnel", "mtu": mtu},
	})
}

func coreConfiguration(link string, inbound object) (string, error) {
	server, err := imports.ParseServerLink(link)
	if err != nil {
		return "", err
	}
	proxy, err := outbound(server)
	if err != nil {
		return "", err
	}
	config, err := json.Marshal(object{
		"log":       object{"loglevel": "warning"},
		"inbounds":  []object{inbound},
		"outbounds": []object{proxy},
	})
	if err != nil {
		return "", fmt.Errorf("encode Xray configuration: %w", err)
	}
	return string(config), nil
}

func outbound(server imports.ServerProfile) (object, error) {
	endpoint := object{"address": server.Address, "port": server.Port}
	switch server.Protocol {
	case imports.SOCKS5:
		if server.Username != "" || server.Password != "" {
			endpoint["users"] = []object{{"user": server.Username, "pass": server.Password}}
		}
		return object{
			"tag":      "proxy",
			"protocol": "socks",
			"settings": object{"servers": []object{endpoint}, "version": "5"},
		}, nil
	case imports.Shadowsocks:
		endpoint["method"] = defaultString(server.Encryption, "aes-256-gcm")
		endpoint["password"] = server.Password
		endpoint["uot"] = true
		return object{
			"tag":      "proxy",
			"protocol": "shadowsocks",
			"settings": object{"servers": []object{endpoint}},
		}, nil
	case imports.Hysteria2:
		return hysteria2Outbound(server), nil
	case imports.VLESS, imports.VMess, imports.Trojan:
	default:
		return nil, errors.New("unsupported Xray protocol")
	}
	stream, err := streamSettings(server)
	if err != nil {
		return nil, err
	}
	settings := object{"packetEncoding": "xudp"}
	switch server.Protocol {
	case imports.VLESS:
		user := object{"id": server.ID, "encryption": defaultString(server.Encryption, "none")}
		if server.Flow != "" && server.Network == "tcp" &&
			(server.Security == "tls" || server.Security == "reality") {
			user["flow"] = server.Flow
		}
		endpoint["users"] = []object{user}
		settings["vnext"] = []object{endpoint}
	case imports.VMess:
		if server.ID == "" {
			return nil, errors.New("missing VMess user ID")
		}
		user := object{
			"id":       server.ID,
			"alterId":  0,
			"security": defaultString(server.Encryption, "auto"),
		}
		endpoint["users"] = []object{user}
		settings["vnext"] = []object{endpoint}
	case imports.Trojan:
		if server.Password == "" {
			return nil, errors.New("missing Trojan password")
		}
		endpoint["password"] = server.Password
		settings["servers"] = []object{endpoint}
	}
	return object{
		"tag": "proxy", "protocol": string(server.Protocol), "settings": settings, "streamSettings": stream,
	}, nil
}

func streamSettings(server imports.ServerProfile) (object, error) {
	stream := object{"network": server.Network, "security": server.Security}
	switch server.Network {
	case "tcp":
	case "ws":
		stream["wsSettings"] = object{"path": server.Path, "host": server.Host}
	case "grpc":
		stream["grpcSettings"] = object{"serviceName": server.Path, "authority": server.Host}
	case "httpupgrade":
		stream["httpupgradeSettings"] = object{"path": server.Path, "host": server.Host}
	case "xhttp":
		stream["xhttpSettings"] = object{
			"path": server.Path, "host": server.Host, "mode": server.Mode,
			"extra": object{"xPaddingBytes": server.Padding},
		}
	default:
		return nil, errors.New("unsupported transport for server-link configuration")
	}
	switch server.Security {
	case "none":
	case "tls":
		peer := defaultString(server.Host, server.Address)
		tls := object{
			"serverName":  defaultString(server.SNI, peer),
			"fingerprint": defaultString(server.Fingerprint, "chrome"),
		}
		if server.SNI != "" && server.SNI != peer && net.ParseIP(peer) == nil {
			tls["verifyPeerCertByName"] = peer
		}
		stream["tlsSettings"] = tls
	case "reality":
		if server.PublicKey == "" {
			return nil, errors.New("missing REALITY public key")
		}
		stream["realitySettings"] = object{
			"serverName":  defaultString(server.SNI, server.Address),
			"fingerprint": defaultString(server.Fingerprint, "chrome"),
			"publicKey":   server.PublicKey, "shortId": server.ShortID, "spiderX": server.SpiderX,
		}
	default:
		return nil, errors.New("unsupported transport security")
	}
	return stream, nil
}

func hysteria2Outbound(server imports.ServerProfile) object {
	tls := object{
		"serverName": defaultString(server.SNI, server.Address),
		"alpn":       []string{"h3"},
	}
	if server.PinSHA256 != "" {
		tls["pinnedPeerCertSha256"] = server.PinSHA256
	}

	stream := object{
		"network":          "hysteria",
		"security":         "tls",
		"hysteriaSettings": object{"version": 2, "auth": server.Password},
		"tlsSettings":      tls,
	}

	var masks []object
	if server.Obfs == "salamander" && server.ObfsPassword != "" {
		masks = append(masks, object{
			"type":     "salamander",
			"settings": object{"password": server.ObfsPassword},
		})
	}
	if server.HopPorts != "" {
		interval := server.HopInterval
		if interval < 5 {
			interval = 30
		}
		masks = append(masks, object{
			"type": "udphop",
			"settings": object{
				"mode":        "intervalLocal,intervalRemote",
				"interval":    interval,
				"remotePorts": server.HopPorts,
			},
		})
	}
	if len(masks) > 0 {
		stream["finalmask"] = object{"udp": masks}
	}

	return object{
		"tag":      "proxy",
		"protocol": "hysteria",
		"settings": object{
			"version": 2,
			"address": server.Address,
			"port":    server.Port,
		},
		"streamSettings": stream,
	}
}

func defaultString(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
