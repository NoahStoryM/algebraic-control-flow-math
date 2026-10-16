# 控制流系列：数学背景

Oct 8, 2026 · @Noah W.M

这份文档列出系列依赖的数学论断，力求准确、全面，用范畴论的词。它取代送审稿的「数学背景」和总纲的「数学背景」页。每条论断标核对程度，另有一列「归属」，写放第一部、第二部，还是第一部轻点、第二部回收；这一列由 Noah 逐条定，现在全部未定。

## 读法

编号沿用送审稿的 1.1–8.6，评审里引用的编号因此都还对得上；10/8 新增的论断放在第 9 组。每组一张表，四列：

- **论断**：已经改入评审里几家一致、Claude 核对成立的更正（Noah 10/8 定：这类更正直接改）。改了哪里、依据是什么，见文末「相对送审稿的改动」。
- **核对**：实测（代码跑过）、推导（按定义推出，没有查文献）、标准结论、凭记忆（没有对照原文）。后面括号里记谁核过。凭记忆的不能当作结论写进文章。
- **归属**：第一部 / 第一部轻点、第二部回收 / 第二部 / 不写。由 Noah 逐条定，现在全是「未定」。

这份文档与其他文档的关系：送审稿是 10/7 发出时的快照，不再改；总纲的「数学背景」页以后只留一句指向这里。这里是系列的理论账本，不是正文；正文的标准是「讲的东西不出差错」（Noah 10/8），不要求讲到这里的精度。

符号：𝒞 是宿主的范畴，按笛卡尔闭范畴处理；R 是答案类型；¬p 是内部的指数 R^p，在延续一侧 R 常写作 ⊥；Kl(T) 是单子 T 的 Kleisli 范畴。

## 第 1 组：延续（第一到四篇）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 1.1 | 取答案类型 R，¬p = R^p 是内部的指数。¬ : 𝒞 → 𝒞ᵒᵖ 是函子，并且与自己伴随：𝒞(p, ¬k) ≅ 𝒞(p × k, R) ≅ 𝒞(k, ¬p)，`flip` 就是这个 Hom 集双射。它给出延续单子 ¬¬；𝒦 是 Kl(¬¬)，𝒰 是同一个范畴写在对偶一侧的样子。外部的 Hom(−, R) 是到 Set 的函子，与内部的 ¬ 不是一回事。R 取空集时 ¬¬p 只记得 p 空不空，单子退化，要算出东西得让 R 非空 | 推导；记号问题 Sol、Astra、Opus、Sonnet 指出 | 第一部轻点（第三篇末尾的总结），AI 审稿读过以后再定（Noah 10/13） |
| 1.2 | `cps` 是单位 η（按「自然变换由它在态射上的作用定义」的约定，即 α(f) = α\_b ∘ F f）；`cps->neg²` 是 Kleisli 扩张；μ = `(cps->neg² values)` | 实测（外延相等） | 未定：命名 `let*` 宏所用的 Kleisli 复合对应 μ，第六篇也许提一下，写第六篇时定（Noah 10/13） |
| 1.3 | 𝒞 ≅ 𝒦 经 `(∘ call/cc cps:f)`，需要 `call/cc` 与第二篇注意框的两个前提；它是观察意义下的等价：来回一趟得到的程序在任何上下文中与原程序行为相同，不是语法上相等。𝒰 ≅ 𝒦 经 `flip`，对纯函数严格互逆；柯里化函数有副作用时不互逆 | 第二篇正文；限定 Astra、Sonnet、Sol 提出 | 第一部：第二篇注意框已写观察意义与三个前提；`flip` 对有副作用的柯里化函数不互逆，不写（Noah 10/13 无异议） |
| 1.4 | Hom(−, ⊥) 的元素范畴是切片 𝒞/⊥：对象是一个具体的延续 (p, k : p → ⊥)，态射是满足 kq ∘ f = kp 的 f。切片的切片还是切片：(𝒞/⊥)/(p, k) ≅ 𝒞/p，这就是「栈的切片」，答案类型从 ⊥ 换成了 p。⊥ 取空集时切片退化，只剩 ∅ → ∅ 一个对象，所以这里的 ⊥ 也要读作答案类型 | 推导，未查文献；退化一句各家在 M12 指出 | 第一部轻点（第二篇「计算的位置」的 `kp = (∘ kq f)` 就是切片的箭头条件，不给名字）、第二部回收（Noah 10/13 无异议） |
| 1.5 | 延续 k : p → R 是 𝒞/R 的对象；恒等 id\_R 是终对象，⊥ → R（第一篇的 `absurd`）是始对象。正文的「初始延续」指的是前者，名字与「始对象」相反；Noah 10/8 定改叫「终结延续」，记在修订清单里。`exit` 是终对象，要站在操作系统那一层看：程序的答案是 `Byte`，`exit` 相当于 `Byte` 上的恒等。另有三处注意：⊥ → R 是始对象，要 ⊥ 真是始对象，发散给出的 ⊥ 不算；切片只记一个复合好的延续，不记帧的序列和 tag；不是每个延续都能在任意位置切开（Sol 给了 Bool 的反例） | 推导；名字相反 DeepSeek、Opus、Qwen 指出 | 第二部；`exit` 与 `Byte` 那句不写（「终结延续」的名字已在第一部）（Noah 10/13 无异议） |
| 1.6 | 按值调用的 CPS 最接近 Kuroda 的否定翻译，按名调用对应 Kolmogorov（Murthy 1990，Cornell 博士论文） | 二手核对（10/16 Claude）：Leroy 2019 法兰西公学院讲座第 4 讲幻灯片 35–39 明说按名 CPS 的类型对应「相对化的」Kolmogorov 翻译（归于 Murthy 博论），按值 CPS 对应 Kuroda「节俭」翻译的变体。Ferreira–Oliva §6.4 只说两者有密切联系，没有逐一对应。Murthy 原文仍未取得 | 核实前不写；核实后可作第二篇「否定翻译」注意框的文献（Noah 10/13 无异议） |
| 1.7 | 答案类型可变时，eval(c) = c(id) : ((A → A) → B) → B，与 Atkey 的参数化单子一致（Parameterised Notions of Computation）。另一篇 Answer-Type Modification without Tears 的作者是 Kobori、Kameyama、Kiselyov，不是 Atkey | 凭记忆；归属更正 Sol、Astra、Opus、Sonnet 一致 | 第二部（Noah 10/13 无异议） |
| 1.8 | A-翻译一节的来历。异常单子 E p = p + a；先否定翻译再 A-翻译，得到 ((p + a) → a) → a。(p + a) → a 与一对函数 \[k, j\] 同构（余积的泛性质），k : p → a 是当前局部延续，j : a → a 处理提前到来的答案。接下来不是「省掉 j」的同构，而是特化：固定 j = id 后取值，得到 (p → a) → a。特化会把不同的计算等同起来：a 取 Bool，H₁ = λk j. j(false) 与 H₂ = λk j. false 在 j = id 处相等，在 j = not 处不等。正文能这样做，是因为一段局部计算里传进来的 j 始终是那一个恒等。提前返回就是不调用 k。带两个延续的 CPS 叫 double-barrelled CPS（Thielecke），整个构造对应 Friedman 的 A-翻译 | 推导；反例由 Sol 给出，Astra、Sonnet 同意；出处 Sol 给出，未核原文 | 第一部：正文不说成同构，出处作文献；随文章仓库 #20（Noah 10/13 同意） |
| 1.9 | run e = λk. \[k, id\] e 是从异常单子 E 到延续单子 C p = (p → a) → a 的单子态射；A-翻译之后那一步是 run 的 Kleisli 扩张 `(cps->neg² run)` | 推导，草图实测；Astra 形式化；Sol 确认 | 第二部（Noah 10/13 同意） |
| 1.10 | 自伴随 ¬ ⊣ ¬ 有两种等价的给法：`neg` 加 Hom 集双射 `flip`（1.1），或 `neg` 加单位 `cps`（1.2 的对角线约定）。两者互推：`cps = (∘ flip neg)`；反过来 `(flip h) = (∘ (neg h) cps:id)`，其中 `cps:id` 取在 ¬q 上（余单位在 𝒞ᵒᵖ 里，读回 𝒞 是 c → ¬¬c，与单位是同一族箭头，所以第三篇末尾总结里的 `cps` 可读作 (co)unit）。`neg`、`flip` 两两复合给出伴随的全部数据：`(∘ flip neg)` 是 J : 𝒞 → 𝒦，`(∘ neg flip)` 是 G(h♭) 即 Kleisli 扩张（1.2 的 `cps->neg²`），`(∘ neg neg)` 是 T，`(∘ flip flip)` 是恒等。生成 ¬¬ 的伴随至少有两个：¬ ⊣ ¬（中间范畴是 𝒰 ⊂ 𝒞ᵒᵖ，全是 lambda）与 inj ⊣ R（中间范畴是有 `call/cc` 的宿主）。𝒦 到两者各有比较函子，`flip` 与 `uncps`（后者要 `call/cc`），再经各自的右伴随 `neg` 与 R 回到纯宿主（R 作用在程序上要语法翻译，见 #15 的讨论与 `articles/06-monads/reviews/`）；𝒦 是其中最初的一个 | 推导（Noah 10/16）；互推与两两复合实测（Claude 10/16，`articles/02-cps/checks/neg-flip-two-presentations-1016.rkt`） | 未定。建议第二篇只用两两复合的表，不点名；其余第六篇或第二部 |

