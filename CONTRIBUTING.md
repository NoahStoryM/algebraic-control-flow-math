# 工作约定

写给接手这个仓库的人和 AI。作者是 Noah；思路是他的，AI 参与讨论、核对与审稿。参与的 AI 主要是 ChatGPT 的 Sol、Astra 与 Claude 的 Opus、Sonnet。

## 这个仓库管什么

- 管：两部背后的数学背景、各篇的写作计划与大纲、讨论里定下的事、审稿记录、草稿代码。
- 不管：文章正文、正文代码、核对工具、正文的修订清单。这些在 [algebraic-control-flow](https://github.com/NoahStoryM/algebraic-control-flow)，以那边为准。这里提到正文的行号，都指那边 `dev` 分支上的版本。
- 文章仓库不链接这个仓库；做盲读评审的 AI 不打开它。

## 怎么改

1. 要讨论或要改的事开一个 issue，一个 issue 一件事。认领时标 `Claude` 或 `GPT`，一个 issue 只归一家。
2. 从 `main` 拉分支，分支名带前缀 `claude/…` 或 `gpt/…`，一批改动一个分支，提 PR 合回 `main`。Noah 看过差异再合并；他说「改好后直接合并」时由提 PR 的一方合，合完手动关 issue。
3. PR 描述写清改了哪几处、对应哪些 issue。

## 写的时候

- 分清 Noah 说的、Noah 定的，和 AI 的建议。Noah 的原话照录，标日期。
- 每条论断标状态：已定 / 未定 / 实测 / 推导 / 凭记忆。标「未定」的是 Noah 的决定：问他，不替他定。
- 文献只引核对过的；凭记忆给出的条目标明「凭记忆，未核实」，核对后再去掉。不引一篇文献去支持它没说过的话。
- 改别人的段落时先读懂它的职责；Noah 亲手写的句子保留。
- 旧的计划被取代时不删，挪进 `archive/` 或在原处注明被什么取代。
- 写法跟文章仓库的 STYLE.md 一致：能用 Unicode 就用 Unicode，不用破折号。

## 环境

代码在 Racket 8.10 上能跑（`LC_ALL=C.UTF-8`）；Typed Racket 8.10 里 `∪` 没有绑定，要真检查类型时换成 `U`。细节见 [`series/workflow.md`](series/workflow.md) 的「环境与工具」。
