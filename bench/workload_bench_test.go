package bench

import (
	"sync"
	"testing"

	"sugiyan97/go-prof-labs/internal/workload"
)

func BenchmarkFib(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = workload.Fib(35)
	}
}

func BenchmarkFibMemo(b *testing.B) {
	for i := 0; i < b.N; i++ {
		memo := map[int]int{}
		mu := sync.Mutex{}
		_ = workload.FibMemo(35, memo, &mu)
	}
}

func BenchmarkAllocate(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = workload.Allocate(1024, 1000, false)
	}
}

func BenchmarkAllocateWithPool(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = workload.AllocateWithPool(1024, 1000, false)
	}
}

func BenchmarkHotMutex(b *testing.B) {
	h := &workload.HotMutex{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = h.WorkWithContention(1000, 10)
	}
}

func BenchmarkHotMutexSharded(b *testing.B) {
	h := workload.NewHotMutexSharded(8)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = h.Work(1000)
	}
}