## 第 2 组：关系（第五篇）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 2.1 | Kl(P) ≅ Rel，P 是幂集单子。程序里只有有限分支，对应的是 Kl(P\_fin)，即「有限分支的关系」：每个输入只关联有限多个输出。第五篇后半的 ℛ 是后者，不是 Rel | 标准结论；有限分支一句 Sonnet 提出 | 第一部：第五篇以关系为主线，要体现关系范畴；介绍幂集与 Kl(P)，再说编程中为了方便，妥协用 List；「Kleisli」这个名字留到第六篇讲单子时再出场（Noah 10/13） |
| 2.2 | ℒ 是 Kl(List)。到有限分支的关系有「取支撑」的函子，保持复合，不忠实：列表多记了先后与重数 | Astra 10/1 | 第一部：正文不说 ℒ 与关系同构；Kl(List) 的名字留到第六篇（Noah 10/13 无异议） |
| 2.3 | 带 `amb` 的宿主 ℬ 与 ℒ 等价，只在受限意义下成立：有限终止、无其他效应、延续可多次调用、按 `in-amb` 收到的列表观察、一阶数据。理由是 `scatter` 与 `gather` 来回一趟不变；「两边表示的都是二元关系」不是理由，因为 ℒ 与关系本身不同构（见 2.2） | Astra 10/1；理由一句 Sol、Opus、Astra、Sonnet 一致 | 第一部（正文已限定为纯的、有限的搜索）（Noah 10/13 无异议） |
| 2.4 | `gather` 与 `scatter` 是 Filinski 的 reify 与 reflect 在列表单子上的实例；`choose : (Listof a) → a` 与 `call/cc : ¬¬a → a` 同形 | Astra；文献凭记忆 | 第一部轻点 `choose` 与 `call/cc` 同形（第五篇用得上时）；Filinski 第二部（Noah 10/13 无异议） |
| 2.5 | Rel 是紧闭的，Rel(X, Y) ≅ Rel(1, X × Y)，所以关系的元数只是「看成几组」。有限分支的关系不是紧闭的：ℕ 上的恒等是有限分支的，对应的 1 → ℕ × ℕ 却有无穷多行。合取在环境之间的关系上是复合，复合不交换；逻辑里的合取交换，二者只在解集上对得上（取交）。析取是并；列表一侧析取是有序追加，复合只对一侧分配 | Astra 10/4；紧闭一句 Sonnet，不交换一句 Astra、Sol、Opus | 第一部：元数只是「看成几组」用程序讲，不说紧闭；合取不交换要讲对；随文章仓库 #38（Noah 10/13） |
| 2.6 | 关系语言只用到 =、∧、∨、∃、⊤、⊥，没有否定与全称，是相干（几何）逻辑的片段。前提与结论都是相干公式时，经典可证当且仅当构造可证（Barr 定理一系）；以 ¬¬P 作前提就不在这个范围里。另外，可证不等于搜索找得到，搜索的完备性另说。对应的是「程序是公式，运行是找证明，答案是见证」，不是 Curry-Howard 那一支 | 定理凭记忆；限定 Sol、Astra、Opus、Sonnet 在 M13 一致 | 不写（或第二部）（Noah 10/13 无异议） |
| 2.7 | 记着列表的字典（键 ↦ 列表）与表（行的列表）之间，摊开与按键收拢是一对对应，不是同构：空列表的键摊开后消失，行的先后与重复也不完全对得上。去掉空键、按集合看，「键 ↦ 非空有限子集」与「有限分支的关系」才一一对应。对应第五篇第 171 行 | 推导；空键一句 Sol、Opus、Sonnet 指出 | 第一部：第五篇的说法与它一致即可（Noah 10/13 无异议） |
| 2.8 | 有了 `amb`，普通写法的函数能表示的是有限分支的关系，不是任何二元关系。对应第五篇第 366 行，与第 171 行「只要每个输入对应的行能完整地列出来」的限定一致 | 推导；Sol、Opus、Astra、GLM、Sonnet 指出 | 第一部（正文已限定）（Noah 10/13 无异议） |

