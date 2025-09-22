#!/usr/bin/env bash
set -euo pipefail

echo "[post-create] Installing Go tools ..."

# ツールは適宜バージョンを固定したい場合は @vX.X.X を付与
TOOLS=(
  golang.org/x/tools/gopls@latest
  golang.org/x/tools/cmd/goimports@latest
  honnef.co/go/tools/cmd/staticcheck@latest
  github.com/go-delve/delve/cmd/dlv@latest
  github.com/segmentio/golines@latest
)

for t in "${TOOLS[@]}"; do
  echo "  -> go install $t"
  go install "$t"
done

echo "[post-create] Verifying Graphviz and Go toolchain ..."
dot -V || true
go version
gopls version || true

echo "[post-create] Done."
