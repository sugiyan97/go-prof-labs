# Go プロファイリング学習ガイド

このドキュメントでは、Go のプロファイリング手法（pprof / trace）について学習観点を整理し、実行手順や改善前後の比較方法を示します。
実行した結果は各ステップの「結果記録」に追記してください。

## Step 1 — CPU プロファイル
### 学習観点

- どの関数が CPU 時間を消費しているかを特定する
- top（自己時間）と top -cum（累積時間）の違い
- list <関数名> でホット行を確認
- Graph で「どこから呼ばれて重いのか」を俯瞰

### 実行方法

- 改善前の CPU プロファイル: make pprof-fib-before
- 改善後（メモ化版）: make pprof-fib-after
- Before/After を並べて比較: make compare-fib
```shell
    make compare-fib

    ==> Fib BEFORE (recursive)
    goos: linux
    goarch: arm64
    pkg: sugiyan97/go-prof-labs/bench
    BenchmarkFib-8               226          26178138 ns/op               0 B/op          0 allocs/op
    PASS
    ok      sugiyan97/go-prof-labs/bench    8.579s
    ==> Fib AFTER  (memoized)
    goos: linux
    goarch: arm64
    pkg: sugiyan97/go-prof-labs/bench
    BenchmarkFibMemo-8       3463597              1719 ns/op            2128 B/op          8 allocs/op
    PASS
    ok      sugiyan97/go-prof-labs/bench    7.707s
    ==> collecting Fib BEFORE (x10)
    ==> collecting Fib AFTER  (x10)
    ==> benchstat (Fib)
    goos: linux
    goarch: arm64
    pkg: sugiyan97/go-prof-labs/bench
            │ tmp/fib_before_many.txt │ tmp/fib_after_many.txt │
            │         sec/op          │     sec/op       vs base   │
    Fib-8                   26.21m ± 1%
    FibMemo-8                                 1.676µ ± 3%
    geomean                 26.21m            1.676µ       ? ¹ ²
    ¹ benchmark set differs from baseline; geomeans may not be comparable
    ² ratios must be >0 to compute geomean

            │ tmp/fib_before_many.txt │ tmp/fib_after_many.txt │
            │          B/op           │      B/op        vs base   │
    Fib-8                  0.000 ± 0%
    FibMemo-8                                2.078Ki ± 0%
    geomean                           ¹      2.078Ki       ? ² ³
    ¹ summaries must be >0 to compute geomean
    ² benchmark set differs from baseline; geomeans may not be comparable
    ³ ratios must be >0 to compute geomean

            │ tmp/fib_before_many.txt │ tmp/fib_after_many.txt │
            │        allocs/op        │    allocs/op     vs base   │
    Fib-8                  0.000 ± 0%
    FibMemo-8                                  8.000 ± 0%
    geomean                           ¹        8.000       ? ² ³
    ¹ summaries must be >0 to compute geomean
    ² benchmark set differs from baseline; geomeans may not be comparable
    ³ ratios must be >0 to compute geomean
    ==> Opening pprof (Fib BEFORE/AFTER)
    Open: http://localhost:18090/ui/
    goos: linux
    goarch: arm64
    pkg: sugiyan97/go-prof-labs/bench
    BenchmarkFib-8          Open: http://localhost:18091/ui/
    goos: linux
    goarch: arm64
    pkg: sugiyan97/go-prof-labs/bench
```
- 開く URL:
  - （Before）http://localhost:18090/ui/
  - （After）http://localhost:18091/ui/ 

### 学ぶべきこと

- アルゴリズム改善の効果を数値で確認（Fib → FibMemo）
- 「25ms → 1.7µs」級の差を体感

## Step 2 — Heap プロファイル
### 学習観点

- alloc_space = 累積割当量（どれだけ作ったか）
- inuse_space = 現在保持量（どれだけ抱えているか）
- GC と割当の関係を理解する

### 実行方法