## 第 3 组：单子（第六篇）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 3.1 | 用复合定义单子：给定对象上的映射 T，以及 p → T q 形状箭头上的复合 ⋆ 与单位 η，满足单位律、结合律，再加相容律 g ⋆ (η ∘ h) = g ∘ h，就得到 Kleisli 三元组，与单子等价。令 g\* = g ⋆ id，相容律给出 g ⋆ f = g\* ∘ f，再由另两条得到三条 Kleisli 律 | 推导（9/24）；M7 各家同意 | 未定 |
| 3.2 | 只有单位律与结合律不够。反例一：T = Id，对每个 Hom 集任取把恒等送到恒等的双射 Φ，令 g ⋆ f = Φ⁻¹(Φg ∘ Φf)，总是范畴，却与原来的复合无关。反例二：Set 上 T = Id，取双射 σ，令 g ⋆ f = g ∘ σ ∘ f，单位只能是 η = σ⁻¹；它满足范畴公理与相容律，推出的函子却是共轭 T f = σ⁻¹ f σ。所以若 T 事先是函子，还要求 T f = (η ∘ f)\* | 推导；两个反例的条件（Φ 保单位、η = σ⁻¹）由 Sol、Astra、Opus 在 M7 补全，Claude 验算 | 未定 |
| 3.3 | 相容律的两种形式 g ⋆ (f ∘ h) = (g ⋆ f) ∘ h 与 g ⋆ (η ∘ h) = g ∘ h，在单位律、结合律之下等价。正文用后一种，写成 `(∘𝒦 f (∘ cps:id h)) = (∘ f h)` | 推导；反向一行可证（Claude 验算） | 未定 |
| 3.4 | 多态的 Kleisli 复合由参数性（自由定理）自动满足相容律，所以 Haskell 用 return 加 >=> 定义单子时只要求两条；一般的 Hom 集族没有这个约束 | 凭记忆 | 未定 |
| 3.5 | Kleisli 伴随里，去程 `cps` 同时是 η 的对角线，回程 `cps->neg²` 同时是 ε 的对角线；μ = UεJ | 推导 | 未定 |
| 3.6 | reflect 与 reify：`((reflect connector) m) = (shift k ((connector k) m))`，`((reify unit) thunk) = (reset (unit (thunk)))`。答案类型取 T q 时，`shift` 捕获的 `k` 是一支 Kleisli 箭头。定界延续能表示的是「单位与扩张可用纯函数写出、满足单子律」的单子（Filinski 1994） | 列表的情形实测；定理及其条件凭记忆 | 未定 |
| 3.7 | 「单子之母」指延续单子，说法因 Piponi 2008 年的博文流行；技术内容归 Filinski | 凭记忆 | 未定 |
| 3.8 | 固定答案类型时，m ↦ λk. bind m k 是从 T 到答案类型为 T q 的延续单子的单子态射；∀q. (p → T q) → T q（codensity）解决的是答案类型须事先固定的问题 | 推导；凭记忆 | 未定 |
| 3.9 | 组合：分配律（Beck）只是使复合函子获得单子结构的一种办法。「要么一个错误，要么一个结果列表」：异常值不止一种时，Astra 给出的那个具体乘法结合律失效；Zwart 与 Marsden 例 4.8 说的是某一个方向的分配律不存在。两者都推不出「这个复合函子上没有任何单子结构」。层次顺序影响语义的经典例子是状态与异常（Filinski 1999） | 反例已实测；收紧 Astra、Opus、Sonnet 一致；文献凭记忆 | 未定 |
| 3.10 | 宿主的顺序绑定可以看作一个巨大单子的绑定写法（Moggi 的计算 λ 演算；ANF 作为单子范式：Hatcliff 与 Danvy 1994，Sabry 与 Felleisen 1993，Sabry 与 Wadler 1997） | 凭记忆 | 未定 |
| 3.11 | 状态世界：T q = s → (q × s)，模拟的是带赋值的宿主。直接风格里读与写各是一次 `shift`，答案类型是等着状态的函数 | 实测（带 tag 的写法） | 未定 |

## 第 4 组：强度、可交换与求值顺序（第六篇）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 4.1 | 绑定写法是 Kleisli 复合加上名字。起了名字，中间值能被后面每一步使用，后面的 λ 因此是引用了前面名字的闭包；闭包能当 Kleisli 箭头用，靠的是强度。不引用外面名字的 λ 对任何单子都是 Kleisli 箭头 | 推导；三步的例子实测 | 未定 |
| 4.2 | 强度 a × T b → T(a × b) 可以只用连接器、单位和一个闭包写出：`((connector (λ (b) (unit (cons a b)))) tb)`。这样写出的配对操作自动满足强度的四条规则，前提是单子律成立、T f = (η ∘ f)\*、连接器对类型参数多态；四条分别来自单位律、结合律、函子律 | 列表、状态、延续三个世界实测；规则 Sonnet 手验、Opus 给出来源 | 未定 |
| 4.3 | Set 上的单子有唯一的典范强度，规则自动成立。一般的笛卡尔闭范畴里，「有闭包」不够：要求扩张是语言内部的一等函数，能在任意上下文里用，单子律在语言内部成立。一阶语言、线性类型、分阶段类型里会失败。计算效应的语义需要的是强单子（Moggi）。第六篇注意框的旧拟稿「在有闭包的语言里，强度总能由连接器和单位写出来，所以这里遇到的每个单子都是强单子」要补上这些前提 | 结论 Sol、Astra、Opus、Sonnet 一致；出处（Moggi 1991 命题 3.4；McDermott 与 Uustalu 2022）由它们给出，未核原文 | 未定 |
| 4.4 | 可交换：两步互不依赖时调换先后结果不变。四个例子各要排除退化情形：状态至少两个状态时不可交换；延续的答案至少两个值时不可交换；异常在异常值不止一种时不可交换，只有一种时就是 Maybe，可交换；列表按列表观察不可交换，忽略顺序、保留重数（多重集）就已可交换。所以排除退化情形后，第六篇的四个例子都不可交换 | 状态与列表实测；限定 Sol、Astra、Opus、Sonnet、Qwen 一致 | 未定 |
| 4.5 | 有两种「顺序」：求值顺序（谁先算）与效应之间的层次顺序（谁在里谁在外）。巨大单子本身不定死求值顺序，定顺序的是语言及其解释（把表达式翻成绑定序列的那一步）。第六篇「为什么不直接用巨大单子」说前一种，「组合困难」说后一种 | Claude 的分析；更正 Sol、Astra 提出 | 未定 |
| 4.6 | 求值顺序在现实里的例子：C 与 C++ 不规定函数参数的求值顺序；Scheme 标准与 OCaml 也不规定，Racket 规定从左到右；惰性求值下副作用的时机不可预测 | 凭记忆 | 未定 |

