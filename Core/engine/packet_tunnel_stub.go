//go:build !ios

package engine

import "errors"

func (engine *Engine) StartPacketTunnel(link string, fd int, mtu int) error {
	return errors.New("packet tunnel descriptor mode requires iOS")
}

func (engine *Engine) StartPacketTunnelWithOptions(link, fullConfigJSON string, fd int, opts TunnelOptions) error {
	return errors.New("packet tunnel descriptor mode requires iOS")
}
