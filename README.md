# Go プロファイラ学習ガイド

このドキュメントは Go 言語におけるプロファイラ (pprof, trace 等) の学習観点と、
実際に学習すべきタスク (TODO リスト) をまとめたものです。

---

## 学習すべき観点・内容

### 1. プロファイラの種類

- **CPU プロファイル**: サンプリングにより「どの関数に時間がかかっているか」を可視化
- **Heap (メモリ) プロファイル**: 割当／保持メモリの観測 (`alloc_space`, `inuse_space`)
- **Goroutine プロファイル**: 現在実行中／ブロック中のスタックを取得
- **Block プロファイル**: channel 送受信や sync の待機時間を可視化
- **Mutex プロファイル**: Mutex 競合のホットスポットを可視化
- **Trace**: スケジューライベント、GC、ネットワーク、タイムライン全体を観測

---

### 2. 収集方法

- `go test -cpuprofile/-memprofile/-trace`
- `runtime/pprof` (コードから取得)
- `net/http/pprof` (開発／本番サーバに組込み)
- 環境変数: `BLOCK_PROFILE_RATE_NS`, `MUTEX_PROFILE_FRACTION`

---

### 3. 解析コマンド (pprof)

- 基本: `top`, `top -cum`, `list <func>`, `web`
- Heap 特有: `-sample_index=alloc_space` / `inuse_space`
- Trace: `go tool trace trace.out`

---

### 4. 改善の観点

- **アルゴリズム改善**が最重要
- **割当削減**: `sync.Pool`、スライス再利用
- **同期削減**: ロック粒度縮小、Copy-on-Write
- **GC 調整**: `GOGC`, `GOMEMLIMIT`（最後の手段）

---

### 5. 運用上の注意

- 本番環境では `/debug/pprof` を **閉域／認証／ポートフォワード** 下で利用
- プロファイルをファイル出力 → S3 等で集約してローカル解析
- Kubernetes: `kubectl port-forward` を利用

---

## TODO リスト（学習ステップ）

- [ ] **Step 0**: 環境構築
  - Go 1.22+ / Graphviz / `go tool pprof` 動作確認
  - go mod tidy を最初に一度だけやっておく
- [ ] **Step 1**: CPU プロファイル基礎
  - `go test -cpuprofile` で Fib の CPU ボトルネックを確認
    * ns/op: 1 回の実行に何ナノ秒かかったか
      * → メモ化なしは ~25.7ms、メモ化ありは ~1.7µs と桁違い（アルゴリズム改善の威力）。
    * B/op / allocs/op: 1 回の実行で割り当てたメモリ量/回数
      * → メモ化は少し割当が発生（ハッシュマップ利用のため）しますが、CPU 時間は圧倒的に減少。
    * 画像として保存したい
      ```shell
      $ go tool pprof -png cpu.pprof > cpu.png
      $ go tool pprof -svg cpu.pprof > cpu.svg
      ```
- [ ] **Step 2**: Heap プロファイル基礎
  - `go test -memprofile` で割当と保持の違いを確認
- [ ] **Step 3**: Goroutine/Block/Mutex プロファイル
  - `net/http/pprof` 経由で競合・待ち時間を可視化
- [ ] **Step 4**: Trace 分析
  - `go test -trace` → `go tool trace` でスケジューラ・GC を観察
- [ ] **Step 5**: 改善実験
  - Fib をメモ化して CPU プロファイル改善を確認
  - Allocate を `sync.Pool` で改善して Heap プロファイル比較
  - ロック粒度を調整して Block/Mutex プロファイル比較
- [ ] **Step 6**: 運用設計
  - 本番での `/debug/pprof` セキュリティ設計を整理
- [ ] **Step 7**: GC チューニング実験
  - `GOGC=50` と `200` を比較し、レイテンシとメモリを観察
- [ ] **Step 8**: 連続プロファイリング
  - Pyroscope / Parca などを調査・試用

---

## 学習のゴール

- pprof / trace を自在に扱える
- ホットスポットを説明できる
- プロファイルを根拠に改善提案・実装ができる
