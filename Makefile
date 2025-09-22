.PHONY: all build test bench bench-cpu bench-mem run-cpu run-mem run-server pprof-cpu pprof-heap trace clean bench-compare

all: build

build:
	go build ./...

test:
	go test ./...

bench:
	# すべてのベンチを実行（テストは実行しない: -run=^\$$）
	go test ./bench -bench=. -benchmem -run=^\$$

bench-cpu:
	# 厳密に BenchmarkFib のみ（メモ化版は含めない）
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -run=^\$$ -cpuprofile cpu.pprof

bench-mem:
	# 厳密に BenchmarkAllocate のみ
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -run=^\$$ -memprofile mem.pprof

run-cpu:
	go run ./cmd/cpu_hot -n 38 -workers 4 -cpuprofile cpu.pprof

run-mem:
	go run ./cmd/mem_hot -bytes 1024 -count 200000 -hold=true -memprofile heap.pprof

run-server:
	# ブロック/Mutexプロファイルを強めに取る設定例
	BLOCK_PROFILE_RATE_NS=1000 MUTEX_PROFILE_FRACTION=5 go run ./cmd/server

pprof-cpu:
	# 固定ポート & VS Code から開きやすいよう /ui/ を案内
	@echo "Open: http://localhost:18080/ui/"
	go tool pprof -http=0.0.0.0:18080 cpu.pprof

pprof-heap:
	@echo "Open: http://localhost:18081/ui/"
	go tool pprof -http=0.0.0.0:18081 heap.pprof

trace:
	go test ./bench -bench=^BenchmarkFib$$ -run=^\$$ -trace trace.out && go tool trace trace.out

clean:
	rm -f *.pprof trace.out cpu.pprof mem.pprof heap.pprof

# --- Before/After 比較（改善版ベンチ） ---
bench-compare:
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -run=^\$$
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -run=^\$$
	go test ./bench -bench=^BenchmarkHotMutex$$ -benchmem -run=^\$$
