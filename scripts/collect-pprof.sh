#!/usr/bin/env bash
set -euo pipefail

# 設定
TARGET_BASE_URL="${TARGET_BASE_URL:-http://localhost:6060/debug/pprof}"
OUT_DIR="${OUT_DIR:-./profiles}"
INTERVAL_SEC="${INTERVAL_SEC:-60}"      # 何秒に一回切るか（CPUは期間サンプル）
CPU_WINDOW_SEC="${CPU_WINDOW_SEC:-30}"  # CPUプロファイルの収集窓

mkdir -p "${OUT_DIR}/cpu" "${OUT_DIR}/heap"

while true; do
  ts="$(date +%Y%m%d-%H%M%S)"

  # CPU: 直近 CPU_WINDOW_SEC 秒の CPU サンプルを取得
  CPU_OUT="${OUT_DIR}/cpu/cpu_${ts}.pb.gz"
  echo "[collect] CPU -> ${CPU_OUT}"
  # 取得中にワークロードを動かしておくと確実に中身が入る（Step6参照）
  go tool pprof -proto "${TARGET_BASE_URL}/profile?seconds=${CPU_WINDOW_SEC}" > "${CPU_OUT}" || true

  # HEAP: 取得時点のヒープスナップショット（inuse）
  HEAP_OUT="${OUT_DIR}/heap/heap_${ts}.pb.gz"
  echo "[collect] HEAP -> ${HEAP_OUT}"
  go tool pprof -proto "${TARGET_BASE_URL}/heap" > "${HEAP_OUT}" || true

  # ローテーション例: 直近100個だけ残す（必要なら）
  ls -1t "${OUT_DIR}/cpu"/cpu_*.pb.gz 2>/dev/null | tail -n +101 | xargs -r rm -f
  ls -1t "${OUT_DIR}/heap"/heap_*.pb.gz 2>/dev/null | tail -n +101 | xargs -r rm -f

  sleep "${INTERVAL_SEC}"
done
