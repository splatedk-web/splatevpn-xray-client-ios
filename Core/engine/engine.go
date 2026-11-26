package engine

import (
	"bytes"
	"errors"
	"fmt"
	"runtime/debug"
	"sync"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/features/stats"
	_ "github.com/xtls/xray-core/main/distro/all"
)

// ApplyExtensionMemoryLimit tunes the Go runtime for iOS NetworkExtension memory budgets.
func ApplyExtensionMemoryLimit(limitMB int64) {
	if limitMB < 10 {
		limitMB = 30
	}
	debug.SetGCPercent(25)
	debug.SetMemoryLimit(limitMB * 1024 * 1024)
}

// Engine owns an embedded Xray instance and serializes its lifecycle.
type Engine struct {
	mu       sync.Mutex
	instance *core.Instance
}

func NewEngine() *Engine {
	return &Engine{}
}

func (engine *Engine) IsRunning() bool {
	engine.mu.Lock()
	defer engine.mu.Unlock()
	return engine.instance != nil
}

// TrafficStats returns cumulative proxy outbound uplink and downlink byte counters.
func (engine *Engine) TrafficStats() (uplink int64, downlink int64) {
	engine.mu.Lock()
	instance := engine.instance
	engine.mu.Unlock()
	if instance == nil {
		return 0, 0
	}
	manager, ok := instance.GetFeature(stats.ManagerType()).(stats.Manager)
	if !ok || manager == nil {
		return 0, 0
	}
	if c := manager.GetCounter("outbound>>>proxy>>>traffic>>>uplink"); c != nil {
		uplink = c.Value()
	}
	if c := manager.GetCounter("outbound>>>proxy>>>traffic>>>downlink"); c != nil {
		downlink = c.Value()
	}
	return uplink, downlink
}

func (engine *Engine) Start(configuration string) error {
	engine.mu.Lock()
	defer engine.mu.Unlock()

	if engine.instance != nil {
		return errors.New("Xray is already running")
	}
	config, err := core.LoadConfig("json", bytes.NewBufferString(configuration))
	if err != nil {
		return fmt.Errorf("load Xray configuration: %w", err)
	}
	instance, err := core.New(config)
	if err != nil {
		return fmt.Errorf("initialize Xray: %w", err)
	}
	if err := instance.Start(); err != nil {
		closeErr := instance.Close()
		return errors.Join(fmt.Errorf("start Xray: %w", err), closeErr)
	}
	engine.instance = instance
	return nil
}

func (engine *Engine) Stop() error {
	engine.mu.Lock()
	defer engine.mu.Unlock()
	if engine.instance == nil {
		return nil
	}
	err := engine.instance.Close()
	engine.instance = nil
	return err
}
