# Argon（Gemini-4）：逆否的构造性替身（2026-10-17）

回答《咨询说明-逆否的构造性替身.md》，两步作答。Argon 只能看到仓库内容，看不到 issue、PR；它没有运行代码，所引 Troelstra–van Dalen、Kleene 的页码未核。它指出账本 1.10 的核对只测了一个方向，已补（`../checks/neg-flip-two-presentations-1016.rkt`）。Noah 10/17 转来，原文照录。

---

我已按两步流程完成审阅：第一步仅拆阅文章仓库中的 `STYLE.md`、第一篇与第二篇正文、第二篇 `code.rkt` 及你附上的咨询说明，先把七个问题的独立判断全部写定；第二步再拆阅数学仓库中的三份 10/16 评审与 `math/background.md` 第 1 组做对照。

> **代码运行与标注说明**：当前沙箱虚拟机未安装 Racket（环境中无 `racket` 可执行程序），按 `STYLE.md`「不要声称做过没做的运行验证」的约定照实说明：以下所有 `#lang typed/racket/no-check` 代码块**均未在 Racket 8.10 下实际运行**，而是严格对照 `zh/02-cps/code.rkt` 的定义通过逐步 $\beta$-归约与多值传递语义做了静态推演。数学论断均标明 **【推导】**、**【定理（附出处）】** 或 **【凭记忆】**。

### 第一步：独立回答说明第三节的七个问题

#### 1. 这条动机在数学上站得住吗？逆否律、它的逆、Glivenko 定理以及 $\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$ 的说法是否准确？请给出能核对的出处。

以「不许用经典规则时，逆否律不能倒着用（消 $\neg$），只能正着再用一次（套 $\neg$）」作为引出 `neg` 第二种读法与 `(∘ neg flip)` 的数学动机，**完全站得住脚**。但咨询说明第 2 节第 3 点将「单个箭头 $p \to q$ 变成 $\neg\neg p \to \neg\neg q$」归结为 **Glivenko 定理**，在数学表述上混同了「整条定理外加 $\neg\neg$」与「蕴含连接词两端加 $\neg\neg$」，需要收紧。逐项核对如下：

* **逆否律与它的迭代【定理 + 推导】**：
* **逆否律 $(p \to q) \to (\neg q \to \neg p)$**：在直觉主义命题逻辑（IPC）乃至**最小逻辑**（Minimal Logic，仅把 $\neg A$ 定义为 $A \to \bot$，不使用爆炸原理 $\bot \to A$）中均是定理，证明项即前复合 $\lambda f.\,\lambda k_q.\,\lambda x.\, k_q(f\,x)$，对应 `(define ((neg f) kq) (∘ kq f))`。
* **逆否律的逆 $(\neg q \to \neg p) \to (p \to q)$**：在 IPC 中不成立（【推导】反例：取两点 Kripke 模型 $w_0 \le w_1$，令 $p$ 在 $w_0, w_1$ 均真，$q$ 仅在 $w_1$ 真；则在 $w_0$ 处 $\neg q$ 与 $\neg p$ 均假，故 $\neg q \to \neg p$ 在 $w_0$ 真，但 $p \to q$ 在 $w_0$ 假）。它在 IPC 上与双重否定消除（DNE: $\neg\neg q \to q$）互相可导【推导】：给定 $h : \neg q \to \neg p$ 和 $x : p$，$\lambda k_q.\,(h\,k_q)\,x$ 的类型是 $\neg\neg q$（即 `((flip h) x)`），再喂给 $\text{DNE}_q$ 即得 $q$（即正文第 428 行的 `unneg = (∘ uncps flip)`）；反过来在 $(\neg q \to \neg p) \to (p \to q)$ 中取 $p = \top$ 即得 $\neg\neg q \to q$。
* **再取一次逆否 $(\neg q \to \neg p) \to (\neg\neg p \to \neg\neg q)$**：【推导】直接将逆否律 $(A \to B) \to (\neg B \to \neg A)$ 中的命题变量代换为 $A = \neg q, B = \neg p$ 即得，因此在最小逻辑和直觉主义逻辑中无条件成立，证明项仍是同一个 `neg`。
* **$\mathcal{K}$ 的构造性替身 $(p \to \neg\neg q) \to (\neg\neg p \to \neg\neg q)$**：【推导】先由 `flip`（最小逻辑定理 $(p \to \neg q \to \bot) \to (\neg q \to p \to \bot)$）转成 $\neg q \to \neg p$，再由 `neg` 得 $\neg\neg p \to \neg\neg q$，代码为 `(∘ neg flip)`：
```racket
;; 【手工 β-归约，未在 Racket 8.10 下运行】
  (((∘ neg flip) cps:f) kkp)
= ((neg (flip cps:f)) kkp)
= (∘ kkp (flip cps:f))
= (λ (kq) (kkp (λ (p) ((cps:f p) kq))))

```


在范畴论中，这正是延续单子 $T X = \neg\neg X$ 的 **Kleisli 扩张（Kleisli extension / bind）**。


* **$\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$ 的准确性与隐藏边界【定理 + 推导】**：
在直觉主义命题逻辑（IPC）中，$\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$ **确实成立**。但有两个关键细节不能忽略：
* **两个方向对 `absurd`（爆炸原理）的依赖不同【推导】**：
* 正向 $\neg\neg(p \to q) \to (\neg\neg p \to \neg\neg q)$ 在**最小逻辑**中即成立，无需 `absurd`，证明项就是把 `neg²` 喂给外层双重否定：

