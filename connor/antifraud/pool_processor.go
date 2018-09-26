package antifraud

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/rcrowley/go-metrics"
	"github.com/sonm-io/core/connor/price"
	"github.com/sonm-io/core/connor/types"
	"github.com/sonm-io/core/util"
	"go.uber.org/atomic"
	"go.uber.org/zap"
	"gopkg.in/oleiade/lane.v1"
)

type updateFunc func(ctx context.Context, url string, workerID string) (float64, error)

type commonPoolProcessor struct {
	cfg      *ProcessorConfig
	log      *zap.Logger
	taskID   string
	workerID string
	deal     *types.Deal

	startTime       time.Time
	currentHashrate *atomic.Float64
	hashrateEWMA    metrics.EWMA
	hashrateQueue   *lane.Queue
	update          updateFunc
}

func newDwarfPoolProcessor(cfg *ProcessorConfig, log *zap.Logger, deal *types.Deal, taskID string) *commonPoolProcessor {
	workerID := fmt.Sprintf("c%s", deal.GetId().Unwrap().String())
	l := log.Named("dwarfpool").With(
		zap.String("deal_id", deal.GetId().Unwrap().String()),
		zap.String("task_id", taskID),
		zap.String("worker_id", workerID))

	return &commonPoolProcessor{
		log:             l,
		cfg:             cfg,
		taskID:          taskID,
		workerID:        workerID,
		startTime:       time.Now(),
		deal:            deal,
		hashrateEWMA:    metrics.NewEWMA(1 - math.Exp(-5.0/cfg.DecayTime)),
		currentHashrate: atomic.NewFloat64(float64(deal.BenchmarkValue())),
		hashrateQueue:   &lane.Queue{Deque: lane.NewCappedDeque(60)},
		update:          dwarfPoolUpdateFunc,
	}
}

func newNanoPoolProcessor(cfg *ProcessorConfig, log *zap.Logger, deal *types.Deal, taskID string) *commonPoolProcessor {
	workerID := fmt.Sprintf("x%s", deal.GetId().Unwrap().String())
	l := log.Named("nanopool").With(
		zap.String("deal_id", deal.GetId().Unwrap().String()),
		zap.String("task_id", taskID),
		zap.String("worker_id", workerID))

	return &commonPoolProcessor{
		log:             l,
		cfg:             cfg,
		taskID:          taskID,
		workerID:        workerID,
		startTime:       time.Now(),
		deal:            deal,
		hashrateEWMA:    metrics.NewEWMA(1 - math.Exp(-5.0/cfg.DecayTime)),
		currentHashrate: atomic.NewFloat64(float64(deal.BenchmarkValue())),
		hashrateQueue:   &lane.Queue{Deque: lane.NewCappedDeque(60)},
		update:          nanoPoolUpdateFunc,
	}
}

func (m *commonPoolProcessor) Run(ctx context.Context) error {
	m.hashrateEWMA.Update(int64(m.currentHashrate.Load() * 5.))
	m.hashrateEWMA.Tick()

	m.log.Info("starting task's warm-up")
	timer := time.NewTimer(m.cfg.TaskWarmupDelay)
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
	}

	timer.Stop()
	m.log.Info("task is warmed-up")

	// This should not be configured, as ticker in ewma is bound to 5 seconds
	ewmaTick := util.NewImmediateTicker(5 * time.Second)
	ewmaUpdate := util.NewImmediateTicker(1 * time.Second)
	track := util.NewImmediateTicker(m.cfg.TrackInterval)

	defer ewmaUpdate.Stop()
	defer ewmaTick.Stop()
	defer track.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ewmaUpdate.C:
			m.hashrateEWMA.Update(int64(m.currentHashrate.Load()))
		case <-ewmaTick.C:
			m.hashrateEWMA.Tick()
		case <-track.C:
			v, err := m.update(ctx, m.cfg.URL, m.workerID)
			if err != nil {
				m.log.Warn("failed to load data", zap.Error(err))
				continue
			}

			m.log.Debug("received new hashrate", zap.Float64("value", v))
			// WARN: don't forget to uncomment
			// m.currentHashrate.Store(v)
			// m.updateHashRateQueue(v)
		}
	}
}