## 第 5 组：定界延续与四变体（第三、七篇）

第三篇的化简规则：

```racket
(reset val) => val
(reset E[(shift k expr)])
  => (reset (let ([k (λ (v) (reset E[v]))]) expr))
;;    ^ 外层                    ^ 内层
```

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 5.1 | 两个 `reset` 各自的有无给出四种变体：外有内有是 `shift` / `reset`，外有内无是 `control` / `prompt`，外无内有是 `shift0` / `reset0`，外无内无是 `control0` / `prompt0` | 标准分类，凭记忆；Opus 指出对应 Dybvig、Peyton Jones、Sabry 的 ⁺F⁺、⁺F⁻、⁻F⁺、⁻F⁻ | 未定 |
| 5.2 | 把栈写成帧的列表、边界写成列表里的 tag 条目，这两个有无就是两次决定：外层对应切开以后 tag 放不放回剩下的栈，内层对应捕获的那段拼回去时垫不垫一个新 tag。一刀两段，边界只有一个，两段各自决定留不留，所以两个决定独立 | Noah 提出，按规则核对 | 未定 |
| 5.3 | 效应处理者对应外层无的两种。深处理者：handle E\[op v\] with h 变成 h 的分支作用于 v 与 λx. handle E\[x\] with h，分支在边界之外运行（外无），恢复时重装处理者（内有），即 `shift0`；浅处理者恢复时不装，即 `control0`。8 月「深处理者对应 `shift` / `reset`」的说法错在外层：`shift` 把分支留在边界之内，分支里再做同族操作会被自己接住。两者的关系是 (shift k e) = (shift0 k (reset e))。用 `shift` / `reset` 另加处理仍然写得出深处理者 | 裁定：M2 七家都答「对」，与 10/7 的结论一致；出处 Piróg、Polesiuk、Sieczkowski（FSCD 2019），Forster 等（2017）。Sol 与 Astra 引的定理编号不一致，未核原文 | 未定 |
| 5.4 | 第五篇的写法用的是 `shift`，分支在边界之内运行；只有一族操作、分支里不再做同族操作、也没有别的能观察边界的控制时，与 `shift0` 看不出差别 | 推导；最后一个条件 Sol、Astra 补 | 未定 |
| 5.5 | 逃逸式延续等于可组合延续加 abort；`call/cc` 可由 control、prompt、abort 定义（Sitaram 与 Felleisen 1990 第 3 节） | Astra 10/12 核扫描原页：第 3 节从第 73 页起，abort 在第 74 页，完整的 `call/cc` 定义在第 75 页，冲突解决。注意 abort 是先丢弃上下文再求值主体的语法形式；有 prompt 时，模拟整个程序的逃逸要让范围覆盖整个程序 | 未定 |

## 第 6 组：树、tag、处理者（第七篇）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 6.1 | 三者是同一件事的三面。一次操作只做一件事：把（要的是什么，参数，到边界为止的剩余工作 k）递给边界。自由单子回答「递出去的是什么」，是树的一个节点；prompt-tag 回答「怎么送到」，是在有名字的边界处切栈；代数效应回答「谁来拆」，是边界上的处理者。栈上切下来的那一段就是节点里的 k | Claude 的分析 | 未定 |
| 6.2 | 深处理者是签名函子 F 的一个代数加一条对叶子的子句，处理就是从自由代数出发的唯一同态（fold）。正文的说法是：每种节点给一个解释，整棵树就恰好有一个解释。「代数效应」的「代数」指的是这个。两处限定：浅处理者只拆一层，不是 fold；操作带等式时，代数还要满足这些等式 | 标准结论，凭记忆；限定 Sol、Opus、Astra、Sonnet 一致 | 未定 |
| 6.3 | 两族操作合在一起是 Free(F + G)，在代码里是两族结构体的并类型。只认识 F 的处理者遇到 G 的节点时转交出去，但孩子要继续处理：H(op(p, k)) = op(p, λx. H(k x))，不是「原样」。结果是 Free G 里的树，载体未必是 Free G A：状态处理者的载体是 S → Free G (A × S)。转交（树）与按 tag 直达（栈）是「越过不认识的边界」的两种做法 | 状态加选择的例子实测，两种写法结果相同；更正 Sol、Astra、Opus 一致。`three.rkt` 的实现本来就继续处理孩子，注释里的「原样转交」要改 | 未定 |
| 6.4 | 处理者的嵌套顺序决定语义。同一段程序（选一个数，累加进状态，读出状态）：状态在里、选择在外，每条分支各有一份状态，得 `((1 . 1) (2 . 2))`；选择在里、状态在外，各分支共用一份状态，得 `((1 3) . 3)`。单子组合的困难没有消失，变成了这个看得见的选择 | 实测 | 未定 |
| 6.5 | 单子好比把意思写死在操作里的嵌入语言，树好比先写成数据、解释留到以后的嵌入语言。前者难组合，是因为每个都自带一种连接器；树的连接器对所有签名都是同一个嫁接 | 类比，Noah 提出，Claude 收紧 | 未定 |
| 6.6 | 不是所有操作都是代数的：代数操作要与 bind 交换（Plotkin 与 Power），`call/cc` 和 catch 不是。延续单子不是任何自函子的自由单子。短证：自由单子里，若 m >>= f 是叶子，则 m 必是叶子（嫁接一个节点得到的还是节点），单子同构保持这条性质。答案取 Bool，令 m = λk. k(0) ∧ k(1)，f 取常值 η(())，则 m >>= f = λk. k(()) ∧ k(()) = η(())；但 m 不在 η 的像里（取 k(0) = 真、k(1) = 假，m 给假，η(0) 给真；对 η(1) 同理） | 第一句凭记忆；短证由 Sol、Astra、Opus、Sonnet 在 M3 给出，Claude 验算成立。Gemini、Qwen、DeepSeek 的论证不成立 | 未定 |
| 6.7 | 这棵树与编译器处理的语法树有两点不同：节点只有操作，算术、分支、绑定都留给宿主，因为孩子是宿主的函数；树是程序跑出来的，用 `(shift k (node arg k))`，不是解析出来的 | 实测 | 未定 |
| 6.8 | 树加转交的处理者，与每族操作一个 tag 的写法，在下列条件下给出相同的结果：深处理者；处理者是纯的；tag 与操作族一一对应、按最近的边界查找；分支在边界外运行；转交时继续处理孩子；状态正确穿过；程序有限。没有现成的定理。证明路线：两边满足同样的递归等式，由 fold 的唯一性得一致 | 条件是 M11 各家的合并，证明路线是 Sonnet 的；未证。Opus 建议随机对拍 | 未定 |