$$\lambda kkf.\,\lambda kkp.\,\lambda kq.\, kkf\,(\lambda f.\, kkp\,(\lambda x.\, kq\,(f\,x))) \;=\; \lambda kkf.\,\lambda kkp.\,\lambda kq.\, kkf\,(\lambda f.\, ((\text{neg}^2\,f)\,kkp)\,kq)$$


* 反向 $(\neg\neg p \to \neg\neg q) \to \neg\neg(p \to q)$ **必须使用爆炸原理 `absurd : ⊥ → q**`（在最小逻辑中不成立）：

$$\lambda F.\,\lambda k.\, k\,\bigl(\lambda x.\, \text{absurd}\,\bigl(F\,(\lambda k_p.\, k_p\,x)\,(\lambda y.\, k\,(\lambda \_.\, y))\bigr)\bigr)$$



而第二篇正文的所有核心组合子（`neg`、`cps`、`flip`、`∘𝒰`、`∘𝒦`、`cps:call/cc`、`neg:call/cc`、`neg²`）全都住在**最小逻辑**（纯 $\to$ 片段）里，从未调用 `absurd`。


* **逻辑等价 $\leftrightarrow$ 不等于类型同构 $\cong$【推导】**：在程序与范畴层面，$\neg\neg(p \to q)$ 与 $\neg\neg p \to \neg\neg q$ 只是双向有态射，并不是同构。


