.PHONY: all build test bench \
        bench-cpu bench-mem run-cpu run-mem run-server \
        pprof-cpu pprof-heap trace clean bench-compare \
        tools bench-fib bench-alloc bench-mutex \
        benchstat-fib benchstat-alloc benchstat-mutex \
        pprof-fib-before pprof-fib-after \
        pprof-alloc-before pprof-alloc-after \
        compare-fib compare-alloc compare-mutex

# ---------------------------
# 設定（必要なら上書き）
# ---------------------------
BENCH_TIME ?= 5s
BENCH_COUNT ?= 10

# pprof UI のポート（被りに注意）
PORT_FIB_BEFORE  ?= 18090
PORT_FIB_AFTER   ?= 18091
PORT_ALLOC_BEFORE?= 18092
PORT_ALLOC_AFTER ?= 18093

# ---------------------------
# 既存
# ---------------------------
all: build

build:
	go build ./...

test:
	go test ./...

bench:
	go test ./bench -bench=. -benchmem -benchtime=$(BENCH_TIME) -run=^\$$

bench-cpu:
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -cpuprofile cpu.pprof

bench-mem:
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -memprofile mem.pprof

run-cpu:
	go run ./cmd/cpu_hot -n 38 -workers 4 -cpuprofile cpu.pprof

run-mem:
	go run ./cmd/mem_hot -bytes 1024 -count 200000 -hold=true -memprofile heap.pprof

run-server:
	# ブロック/Mutexプロファイルを強めに取る設定例
	BLOCK_PROFILE_RATE_NS=1000 MUTEX_PROFILE_FRACTION=5 go run ./cmd/server


pprof-cpu:
	@echo "Open: http://localhost:18080/ui/"
	go tool pprof -http=0.0.0.0:18080 cpu.pprof

pprof-heap:
	@echo "Open: http://localhost:18081/ui/"
	go tool pprof -http=0.0.0.0:18081 heap.pprof

trace:
	go test ./bench -bench=^BenchmarkFib$$ -run=^\$$ -trace trace.out && go tool trace trace.out

clean:
	rm -f *.pprof trace.out cpu.pprof mem.pprof heap.pprof \
	      cpu_before.pprof cpu_after.pprof \
	      heap_before.pprof heap_after.pprof \
		  cpu.pb.gz \
		  profiles/cpu/* profiles/heap/*
	rm -rf tmp

# 既存のざっくり比較
bench-compare:
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -run=^\$$
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -run=^\$$
	go test ./bench -bench=^BenchmarkHotMutex$$ -benchmem -run=^\$$

# ---------------------------
# New: ツール（benchstat）
# ---------------------------
tools:
	@which benchstat >/dev/null 2>&1 || (echo "Installing benchstat..." && go install golang.org/x/perf/cmd/benchstat@latest)

# ---------------------------
# New: Before/After ベンチ（Fib/Alloc/Mutex）
# ---------------------------
bench-fib:
	@mkdir -p tmp
	@echo "==> Fib BEFORE (recursive)"; \
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/fib_before.txt
	@echo "==> Fib AFTER  (memoized)"; \
	go test ./bench -bench=^BenchmarkFibMemo$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/fib_after.txt

bench-alloc:
	@mkdir -p tmp
	@echo "==> Allocate BEFORE (plain)"; \
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/alloc_before.txt
	@echo "==> Allocate AFTER  (sync.Pool)"; \
	go test ./bench -bench=^BenchmarkAllocateWithPool$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/alloc_after.txt

bench-mutex:
	@mkdir -p tmp
	@echo "==> Mutex BEFORE (single lock)"; \
	go test ./bench -bench=^BenchmarkHotMutex$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/mutex_before.txt
	@echo "==> Mutex AFTER  (sharded)"; \
	go test ./bench -bench=^BenchmarkHotMutexSharded$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ | tee tmp/mutex_after.txt

# ---------------------------
# New: benchstat（統計比較）
# ---------------------------
benchstat-fib: tools
	@mkdir -p tmp
	@echo "==> collecting Fib BEFORE (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/fib_before_many.txt
	@echo "==> collecting Fib AFTER  (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkFibMemo$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/fib_after_many.txt
	@echo "==> benchstat (Fib)"; benchstat tmp/fib_before_many.txt tmp/fib_after_many.txt

benchstat-alloc: tools
	@mkdir -p tmp
	@echo "==> collecting Allocate BEFORE (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/alloc_before_many.txt
	@echo "==> collecting Allocate AFTER  (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkAllocateWithPool$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/alloc_after_many.txt
	@echo "==> benchstat (Allocate)"; benchstat tmp/alloc_before_many.txt tmp/alloc_after_many.txt

benchstat-mutex: tools
	@mkdir -p tmp
	@echo "==> collecting Mutex BEFORE (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkHotMutex$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/mutex_before_many.txt
	@echo "==> collecting Mutex AFTER  (x$(BENCH_COUNT))"; \
	go test ./bench -bench=^BenchmarkHotMutexSharded$$ -benchmem -count=$(BENCH_COUNT) -run=^\$$ > tmp/mutex_after_many.txt
	@echo "==> benchstat (Mutex)"; benchstat tmp/mutex_before_many.txt tmp/mutex_after_many.txt

# ---------------------------
# New: pprof（Before/After を別ポートで表示）
# ---------------------------
# CPU: Fib
pprof-fib-before:
	@echo "Open: http://localhost:$(PORT_FIB_BEFORE)/ui/"
	go test ./bench -bench=^BenchmarkFib$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -cpuprofile cpu_before.pprof
	go tool pprof -http=0.0.0.0:$(PORT_FIB_BEFORE) cpu_before.pprof

pprof-fib-after:
	@echo "Open: http://localhost:$(PORT_FIB_AFTER)/ui/"
	go test ./bench -bench=^BenchmarkFibMemo$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -cpuprofile cpu_after.pprof
	go tool pprof -http=0.0.0.0:$(PORT_FIB_AFTER) cpu_after.pprof

# HEAP: Allocate
pprof-alloc-before:
	@echo "Open: http://localhost:$(PORT_ALLOC_BEFORE)/ui/"
	go test ./bench -bench=^BenchmarkAllocate$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -memprofile heap_before.pprof
	go tool pprof -http=0.0.0.0:$(PORT_ALLOC_BEFORE) heap_before.pprof

pprof-alloc-after:
	@echo "Open: http://localhost:$(PORT_ALLOC_AFTER)/ui/"
	go test ./bench -bench=^BenchmarkAllocateWithPool$$ -benchmem -benchtime=$(BENCH_TIME) -run=^\$$ -memprofile heap_after.pprof
	go tool pprof -http=0.0.0.0:$(PORT_ALLOC_AFTER) heap_after.pprof

# ---------------------------
# New: まとめ実行（一発で比較）
# ---------------------------
compare-fib: bench-fib benchstat-fib
	@echo "==> Opening pprof (Fib BEFORE/AFTER)"
	@$(MAKE) -s pprof-fib-before & sleep 1; $(MAKE) -s pprof-fib-after

compare-alloc: bench-alloc benchstat-alloc
	@echo "==> Opening pprof (Alloc BEFORE/AFTER)"
	@$(MAKE) -s pprof-alloc-before & sleep 1; $(MAKE) -s pprof-alloc-after

compare-mutex: bench-mutex benchstat-mutex
	@echo "==> (Mutex は CPU/Block/Mutex の“待ち”が本質なので、Step3 のサーバ計測も併用推奨)"