## 第 7 组：自由单子、列表与 Recof（第七篇结尾与第二部）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 7.1 | Free F a = μX. a + F X。它不总存在：F 是有限元的（比如只有有限元操作的签名、`List`）时存在，幂集函子就没有。单位是叶子，扩张是嫁接（把每片叶子换成一棵树）。存在时，F-代数的范畴与 Free F 的 Eilenberg-Moore 代数的范畴等价 | 标准结论，凭记忆；存在条件 Sol、Astra 补 | 未定 |
| 7.2 | `(Treeof a) = (∪ a (Listof (Treeof a)))` 是 Free List，只在叶子上带数据的多叉树（leaf-labelled tree），不是玫瑰树（见 7.10）。空列表 '() 是不带数据的叶子，即 (amb) 的死路。把第五篇 `choose` 里的 `append-map` 换成 `map`、边界处去掉 `list`，得到的就是它；拍平以后得回第五篇的列表 | 实测 | 未定 |
| 7.3 | 拍平 Free List ⇒ List 是单子态射，由 List 自己的乘法作为 List-代数诱导，而且逐分量是满射，所以 List 是 Free List 的商：模去的是幺半群的方程，忘掉的是嵌套，不是先后与重数。列表世界 ℒ 因此是树世界忘掉嵌套之后的样子。这不是列表独有的：任何单子 T，只要 Free T 存在，都是 Free T 的商（由 μ 诱导，并且有截面） | 推导；满射一句 Sol、Astra、Sonnet，普遍性一句 Opus，Claude 验算 | 未定 |
| 7.4 | `(Recof a b) = (∪ b (Pair a (Recof a b)))` 是 b + a × X 的初始代数，也是 Free(a × −) 在 b 处的值，同构于 List a × b，即日志单子（Writer），日志取 a 上的自由幺半群。b 取 `Null` 时就是 `(Listof a)`，`Null` 对应的是 1，不是 0。这棵树每个节点只有一个孩子，只有一片叶子，嫁接就是 `append`。它是 Barr 与 Wells 14.2 节的 rec(A, B)，`r0` 就是书上的 B → rec(A, B)；书上的局部递归说的是 rec(A, B) ≅ A\* × B，还要求在切片上成立，「local recursion」与「locally recursive」要分开 | typed/racket 下实测；数学部分 M9 各家同意；节号（14.2.3、14.2.4、14.2.6）由 Sol、Astra 给出，未翻书核对 | 未定 |
| 7.5 | `Pair` 的两个位置都当孩子时，Free(X ↦ X × X) 是叶子带标号的二叉树，即带点对的 S 表达式；第四篇 `fib` 的递归树是这种形状 | 推导 | 未定 |
| 7.6 | 列表单子（按元素类型算的那个，连接器是 `append-map`）不是任何自函子的自由单子。论证：自由单子里嫁接一个节点得到的还是节点，所以结果是叶子时原树必是叶子；而列表里两个元素的列表，一个送到空列表、一个送到单元素列表，接出来是单元素列表 | 推导，反例实测；M3 各家同意 | 未定 |
| 7.7 | `Listof` 因此有三个身份，正文不能说混：当签名用（Free List 是 `Treeof`）；自己是一棵树（Free(a × −) 在 `Null` 处）；作为列表单子是树的商。第二种身份里单子的参数是叶子（列表的结尾），不是元素类型 | 推导 | 未定 |
| 7.8 | 用结构体表示语法树时，签名必须是「一层」：孩子的位置留成类型参数，`(Exp x)` 是若干结构体的和，`(Ast a) = (∪ (Var a) (Exp (Ast a)))` 才是自由单子。直接递归定义的语法树是叶子类型为空的那一棵，即初始代数。带绑定的语言不在这套里 | typed/racket 下实测；绑定一句凭记忆 | 未定 |
| 7.9 | Typed Racket 里的四处限制：`∪` 不带标签，叶子本身是列表或序对时与节点分不开；多态操作的返回类型藏在节点里，需要存在类型，语言没有；没有高阶类型，写不出「对任意签名的自由单子」，第一部只能一个签名造一棵树；用结构体继承表示和时，判断子类型以后类型参数会丢，写成并类型则过检查 | 实测 | 未定 |
| 7.10 | 玫瑰树是每个节点都带数据的多叉树，形状是 a × List X。有限的版本是 μX. a × List X（初始代数），可能无限的版本是 νX. a × List X（终余代数），后者就是 Cofree List a，即 List 上的余自由余单子。它与自由单子对偶：Free F a = μX. a + F X 用 +，数据只在叶子，有限，靠 fold 拆，Free 是遗忘函子的左伴随；Cofree F a = νX. a × F X 用 ×，每个节点都有数据，可以无限，靠 unfold 造，Cofree 是右伴随。流是 νX. a × X，即 Cofree Id a。Haskell 是惰性的，μ 与 ν 的类型重合，所以常被混着说；Typed Racket 里用 ∪ 写的递归类型只装得下有限值，要 ν 得用 promise 或 stream | 标准结论；Kmett 的 free 库文档把 Cofree \[\] 叫作 rose tree，7 月的对话里查过。Noah 10/8 的印象核对成立，只补一点：玫瑰树本身可以按 μ 或 ν 读，Cofree 指 ν 的那一种 | 未定 |
| 7.11 | amb 库的 in-amb 是惰性的：搜索树是流函子上的自由单子（库文档原话），分支可以无穷，这时它落在 νX. a + F X 一侧：可能无限、只在叶子带数据的树，文献里叫 free completely iterative monad。遍历策略在这里才有实质区别。库用不可变的双端队列当前沿：新子树放前面是深度优先，放后面是广度优先；父树放回前面是不公平，放回后面是公平。有限树上各种遍历交出同样的叶子，只是先后不同；无限树上深度优先可能永远到不了某些叶子，广度优先或公平交错在分支有限时都到得了。第五篇「纯、有限」的范围声明正好落在 μ 一侧 | 库的行为读文档与源码（noahstorym/amb 的 scribblings/amb.scrbl、private/data/ideque.rkt）；ν 一侧的名字与文献（Aczel、Adámek、Milius、Velebil）凭记忆 | 未定 |

