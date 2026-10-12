#!/bin/sh
# 用法：sh make-demos.sh <ambKanren 仓库的路径>
# 从 ambKanren 的 demo.rkt 生成两份副本，只改三处：
#   1. #lang 换成不做类型检查的 typed/racket/base/no-check
#   2. (require … typed/amb) 换成本目录下的 minimal-amb.rkt 或 frontier-amb.rkt
#   3. match-λ 写成 match-lambda（Racket 8.10 没有 match-λ；新版 Racket 可以去掉这一条）
for v in minimal frontier; do
  sed -e 's|#lang typed/racket/base|#lang typed/racket/base/no-check|' \
      -e "s|(require racket/match typed/amb)|(require racket/match \"$v-amb.rkt\")|" \
      -e 's/match-λ/match-lambda/g' "$1/demo.rkt" > "demo-$v.rkt"
done
