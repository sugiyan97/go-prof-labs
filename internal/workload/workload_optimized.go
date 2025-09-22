package workload

import (
	"crypto/sha256"
	"sync"
)

// ---------- 改善版 Fib （メモ化） ----------

// FibMemo はメモ化付きフィボナッチ
func FibMemo(n int, memo map[int]int, mu *sync.Mutex) int {
	mu.Lock()
	if v, ok := memo[n]; ok {
		mu.Unlock()
		return v
	}
	mu.Unlock()

	if n < 2 {
		return n
	}
	val := FibMemo(n-1, memo, mu) + FibMemo(n-2, memo, mu)

	mu.Lock()
	memo[n] = val
	mu.Unlock()
	return val
}

// BurnCPUMemo はメモ化を利用した CPU バージョン
func BurnCPUMemo(N, workers int) int {
	var wg sync.WaitGroup
	wg.Add(workers)
	resCh := make(chan int, workers)

	// 共有メモ（スレッドセーフ）
	memo := map[int]int{}
	var mu sync.Mutex

	for w := 0; w < workers; w++ {
		go func() {
			defer wg.Done()
			sum := 0
			for i := 0; i < N; i++ {
				sum += FibMemo(30+(i%5), memo, &mu)
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

// ---------- 改善版 Allocate （sync.Pool 利用） ----------

var bufPool = sync.Pool{
	New: func() any {
		return make([]byte, 1024)
	},
}

// AllocateWithPool は sync.Pool を使って割当回数を削減
func AllocateWithPool(bytesPerItem, count int, hold bool) int {
	tmp := make([][]byte, 0, count)
	for i := 0; i < count; i++ {
		b := bufPool.Get().([]byte)
		if cap(b) < bytesPerItem {
			b = make([]byte, bytesPerItem)
		} else {
			b = b[:bytesPerItem]
		}
		h := sha256.Sum256([]byte{byte(i)})
		copy(b, h[:])
		tmp = append(tmp, b)
		// 再利用可能に戻す
		bufPool.Put(b)
	}
	if hold {
		globalHold = append(globalHold, tmp...)
	}
	return len(tmp)
}

// ---------- 改善版 HotMutex （ロック分割 / シャーディング） ----------

// HotMutexSharded はシャーディングにより競合を削減
type HotMutexSharded struct {
	mus  []sync.Mutex
	data []int
}

func NewHotMutexSharded(shards int) *HotMutexSharded {
	return &HotMutexSharded{
		mus:  make([]sync.Mutex, shards),
		data: make([]int, shards),
	}
}

func (h *HotMutexSharded) Work(iter int) int {
	for i := 0; i < iter; i++ {
		idx := i % len(h.mus)
		h.mus[idx].Lock()
		h.data[idx]++
		h.mus[idx].Unlock()
	}
	sum := 0
	for _, v := range h.data {
		sum += v
	}
	return sum
}