`Recof` 与 fold 拟用的写法（已定），接口照 rec(A, B) 的交换图，在 `typed/racket` 下过检查：

```racket
(struct (b) r0 ([b : b]))                 ; r0 : b → (Recof a b)             init
(struct (a v) r ([a : a] [v* : v]))       ; r  : a × (Recof a b) → (Recof a b)  cons
(define-type (Recof a b) (U (r0 b) (r a (Recof a b))))

;; f 由两条等式决定：
;;   (f (r0 b))   = (t0 b)
;;   (f (r a v*)) = (t a (f v*))
(: fold (∀ (a b x) (→ (→ b x) (→ a x x) (→ (Recof a b) x))))
(define ((fold t0 t) v)
  (define f (fold t0 t))
  (match v
    [(r0 b)   (t0 b)]
    [(r a v*) (t a (f v*))]))
```

## 第 8 组：栈与自由范畴（第七篇的代码，第二部的名字）

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 8.1 | 把延续单子的 Kleisli 范畴看作图，栈是图上自由范畴的态射，即待复合箭头的列表；复合是拼接；把栈应用到值上，是从自由范畴回到 Kleisli 范畴的求值函子 | 4 到 7 月的讨论，10/7 复核；未查文献 | 未定 |
| 8.2 | 有两种列表，不是同一个：帧的列表是留着复合不做，表示树上每个节点里的那条延续；操作的列表是每个操作只有一个孩子时树退化成的脊。留着复合不做，和留着操作不解释，是两件独立的事 | 推导 | 未定 |
| 8.3 | 签名只有有限元、不带等式的操作时，把 Kl(Free F) 限制到有限集，就是由各个操作 σ : 1 → n\_σ 生成的、带有限余积的自由范畴，也就是自由 Lawvere 理论的对偶。生成元的终点本身就是余积，所以不是「先取图上的自由范畴、再添余积」；「自由范畴里只有路径」按字面也不对，没有余积时 1 → n 后面接不上箭头。不限制到有限集就不对：空签名时整个 Kl 是 Set，自由生成的却是 FinSet。孩子按无穷集索引（如 S 无穷时的读状态）要换成 κ 元的余积与 κ 元的 Lawvere 理论 | 结论 M1 中 Sol、Astra、Opus、Sonnet 一致，Claude 推导同意；出处（Plotkin 与 Power 2003，Hyland 与 Power 2007，Plotkin 与 Pretnar 2013 §4.2）由它们给出，未核原文 | 未定 |
| 8.4 | 栈带着求值映射，但不是指数对象：指数对象的判据是转置唯一，而不同的列表可以表示同一个函数，唯一性不成立 | 推导；「幂对象」改「指数对象」由 Opus、Sol 指出 | 未定 |
| 8.5 | 自由范畴里一条路径分解成生成边的序列是唯一的（n 条边有 n + 1 个切点），求值以后就不唯一了，求值函子把「在哪里接的」忘掉了。在 tag 处切开栈，靠的正是这份记忆。能推出的只是「要保存足够的边界信息」，即 tag 与整段延续交替的序列；推不出「必须留着列表」。层数固定时，Danvy 与 Filinski 的 CPS 层次也行；tag 数没有上界，才逼出一个数据结构。第三篇只有一条边界，那一刀由宿主的调用栈替我们记着 | 推导；收紧 M10 中 Sol、Astra、Opus、Sonnet 一致 | 未定 |
| 8.6 | 帧必须是 CPS 箭头，不能是逆否形式：逆否的帧收的是延续，喂不进值 | 4 月的讨论 | 未定 |

## 第 9 组：10/8 新增

这一组来自评审和 Noah 10/8 的讨论，送审稿里没有。

| 编号 | 论断 | 核对 | 归属 |
| --- | --- | --- | --- |
| 9.1 | 列表是 X ↦ 1 + a × X 的初始代数，`foldr` 是从它出发的唯一同态。任何按结构递归的列表函数都恰好是一个 `foldr`：`map f` 是 `(foldr (λ (x acc) (cons (f x) acc)) '())`，`append-map f` 是 `(foldr (λ (x acc) (append (f x) acc)) '())`，第五篇的 `∘ℒ` 是对箭头列表的 `foldr append-map`。这与 7.4 的 `Recof` 是同一张交换图 | 标准结论；Noah 10/8 提出，GLM 提过 `∘ℒ` 一句 | 未定 |
| 9.2 | Racket 的实现：`for`、`for/list`、`for*/list` 一族都由 `for/fold/derived` 定义，`for/list` 是一路 `cons` 累积、最后 `reverse`；`map`、`for-each` 是直接写的具名 `let` 循环，不经过 fold；`append-map` 是 `(apply append (map f l))`。所以 `(for/list ([v e*]) body)` 等于 `(map (λ (v) body) e*)`、`for*/list` 等于嵌套的 `append-map`，都是外延相等，不是实现上相同 | 实测（读 Racket 8.10 的 `racket/private/for.rkt`、`racket/private/map.rkt`、`racket/list.rkt`） | 未定 |
| 9.3 | 对恒等函子的米田引理：∀R. (a → R) → R ≅ a，把恒等交给它就取出结果。只在答案类型任意（多态）时成立；固定 R 时 ¬¬a 比 a 大，6.6 的 m 就是一个不来自 a 的元素。第二、三篇把恒等交给 CPS 计算、答案类型任意的 `reset`，都是这个例子，文中没有点明 | 标准结论；与文中的对应是 Claude 的分析，送审稿「第二部要认的范畴论」表里记过 | 未定 |
| 9.4 | 「延续只用一次」有三种计数，要分开：编译期闭包被调用几次、目标代码里出现几次、运行期被调用几次。第四篇的 `ctx` 是「至多一次」，不是「恰好一次」：`(shift _ …)` 与 `abort` 会丢掉它。Linear CPS 说的也不等于「恰好调用一次」 | 分类 Sol 提出；「至多一次」是 Claude 对第四篇代码的核对；Linear CPS 一句来自 L1，未核原文 | 未定 |
| 9.5 | `scatter` / `gather`、`uncps` / `cps`、`anf0` / `anf1` 同形，都是一对 reflect / reify：一个把显式编码放回直接风格，一个把直接风格收回编码 | Opus 提出，Claude 没有逐对核对 | 未定 |
| 9.6 | 组合子 B、C、I、K 可以读第三篇的四个基本运算。组合子逻辑是 λ 演算不带变量的写法，对应笛卡尔闭范畴里只用复合、配对、柯里化与求值的写法（范畴组合子） | 第一句 Opus 提出，未对照第三篇核；第二句凭记忆。Noah 10/8：早先有一版写过，重写第三篇时丢了 | 未定 |

