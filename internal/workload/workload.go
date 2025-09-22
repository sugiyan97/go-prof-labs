package workload

import (
	"crypto/sha256"
	"math/rand"
	"sync"
	"time"
)

// CPUを食う作業（意図的に非効率）
func Fib(n int) int {
	if n < 2 {
		return n
	}
	return Fib(n-1) + Fib(n-2)
}

// CPUホットループ：仕事量を調整してCPUを継続的に使う
func BurnCPU(N, workers int) int {
	var wg sync.WaitGroup
	wg.Add(workers)
	resCh := make(chan int, workers)
	for w := 0; w < workers; w++ {
		go func() {
			defer wg.Done()
			sum := 0
			for i := 0; i < N; i++ {
				sum += Fib(30 + (i % 5)) // 少しバラしてサンプルを稼ぐ
			}
			resCh <- sum
		}()
	}
	wg.Wait()
	close(resCh)
	total := 0
	for v := range resCh {
		total += v
	}
	return total
}

// メモリアロケーション（大量に確保してオプションで保持）
var globalHold [][]byte

func Allocate(bytesPerItem, count int, hold bool) int {
	tmp := make([][]byte, 0, count)
	for i := 0; i < count; i++ {
		b := make([]byte, bytesPerItem)
		// 何か書いておく（最適化で消えないように）
		h := sha256.Sum256([]byte{byte(i)})
		copy(b, h[:])
		tmp = append(tmp, b)
	}
	if hold {
		globalHold = append(globalHold, tmp...)
	}
	return len(tmp)
}

// Goroutine/Mutex競合を発生させる（Block/Mutexプロファイル用）
type HotMutex struct {
	mu   sync.Mutex
	data int
}

func (h *HotMutex) WorkWithContention(iter, holdNs int) int {
	for i := 0; i < iter; i++ {
		h.mu.Lock()
		// 意図的にロック中に待つ（悪い例）
		busyWait(holdNs)
		h.data++
		h.mu.Unlock()
	}
	return h.data
}

func busyWait(ns int) {
	start := time.Now()
	for time.Since(start) < time.Duration(ns)*time.Nanosecond {
		_ = rand.Int() // ちょっとだけ計算
	}
}

// Goroutineリークのサンプル（使ったら止めること）
func LeakGoroutines(n int, stop <-chan struct{}) {
	for i := 0; i < n; i++ {
		go func() {
			t := time.NewTicker(10 * time.Second)
			defer t.Stop()
			for {
				select {
				case <-t.C:
				default:
					time.Sleep(100 * time.Millisecond)
				}
				select {
				case <-stop:
					return
				default:
				}
			}
		}()
	}
}
