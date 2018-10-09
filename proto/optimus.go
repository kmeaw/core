package sonm

import (
	"fmt"
)

func (m *PredictSupplierRequest) Normalize() {
	for id, dev := range m.GetDevices().GetGPUs() {
		dev.GetDevice().ID = fmt.Sprintf("%x", id)
		dev.GetDevice().FillHashID()
	}
}