## 10/12 Astra 数学总审

Astra 审了文章仓库 `c83ed2f` 的第一到五篇，以及这份文档 `edd4e53` 的第 1、2、5 组；报告在文章仓库 #64。正文的七条发现拆成了文章仓库 #65–#70。下表只记对这份文档的结论，论断本身等 Noah 定归属时一起改（见本仓库 #10）。

| 编号 | 结论 | 后续 |
| --- | --- | --- |
| 1.1 | 纯 CCC 基底上成立（推导） | 见 M8 |
| 1.2 | 成立（推导）；`cps->neg²` 已从正文删去，构造仍成立 | |
| 1.3 | **要改**。M1：来回一趟还要求 CPS 箭头收到参数时只构造计算，否则可观察的先后会变（实测），「任何上下文」过宽。M8：1.1 的 𝒞 是纯的 CCC 基底，1.3 的 𝒞 带 `call/cc`，不能共用一个字母；例如 Set、R = Bool 时 Set(1, 1) 有 1 个元素，Kl(C\_R)(1, 1) 有 4 个，保持对象的同构要靠另一层控制语义 | 建议把纯基底记作 𝒟，写 𝒦 = Kl\_𝒟(C\_R)，带控制的直接风格另说；正文对应文章仓库 #65 |
| 1.4、1.5 | 成立（推导）；1.5 的 `exit` 一句要按答案接口的模型读 | |
| 1.6 | 方向对；Kuroda 指适于按值 CPS 的变体。Ferreira 与 Oliva 的 §6、§7.4 给出对应并指向 Murthy 博论第 9、10 章；博论原页未取得 | 文献可改引 Ferreira–Oliva |
| 1.7 | 成立，核了 Atkey §2.3.5。Kobori、Kameyama、Kiselyov 正式发表于 EPTCS 212（2016），36–52 页 | |
| 1.8 | 成立（推导）。Thielecke 核了 CW'01 前身版本；Friedman 1978 原文未核 | |
| 1.9 | 成立（推导） | |
| 2.1–2.3、2.7、2.8 | 在条目写明的范围内成立（推导）；2.1 要连同整个搜索终止的约定读 | |
| 2.4 | 成立，核了 Filinski 1994 §5.2、§5.5；「同形」只指都是 T a → a | |
| 2.5 | 成立；逻辑合取与环境变换要按同一解集语义比较 | |
| 2.6 | 保守性核了 Rathjen 的 Corollary 1.2；带背景理论时其公理也要满足条件 | |
| 5.1 | 成立，核了 Dybvig、Peyton Jones、Sabry §2 | |
| 5.2、5.4 | 成立（推导） | |
| 5.3 | 成立。Piróg 等 §3.3 定理 3–6、§4.3 定理 9–12；定理 6 用的是上下文内归约，不能说成两个语言逐小步相同。Forster 2017 未核 | Sol 与 Astra 的编号冲突由此解决 |
| 5.5 | 页码冲突解决，见上表 | |

## 相对送审稿的改动

10/8 改入的都是评审中几家一致、Claude 核对成立的更正，依据见「盲读评审」文档「记录」一节的数学问题表与 M1–M13 表。送审稿的「第二部要认的范畴论」对照表和 CTP 初版一节没有搬进来，它们属于取舍与计划，留在总纲「第二部：CTP」。

| 编号 | 改了什么 | 提出的 |
| --- | --- | --- |
| 1.1 | ¬ 写成内部的指数 R^p，与外部的 Hom(−, R) 分开；补 R 为空时退化 | Sol、Astra、Opus、Sonnet |
| 1.3 | 「同构」写明是观察意义下的等价；`flip` 互逆限于纯函数 | Astra、Sonnet、Sol |
| 1.4 | 补 ⊥ 为空集时切片退化 | M12 各家 |
| 1.5 | 记下改名「终结延续」；补始对象要 ⊥ 真是始对象、切片不记帧与 tag、不是处处可切 | Noah；DeepSeek、Opus、Qwen、Sol、Astra |
| 1.6 | Murthy 1990 注明是博士论文 | L1 |
| 1.7 | Answer-Type Modification without Tears 的作者改正 | Sol、Astra、Opus、Sonnet |
| 1.8 | 「省掉 j」改为「固定 j = id 后取值」，是特化不是同构，补反例与文献名 | Sol、Astra、Sonnet |
| 2.1 | 补「有限分支的关系」，指出 ℛ 是它而不是 Rel | Sonnet |
| 2.3 | 写明同构的理由是来回不变 | Sol、Opus、Astra、Sonnet |
| 2.5 | 补有限分支的关系不紧闭；补复合不交换、逻辑合取交换 | Sonnet；Astra、Sol、Opus |
| 2.6 | 收紧为相干片段里的序列，补「可证不等于搜得到」 | M13 各家 |
| 2.7、2.8 | 新增：字典与表只是对应；`amb` 能表示的是有限分支的关系 | Sol、Opus、Sonnet、Astra、GLM |
| 3.2 | 两个反例补上条件：Φ 保单位；η = σ⁻¹ | M7 各家 |
| 3.9 | 收紧：反例与不存在定理都推不出「没有任何单子结构」 | Astra、Opus、Sonnet |
| 4.2 | 补配对操作自动满足强度规则的前提 | Sonnet、Opus |
| 4.3 | 「有闭包」改成说清前提；Set 上强度唯一 | M4 各家 |
| 4.4 | 「答案不止一种」改「异常值不止一种」；各例排除退化情形；列表取多重集即可交换 | M5 各家 |
| 4.5 | 巨大单子不定死求值顺序，定顺序的是语言与解释 | Sol、Astra |
| 5.3 | 裁定：深处理者是 `shift0`，写出 8 月说法错在哪里 | M2 各家 |
| 5.4 | 补「没有别的能观察边界的控制」 | Sol、Astra |
| 5.5 | 标出页码冲突 | Sol 对 Astra |
| 6.2 | 限于深处理者；有等式时代数要满足等式 | Sol、Opus、Astra、Sonnet |
| 6.3 | 「原样转交」改为转交时继续处理孩子；补状态处理者的载体 | Sol、Astra、Opus |
| 6.6 | 补「延续单子不是自由单子」的短证 | M3 |
| 6.8 | 新增：树与 tag 两种写法一致的条件 | M11 |
| 7.1 | 补自由单子的存在条件 | Sol、Astra |
| 7.3 | 补满射；补「任何单子都是其自由单子的商」 | Sol、Astra、Sonnet、Opus |
| 7.4 | 补 `Null` 对应 1、`r0` 对应书上的构造、局部递归的切片条件 | M9 |
| 8.3 | 重写准确陈述与适用条件 | M1 |
| 8.4 | 「幂对象」改「指数对象」，判据是转置唯一 | Opus、Sol |
| 8.5 | 「必须留着列表」收紧为「保存足够的边界信息」 | M10 |
| 9.1–9.6 | 新增 | Noah 10/8；评审 |
| 7.2 | 「叶子带标号的玫瑰树」改为「只在叶子上带数据的多叉树」，补空列表是死路 | Noah 10/8（7 月已纠正过一次，送审稿又写错了） |
| 7.10、7.11 | 新增：玫瑰树与 Cofree；amb 库的惰性搜索树与可换的遍历 | Noah 10/8 |