func (m *commonPoolProcessor) TaskID() string {
	return m.taskID
}

func (m *commonPoolProcessor) TaskQuality() (bool, float64) {
	accurate := m.startTime.Add(m.cfg.TaskWarmupDelay).Before(time.Now())
	desired := float64(m.deal.BenchmarkValue())
	actual := m.hashrateEWMA.Rate()
	rate := actual / desired

	if !m.nonZeroHashrate() {
		rate = 0
	}

	return accurate, rate
}

func (m *commonPoolProcessor) updateHashRateQueue(v float64) {
	if !m.hashrateQueue.Full() {
		m.hashrateQueue.Append(v)
	} else {
		m.hashrateQueue.Shift()
		m.hashrateQueue.Append(v)
	}
}

func (m *commonPoolProcessor) nonZeroHashrate() bool {
	if m.hashrateQueue.Size() < 5 {
		return true
	}

	for i := 0; i < 5; i++ {
		v := m.hashrateQueue.Pop()
		m.hashrateQueue.Append(v)
		if v.(float64) > 0 {
			return true
		}
	}

	return false
}

type dwarfPoolWorker struct {
	Alive              bool    `json:"alive"`
	Hashrate           float64 `json:"hashrate"`
	HashrateCalculated float64 `json:"hashrate_calculated"`
	SecondSinceSubmit  int64   `json:"second_since_submit"`
}

type dwarfPoolResponse struct {
	Workers map[string]*dwarfPoolWorker `json:"workers"`
}

func dwarfPoolUpdateFunc(ctx context.Context, url string, workerID string) (float64, error) {
	data, err := price.FetchURLWithRetry(url)
	if err != nil {
		return 0, fmt.Errorf("failed to fetch dwarfpool data: %v", err)
	}

	resp := &dwarfPoolResponse{}
	if err := json.Unmarshal(data, resp); err != nil {
		return 0, fmt.Errorf("failed to parse dwarfpool response: %v", err)
	}

	worker, ok := resp.Workers[workerID]
	if !ok {
		return 0, fmt.Errorf("cannot find worker %s in reponse data", workerID)
	}

	var rate float64
	if worker.HashrateCalculated > 0 {
		rate = worker.HashrateCalculated
	} else {
		rate = worker.Hashrate
	}

	return rate * 1e6, nil
}

type nanoPoolWorker struct {
	ID       string `json:"id"`
	Hashrate string `json:"hashrate"`
	H1       string `json:"h1"`
	H3       string `json:"h3"`
	H6       string `json:"h6"`
	H12      string `json:"h12"`
	H24      string `json:"h24"`
}

type nanoPoolResponse struct {
	Data struct {
		Workers []*nanoPoolWorker `json:"workers"`
	} `json:"data"`
}

func nanoPoolUpdateFunc(ctx context.Context, url string, workerID string) (float64, error) {
	data, err := price.FetchURLWithRetry(url)
	if err != nil {
		return 0, fmt.Errorf("failed to fetch nanopool data: %v", err)
	}

	resp := &nanoPoolResponse{}
	if err := json.Unmarshal(data, resp); err != nil {
		return 0, fmt.Errorf("failed to parse nanopool response: %v", err)
	}

	found := true
	var workerData *nanoPoolWorker
	for _, w := range resp.Data.Workers {
		if w.ID == workerID {
			found = true
			workerData = w
			break
		}
	}

	if !found {
		return 0, fmt.Errorf("cannot find worker %s in reponse data", workerID)
	}

	z, _ := zap.NewDevelopment()
	z.Debug("full hashrate response from nanopool", zap.Any("response", *workerData))
	rate, err := strconv.ParseFloat(workerData.H1, 64)
	if err != nil {
		return 0, fmt.Errorf("failed to parse hashrate: %v", err)
	}

	return rate, nil
}
