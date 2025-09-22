# syntax=docker/dockerfile:1.6
ARG VARIANT="1.24"
FROM golang:${VARIANT}-bookworm

ARG UID="1000"
ARG GID="1000"

RUN groupadd -g ${GID} vscode \
  && useradd -m -s /bin/bash -u ${UID} -g ${GID} vscode

# 基本ツール + pprof web 用 Graphviz
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git curl make bash-completion less unzip ca-certificates graphviz procps \
  && rm -rf /var/lib/apt/lists/*

# GOPATH とビルドキャッシュ用ディレクトリを vscode 所有に
RUN mkdir -p /go/pkg/mod /go/bin /home/vscode/.cache/go-build \
  && chown -R vscode:vscode /go \
  && chown -R vscode:vscode /home/vscode/.cache

ENV GOPATH=/go \
    GOCACHE=/home/vscode/.cache/go-build \
    PATH=/usr/local/go/bin:/go/bin:$PATH

WORKDIR /workspaces/go-prof-labs

USER vscode