- 改善前の Heap プロファイル: make pprof-alloc-before
- 改善後（sync.Pool 利用）: make pprof-alloc-after
- Before/After を並べて比較: make compare-alloc
```shell
make compare-alloc
==> Allocate BEFORE (plain)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkAllocate-8        23444            228348 ns/op         1048580 B/op       1001 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    7.944s
==> Allocate AFTER  (sync.Pool)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkAllocateWithPool-8        79994             69259 ns/op           48594 B/op       1001 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    6.301s
==> collecting Allocate BEFORE (x10)
==> collecting Allocate AFTER  (x10)
==> benchstat (Allocate)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
                   │ tmp/alloc_before_many.txt │ tmp/alloc_after_many.txt │
                   │          sec/op           │      sec/op        vs base   │
Allocate-8                         238.7µ ± 4%
AllocateWithPool-8                                     71.15µ ± 2%
geomean                            238.7µ              71.15µ       ? ¹ ²
¹ benchmark set differs from baseline; geomeans may not be comparable
² ratios must be >0 to compute geomean

                   │ tmp/alloc_before_many.txt │ tmp/alloc_after_many.txt │
                   │           B/op            │       B/op         vs base   │
Allocate-8                        1.000Mi ± 0%
AllocateWithPool-8                                    47.46Ki ± 0%
geomean                           1.000Mi             47.46Ki       ? ¹ ²
¹ benchmark set differs from baseline; geomeans may not be comparable
² ratios must be >0 to compute geomean

                   │ tmp/alloc_before_many.txt │ tmp/alloc_after_many.txt │
                   │         allocs/op         │     allocs/op      vs base   │
Allocate-8                         1.001k ± 0%
AllocateWithPool-8                                     1.001k ± 0%
geomean                            1.001k              1.001k       ? ¹ ²
¹ benchmark set differs from baseline; geomeans may not be comparable
² ratios must be >0 to compute geomean
==> Opening pprof (Alloc BEFORE/AFTER)
Open: http://localhost:18092/ui/
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkAllocate-8     Open: http://localhost:18093/ui/
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkAllocateWithPool-8        80288             76500 ns/op           48593 B/op       1001 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    6.906s
Serving web UI on http://0.0.0.0:18093
   25440            231976 ns/op         1048580 B/op       1001 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    8.292s
Serving web UI on http://0.0.0.0:18092
```
- 開く URL
  - （Before）http://localhost:18092/ui/
  - （After）http://localhost:18093/ui/

### 学ぶべきこと

- 割当源を確認し、sync.Pool による GC 負荷削減を理解


## Step 3 — Block/Mutex プロファイル
### 学習観点

- Block プロファイル = 待機時間（channel, sync, syscall）
- Mutex プロファイル = ロック競合時間
- Goroutine ダンプでリークや詰まりを確認

### 実行方法

- サーバをバックグラウンド起動: make run-server
  - または以下のタスクを実行
  - VSCode のタスク「Step 3: 同期待ちの可視化（Block/Mutex/CPU）」を実行
- 追加で Block/Mutex プロファイルを表示したい場合:
  - Block: go tool pprof -http=:18083 http://localhost:6060/debug/pprof/block
  - Mutex: go tool pprof -http=:18084 http://localhost:6060/debug/pprof/mutex

### 学ぶべきこと

- ロック下で重い処理をすると Block/Mutex が跳ね上がる
- シャーディング（分割ロック）で改善可能


## Step 4 — Trace
### 学習観点

- CPU/Heap は点の濃さ → Trace は時間の流れ
- スケジューラの動き、GC の Stop-the-world、I/O 待ちを把握
- 「なぜ詰まったか」を時間軸で説明できる

### 実行方法

- make trace
```shell
make trace
go test ./bench -bench=^BenchmarkFib$ -run=^\$ -trace trace.out && go tool trace trace.out
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkFib-8                46          25117269 ns/op
PASS
ok      sugiyan97/go-prof-labs/bench    1.187s
2025/09/26 14:14:54 Preparing trace for viewer...
```
- 開いた Trace UI で Goroutines, GC, Scheduler を確認

### 学ぶべきこと

- Goroutines: 長時間 vs 短時間大量の違い
- GC: 間隔・停止時間・各フェーズの負荷
- Scheduler latency: CPU 過負荷やアンバランスを検知


## Step 5 — 改善実験
### 学習観点

- Before/After を数値とグラフで比較して改善を証明する
- Fib / Allocate / HotMutex それぞれで実験する

### 実行方法

