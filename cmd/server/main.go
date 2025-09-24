package main

import (
	"fmt"
	"log"
	"net/http"
	pp "net/http/pprof"
	"os"
	"runtime"
	"strconv"
	"time"

	"sugiyan97/go-prof-labs/internal/workload"
)

func main() {
	// Block/Mutexプロファイルのサンプリング調整（環境変数）
	if v := os.Getenv("BLOCK_PROFILE_RATE_NS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			runtime.SetBlockProfileRate(n) // 例: 1000ns
		}
	}
	if v := os.Getenv("MUTEX_PROFILE_FRACTION"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			runtime.SetMutexProfileFraction(n) // 例: 5
		}
	}

	mux := http.NewServeMux()

	// ---- pprof: 自前 mux に明示登録（DefaultServeMux だけに登録される問題への対処） ----
	mux.HandleFunc("/debug/pprof/", pp.Index)
	mux.HandleFunc("/debug/pprof/cmdline", pp.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", pp.Profile)
	mux.HandleFunc("/debug/pprof/symbol", pp.Symbol)
	mux.HandleFunc("/debug/pprof/trace", pp.Trace)
	// -----------------------------------------------------------------------------

	mux.HandleFunc("/work/cpu", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		n := atoiDefault(q.Get("n"), 50)
		workers := atoiDefault(q.Get("workers"), 4)
		total := workload.BurnCPU(n, workers)
		fmt.Fprintf(w, "cpu ok total=%d\n", total)
	})

	mux.HandleFunc("/work/mem", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		bytes := atoiDefault(q.Get("bytes"), 2048)
		count := atoiDefault(q.Get("count"), 50000)
		hold := q.Get("hold") != "false"
		n := workload.Allocate(bytes, count, hold)
		fmt.Fprintf(w, "mem ok allocated=%d (hold=%v)\n", n, hold)
	})

	mux.HandleFunc("/work/contention", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		iter := atoiDefault(q.Get("iter"), 10000)
		holdNs := atoiDefault(q.Get("holdNs"), 5000)
		h := &workload.HotMutex{}
		got := h.WorkWithContention(iter, holdNs)
		fmt.Fprintf(w, "contention ok data=%d\n", got)
	})

	mux.HandleFunc("/work/leak", func(w http.ResponseWriter, r *http.Request) {
		stop := make(chan struct{})
		workload.LeakGoroutines(100, stop) // 注意: デモ用
		time.AfterFunc(30*time.Second, func() { close(stop) })
		fmt.Fprintln(w, "leak started (auto stop after ~30s)")
	})

	addr := ":6060"
	log.Printf("listening on %s (pprof endpoints at /debug/pprof)", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}

func atoiDefault(s string, d int) int {
	if s == "" {
		return d
	}
	i, err := strconv.Atoi(s)
	if err != nil {
		return d
	}
	return i
}
