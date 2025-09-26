# benchstat の読み方

benchstat は「Before と After のベンチ結果」を統計的に比較してくれるツールです。
出力は3つの表が並ぶことが多いです（time/op、B/op、allocs/op）。

## 典型的な行の読み方（例）：

- 行の例：
    `BenchmarkFib-8 old time/op 25.7ms ± 3% new time/op 1.74µs ± 2% -99.99% (p=0.000 n=10+10)`
- 各列の意味：
  - old/new time/op … 1回あたりの実行時間。± はばらつき（標準偏差に基づく推定）
  - delta（-99.99%）… 新旧の差分（負は改善）
  - p=… … 統計的有意性（通常 p < 0.05 なら有意差あり）
  - n=10+10 … 測定回数（Before=10回、After=10回）
- 他の2表：
  - B/op（bytes per op）… 1回の実行で割り当てたバイト数
  - allocs/op … 割り当て回数

## 読み方のコツ

- time/op の delta をまず見る（性能そのもの）
- ついで B/op と allocs/op：割当削減が GC 負荷軽減→レイテンシ安定に効く
- p 値が十分に小さい（<0.05）なら「偶然の揺らぎでなく、改善と言える」

## 測定精度を上げる小技

- BENCH_TIME=10s（1サンプルを長く）
- BENCH_COUNT=20（サンプル数を多く）
- 温度や他負荷の影響が少ない状態で測る（DevContainer 内なら再現性↑）
