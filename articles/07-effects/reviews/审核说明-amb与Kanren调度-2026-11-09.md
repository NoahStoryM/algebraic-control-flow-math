# amb、Kanren 的调度与 Stream ∘ Maybe：请 Astra 核对（2026-11-09）

这一轮请查**硬伤**：下面的说法在数学上、技术上是否成立，哪里说过头了、需要限定，怎样说才准确。叙事和章节安排先不管（那是 #66，等 Noah 定）。Claude 自己的看法另附在 `审核说明-amb与Kanren调度-Claude的看法.md`，请先回答本文，再读那一份。

## 一、背景

- 第五章用 `amb` 讲关系，后半照 Noah 的 ambKanren 实现一个 microKanren：目标是 `Subst → Subst`，回溯靠 `amb`。上一轮（11/6，#64）你核过第五章后半，其中第 18 条是结论里的「未解的线索」：`amb` 深度优先，`(run 1 (q) (conde [(nevero)] [(== q 1)]))` 不停，流写法能交错。
- 11/8 起，Noah 与 Claude 在 ambKanren 上研究这条线索：在保持 `Goal : Subst → Subst` 和直接风格的前提下，ambKanren 能否在局部实现 The Reasoned Schemer 第一版（TRS1）、第二版（TRS2）的搜索组合子，以及最少还缺什么控制能力。全部记录在 [ambKanren #14](https://github.com/NoahStoryM/ambKanren/issues/14)。
- 第六章计划认出单子，用通用的 reflect / reify 回看第五章的 `choose`；第七章讲多 prompt-tag 与代数效应（`series/threads.md` 的「后几篇要讲什么」）。本文的说法跨这三章。

### 记号与代码

原书 TRS2 的流与两个组合子（`trs2-impl.scm`）：

```racket
;; Inf a = '() | (cons a (Inf a)) | (→ (Inf a))      ; 最后一种是暂停（thunk）
(define (append-inf s t)                 ; 析取
  (cond [(null? s) t]
        [(pair? s) (cons (car s) (append-inf (cdr s) t))]
        [else (λ () (append-inf t (s)))]))   ; 遇到暂停就交换两支
(define (append-map-inf g s)             ; 合取
  (cond [(null? s) '()]
        [(pair? s) (append-inf (g (car s)) (append-map-inf g (cdr s)))]
        [else (λ () (append-map-inf g (s)))]))
;; defrel 在关系体外包一层暂停：(λ (s) (λ () ((conj g ...) s)))
```

amb 库（Noah 的 `amb`）：`(amb e ...)` 建一个选择点；`(amb)` 失败；`(in-amb/do e)` 是一个局部搜索，逐个交出 `e` 的结果，内部只有一条前沿（默认深度优先）。

局部组合（Claude 的原型，`ambKanren` 分支 `research/local-search-20261109`）：

```racket
(define (reify-goal g s) ...)            ; Goal × Subst → Inf：在 in-amb/do 里跑 (g s)
(define (reflect s-inf)                  ; Inf → Subst：回到直接风格
  (cond [(null? s-inf) (amb)]
        [(pair? s-inf) (amb (car s-inf) (reflect (cdr s-inf)))]
        [else (suspend) (reflect (s-inf))]))
(define ((lift f) s) (reflect (f s)))
(define (disj2 g1 g2) (lift (λ (s) (append-inf (reify-goal g1 s) (reify-goal g2 s)))))
(define (conj2 g1 g2) (lift (λ (s) (append-map-inf (λ (s) (reify-goal g2 s)) (reify-goal g1 s)))))
```

`suspend` 要让暂停被最近一层 `in-amb/do` 看到，又不丢掉剩余计算。amb 研究分支 `research/amb-empty-20261109` 为此新增：

```racket
(in-amb/do e #:empty-values vs)   ; 声明本层搜索用 vs 表示「空输出」
(amb-fail)                        ; : ⊥  没有产出（与 (amb) 相同）
(amb-empty)                       ; : ⊥  让最近一层搜索输出它声明的 vs；未声明时等同 (amb-fail)
(define (suspend) (when (amb #t #f) (amb-empty)))
```

## 二、实测的事实（供判断时引用，不必重核）

以下都在 Racket 9.3 上运行过，代码与输出见 ambKanren #14 及各分支。

- E1：原书 TRS1 中 `(run 1 (q) (condi [nevero] [else (== q 'R)]))` 不停。
- E2：13 个对照程序与原书 TRS2 的答案顺序比较：
  - ambKanren 现状（全局前沿）13 个全同；
  - 只按答案交错的局部析取：5 个饿死，3 个顺序不同；
  - 局部析取加函数复合的合取：1 个饿死（合取的第一个目标有无限多个答案，第二个目标在第一个答案上无限暂停）；
  - 析取、合取都局部：13 个全同。
- E3：析取、合取、`ifte`、`once`、`defrel` 都照原书局部提升后，TRS2 书中例子严格比较通过（285 项）。现状 ambKanren 需要放宽 15 项。
- E4：未融合时，`very-recursiveo` 取 n 个答案的时间随 n 超线性增长（n 翻倍，时间约变为 4 到 6 倍）。加入 `reify (lift f) = f`，并让 `defrel` 直接提升原书的 thunk 后，变为线性：10⁶ 个答案约 5 秒，原书流实现约 2 秒，现状 ambKanren 约 64 秒。
- E5：融合后跑完 285 项，`suspend` 与 `reflect` 调用次数为 0。amb 只用于 `==` 等直接风格的叶子目标（约 334 万次局部搜索）。
- E6：用单独的 prompt tag 表示暂停（不改 amb）时：`(run* q (raw-once (oneo q)) (== q 1))` 期望 `(1)`，实得 `()`。这里 `raw-once` 是 Goal 内部一个没有装暂停 prompt 的普通 `in-amb/do`。改用 `amb-empty` 后得到 `(1)`。
- E7：只用 amb master（没有 `amb-empty`）、在 `reflect` 处强制暂停的版本也通过 285 项。但「手写的直接风格目标，其中调用的组合子目标无限暂停而永无答案」会饿死兄弟分支；同一个组合子目标直接放进 `disj` 则不会。
- E8：在 `racket/stream` 上把暂停写成显式元素 `(stream-cons #:eager PAUSE e)`，三个 Kanren（μKanren、TRS1、TRS2）的书中测试严格通过；与原 pair / thunk 实现的答案与暂停轨迹在 250 个随机表达式上一致（miniKanren-typed PR #17）。在那个版本里，如果 Goal 自己遍历子目标的流来取第一个答案（遇到 PAUSE 就强制），同样会出现 E7 的饿死；用 `append-map-inf` 接着写则不会。

## 三、请逐条判断：成立 / 需要限定 / 不成立

**A. 单子与它的运算**

1. Kanren 的流是 `T a = Stream (1 + a)`，Nothing 表示暂停（静默步），不表示失败；失败是空流。原书的 `Inf a = μX. 1 + a × X + (1 → X)`，在尾部惰性的流上与 `μX. 1 + (1 + a) × X` 同构。E8 的显式 PAUSE 版就是这个同构。
2. 若取拼接作为 `mplus`，`T` 经由分配律 `Maybe ∘ Stream → Stream ∘ Maybe`（`Nothing ↦ [Nothing]`，`Just xs ↦ map Just xs`）成为单子。有限情形下，`T a` 是带一个额外常元的幺半群理论的自由代数：生成元是 `a`，常元是 tick。
3. TRS2 的 `append-inf` 在暂停处交换两支，不是拼接，所以 TRS2 只在「答案集合」意义下对应上面的单子；在严格的答案顺序下，它的析取不满足结合律，合取不满足通常的单子律。请判断这样说是否准确，并指出能成立的最强说法。
4. 这个单子有三个运算：`mzero : ∀a. T a`、`mplus`、`tick : ∀a. T a`（`tick = [Nothing]`），且 `tick >>= k = tick`。原书的 `defrel` 暂停就是 `tick ⊕ (g s)`。
5. 直接风格中，`amb` / `(amb)` 反射 `mplus` / `mzero`，`amb-empty` 反射 `tick`。Typed Racket 中 `(amb-empty) : ⊥`，对应 `tick : ∀a. T a`。`(amb PAUSE v)` 对应 `return PAUSE ⊕ v`，类型是 `T (Pause ∪ a)`，与 `tick ⊕ v` 不同：它把 Pause 交给了 continuation，即 `bind` 的 `k`。
6. 在 `reflect` 处强制暂停（E7）等于把单子沿 `catMaybes : Stream (1 + a) → Stream a` 送到 Stream 单子，即添上等式 `tick = mzero`。在有限流上，这是单子态射；在全是 Nothing 的无限流上，它不产出任何元素。E7 的饿死就是这里失去了生产性。
7. 暂停的三种处理方式（Pause 留在值里、`tick` 作为运算、商掉 `tick = mzero`）穷尽了在 `amb` 之上实现这个单子的选择。

**B. reify、reflect 与融合**

8. `in-amb/do` 加上暂停的观察，是 `T` 的 reify；`reflect` 是 reflect。原型满足：在答案与暂停的轨迹上，`reify ∘ reflect = id`（只有实测证据）。这与 Filinski 的 monadic reflection 是同一回事，还是只是同一个形状？
9. 融合律 `reify (lift f) = f`：语义上是恒等式，操作上去掉了一层嵌套驱动器。E4 的超线性来自递归关系每深入一层留下一层无法消去的中继。这个解释成立吗？
10. 由 E5：融合以后，组合子层完全在 `T` 里，amb 只承担直接风格的叶子。所以「用 amb 实现 Kanren」精确地说，是 `T` 的组合子加上 Stream 层对叶子的反射。

**C. 效应与 handler 的嵌套**

11. Maybe 的效应是不带值的中止。直接风格中就是另一个 prompt 加 abort，handler 把它变回 Nothing。
12. Maybe 的 handler 装在每一个 `in-amb`（Stream 的 handler）**之内**，得到 `Stream ∘ Maybe`：一次中止只结束当前分支，并向流里输出一个静默步。装在**之外**，得到 `Maybe ∘ Stream`：一次中止结束整个搜索。这就是台账里第七章「中止整个搜索与只中止一条分支两种意图」与「两个 tag 两种嵌套」。
13. E6 的反例是两层 handler 没有成对出现：内层 Stream handler 没有配 Maybe handler，中止越过它，被外层 Maybe handler 接住，内层搜索被整个中止。`amb-empty` 把两层合进同一个 handler，配对由构造保证；`#:empty-values` 是在观察端（reify）选择用什么值表示 Nothing。
14. 与「留给第二部」的问题对照：两个 tag 两种嵌套，哪种对？还有没有第三种？可以回答为：两种嵌套对应 `Stream ∘ Maybe` 与 `Maybe ∘ Stream`；第三种是 7 中的商（丢掉 Maybe），代价是生产性。这样说准确吗？会不会和 Zwart、Marsden 的 No-Go 结果冲突（台账里列为待核文献）？

**D. Kanren 的两个版本**

15. TRS1 没有独立于答案的暂停边界：目标一调用，就严格运行到第一个答案或失败（E1）。所以只按答案交错（用 `sequence-generate` 一次取一个答案）足以实现 `mplusi` / `bindi`；TRS2 则必须让暂停可观察。
16. TRS2 中，局部析取不够，合取也必须是局部组合子（E2）。用 1 到 7 的语言说：合取在 `T` 的 `bind` 里，而不是在 `amb` 的全局前沿上。

## 四、文献（都凭记忆，未核实）

请确认或更正，只引你核过原文的：

- Filinski 1994，Representing Monads（monadic reflection，reify / reflect）；
- Filinski 1999，Representing Layered Monads（台账已列）；
- Capretta 2005，General Recursion via Coinductive Types（delay 单子）；
- Kiselyov、Shan、Friedman、Sabry 2005，Backtracking, Interleaving, and Terminating Monad Transformers（交错与公平）；
- Plotkin 与 Power 关于代数运算的论文（具体篇目未定）；
- Zwart 与 Marsden，单子组合的 No-Go 定理（台账已列）。

## 五、附件

- [ambKanren #14](https://github.com/NoahStoryM/ambKanren/issues/14) 的报告与后续评论，包括 11/9 的更正（E5）；
- ambKanren `research/local-search-20261109` 分支的 `research/local-search/`：README、`compare.out`、`traces.out`、各 `trs2-*.rkt`；
- amb `research/amb-empty-20261109` 分支：`pkgs/amb/tests/amb-empty.rkt`；
- miniKanren-typed PR #17：`miniKanren/stream-pause/README.md`；
- 本仓库 #66（这条线怎样串起第五至七章）、`series/threads.md`、`articles/07-effects/two-tags-nesting-20261015.rkt`。

请按「判定、限定或修改、理由」逐条回答；做过运行检查的注明。
