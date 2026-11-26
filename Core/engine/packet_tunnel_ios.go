package engine

import (
	"errors"
	"os"
	"strconv"
	"sync"

	"golang.org/x/sys/unix"

	"github.com/xtls/xray-core/common/platform"
)

// Xray reads this process-wide setting while creating its TUN inbound.
var packetTunnelStart sync.Mutex

// StartPacketTunnel starts Xray using a descriptor that carries Darwin utun frames.
// The caller owns fd. Xray takes its own duplicate during startup.
func (engine *Engine) StartPacketTunnel(link string, fd int, mtu int) error {
	opts := DefaultTunnelOptions()
	opts.MTU = mtu
	return engine.StartPacketTunnelWithOptions(link, "", fd, opts)
}

// StartPacketTunnelWithOptions starts Xray on a Darwin utun fd with full routing/DNS/stats options.
func (engine *Engine) StartPacketTunnelWithOptions(link, fullConfigJSON string, fd int, opts TunnelOptions) error {
	if fd < 3 {
		return errors.New("invalid packet tunnel descriptor")
	}
	if _, err := unix.FcntlInt(uintptr(fd), unix.F_GETFD, 0); err != nil {
		return err
	}
	config, err := PacketTunnelConfigurationWithOptions(link, fullConfigJSON, opts)
	if err != nil {
		return err
	}

	packetTunnelStart.Lock()
	defer packetTunnelStart.Unlock()

	previousFd, existedFd := os.LookupEnv(platform.TunFdKey)
	if err := os.Setenv(platform.TunFdKey, strconv.Itoa(fd)); err != nil {
		return err
	}
	defer func() {
		if existedFd {
			_ = os.Setenv(platform.TunFdKey, previousFd)
		} else {
			_ = os.Unsetenv(platform.TunFdKey)
		}
	}()

	if opts.AssetsDir != "" {
		previousAsset, existedAsset := os.LookupEnv(platform.AssetLocation)
		if err := os.Setenv(platform.AssetLocation, opts.AssetsDir); err != nil {
			return err
		}
		defer func() {
			if existedAsset {
				_ = os.Setenv(platform.AssetLocation, previousAsset)
			} else {
				_ = os.Unsetenv(platform.AssetLocation)
			}
		}()
	}

	return engine.Start(config)
}
