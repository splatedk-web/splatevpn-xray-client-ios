package engine

import "strings"

type SmartDNSProvider struct {
	Key           string
	Label         string
	Host          string
	BootstrapIPv4 []string
}

func (p SmartDNSProvider) DoHURL() string {
	return "https://" + p.Host + "/dns-query"
}

var smartDNSProviders = []SmartDNSProvider{
	{Key: "dns_ai", Label: "DNS-AI", Host: "dns.dns-ai.ru", BootstrapIPv4: []string{"194.87.196.13", "45.151.102.219"}},
	{Key: "geohide", Label: "GeoHide RU", Host: "geohide.ru", BootstrapIPv4: []string{"159.194.200.33", "193.233.112.67", "193.233.112.88", "193.233.112.68"}},
	{Key: "geohide_eu", Label: "GeoHide EU", Host: "eu.geohide.ru", BootstrapIPv4: []string{"5.175.161.3", "5.175.161.40", "45.13.237.213"}},
	{Key: "malw", Label: "MALW", Host: "dns.malw.link", BootstrapIPv4: []string{"164.5.224.81", "179.254.166.171"}},
	{Key: "malw_gateway", Label: "MALW · CF", Host: "5u35p8m9i7.cloudflare-gateway.com", BootstrapIPv4: []string{"162.159.36.20", "162.159.36.5"}},
	{Key: "zapret_dns", Label: "Zapret DNS", Host: "dns.zapret.moe", BootstrapIPv4: []string{"83.217.211.149"}},
	{Key: "dagami", Label: "Dagami", Host: "dns.dagami.ru", BootstrapIPv4: []string{"48.102.213.179"}},
	{Key: "wlrus", Label: "WLRus", Host: "dns.wlrus.cfd", BootstrapIPv4: []string{"95.85.240.254", "138.124.254.134"}},
	{Key: "geodema", Label: "Geodema · Beta", Host: "dns.geodema.love", BootstrapIPv4: []string{"179.236.130.11", "179.236.130.10"}},
}

func resolveSmartDNSProvider(key string) SmartDNSProvider {
	norm := strings.ToLower(strings.TrimSpace(key))
	if norm == "comss" || norm == "comss_smart" || norm == "xbox" {
		norm = "dns_ai"
	}
	for _, p := range smartDNSProviders {
		if p.Key == norm {
			return p
		}
	}
	return smartDNSProviders[0]
}

var aiSmartDNSDomains = []string{
	"full:gemini.google.com",
	"full:generativelanguage.googleapis.com",
	"full:proactivebackend-pa.googleapis.com",
	"full:robinfrontend-pa.googleapis.com",
	"full:alkalimakersuite-pa.googleapis.com",
	"full:aisandbox-pa.googleapis.com",
	"full:geller-pa.googleapis.com",
	"full:waa-pa.googleapis.com",
	"full:aistudio.google.com",
	"full:makersuite.google.com",
	"full:notebooklm.google.com",
	"full:notebooklm.google",
	"full:labs.google",
	"full:labs.google.com",
	"full:jules.google.com",
	"full:opal.withgoogle.com",
	"full:bard.google.com",
	"full:deepmind.google",
	"full:copilot.microsoft.com",
	"full:sydney.bing.com",
	"full:edgeservices.bing.com",
	"full:githubcopilot.com",
	"full:api.githubcopilot.com",
	"full:copilot-proxy.githubusercontent.com",
	"full:duck.ai",
	"full:search.brave.com",
	"full:leo.brave.com",
	"full:ai-chat.bsg.brave.com",
	"full:openai.com",
	"full:chatgpt.com",
	"full:ws.chatgpt.com",
	"full:realtime.chatgpt.com",
	"full:ab.chatgpt.com",
	"full:chat.openai.com",
	"full:android.chat.openai.com",
	"full:ios.chat.openai.com",
	"full:api.openai.com",
	"full:auth.openai.com",
	"full:auth0.openai.com",
	"full:platform.openai.com",
	"full:oaistatic.com",
	"full:cdn.oaistatic.com",
	"domain:oaistatic.com",
	"full:oaiusercontent.com",
	"domain:oaiusercontent.com",
	"full:sora.com",
	"full:ai.com",
	"full:claude.ai",
	"full:claude.com",
	"full:anthropic.com",
	"full:anthropic.ai",
	"full:api.anthropic.com",
	"full:console.anthropic.com",
	"full:perplexity.ai",
	"full:api.perplexity.ai",
	"full:x.ai",
	"full:api.x.ai",
	"full:accounts.x.ai",
	"full:grok.com",
	"full:poe.com",
	"full:cursor.sh",
	"full:api2.cursor.sh",
	"full:cursor.com",
	"full:midjourney.com",
	"full:suno.com",
	"full:suno.ai",
	"full:elevenlabs.io",
	"full:character.ai",
	"full:lumo.proton.me",
	"full:lumo-api.proton.me",
}