- Fib の比較: make compare-fib
- Allocate の比較: make compare-alloc
- Mutex の比較: make compare-mutex
```shell
make compare-mutex
==> Mutex BEFORE (single lock)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkHotMutex-8        75637             78598 ns/op               0 B/op          0 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    6.750s
==> Mutex AFTER  (sharded)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
BenchmarkHotMutexSharded-8       3146959              1911 ns/op               0 B/op          0 allocs/op
PASS
ok      sugiyan97/go-prof-labs/bench    7.942s
==> collecting Mutex BEFORE (x10)
==> collecting Mutex AFTER  (x10)
==> benchstat (Mutex)
goos: linux
goarch: arm64
pkg: sugiyan97/go-prof-labs/bench
                  │ tmp/mutex_before_many.txt │ tmp/mutex_after_many.txt │
                  │          sec/op           │      sec/op        vs base   │
HotMutex-8                        78.71µ ± 1%
HotMutexSharded-8                                     1.871µ ± 0%
geomean                           78.71µ              1.871µ       ? ¹ ²
¹ benchmark set differs from baseline; geomeans may not be comparable
² ratios must be >0 to compute geomean

                  │ tmp/mutex_before_many.txt │ tmp/mutex_after_many.txt │
                  │           B/op            │      B/op        vs base │
HotMutex-8                       0.000 ± 0%
HotMutexSharded-8                                    0.000 ± 0%
geomean                                     ¹                    ? ² ¹ ³
¹ summaries must be >0 to compute geomean
² benchmark set differs from baseline; geomeans may not be comparable
³ ratios must be >0 to compute geomean

                  │ tmp/mutex_before_many.txt │ tmp/mutex_after_many.txt │
                  │         allocs/op         │    allocs/op     vs base │
HotMutex-8                       0.000 ± 0%
HotMutexSharded-8                                    0.000 ± 0%
geomean                                     ¹                    ? ² ¹ ³
¹ summaries must be >0 to compute geomean
² benchmark set differs from baseline; geomeans may not be comparable
³ ratios must be >0 to compute geomean
==> (Mutex は CPU/Block/Mutex の“待ち”が本質なので、Step3 のサーバ計測も併用推奨)
```
- 統計的に比較:
  - make benchstat-fib
  - make benchstat-alloc
  - make benchstat-mutex


## Step 6 — 運用設計
### 学習観点

- 本番での安全な pprof 取得方法を理解する
- オフライン解析パターンを試す

### 実行方法

- 本番から30秒 CPU プロファイルを取得し、ローカルで解析(make run-server 事前起動)
  - `go tool pprof -proto http://localhost:6060/debug/pprof/profile?seconds=30 > cpu.pb.gz`
    - （ヒープを取りたいなら http://localhost:6060/debug/pprof/heap）
  - `go tool pprof -http=:18080 cpu.pb.gz`

※ /ui を表示しても何も表示されない場合は以下のコマンドを実行してください。(make run-server, go tool pprof -proto ... の実行後別ターミナルにて)その後に再度 /ui を表示してください。
- `while true; do curl -s "http://localhost:6060/work/cpu?n=80&workers=8" >/dev/null; done`
- `while true; do curl -s "http://localhost:6060/work/contention?workers=16&iter=5000&holdNs=50000" >/dev/null; done `

## Step 7 — GC 実験
### 学習観点

- GC 調整によるレイテンシ・メモリのトレードオフを理解する
- GC よりも割当削減が本命であることを学ぶ

### 実行方法