## 文献

只有 Sitaram 与 Felleisen 一条有人对照过原文，而且页码有冲突；其余都是凭记忆，或者由审阅的 AI 给出。正式整理仍按「定位与发布」的做法，第一部冻结后逐条打开原文核到节或页。红线不变：不引一篇文献来支持它没有说过的话。

| 文献 | 用来说明什么 | 状态 |
| --- | --- | --- |
| Sitaram 与 Felleisen，Control Delimiters and Their Hierarchies（1990） | 5.5：第 3 节用 control、prompt、abort 定义 `call/cc` | Astra 10/12 核扫描原页：§3 第 73–75 页，`call/cc` 的完整定义在第 75 页 |
| Murthy，博士论文（Cornell，1990）；An Evaluation Semantics for Classical Proofs | 1.6 否定翻译的变体；1.8 A-翻译 | 博士论文一点来自 L1；后一篇及其节号由 Sol 给出，未核 |
| Thielecke，Comparing Control Constructs by Double-Barrelled CPS | 1.8 带两个延续的 CPS | 题名由 Sol 给出，未核 |
| Atkey，Parameterised Notions of Computation | 1.7 答案类型可变 | 凭记忆 |
| Kobori、Kameyama、Kiselyov，Answer-Type Modification without Tears | 1.7 | 作者已改正（送审稿误归 Atkey），年份未核 |
| Berdine、O'Hearn、Reddy、Thielecke，Linear Continuation-Passing | 9.4：它说的线性不等于「恰好调用一次」 | 凭记忆 |
| Moggi，Computational Lambda-Calculus and Monads（1989）；Notions of Computation and Monads（1991） | 3.10 巨大单子；4.3 强单子；4.4 的例子 | 凭记忆；定义 3.2、命题 3.4 等节号由 Sol、Astra 给出 |
| McDermott 与 Uustalu，What Makes a Strong Monad?（2022） | 4.3 强度的前提；4.4 | 新增，Sol、Astra、Opus 给出，未核 |
| Kock，Strong Functors and Monoidal Monads（1972） | 4.2、4.3 | Opus、Sonnet 给出，未核 |
| Danvy 与 Filinski，Abstracting Control（1990）；Representing Control（1992） | `shift` / `reset`；CPS 层次（8.5）；第四篇一遍 CPS 变换 | 凭记忆 |
| Felleisen，The Theory and Practice of First-Class Prompts（1988） | prompt | 凭记忆 |
| Filinski，Representing Monads（1994）；Representing Layered Monads（1999）；博士论文 Controlling Effects | 2.4、3.6、3.7、3.9 | 凭记忆；博士论文是 Astra、Opus 在 L3 提的 |
| Flanagan、Sabry、Duba、Felleisen，The Essence of Compiling with Continuations（1993） | ANF 的出处 | 凭记忆 |
| Hatcliff 与 Danvy（1994）；Sabry 与 Felleisen（1993）；Sabry 与 Wadler（1997） | 3.10 ANF 作为单子范式 | 凭记忆 |
| Dybvig、Peyton Jones、Sabry，A Monadic Framework for Delimited Continuations（2007） | 5.1 四变体；8.5 栈与 tag | 凭记忆 |
| Plotkin 与 Power，Algebraic Operations and Generic Effects（2003） | 6.6 代数操作；8.3 | 凭记忆 |
| Plotkin 与 Pretnar，Handlers of Algebraic Effects（2009）；Handling Algebraic Effects（2013） | 6.2、6.3、7.3、8.3 | 两个题名别混（L1）；2013 §4.2 命题 4.3 由 Astra 给出，未核 |
| Hyland 与 Power，The Category Theoretic Understanding of Universal Algebra（2007） | 8.3 Lawvere 理论 | 新增，Opus、Sonnet 给出，未核 |
| Forster、Kammar、Lindley、Pretnar（2017）；Piróg、Polesiuk、Sieczkowski，Typed Equivalence of Effect Handlers and Delimited Control（FSCD 2019） | 5.3 深浅处理者与 `shift0`、`control0` | 凭记忆；Sol 与 Astra 引的定理编号不一致 |
| Beck，Distributive Laws（1969）；Zwart 与 Marsden，No-Go Theorems for Distributive Laws | 3.9；例 4.8 | 凭记忆 |
| Barr 与 Wells，Category Theory for Computing Science，第 14 章 | 7.4 rec(A, B)；triple | triple 在 14.3 节（L1，送审稿写的 14.4 有误）；14.2 各小节号未翻书核。作者实际读过的书 |
| McCarthy（`amb`，1961 / 1963）；Wand 与 Vaillancourt，Relating Models of Backtracking（2004） | 第五篇的 `amb` 与回溯 | 凭记忆 |
| Codd（1970）；Hemann 与 Friedman，μKanren（2013）；The Reasoned Schemer；Byrd 博士论文（2009） | 关系模型；关系语言的骨架 | 凭记忆 |
| Wadler，Comprehending Monads（1990） | 列表推导式与单子 | 凭记忆 |
| Piponi，The Mother of all Monads（博文，2008） | 3.7 | 凭记忆 |
| van der Ploeg 与 Kiselyov，Reflection without Remorse；Swierstra，Data Types à la Carte；Fiore、Plotkin、Turi，Abstract Syntax and Variable Binding | 延续的队列表示；签名的和；带绑定的语法（7.8） | 凭记忆 |
| Mac Lane，Categories for the Working Mathematician，I.4 的习题 | 1.2 把自然变换定义为对态射的作用 | 凭记忆 |
| Reynolds，The Discoveries of Continuations；Leroy，Control Structures in Programming Languages: from goto to Algebraic Effects | 与本系列叙事线最接近的已有著作（L3） | 前者 Sonnet 提；后者 Sol 提，Claude 不确定，待核 |

L2 里几家交集最大、最值得先读的五篇：Filinski 1994、Moggi 1991、Plotkin 与 Pretnar 2013、Piróg 等 2019、Dybvig 等 2007。
