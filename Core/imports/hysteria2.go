package imports

import (
	"errors"
	"net"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

var (
	hy2PortToken   = regexp.MustCompile(`^[0-9]+(?:-[0-9]+)?$`)
	hy2HopInterval = regexp.MustCompile(`^[0-9]+s?$`)
	hy2PinHex      = regexp.MustCompile(`^[0-9a-fA-F]{64}$`)
)

type portRange struct{ from, to int }

func parseHysteria2(raw string) (ServerProfile, error) {
	_, payload, found := strings.Cut(raw, "://")
	if !found {
		return ServerProfile{}, errors.New("invalid Hysteria2 link")
	}

	linkPart, fragment, hasFragment := strings.Cut(payload, "#")
	location, rawQuery, _ := strings.Cut(linkPart, "?")
	authority, _, _ := strings.Cut(location, "/")

	var auth, hostPort string
	if at := strings.LastIndexByte(authority, '@'); at >= 0 {
		auth = unescape(authority[:at])
		hostPort = authority[at+1:]
	} else {
		hostPort = authority
	}

	host, portText, err := splitHy2HostPorts(hostPort)
	if err != nil {
		return ServerProfile{}, err
	}

	query := parseQueryMap(rawQuery)
	obfs := strings.ToLower(strings.TrimSpace(query["obfs"]))
	if obfs != "" && obfs != "none" && obfs != "salamander" {
		return ServerProfile{}, errors.New("unsupported Hysteria2 obfuscation")
	}
	obfsPassword := query["obfs-password"]
	if obfs == "salamander" && obfsPassword == "" {
		return ServerProfile{}, errors.New("missing Salamander password")
	}

	pin := normalizePinSHA256(query["pinSHA256"])
	if pin != "" && !hy2PinHex.MatchString(pin) {
		return ServerProfile{}, errors.New("invalid Hysteria2 pinSHA256")
	}
	insecure := strings.ToLower(strings.TrimSpace(query["insecure"]))
	if (insecure == "1" || insecure == "true") && pin == "" {
		return ServerProfile{}, errors.New("Hysteria2 requires a valid certificate or pinSHA256")
	}

	hopSec, err := parseHy2HopInterval(query)
	if err != nil {
		return ServerProfile{}, err
	}

	authPorts, err := parseHy2Ports(portText)
	if err != nil {
		return ServerProfile{}, err
	}
	effectivePorts := authPorts
	for _, key := range []string{"mport", "ports"} {
		if v := strings.TrimSpace(query[key]); v != "" {
			parsed, err := parseHy2Ports(v)
			if err != nil {
				return ServerProfile{}, err
			}
			effectivePorts = parsed
		}
	}

	hopPorts := ""
	if len(effectivePorts) > 1 || effectivePorts[0].to > effectivePorts[0].from {
		hopPorts = formatHy2Ports(effectivePorts)
	}

	name := "Hysteria 2 · " + host
	if hasFragment {
		if decoded := strings.TrimSpace(decodeLabel(fragment)); decoded != "" {
			name = decoded
		}
	}

	return ServerProfile{
		Protocol:     Hysteria2,
		Name:         name,
		Address:      host,
		Port:         effectivePorts[0].from,
		Password:     auth,
		Network:      "hysteria",
		Security:     "tls",
		SNI:          strings.TrimSpace(query["sni"]),
		Obfs:         obfs,
		ObfsPassword: obfsPassword,
		PinSHA256:    pin,
		HopPorts:     hopPorts,
		HopInterval:  hopSec,
		RawLink:      raw,
	}, nil
}

func splitHy2HostPorts(hostPort string) (host, portText string, err error) {
	hostPort = strings.TrimSpace(hostPort)
	if hostPort == "" {
		return "", "", errors.New("missing Hysteria2 host")
	}
	if strings.HasPrefix(hostPort, "[") {
		closeIdx := strings.IndexByte(hostPort, ']')
		if closeIdx <= 1 {
			return "", "", errors.New("invalid IPv6 Hysteria2 host")
		}
		host = hostPort[1:closeIdx]
		if net.ParseIP(host) == nil {
			return "", "", errors.New("invalid IPv6 Hysteria2 address")
		}
		tail := hostPort[closeIdx+1:]
		if tail == "" {
			return host, "443", nil
		}
		if !strings.HasPrefix(tail, ":") {
			return "", "", errors.New("invalid Hysteria2 port separator")
		}
		return host, tail[1:], nil
	}
	if strings.Count(hostPort, ":") > 1 {
		return "", "", errors.New("IPv6 Hysteria2 host requires brackets")
	}
	if colon := strings.IndexByte(hostPort, ':'); colon >= 0 {
		host = strings.TrimSpace(hostPort[:colon])
		portText = strings.TrimSpace(hostPort[colon+1:])
	} else {
		host = hostPort
		portText = "443"
	}
	if host == "" {
		return "", "", errors.New("missing Hysteria2 host")
	}
	return host, portText, nil
}

func parseHy2Ports(value string) ([]portRange, error) {
	value = strings.TrimSpace(value)
	if value == "" || len(value) > 4096 {
		return nil, errors.New("invalid Hysteria2 ports")
	}
	var ranges []portRange
	for _, token := range strings.Split(value, ",") {
		token = strings.TrimSpace(token)
		if !hy2PortToken.MatchString(token) {
			return nil, errors.New("invalid Hysteria2 port range")
		}
		aStr, bStr, hasDash := strings.Cut(token, "-")
		from, err := strconv.Atoi(aStr)
		if err != nil || from < 1 || from > 65535 {
			return nil, errors.New("invalid Hysteria2 port")
		}
		to := from
		if hasDash {
			to, err = strconv.Atoi(bStr)
			if err != nil || to < from || to > 65535 {
				return nil, errors.New("invalid Hysteria2 port range")
			}
		}
		ranges = append(ranges, portRange{from: from, to: to})
	}
	sort.Slice(ranges, func(i, j int) bool { return ranges[i].from < ranges[j].from })
	merged := []portRange{ranges[0]}
	for _, r := range ranges[1:] {
		last := &merged[len(merged)-1]
		if r.from <= last.to+1 {
			if r.to > last.to {
				last.to = r.to
			}
		} else {
			merged = append(merged, r)
		}
	}
	return merged, nil
}

func formatHy2Ports(ranges []portRange) string {
	parts := make([]string, 0, len(ranges))
	for _, r := range ranges {
		if r.from == r.to {
			parts = append(parts, strconv.Itoa(r.from))
		} else {
			parts = append(parts, strconv.Itoa(r.from)+"-"+strconv.Itoa(r.to))
		}
	}
	return strings.Join(parts, ",")
}

func parseHy2HopInterval(query map[string]string) (int, error) {
	for _, key := range []string{"hop-interval", "hopInterval"} {
		v := strings.TrimSpace(query[key])
		if v == "" {
			continue
		}
		if !hy2HopInterval.MatchString(v) {
			return 0, errors.New("invalid Hysteria2 hop interval")
		}
		sec, err := strconv.Atoi(strings.TrimSuffix(v, "s"))
		if err != nil || sec < 5 {
			return 0, errors.New("Hysteria2 hop interval must be at least 5 seconds")
		}
		return sec, nil
	}
	return 30, nil
}

func normalizePinSHA256(raw string) string {
	s := strings.TrimSpace(raw)
	if len(s) >= 7 && strings.EqualFold(s[:7], "sha256:") {
		s = s[7:]
	}
	return strings.ReplaceAll(s, ":", "")
}

func parseQueryMap(rawQuery string) map[string]string {
	out := make(map[string]string)
	for _, part := range strings.Split(rawQuery, "&") {
		if k, v, ok := strings.Cut(part, "="); ok && strings.TrimSpace(k) != "" {
			out[unescape(strings.TrimSpace(k))] = unescape(v)
		}
	}
	return out
}