- GC 頻度高め: GOGC=50 make run-mem
- GC 頻度低め: GOGC=200 make run-mem
- GC ログを出力:
  - GODEBUG=gctrace=1 go run ./cmd/mem_hot -bytes 1024 -count 200000 -hold=true
  ```shell
    GODEBUG=gctrace=1 go run ./cmd/mem_hot -bytes 1024 -count 200000 -hold=true
    gc 1 @0.014s 5%: 0.77+1.2+0.17 ms clock, 6.1+0.51/0.72/0+1.4 ms cpu, 3->4->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 2 @0.021s 7%: 0.85+1.8+0.010 ms clock, 6.8+0.18/1.0/0+0.081 ms cpu, 3->4->1 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 3 @0.026s 8%: 0.25+2.1+0.058 ms clock, 2.0+1.3/1.8/0.091+0.46 ms cpu, 3->3->1 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 4 @0.032s 8%: 0.31+1.8+0.005 ms clock, 2.5+1.1/1.9/0+0.043 ms cpu, 3->4->2 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 5 @0.035s 11%: 1.1+0.90+0.004 ms clock, 9.1+1.2/0.85/0.092+0.036 ms cpu, 5->6->2 MB, 6 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 6 @0.037s 11%: 0.16+1.3+0.003 ms clock, 1.3+0.24/1.0/0.88+0.027 ms cpu, 4->4->2 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 7 @0.039s 11%: 0.038+1.5+0.004 ms clock, 0.30+0.16/1.0/0.32+0.033 ms cpu, 4->4->2 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 8 @0.043s 11%: 0.043+0.78+0.006 ms clock, 0.34+0.086/0.71/0.57+0.055 ms cpu, 4->4->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 9 @0.045s 11%: 0.34+0.96+0.005 ms clock, 2.7+0.091/0.97/0+0.045 ms cpu, 4->4->2 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 10 @0.047s 11%: 0.15+1.8+0.004 ms clock, 1.2+0.56/1.0/0.038+0.035 ms cpu, 4->5->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 11 @0.050s 11%: 0.13+1.0+0.005 ms clock, 1.0+0.71/1.0/0+0.042 ms cpu, 4->5->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 12 @0.052s 11%: 0.28+0.91+0.003 ms clock, 2.2+0.053/0.97/0+0.028 ms cpu, 4->5->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 13 @0.054s 11%: 0.16+1.8+0.003 ms clock, 1.2+0.59/1.6/0.053+0.025 ms cpu, 4->5->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 1 @0.000s 28%: 0.48+1.1+0.057 ms clock, 3.8+0.038/0.79/0+0.45 ms cpu, 5->7->7 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 2 @0.003s 11%: 0.008+2.0+0.035 ms clock, 0.071+0.025/0.87/0.058+0.28 ms cpu, 12->18->18 MB, 15 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 3 @0.008s 9%: 0.008+1.4+0.14 ms clock, 0.065+0.038/0.97/0+1.1 ms cpu, 31->35->35 MB, 37 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 4 @0.023s 5%: 0.014+2.2+0.28 ms clock, 0.11+0.029/1.0/0.003+2.2 ms cpu, 66->67->67 MB, 72 MB goal, 0 MB stacks, 0 MB globals, 8 P
    gc 5 @0.061s 2%: 0.024+1.5+0.029 ms clock, 0.19+0/1.0/0.54+0.23 ms cpu, 128->129->129 MB, 134 MB goal, 0 MB stacks, 0 MB globals, 8 P
    2025/09/26 14:53:13 allocated items=200000
  ```

## Step 8 — 連続プロファイリング
### 学習観点

- Pyroscope / Parca など always-on 型で再現しづらい遅延を捕捉する
- 常時プロファイリングの価値を理解する

### 実行方法（例: Pyroscope）

この場合はツールの用意などが追加で必要です

- サーバ起動:
    - `docker run -it -p 4040:4040 -v /var/run/docker.sock:/var/run/docker.sock pyroscope/pyroscope:latest server`

### 実行方法(例: local)

この場合は現状の構成で収集できます
※ collect-pprof.sh に実行権限を付与していない場合は、こちらのコマンドを実行 `chmod +x scripts/collect-pprof.sh`


- 別ターミナルを 2つ用意して：
  - ターミナルA：サーバ
    ```shell
        make run-server
    ```
  - ターミナルB：ワークロード（連続でかけ続ける）
    ```shell
        # CPU 偏重の負荷
        while true; do curl -s "http://localhost:6060/work/cpu?n=80&workers=8" >/dev/null; done
        # 競合（Mutex/Block）を見たいならこちらに切り替え
        # while true; do curl -s "http://localhost:6060/work/contention?workers=16&iter=5000&holdNs=50000" >/dev/null; done
    ```
  - ターミナルC：収集
    ```shell
        TARGET_BASE_URL=http://localhost:6060/debug/pprof \
        OUT_DIR=./profiles \
        INTERVAL_SEC=60 \
        CPU_WINDOW_SEC=30 \
        scripts/collect-pprof.sh
    ```
- 可視化（後から好きな時点を開く）
    ```shell
        # 例：直近の CPU を開く  ブラウザ http://localhost:18080/ui/
        LATEST=$(ls -1t profiles/cpu/*.pb.gz | head -n1)
        echo "open $LATEST"
        go tool pprof -http=:18080 "$LATEST"

        # ヒープも同様
        LATEST_HEAP=$(ls -1t profiles/heap/*.pb.gz | head -n1)
        go tool pprof -http=:18081 "$LATEST_HEAP"
    ```