* **Glivenko 定理 vs. 递归否定翻译（关键纠偏）【定理】**：
* **Glivenko 定理**（[Glivenko 1929](https://portal.mardi4nfdi.de/wiki/Sur_quelques_points_de_la_logique_de_M._Brouwer.)）断言：对任意命题逻辑公式 $\varphi$，$\vdash_{\text{CPC}} \varphi \iff \vdash_{\text{IPC}} \neg\neg \varphi$。它只在整条**定理**最外层套一层 $\neg\neg$，不往连接词内部钻；而且它只针对逻辑定理 $\varphi$，不针对任意两个数据类型之间的函数类型 $p \to q$（如 $\text{Natural} \to \text{Boolean}$ 不是重言式）。
* 把蕴含 $p \to q$ 翻译为 $\neg\neg p \to \neg\neg q$（把 $\neg\neg$ 分布到箭头两端），是递归定义的**否定翻译**（如 Gödel–Gentzen 翻译在原子命题前加 $\neg\neg$ 并保持蕴含 $(A \to B)^g = A^g \to B^g$，或 Kolmogorov 翻译）以及单子 $T = \neg\neg$ 在态射上的函子作用，而不是 Glivenko 定理本身。
* **修改建议**：正文里**不必提 Glivenko 定理，也不必引入 $\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$**；直接用「逆否律的逆在直觉主义逻辑中不成立，但把逆否律自身再用一次，就能构造性地推出 $(\neg q \to \neg p) \to (\neg\neg p \to \neg\neg q)$」即可，既不超出最小逻辑，也完全不需要额外定理兜底。


* **可核对的文献出处**：
* **V. Glivenko (1929)**, *["Sur quelques points de la logique de M. Brouwer"](https://portal.mardi4nfdi.de/wiki/Sur_quelques_points_de_la_logique_de_M._Brouwer.)*, *Académie Royale de Belgique, Bulletins de la Classe des Sciences*, Série 5, 15: 183–188（Glivenko 定理原始出处）。
* **A. S. Troelstra & D. van Dalen (1988)**, *[Constructivism in Mathematics: An Introduction, Volume I](https://staibabussalamsula.ac.id/wp-content/uploads/2024/01/Constructivism-in-Mathematics-staibabussalamsula.ac_.id_.pdf)*, North-Holland：
* **Chapter 2, §2.1.8 Proposition (pp. 41–42)**：明确列出 $\vdash_{\text{IPC}} (A \to B) \to (\neg B \to \neg A)$ 以及 $\vdash_{\text{IPC}} \neg\neg(A \to B) \leftrightarrow (\neg\neg A \to \neg\neg B)$（并注明正向在最小逻辑 MPC 中即成立）。
* **Chapter 2, §2.3 (pp. 56–62)**：系统对比 Gödel–Gentzen、Kolmogorov、Kuroda 否定翻译与 Glivenko 定理（Corollary 2.3.6）。


* **S. C. Kleene (1952)**, *[Introduction to Metamathematics](https://www.scribd.com/document/438963505/Kleene-Introduction-to-Metamathematics-1971-pdf)*, Van Nostrand：
* **§27 Theorem 12 (p. 119)**：直觉主义系统中逆否律成立、逆方向不成立，以及迭代逆否 $(\neg B \to \neg A) \to (\neg\neg A \to \neg\neg B)$。
* **§27 Theorem 13, *60g–*60h (pp. 119–120)**：$\vdash_{\text{IPC}} \neg\neg(A \to B) \leftrightarrow (\neg\neg A \to \neg\neg B)$。
* **§81 Theorem 59 (p. 492)**：Glivenko 定理与否定翻译。





#### 2. 作为读者动机，它比现稿的「方向对调」好吗？有没有更自然的问法？

* **比现稿的「方向对调」好得多**：
* 现稿第 473 行问「𝒰 的箭头类型 $\neg q \to \neg p$ 本身就是一个函数类型，似乎已经可以算作 𝒟 的箭头了。但检查一下首尾相连的条件……两端对调了」，这是作者在检查协变函子条件时才会问的问题。对读者来说，$\neg q \to \neg p$ 既然只用了纯 lambda，本来就已经在 $\mathcal{D}$ 里了；为了把起点摆回 $p$ 侧先引入 `←` 和 `⨾`，再说「方向反了一次，再反一次就正了」，像在做符号体操。
* 新动机则直接踩在「经典与构造」的主干冲突上：读者刚刚看到，要从 $\mathcal{U}$（$\neg q \to \neg p$）或 $\mathcal{K}$（$p \to \neg\neg q$）拿回 $p \to q$，对应「逆否律的逆」和「DNE」，都必须借宿主的 `call/cc`（`unneg` 与 `uncps`）。此时追问「如果不许用 `call/cc`，构造性地能推出什么？」，一次性解释了三件事：
1. **为什么代码还是 `neg**`：不能倒着用逆否律（消去 $\neg$），就只能把逆否律本身再正着用一次（套上 $\neg$）。
2. **为什么两端多了 $\neg\neg$**：那是不用 `call/cc`、拆不掉 $\neg\neg$ 的代价。
3. **为什么方向自然回正了**：逆否律每次反转方向，$\neg q \to \neg p$ 已经反过一次，再取一次逆否自然回到从 $p$ 侧指向 $q$ 侧的 $\neg\neg p \to \neg\neg q$。「方向回正」成了再取一次逆否的副产品，不再需要人为拿「首尾相连」去硬凑。




* **更自然的问法建议（把逻辑定律与程序拼接合二为一）**：
单纯问「手里只有 $\neg q \to \neg p$，构造性地能推出什么？」稍微有点像做逻辑习题。如果把**第一篇「分水岭」的消费/制造视角**与$\mathcal{K}$ 箭头首尾不对称的拼接痛点扣进来，问法会更抓人：
* **对 $\mathcal{U}$（接在 `unneg` 之后）**：`unneg` 要从 $\neg q \to \neg p$ 拿回 $p \to q$，手头只有 $p$，却要调用收 $\neg q$ 的函数，只能靠 `call/cc` 凭空造出一个 $\neg q$（第一篇「分水岭」）。如果不许借 `call/cc`，造不出 $\neg q$，逆否律就不能倒着用，只能正着再用一次：再调一次 `neg`，把 $\neg q \to \neg p$ 变成 $\neg\neg p \to \neg\neg q$。
* **对 $\mathcal{K}$（接在 `uncps` 之后）**：`uncps` 靠 `call/cc` 消去了 $p \to \neg\neg q$ 出口的 $\neg\neg$。如果不许借 `call/cc` 消去出口的 $\neg\neg$，怎样才能让箭头的入口和出口重新对称、能直接首尾相接？答案是反过来**给入口也补上一层 $\neg\neg$**，把 $p \to \neg\neg q$ 变成 $\neg\neg p \to \neg\neg q$——代码正是先用 `flip` 翻去 $\mathcal{U}$，再用 `neg` 取一次逆否，即 `(∘ neg flip)`！



#### 3. 第二种读法提前到「经典与构造」以后，「落回 𝒟」「否定翻译」「再次隐藏延续」「嵌入语言」这几节怎么排？这会不会改变 #33 里「落回放在宏之前还是之后」的判断？

* **对「落回放在宏之前还是之后」判断的影响**：
**这为「把落回（`neg` 第二种读法与 `(∘ neg flip)`）放在宏之前」补齐了原本缺失的动机闭环。**
旧稿里之所以有人主张把 `(∘ neg flip)` 挪到宏之后，是因为旧稿靠「方向对调」引出它，在宏之前显得悬空；而一旦把它作为 `unneg` / `uncps` 的构造性替身放进「经典与构造」，它在宏之前就有了极强的逻辑与类型动机。到了 `# 再次隐藏延续` 写 `anf:let` 时，读者面对「`kkv : ¬¬a` 怎样喂给 `cps:kv : a → ¬¬b`」的障碍，直接认出宏里每个绑定做的就是上一节的 `(∘ neg flip)`，水到渠成。
* **四节的推荐排布（需特别注意与 `## 两个 call/cc` 的先后关系）**：
如果把「落回 $\mathcal{D}$」提进 `# 经典与构造`，有一个先后顺序非常关键：**必须让读者先看到（或同时看到）$\mathcal{K}$ 和 $\mathcal{U}$ 内部有纯 $\lambda$ 写成的 `cps:call/cc` 和 `neg:call/cc`，再总结「否定翻译」**。否则在看到 `cps:call/cc` 之前，读者手里只有纯函数提升来的 `(neg f)` 和 `(cps f)`，会觉得「把纯函数送进 $\mathcal{U}$ 再落回 $\mathcal{D}$ 变成 `(neg² f)`，从头到尾都没碰过经典推理」。推荐如下排布：
1. **`# 经典与构造`（上）：经典出口回 $\mathcal{C}$**：由 DNE 与逆否律的逆引出 `uncps`、`unneg`，给出三世界图 $\mathcal{C} \cong \mathcal{U} \cong \mathcal{K}$。
2. **`## 两个 call/cc`**：`uncps` 借了宿主的 `call/cc`，但留在 $\mathcal{K}$、$\mathcal{U}$ 内部时，延续已是显式参数，`cps:call/cc` 与 `neg:call/cc` 全是纯 $\lambda$！
3. **`## 落回 𝒟 与否定翻译`（合并原「落回 𝒟」与「否定翻译」）**：
* 既然除 `uncps`/`unneg` 外所有构件（含 `cps:call/cc`）全是纯 $\lambda$，把宿主中不含 `call/cc` 的纯函数部分拆出来记作 $\mathcal{D}$。
* 抛出核心追问：**不许用宿主的 `call/cc`（放弃 DNE 和逆否律的逆），从 $\mathcal{U}$ 和 $\mathcal{K}$ 构造性地能推出什么？**
* 给出 `neg` 的第二种读法 $(\neg q \to \neg p) \to (\neg\neg p \to_{\mathcal{D}} \neg\neg q)$（顺手点明：第一次 `neg` 把方向翻反——这就是 `∘𝒰` 里 `reverse` 及 `←`、`⨾` 的来历；第二次 `neg` 把方向翻回正向）、从 $\mathcal{K}$ 落回 $\mathcal{D}$ 的 `(∘ neg flip)`，以及合成的 `neg² = (∘ neg neg)`。
* 放上修正后的四世界表与交换图表，点名**否定翻译**。


4. **`# 再次隐藏延续`**：用 `anf:let*` 隐藏延续，点破宏里每个绑定的 `(∘𝒦 cps:kv id)` 就是刚刚造出的 `((∘ neg flip) cps:kv)`，最后给出解释器 `anf:eval`。
5. **`# 嵌入语言`**（含 `mul`、阴阳谜题与 `## 计算的位置`）$\to$ **`# 结论`**。



#### 4. 图怎么画才是交换的？𝒞 留在图里吗？`inj` 怎么处理？

* **现稿四世界图（第 526 行）为什么不交换【推导】**：
现稿把 $\mathcal{D} \xrightarrow{\text{inj}} \mathcal{C} \xrightarrow{\text{neg}} \mathcal{U} \xrightarrow{\text{neg}} \mathcal{D}$ 画成一个闭合四边环。但：
1. 从 $\mathcal{D}$ 的 $p \to_{\mathcal{D}} q$ 出发绕一圈回到 $\mathcal{D}$，得到的是 `neg²`（类型为 $\neg\neg p \to_{\mathcal{D}} \neg\neg q$），不是恒等；
2. 从 $\mathcal{U}$ 到 $\mathcal{C}$，走 `unneg` 得到 $p \to_{\mathcal{C}} q$，走 `𝒰 ──neg──→ 𝒟 ──inj──→ 𝒞` 得到 $\neg\neg p \to_{\mathcal{C}} \neg\neg q$，连终点类型都不同。
症结在于：**$\mathcal{D}$ 在图里同时扮演了「源端的纯箭头 $p \to_{\mathcal{D}} q$」和「落点的双否定箭头 $\neg\neg p \to_{\mathcal{D}} \neg\neg q$」两个不同节点，不能画成同一个顶点连成环。**


* **严格交换的画法**：
* **画法一（双出口图：保留 $\mathcal{C}$ 在上、$\mathcal{D}$ 落点在下，隐去 `inj`）**：
```
        𝒞 (p → q) ←───────────┐
          ↑   ↑               │
          │   │               │
       [un]neg│            [un]cps
          │   │               │
          ↓   │               ↓
        𝒰 ────┼────flip─────→ 𝒦
        │                     │
       neg              (∘ neg flip)
        │                     │
        └───→ 𝒟 (¬¬p → ¬¬q) ←─┘

```


在这张图里：上半部是经典三世界环 $\mathcal{C} \cong \mathcal{U} \cong \mathcal{K}$；下半部是从 $\mathcal{U}$、$\mathcal{K}$ 落回 $\mathcal{D}$（$\neg\neg p \to_{\mathcal{D}} \neg\neg q$）的构造性三角形，满足 `(∘ (∘ neg flip) flip) = neg`；从顶到底（对纯函数 $f \in \mathcal{D} \subset \mathcal{C}$）左右两路分别是 `(∘ neg neg)` 与 `(∘ (∘ neg flip) cps)`，严格相等，都是 `neg²`【推导】。
* **画法二（若因跨篇呼应必须保留 `inj`，则把源端 $\mathcal{D}(p \to q)$ 与落点 $\mathcal{D}(\neg\neg p \to \neg\neg q)$ 分开画）**：
```
𝒟 (p → q) ──inj──→ 𝒞 (p → q) ←─────────┐
   │                  ↑                │
   │               [un]neg          [un]cps
  neg                 │                │
   ↓                  ↓                ↓
   └───────────────→  𝒰 ←────flip────→ 𝒦
                      │                │
                     neg         (∘ neg flip)
                      ↓                ↓
                    𝒟 (¬¬p → ¬¬q) ←────┘

```


这样画，左上角 `𝒟 (p → q) ──inj──→ 𝒞 (p → q)` 与 `𝒟 (p → q) ──neg──→ 𝒰 ──unneg──→ 𝒞 (p → q)` 严格交换（因为对纯函数 `f`，`(unneg (neg f)) = f = (inj f)`【推导】），底下落回 `𝒟 (¬¬p → ¬¬q)` 也严格交换，没有任何伪环路。



#### 5. 上面那个前提（只对纯 lambda 的 𝒰 箭头成立）在正文里怎么说才不打断叙事？第 520 行起的表把 𝒦、𝒰 标成「经典」，与这条前提是否矛盾？

* **怎么说才不打断叙事**：
不要在 `neg` 第二种读法后面加防御性补丁，而是像现稿第 547–549 行那样，**把它写成引出「整段程序改写」的正面动机**：
1. 定义 `neg` 第二种读法与 `(∘ neg flip)` 时只用一句话交代事实：「`neg` 和 `flip` 本身只用纯 lambda，因此只要交给它们的 𝒰 或 𝒦 箭头不调用宿主的 `call/cc`，得到的 $\neg\neg p \to \neg\neg q$ 就属于 𝒟。」
2. 紧接着把 `neg²` 的签名从 `𝒞 → 𝒟` 改为 `𝒟 → 𝒟`（`(: neg² (∀ (p q) (→ (→𝒟 p q) (→𝒟 (¬¬ p) (¬¬ q)))))`），并顺势推进：「`neg²` 只能把 𝒟 里原本就纯的函数搬成 $\neg\neg p \to_{\mathcal{D}} \neg\neg q$；如果函数内部调用了宿主的 `call/cc`，外层套上 `neg²` 运行时照样在调它。要让经典控制流真正落在 𝒟 里，不能靠在黑盒函数外面套 `neg²`，而要把程序里的 `call/cc` 换成纯 lambda 写成的 `cps:call/cc`，每一步用 `∘𝒦` 接起来。」


* **第 520 行的表把 $\mathcal{K}$、$\mathcal{U}$ 标成「经典」，与这条前提矛盾吗？**
* **在数学上绝不矛盾，而且正是全文最核心的洞察【推导】**：
这里有两个不同层面——**实现构件的宿主（Metatheory）**与**世界内部的逻辑（Internal Logic）**。$\mathcal{K}$ 和 $\mathcal{U}$ 的每一支箭头（含 `cps:call/cc`、`neg:call/cc`）在宿主里看都是**纯 lambda（属于直觉主义宿主 $\mathcal{D}$）**；但以 $\to_{\mathcal{K}}$ 或 $\to_{\mathcal{U}}$ 作为蕴含时，Clavius 律有纯 lambda 证明项，所以这两个世界**内部的逻辑是经典的**。
* **但在现稿表格的呈现上，读者确实容易看成矛盾**：
现稿表格只有「世界｜箭头类型｜逻辑」三列，$\mathcal{D}$ 标「直觉主义」，$\mathcal{C}, \mathcal{K}, \mathcal{U}$ 都标「经典」，读者很容易把「经典」理解成「允许调用宿主的 `call/cc`」。建议在表格里把这两层拆开：
| 世界 | 箭头类型 | 借用宿主 `call/cc`？ | 世界内部逻辑 |
| --- | --- | --- | --- |
| **𝒟：纯宿主** | $p \to_𝒟 q = p \to q$ | 否（纯 lambda） | 直觉主义 |
| **𝒞：经典宿主** | $p \to_𝒞 q = p \to q$ | 是 | 经典 |
| **𝒦：CPS** | $p \to_𝒦 q = p \to \neg\neg q$ | **否（纯 lambda）** | **经典**（有 `cps:call/cc`） |
| **𝒰：逆否** | $p \to_𝒰 q = \neg p \leftarrow \neg q$ | **否（纯 lambda）** | **经典**（有 `neg:call/cc`） |


这样一拆，「不用宿主 `call/cc`（住在 $\mathcal{D}$ 里），却拥有经典的内部逻辑」一眼可见，表面矛盾瞬间变成全篇点睛之笔。



#### 6. 这样排，是否为后面认出 ¬ 的自伴随（`flip` 是 Hom 集双射，`cps` 是单位）留好了伏笔？有没有会误导读者的地方？

* **伏笔非常完整【推导 + 定理】**：
在笛卡尔闭范畴 $\mathcal{D}$ 中，反变指数函子 $\neg : \mathcal{D} \to \mathcal{D}^{\text{op}}$ 与自身伴随（$\neg^{\text{op}} \dashv \neg$，见 [Peter Selinger 2001, *Control Categories and Duality](https://www.mscs.dal.ca/~selinger/papers/control.pdf)*）。按新方案排布后，`neg`（$\mathcal{D} \to \mathcal{U}$ 与 $\mathcal{U} \to \mathcal{D}$）、`flip`（Hom 集自然双射 $\mathcal{D}^{\text{op}}(\neg p, \neg q) \cong \mathcal{D}(p, \neg\neg q)$）、`cps = (∘ flip neg)`（自由 Kleisli 函子）、`(∘ neg flip)`（Kleisli 扩张 $U_T$）与 `neg² = (∘ neg neg)`（单子函子 $T = \neg\neg$）全部在图上就位。
* **有三处潜在的误导点需注意**：
1. **不要因为不用「方向对调」做动机，就彻底删掉对「$\mathcal{U}$ 方向反了」的指认**：自伴随 $\neg^{\text{op}} \dashv \neg$ 之所以发生在 $\mathcal{D}$ 与 $\mathcal{D}^{\text{op}}$ 之间，正是因为第一次 `neg` 反变（引出 `←` 与 `⨾`），第二次 `neg` 再反变回协变。在用逆否律引出第二次 `neg` 后，仍应顺手指出「第一次逆否把方向翻反，第二次逆否又把方向翻正」。
2. **区分高阶算子 `cps` 与对象分量 `cps:id = (cps id)**`：在标准范畴论教科书中，伴随的单位（unit）指态射族 $\eta_p : p \to \neg\neg p$（即 `cps:id`），而 `cps` 是 $\eta$ 在态射上的对角线作用 $f \mapsto \eta_q \circ f$（即自由函子 $F_T$ 在态射上的作用）。日后在第二部回收时，用一句话点明「`cps:id` 是单位的分量，`cps` 是它在箭头上的作用」即可避免读者对照教科书时困惑。
3. **图上 $\mathcal{D}$ 的落点必须标出 $\neg\neg p \to \neg\neg q$**：否则读者看到 `𝒟 ──neg──→ 𝒰` 和 `𝒰 ──neg──→ 𝒟`，会误以为两次 `neg` 互逆回到了原类型 $p \to q$。



#### 7. 还有什么我们没想到的？

独立审读第一篇、第二篇与 `code.rkt`，还有四处联动细节值得注意：

1. **`(∘ neg flip)` 与 `∘𝒦` 及宏里 `(∘𝒦 cps:kv id)` 的恒等式【推导】**：
在现稿 `anf:let`（第 575–587 行）中，为了把 `kkv : ¬¬a` 喂给 `cps:kv : a →_𝒦 b`，定义了一个类型为 `(→𝒦 (¬¬ a) a)` 的局部 `id`，再写 `(∘𝒦 cps:kv id)`。用 `code.rkt` 的定义做 $\beta$-归约【推导】：
```racket
;; 【手工 β-归约，未在 Racket 8.10 下运行】
  (((∘𝒦 cps:kv id) kkv) kb)
= (((flip (∘ (flip id) (flip cps:kv))) kkv) kb)
= ((id kkv) ((flip cps:kv) kb))
= (kkv ((flip cps:kv) kb))
= ((((∘ neg flip) cps:kv) kkv) kb)

```


不仅 `(∘𝒦 cps:kv id)` 就是 `((∘ neg flip) cps:kv)`，而且两支 $\mathcal{K}$ 箭头的复合本身就是先把后一支落回 $\mathcal{D}$ 再用宿主 `∘` 复合【推导】：

$$(\circ_{\mathcal{K}}\;\texttt{cps:g}\;\texttt{cps:f}) \;=\; (\circ\;((\circ\;\texttt{neg}\;\texttt{flip})\;\texttt{cps:g})\;\texttt{cps:f})$$



在正文里点破这条等式，能把「三种箭头」「落回 $\mathcal{D}$」和「再次隐藏延续」三节彻底焊成一个整体。
2. **第 281 行的练习题已经暗中用到了 `neg` 的第二种读法【推导】**：
第 281 行练习题要求「只用 `neg` 和 `cps` 写出 `flip`（提示：先想想 `(cps id)` 做了什么）」。答案是 `(define (flip f) (∘ (neg f) (cps id)))`【推导】。当 $f : \neg q \to \neg p$ 是 $\mathcal{U}$ 的箭头时，`(cps id)` 的类型是 $p \to \neg\neg p$，外层的 **`(neg f)` 必须把 $\neg q \to \neg p$ 变成 $\neg\neg p \to \neg\neg q$——这恰恰是 `neg` 的第二种读法**！在第 281 行处读者还没学第二种读法，建议在第二种读法出场时回收这道练习。
3. **第 551 行的练习题已被正文吸收，需替换**：
原第 551 行练习题正是让读者写出 `(∘ neg flip)`。它升入正文后，可替换为验证上面的Kleisli扩张恒等式，或让读者验证 `((∘ neg flip) cps:id) = id`（单子右单位律）。
4. **第 549 行的向后引用违规**：
现稿第 549 行写了「（后面的 `cps:display`）」，违反了 `STYLE.md` 第 78 行「同一篇里后面的小节也不提」的约定，顺手删去「后面的」即可。

### 第二步：对照三份 10/16 评审与 `math/background.md` 后的判断

读完数学仓库 `articles/02-cps/reviews/` 下的三份 10/16 评审（[Astra](https://xavierleroy.org/CdF/2018-2019/4.pdf)、Argon、Opus）、两份试写稿及 `math/background.md` 第 1 组（1.1、1.2、1.10）和 `articles/02-cps/overview.md` 后，对照结果如下：

#### 1. 哪些判断没有改变（且得到多方印证）

| 议题 | 第一步独立判断 | 对照三份评审与账本的结果 |
| --- | --- | --- |
| **`neg²` 的签名与定位** | 必须从 `𝒞 → 𝒟` 改为 `𝒟 → 𝒟`；运行时高阶函数包装抹不掉闭包内部的 `call/cc`，整段程序的翻译靠 `cps` + `cps:call/cc` + 宏 | 与 Astra、Argon、Opus 三家及账本 1.10 完全一致 |
| **旧四世界图的不交换性** | `𝒟 ──inj──→ 𝒞 ──neg──→ 𝒰 ──neg──→ 𝒟` 走一圈是 `neg²` 而非 `id`，且从 $\mathcal{U}$ 到 $\mathcal{C}$ 的两条路径类型不同，原因在于未区分 $\mathcal{D}$ 的源节点 $p \to q$ 与落点 $\neg\neg p \to \neg\neg q$ | 与 Argon（问题 6）、Opus（问题 6）独立指出的结论完全一致 |
| **宏中 `(∘𝒦 cps:kv id)` 的本质** | 外延上恒等于 `((∘ neg flip) cps:kv)`，且 `(∘𝒦 g f) = (∘ ((∘ neg flip) g) f)` | 与三家评审及 10/16 试写稿一致 |
| **第 281 行练习题的公式** | 独立推出 `(flip h) = (∘ (neg h) (cps id))` | 与账本 1.10 及 `neg-flip-two-presentations-1016.rkt` 一字不差 |

#### 2. 哪些判断发生了改变或修正

1. **修正一：关于问题 6 中「`cps` 是单位」的说法（对照账本 1.2 与 1.10）**
* **改变前**：我在第一步按标准教科书提醒「单位 $\eta_p : p \to \neg\neg p$ 是 `cps:id`，而 `cps` 是自由函子在态射上的作用」。
* **改变后**：读了账本 **1.2**（「按『自然变换由它在态射上的作用定义』的约定，即 $\alpha(f) = \alpha_b \circ F f$」）和 **1.10** 后，我理解了你们的整体设计：**采用「对角线约定」把自然变换也统一表示为箭头到箭头的算子**！在这个约定下，`neg`、`flip`、单位 `cps`、Kleisli 扩张 `(∘ neg flip)`、单子 `neg²` 全都处于同一个高阶函数层级 $(\text{Hom} \to \text{Hom})$，直接用 `∘` 两两复合就能穷尽伴随的全部数据（1.10）：
* `(∘ flip neg) = cps`（$J : \mathcal{D} \to \mathcal{K}$，也是单位 $\eta$ 的对角线）
* `(∘ neg flip) = cps->neg²`（Kleisli 扩张 $U_T : \mathcal{K} \to \mathcal{D}$，也是余单位的对角线）
* `(∘ neg neg) = neg²`（单子函子 $T = \neg\neg$）
* `(∘ flip flip) = id`
这比拆成对象分量 $\eta_p$ 更契合 Racket 组合子风格。我的建议修正为：第一部完全沿用这套算子对角线写法，只在第二部引出标准自然变换定义时用一句话交代 $\alpha(f) = \alpha_q \circ F f$ 与 $\alpha_p = \alpha(\text{id}_p)$（即 `cps` 与 `cps:id`）的互转。




2. **修正二：关于问题 2、3 中「逻辑动机」与「程序动机」的配合（对照 Astra、Argon、Opus 的分歧）**
* **改变前**：我在第一步认为，仅凭咨询说明的新想法（「不用 `call/cc` 时，逆否律不能倒着用，只能再正着用一次」），就已经完全解决了把 `(∘ neg flip)` 放在宏之前的动机问题。
* **改变后**：对照 Opus（主张放到宏之后）和 Astra/Argon 的评审后，我看清了 #33 分歧的根源：咨询说明的新想法完美回答了「为什么代码还是 `neg`、为什么两端带 $\neg\neg$」**（逻辑侧动机），但如果不在同一处补上半句**程序侧动机，读者仍会像 Opus 说的那样问：「既然我已经有了 $\mathcal{K}$ 和 `∘𝒦`，为什么要关心落回 $\mathcal{D}$ 的 $\neg\neg p \to \neg\neg q$？」
* **最佳合流方案**：把咨询说明的**逻辑追问**（不用 `call/cc` 消去 $\neg\neg$，构造性地能推出什么？）与 Astra/Argon 的**程序追问**（上一步已经算出了打包好的计算 `kkp : ¬¬p`，不调 `uncps` 拆包，怎么把等待裸值 $p$ 的 $p \to \neg\neg q$ 接上去？）放在同一段里并排说出：**因为消不掉前一步出口的 $\neg\neg p$，就只能用 `(∘ neg flip)` 给后一步的入口也补上 $\neg\neg p$！** 这样逻辑动机与程序用途当场咬合，放在宏之前就彻底立住了。


3. **修正三：关于跨篇硬约束对「`inj`、四世界图、宏内 `id`」的限制（对照 `articles/02-cps/overview.md`）**
* **改变前**：我在第一步建议可以直接删去 `inj`，甚至把 `anf:let` 宏里的 `(∘𝒦 cps:kv id)` 直接改写成 `((∘ neg flip) cps:kv)`。
* **改变后**：`overview.md` 第 47–49 行明确记有两条跨篇依赖：
1. 第五篇和第六篇「同一份宏换连接器」依赖 `anf:let` 保持 `((∘𝒦 cps:kv id) e)` 的形状（因为列表单子与一般单子没有 `neg` 和 `flip` 可借）；
2. 第五篇第 8 节开头和结论的四世界图要与第二篇的 `𝒟、𝒞、𝒦、inj` 及四世界图对照。
因此：**宏代码里的 `(∘𝒦 cps:kv id)` 不能改，四世界图和 `inj` 也不能删**！正确的做法是：保留宏代码 `(∘𝒦 cps:kv id)`，在正文里点明 `(∘𝒦 cps:kv id) = ((∘ neg flip) cps:kv)`；保留四世界图和 `inj`，但采用第一步问题 4 的**画法二**，把图里 $\mathcal{D}$ 的源节点 $p \to_{\mathcal{D}} q$（连接 `inj`）与落点 $\neg\neg p \to_{\mathcal{D}} \neg\neg q$（连接第二次 `neg` 与 `(∘ neg flip)`）画成两个不同位置，既满足第五篇的对照需求，又消除不交换的伪环路。





#### 3. 你们（含三份 10/16 评审与咨询说明）还漏掉了什么？

三份 10/16 评审都是在咨询说明写出之前针对旧问题作答的，把咨询说明、三份评审与账本 1.10 合在一起看，还有 **4 处真正的盲点** 没人点破：

1. **把咨询说明的新想法直接放进「经典与构造」（在「两个 call/cc」之前），会导致读者「还没见到经典控制，就先见到了经典控制的翻译」**：
* 在现稿第 375 行（`unneg` 处），读者手里只有纯函数提升来的 `(neg f)` 和 `(cps f)`，**还没见过 `cps:call/cc**`。
* 如果这时就把 `neg` 的第二种读法和 `(∘ neg flip)` 亮出来，说「它把 $\mathcal{U}$、$\mathcal{K}$ 落回纯宿主 $\mathcal{D}$」，读者手头能拿来试的只有 `(neg f)` 和 `(cps f)`，落回 $\mathcal{D}$ 得到的只是 `(neg² f)`——把一个原本就在 $\mathcal{D}$ 里的纯函数绕一圈包上 $\neg\neg$，完全看不出这和「构造性语言支持经典推理」有什么关系！
* **解法**：在 `# 经典与构造` 里，先讲 `uncps`/`unneg`（回 $\mathcal{C}$ 要借 `call/cc`），**紧接着立刻讲 `## 两个 call/cc**`（留在 $\mathcal{K}$、$\mathcal{U}$ 里，连 `call/cc` 都只需要纯 $\lambda$！），然后**紧贴着 `cps:call/cc` 抛出咨询说明的追问**：「既然在 $\mathcal{K}$ 和 $\mathcal{U}$ 里连 `call/cc` 都是纯 $\lambda$，唯独最后拿回 $p \to q$ 时因为 DNE 和逆否律的逆才借了宿主的 `call/cc`；那如果彻底不用宿主的 `call/cc`（留在纯宿主 $\mathcal{D}$ 里），放弃逆否律的逆，构造性地能推出什么？」——再取一次逆否！这样既用上了咨询说明的新动机，又让读者清楚知道落回 $\mathcal{D}$ 的是包含 `cps:call/cc` 在内的整套经典计算。


2. **咨询说明第 2 节第 3 点里的 Glivenko 定理与 $\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$ 存在数学越界（最小逻辑 vs. `absurd`）**：
* 三份 10/16 评审均未审阅咨询说明的这一条。如第一步问题 1 所证：$(\neg\neg p \to \neg\neg q) \to \neg\neg(p \to q)$ 必须用到爆炸原理 `absurd : ⊥ → q`，超出了正文组合子所在的最小逻辑；且 Glivenko 定理作用于整条经典定理而非单个箭头类型。账本和正文都不应拿 Glivenko 定理或 $\neg\neg(p \to q) \leftrightarrow (\neg\neg p \to \neg\neg q)$ 来解释 `neg²`。


3. **账本 1.10 的核对脚本 `neg-flip-two-presentations-1016.rkt` 只测了 `flip` 的一个方向，漏测了真正触发 `neg` 第二种读法的方向 $\mathcal{U} \to \mathcal{K}$**：
* 脚本第 5–7 行定义 `(define (flip′ h) (∘ (neg h) cps:id))`，只拿 $\mathcal{K}$ 箭头 `h = (λ (x) (cps:+ x 1))` 测了 $\mathcal{K} \to \mathcal{U}$ 方向（此时 `cps:id` 取在 $\neg q$ 上，`(neg h)` 的类型是 $\neg\neg\neg q \to \neg p$）。
* 但 `flip` 是双向的（`case→`）！当把同一个公式 `(∘ (neg g) cps:id)` 用在 $\mathcal{U}$ 箭头 $g : \neg q \to \neg p$ 上（即 $\mathcal{U} \to \mathcal{K}$ 方向）时，`cps:id` 取在 $p$ 上（类型 $p \to \neg\neg p$），而 **`(neg g)` 恰恰就是 `neg` 的第二种读法 $(\neg q \to \neg p) \to (\neg\neg p \to \neg\neg q)$**【推导】！
* 也就是说，账本 1.10 里「由 `neg` 与单位 `cps` 恢复 `flip`」的公式 `(flip g) = (∘ (neg g) cps:id)`，在 $\mathcal{U} \to \mathcal{K}$ 方向上**本身就是「先用 `neg` 的第二种读法把 $g$ 落回 $\mathcal{D}$（得 $\neg\neg p \to \neg\neg q$），再在前面接上 DNI `cps:id`（$p \to \neg\neg p$）」**！把这个观察补进账本 1.10，并且把正文第 281 行的练习与 `neg` 的第二种读法关联起来，账本 1.10 的两条主线（自伴随的两种给法 vs. 从 $\mathcal{U}$ 落回 $\mathcal{D}$）就合二为一了。


4. **账本 1.10 末尾「生成 $\neg\neg$ 的两个伴随（$\neg \dashv \neg$ 与 $\text{inj} \dashv R$）」恰好为双出口图提供了精确的范畴论解释**：
* 账本 1.10 指出，Kleisli 范畴 $\mathcal{K}$ 作为初始分解，分别有比较函子 `flip` 通向 $\mathcal{U} \subset \mathcal{D}^{\text{op}}$（纯 $\lambda$ 的自伴随 $\neg^{\text{op}} \dashv \neg$），以及比较函子 `uncps` 通向带 `call/cc` 的 $\mathcal{C}$（伴随 $\text{inj} \dashv R$）。
* 对照第一步问题 4 的双出口图：图的上半部（`uncps` / `unneg`）正是去往 $\mathcal{C}$ 的比较函子，而从 $\mathcal{C}$ 回到 $\mathcal{D}$ 的右伴随 $R$ **不是运行时的函数，而是语法上的 CPS 宏翻译（`anf:` 宏）**；图的下半部（`flip` 接第二种读法的 `neg`，即 `(∘ neg flip)`）则是沿着内部自伴随 $\neg^{\text{op}} \dashv \neg$ 的右伴随回到 $\mathcal{D}$。这从根本上解释了为什么运行时只有 $\mathcal{D} \xrightarrow{\text{neg}^2} \mathcal{D}$ 和 $\mathcal{K} \xrightarrow{(\circ\;\text{neg}\;\text{flip})} \mathcal{D}$ 的函数，而 $\mathcal{C} \to \mathcal{D}$ 只能是宏。
