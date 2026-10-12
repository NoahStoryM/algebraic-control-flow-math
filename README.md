# 控制流的代数本质：数学背景与写作计划

「控制流的代数本质」（第一部）与重写的 Category Theory in Programming（第二部）背后的数学背景、写作计划与讨论记录。文章正文、代码与修订清单在 [NoahStoryM/algebraic-control-flow](https://github.com/NoahStoryM/algebraic-control-flow)；这里放的是正文以外的东西，供作者与参与的 AI 一起审改。

Mathematical background, writing plans and discussion records behind *The Algebraic Essence of Control Flow* (Part 1) and the rewrite of *Category Theory in Programming* (Part 2). The articles themselves live in [NoahStoryM/algebraic-control-flow](https://github.com/NoahStoryM/algebraic-control-flow).

> **在做盲读评审的 AI，请不要打开这个仓库。** 这里有后续各篇的计划和数学背景，读过以后就不算盲读了。
>
> **AI reviewers doing a blind read: please do not open this repository.** It contains the plans for later articles.

## 从哪里读起

1. [`CONTRIBUTING.md`](CONTRIBUTING.md)：工作约定。
2. [`series/overview.md`](series/overview.md)：系列总览、各篇状态、新对话从哪里读起。
3. 要写或要改哪一篇，就读 `articles/` 下那一篇的目录；数学问题读 [`math/background.md`](math/background.md)。

## 目录

| 路径 | 内容 | 原来的位置 |
| --- | --- | --- |
| `series/overview.md` | 系列目标、各篇一览、现状 | 总纲「总览」 |
| `series/positioning.md` | 第一部的定位、完成标准、发布与文献 | 总纲「定位与发布」 |
| `series/narrative-guide.md` | 叙事指南 | 总纲「叙事指南」 |
| `series/worlds-and-notation.md` | 各篇的世界、搬运与记号 | 总纲「世界与记号」 |
| `series/threads.md` | 伏笔与线索的台账 | 总纲「伏笔与线索」 |
| `series/math-notes.md` | 总纲里的数学背景页（指向 `math/background.md`） | 总纲「数学背景」 |
| `series/workflow.md` | 工作方式、环境与工具 | 总纲「工作方式」 |
| `series/revision-list.md` | 旧的修订清单，已搬到文章仓库的 issue，留作历史 | 总纲「修订清单」 |
| `math/background.md` | 两部的数学背景：论断、核对状态、归属、文献 | 文档「控制流系列：数学背景」 |
| `math/review-draft-2026-10-07.md` | 10/7 送审稿（快照） | 文档「后续写作计划与数学背景（送审稿）」 |
| `part2/ctp.md` | 第二部：CTP 初版现状、素材与文献 | 总纲「第二部：CTP」 |
| `articles/02-cps/` | 第二篇的总览、修订记录、核对代码 | 第二篇文档 |
| `articles/05-relations/` | 第五篇的分节状态、大纲（`plan.md`）、决定记录、用词、初稿、笔记、审稿记录 | 第五篇文档与它的工作目录 |
| `articles/06-monads/` | 第六篇的总览、大纲、代码 | 第六篇文档 |
| `articles/07-effects/` | 第七篇的两段草稿代码 | 总纲附件 |

这些文件 2026-10-12 从 Claude Docs 导出，正文里还会说「这份总纲」「标签页」「附件」「文档」，指的就是上表右列的原位置，对应到这里左列的文件。引用其他文档的地方已经改成仓库里的相对链接；`claude.ai/chat/…` 的链接是 Noah 的私人对话，别的人打不开。

还没有搬过来的：盲读评审的流程、提示词与评分表（里面有预测的标准答案），等 Noah 决定。

## 协议

文字 CC BY 4.0（见 [LICENSE-TEXT](LICENSE-TEXT)），代码 MIT（见 [LICENSE](LICENSE)）。
