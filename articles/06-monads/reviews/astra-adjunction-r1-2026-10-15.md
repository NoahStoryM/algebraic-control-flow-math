# Astra：伴随框架，第一轮回复（2026-10-15）

回答《咨询说明-伴随框架.md》的 11 个问题。Noah 10/15 转来，原文照录；公式保留原样的 LaTeX。

---

我的整体判断是：抽象框架成立，而且核心结论相当干净；但附件中把它对应到第二、三篇的方式，还不能成立为同一个严格模型。 第五篇的列表构造最接近完整实例。需要修改的主要不是伴随定理，而是“哪些程序算箭头、箭头按什么等式识别、纯宿主究竟是什么”这三件事。

我建议先严格区分三个符号：

J=\mathrm{inj}:\mathcal D\to\mathcal C,\qquad
U:\mathcal C\to\mathcal D,\qquad
M=UJ:\mathcal D\to\mathcal D.

附件把右伴随叫作 T，容易与单子的自函子混淆。以下用 U 表示右伴随、M 表示单子。

框架可以收紧成：

设 J:\mathcal D\to\mathcal C 在对象上恒等，并有右伴随 U。则伴随诱导的单子 M=UJ 满足
> \mathcal C\cong\operatorname{Kl}(M).
>
若还要求纯宿主作为子范畴嵌入，则另需 J 忠实。若要解释带环境和高阶函数的编程语言，还需相应的 strength、函数空间和类型翻译结构。

这个定理本身没有问题。 但以下四句话不能直接随之成立：

* “添加效应”自动保证 J 有右伴随。
* 用 cps 包装一个带效应的函数，就把它变成了纯函数。
* 把真正的空对象当作延续答案，可以忠实保存普通值与程序行为。
* 否定翻译、A-翻译都只是同一个单子自函子的对象作用。

下面逐条回答。标注“推导”的部分给出论证，不依赖未核实的文献记忆；写作与命名建议另标为判断。

⸻

1．成立条件。〔定理＋推导〕

核心结论只要求：

1. \mathcal D,\mathcal C 是范畴；
2. J:\mathcal D\to\mathcal C 是对象恒等的函子；
3. 有伴随 J\dashv U。

不需要先假设 \mathcal D 笛卡尔闭，也不需要 J 忠实。 这些是模型的其他要求。

这是 Kleisli 比较函子的标准性质。可核对 Riehl《Category Theory in Context》§5.2，当前作者版的 Lemma 5.2.12、Proposition 5.2.13。后者构造了从 Kleisli 伴随到任意生成同一单子的伴随的比较函子。

具体证明如下。记单位、余单位为 \eta,\varepsilon，令

M=UJ,\qquad \mu=U\varepsilon J.

比较函子

K:\operatorname{Kl}(M)\to\mathcal C

定义为

K(A)=JA,\qquad
K(f:A\to MB)=\varepsilon_{JB}\circ Jf.

在每个 Hom 集上，这恰好是伴随双射

\mathcal D(A,UJB)\cong\mathcal C(JA,JB),

所以 K 全且忠实。由于 J 对象恒等，K 也对象恒等，因此是范畴同构。

如果放宽对象条件：

* J 对象双射，仍得到同构；
* J 仅本质满，得到等价；
* 一般情况下，比较函子只覆盖由 JA 这些对象构成的满子范畴，按对象同构闭包理解则覆盖其本质像。

“宿主是子范畴”还需要 J 忠实。对象恒等加忠实，使 \mathcal D 可识别为一个宽子范畴。不能要求它是满子范畴，否则对象相同、箭头也全部相同，便没有真正增加箭头。

这里还有一个精确判据：

J\text{ 忠实}
\iff
\forall B,\ \eta_B:B\to MB\text{ 是单态}.

因为 Jf 在伴随下对应 \eta_B\circ f，所以 Jf=Jg 恰好等价于 \eta_Bf=\eta_Bg。

伴随存在是实质性额外假设。 它要求每个预层

A\longmapsto\mathcal C(JA,B)

都由 \mathcal D 中某个对象 UB 表示，而不只是给每个 Hom 集找一个碰巧等势的集合。

一个反例足以说明：

* \mathcal D=\mathrm{FinSet}，它是笛卡尔闭范畴；
* \mathcal C 对象仍是有限集合，箭头 A\to B 是自然数矩阵 B\times A\to\mathbb N，复合是矩阵乘法；
* J 把函数送到其 0/1 图矩阵，是对象恒等且忠实的函子。

若 J\dashv U，则

\mathbb N\cong\mathcal C(1,1)
\cong\mathrm{FinSet}(1,U1),

但右边有限，矛盾。

所以，纯函数嵌入了一个计算世界，并不足以推出这个世界是该宿主上的 Kleisli 范畴。

另一个必须事先固定的条件是箭头等式。把程序作为箭头，通常指程序模某种等价关系。纯语言中的等价未必在增加控制操作后仍成立；如果等价关系变了，“原样放进去”甚至未必在商集上良定义。

⸻

2．两个 Kleisli 是不是一回事？〔推导〕

目前不是，至少附件尚未证明它们是一回事。

要区分：

\mathcal K_{\mathrm{pure}}(A,B)
=\mathcal D\bigl(A,(B\to R)\to R\bigr)

与“完整 Racket 中拥有同样类型外形的函数”。

后者可以在函数体里调用 call/cc、输出、改变状态、发散。拥有 A → ((B → R) → R) 的类型外形，不意味着它属于前一个 Hom 集。

第二篇的

(define (((cps f) x) k) (k (f x)))

只是延迟调用并包装 f。它没有把 f 内部的控制操作编译成纯代码。uncps 的往返计算，即使在文中限制的观察条件下成立，也不能据此证明存在

\mathcal C(A,B)\cong\mathcal D(A,MB).

它证明的是另一个环境里的往返关系。

严格框架需要一个真正的表示映射，记作

E_{A,B}:\mathcal C(A,B)\longrightarrow\mathcal D(A,MB).

它应当满足

E(\mathrm{id})=\eta,\qquad
E(g\circ_{\mathcal C}f)=E(g)\star E(f).

这里 \star 是 Kleisli 复合。

有了它，右伴随在箭头上的作用才是

U(f)=E(f)^\*
=\mu_B\circ M(E(f)):MA\to MB.

在延续实例中：

U(f)(m)(k)
=
m\bigl(\lambda x.\,E(f)(x)(k)\bigr).

这是一支纯箭头，前提是 E(f) 已经是纯箭头。

因此，“U 作用于用了 call/cc 的箭头，能否写成宿主函数？”应分开回答：

* 作为语义映射：若该伴随已经建立，当然得到 \mathcal D 的箭头。
* 作为源代码变换：可以通过合适的 CPS 编译器实现，但要处理语法、类型、原语和等式。
* 作为接收任意不透明 Racket 闭包的普通高阶函数：附件中的包装代码没有提供这种效应消除能力，不能默认存在。

“U 是函子”不等于“U 是语言内部能接收任意闭包运行的一个函数”。

⸻

3．neg、flip、cps、neg² 各是什么？〔推导〕

先固定答案对象 R，在纯的笛卡尔闭范畴 \mathcal D 中定义

NX=R^X,\qquad MX=NNX.

反变的 N 可写成两个方向相反的函子，并有伴随

N:\mathcal D\rightleftarrows\mathcal D^{op}:N^{op}.

其 Hom 双射来自交换两个参数：

\mathcal D(Y,R^X)
\cong
\mathcal D(X,R^Y).

它生成延续单子 M。注意，这是“否定伴随”；它与 J\dashv U 是生成同一个单子的两个伴随表示，不是字面上同一对函子。

定义

\mathcal U_R(A,B)=\mathcal D(NB,NA),\qquad
\mathcal K_R(A,B)=\mathcal D(A,MB).

则各零件的对应是：

构造	严格解释
neg 作用于纯 f:A\to B	Nf:NB\to NA,\quad k\mapsto k\circ f
flip	\mathcal U_R(A,B)\cong\mathcal K_R(A,B) 的双射；配上相应复合后是范畴同构
cps f，其中 f 纯	J_Mf=\eta_B\circ f，即标准 Kleisli 提升
cps id	单位 \eta_A(x)(k)=k(x)
第二次 neg，输入 h:NB\to NA	Nh:MA\to MB,\quad m\mapsto m\circ h
neg² f，其中 f 纯	自函子 Mf:MA\to MB

其中

(Mf)(m)(k)=m(k\circ f).

若 h=\mathrm{flip}(e)，其中 e:A\to MB，则第二次 neg 给出

(Nh)(m)(k)=m(\lambda x.e(x)(k))=e^\*(m)(k).

这正是右伴随的箭头作用。 第二篇让读者从 \mathcal K 经 \mathcal U 回到 \mathcal D 的那个练习，已经非常接近要认出的核心。

对两个签名，我的结论很明确：

* 第三篇的 neg² : 𝒟 → 𝒟，作为上面的 M，是对的。
* 第二篇的 neg² : 𝒞 → 𝒟，若 𝒟 真表示纯箭头，而代码仍原样调用任意带控制效应的 f，这个归属不成立。
* 它可以成为一个正确的语义签名，但必须把实现换成“先得到 E(f)，再取延拓”，不能继续以原来的运行时包装作为证明。

所以那句“仍然原样调用 f”确实暴露了问题；它不是能够化解问题的免责声明。

还应避免把一般的求值函数认作余单位。Kleisli 余单位为

\varepsilon_B:MB\to_{\mathcal K}B,

它在 \mathcal D 中由

\mathrm{id}_{MB}:MB\to MB

表示。它不是纯函数 MB\to B。第三篇的 anf:eval 是另一件事：在结果类型恰好等于答案类型时，用恒等延续取出答案。

⸻

4．⊥ 真为空时怎样？〔推导；有直接反例〕

伴随和单子仍然存在，但会退化，不能承担附件要求的忠实程序模型。

在 Set 中：

M_{\varnothing}X
=
(X\to\varnothing)\to\varnothing
\cong
\begin{cases}
\varnothing,&X=\varnothing,\\
1,&X\ne\varnothing.
\end{cases}

因此所有非空结果类型都被压成单元素集合。例如两个不同的纯函数

f,g:1\to\mathbf{Bool}

分别返回真假，但

Jf=Jg,

因为 M_{\varnothing}\mathbf{Bool}=1。纯宿主已经不能忠实嵌入。

还有更直接的矛盾：若目标世界包含 exit : 1 → ⊥，且把这个 \bot 解释为空集，则伴随要求

\mathcal C(1,\bot)
\cong
\mathrm{Set}(1,M_{\varnothing}\varnothing)
=
\mathrm{Set}(1,\varnothing)
=
\varnothing.

左边却有 exit。这组假设不能同时成立。

这不只是一种不巧的 Set 解释。在具有真正初对象 0 的笛卡尔闭范畴中，0 是次终对象，从而 0^X 和 0^{0^X} 都是次终对象。因此

\mathcal D(A,0^{0^B})

至多有一个元素。相应 Kleisli 范畴是薄范畴，无法保留一般程序之间的区别。

这里需要分清：

* 逻辑中的假、真正的初对象；
* 运行时“这个调用不正常返回”的类型标记；
* CPS 语义中的最终答案对象。

它们不能不加区分地用同一个 \bot 解释。

第三篇改用普通答案对象 R，确实绕开了这一障碍。但：

* 非空答案不是“伴随存在”的必要条件；
* 非空也不足以保证忠实：R=1 时仍全部退化；
* 在 Set 中，|R|\ge2 足以让 \eta_X(x)(k)=k(x) 区分不同 x；
* 在一般范畴里，需要直接检查 \eta_X 是否单态，不能照搬“至少两个元素”。

另外，全局 call/cc 的 CPS 模型也可以使用普通答案对象 R。使用 R 不等于已经拥有定界控制；全局与定界的差别还在操作语义及类型规则。

⸻

5．“否定翻译是单子的自函子”准确到什么程度？〔推导〕

应分三层说。

第一层，双重否定确实给出一个自函子：

X\mapsto (X\to R)\to R,\qquad
f\mapsto\mathrm{neg}^2(f).

这一句准确。

第二层，完整的高阶 CPS 翻译不是对原类型统一套一个 M。

例如一种标准按值调用翻译需要区分值类型 V(A) 与计算类型 C(A)：

C(A)=M(V(A)),

V(A\to B)=V(A)\to M(V(B)).

所以源语言中一支高阶函数的解释一般是

V(A)\to M(V(B)),

其中输入、输出内部的函数类型也已经递归改变。单纯写

(A\to B)\mapsto M(A\to B)

并没有描述这件事。

Moggi 的计算语义明确区分值与计算；高阶部分使用 M-指数对象，见其 Definition 3.9、Remark 3.10。

第三层，A-翻译尤其不能直接等同于延续单子的对象作用。

第三篇的路径是

(p\to0)\to0
\quad\leadsto\quad
((p+R)\to R)\to R.

然后把处理答案分支的函数固定为 \mathrm{id}_R，得到

(p\to R)\to R.

后一步是以下映射：

\theta(F)(k)=F([k,\mathrm{id}_R]).

一般不单射，因此不是类型同构。 取 p=\varnothing,\ R=\mathbf2：

\left|((p+R)\to R)\to R\right|=16,

而

\left|(p\to R)\to R\right|=2.

16 个可能行为只能压到 2 个。

第三篇具体的 loop/ki 中，第二条延续始终固定，所以删去该参数可以保持这个具体程序的行为；但不能由此声称整个翻译后类型与 M_Rp 同构。

更准确的定位是：

双重否定给出延续单子的类型构造及纯箭头作用；完整否定/CPS 翻译还递归处理类型与程序。第三篇通过 A-翻译启发出答案分支，再对该分支作特定处理，得到局部延续编码。

还有一点：第三篇的 reset 允许内外答案类型分别为 a,x。这更适合说成一族 M_R 及它们之间的边界操作，不能把全篇所有代码都不加说明地塞进一个固定 M_R。

⸻

6．每支 A\to M_RB 都来自目标程序吗？〔推导＋文献边界〕

如果已经假设第 1 问的伴随存在，答案必然是“是”。 Hom 双射已经包含了这个结论。

但验证某种具体语言是否满足这个假设时，答案不能预先给定。

有三个层次。

语义范畴。 如果定义

\mathcal C=\operatorname{Kl}(M_R),

当然每支箭头都在里面。这是构造，不是某门源语言表达能力的定理。

有限源码与所有集合函数。 如果 \mathcal D=\mathrm{Set}，而 \mathcal C 的箭头要求由通常的有限程序表示，那么一般不可能覆盖所有箭头。

例如 R=\mathbf2,\ A=1,\ B=\mathbb N 时，目标 Hom 集包含所有函数

(\mathbb N\to\mathbf2)\to\mathbf2,

远多于可数个有限程序。因此需要把目标收紧到可定义箭头，或承认语义模型包含不可定义元素。

可定义的纯 CPS 箭头与直接风格语言。 在理想的固定答案、纯基础语言加 shift/reset 的设定下，给定纯

h:A\to(B\to R)\to R,

可以定义

(define (reflect-h x)
  (shift k ((h x) k)))

并在纯 k:B\to R 下重化：

(reset (k (reflect-h x)))

按 shift/reset 规则，捕获的延续是

(lambda (b) (reset (k b)))

由于 k 是纯函数，内层 reset 可消去，结果就是 ((h x) k)。

这给出了该设定下的表示满射构造。要得到同构，还要证明另一方向以及选定程序等价关系的正确性。

只有 call/cc 时，不能直接复用第二篇的 uncps 来处理任意固定答案 CPS 值。取

m(k)=\mathrm{not}(k(\mathrm{false})),
\qquad R=B=\mathbf{Bool}.

用逃逸式 call/cc 执行 m，调用捕获的 k 时已经跳走，not 不会执行，得到 false。再做普通 cps 包装得到

k\mapsto k(\mathrm{false}),

与原来的 m 不同。取 k=\mathrm{id}，一个结果为假，一个为真。

这个反例证明的是该逆变换失败，并非一举证明所有加入不同原语的语言都不可表达 m。是否有定界、可恢复调用、答案观察、状态等，都可能改变结论。

Filinski 1994 的结果明确限制在单位与延拓可由纯函数项表达的单子，并使用可组合延续；用普通延续实现它时还加入一份状态。不能将其改述为“单靠 call/cc，任意宿主里任意单子都自动完整实现”。

⸻

7．Set、Rel 与列表世界各处于什么位置？〔推导〕

Set–Rel 是框架的精确实例。

J:\mathrm{Set}\to\mathrm{Rel}

把函数送到图关系。右伴随为

UB=P(B),

对关系 \(r:A\relto B\)：

Ur:P(A)\to P(B),\qquad
Ur(S)=\{b\mid\exists a\in S,\ a\,r\,b\}.

注意这里是关系的直接像。

伴随双射是

\mathrm{Rel}(A,B)\cong\mathrm{Set}(A,P(B)),

r\longmapsto\bigl(a\mapsto\{b\mid a\,r\,b\}\bigr).

单位是单元素集合，乘法是取并。余单位

\[
\varepsilon_B:P(B)\relto B
\]

是成员关系：S\,\varepsilon_B\,b\iff b\in S。

第五篇则首先精确对应 List 单子：

\mathcal L(A,B)=\mathcal D(A,\mathrm{List}(B)),

\eta(b)=[b],\qquad
(g\star f)(a)=\mathrm{appendMap}(g,f(a)).

这里有一个非常值得在第六篇认出的对应：

第五篇构造	在伴随框架中的角色
gather g : A → List B	Hom 双射 E(g)
scatter	Hom 双射的逆
inj	左伴随 J
list->amb : List B →ℬ B	余单位 \varepsilon_B
append-map (gather g) : List A → List B	右伴随的箭头作用 Ug

gather 本身不是右伴随的箭头作用。 两者的定义域不同，这是目前框架里很容易混淆的一点。

列表到关系则经过取支撑：

\mathrm{supp}:\mathrm{List}(B)\to P_{\mathrm{fin}}(B).

它保持单位与复合，诱导

\operatorname{Kl}(\mathrm{List})
\to
\operatorname{Kl}(P_{\mathrm{fin}})
\cong
\mathrm{Rel}_{\mathrm{fin}}.

但它不忠实：

[b],\quad[b,b]

不同，却表示同一个关系输出。

所以第五篇可以同时有两种精确说法：

* 按有序结果列表比较，受限制的直接风格搜索世界可与列表世界同构；
* 忽略顺序与重复后，它表示有限分支关系。

不能把这两种等价混在一个“同构”里。

另外，\mathrm{Rel}_{\mathrm{fin}} 指每个输入只有有限多个输出，不要求关系总共有有限多行。它也不自动具有 Rel 的全部性质：例如转置不保持有限分支，\(\mathbb N\relto1\) 的全关系转置后就变成无限分支。

⸻

8．标题中的“代数”怎样理解？〔数学解释＋编辑判断〕

我认为标题可以成立。最具体的解释是：计算具有可复合的运算结构，并服从单位律、结合律以及与纯计算相容的规律。

从单子看，就是

\mu\circ M\eta=\mathrm{id}
=\mu\circ\eta_M,
\qquad
\mu\circ M\mu=\mu\circ\mu_M.

从程序员已造出的零件看，就是“包入普通值”“接下一步”“把嵌套计算合起来”，以及这些操作的等式。

不过，伴随定理本身主要解释的是表示与复合的结构。控制、搜索、异常的区别还来自具体单子和操作。仅仅说“它们都有一个伴随”，不足以解释各自特有的行为。

英文读者可能联想到 algebraic effects，但不会必然把标题当作那个专门术语。应明确“algebraic”在这里指广义的运算与等式结构。

不能由“有单子/伴随”推出所有控制原语都是技术意义上的 algebraic operations。Plotkin–Power 的框架要求操作满足额外的相容条件，并明确把延续排除在该文的直接处理范围之外。

⸻

9．前五篇应该铺垫什么，哪些现有说法会冲突？〔基于附件的推导与写作判断〕

我会让前五篇真正造出下面四件事，而不提前说范畴术语：

1. 普通值怎样进入新的计算表示；
2. 两步怎样接起来；
3. 为什么接法满足单位与结合规律；
4. 直接写法和编码写法怎样转换，以及什么意义下往返不变。

延续与列表正好可以并排：

零件	延续	列表
包入普通值	\lambda x\,k.k(x)	list
接下一步	\lambda m\,f\,k.m(\lambda x.f(x)(k))	append-map
合并一层	\lambda F\,k.F(\lambda m.m(k))	拼平列表
纯函数作用于编码	neg²	map

第六篇再说明这些零件为何互相决定，足够自然。不必为了伴随，提前把所有范畴论零件逐一摆出来。

但有五处应该先修。

第一，第二篇“落回 𝒟”的归属。
必须把“包装后具有某种类型外形”与“编译后真的不含宿主效应”分开。目前 neg² : 𝒞 → 𝒟 与代码不相符。

第二，第二篇的同构不能直接搬给纯模型。
关于不返回延续、延迟构造、dynamic-wind 的注意框有价值，但它没有解决两个 Hom 集属于不同宿主的问题。

第三，空类型模型的地位。
若继续保留 \bot 的运行时标注，需要明确它不能同时被当作纯外延模型里的真正初对象，去证明程序表示是忠实的。

第四，第三篇固定答案分支的步骤。
可以保留具体程序上的参数消去，但应写成特化，不要暗示一般类型同构。

第五，第五篇关系与列表的观察标准。
该稿已经明确“先后与重复都算在内”，这是对的。前面“函数就是二元关系”等句子最好同步限定为“所表示的关系”，避免后面突然把额外信息当作可观察量。

还有一个此前未在框架中出现、但对 let* 很重要的条件：

只会复合 A\to B\to C 的箭头，不足以解释保留旧变量的任意多变量 let*。

例如后一步同时用 x,y，就需要让环境与计算配合：

\mathrm{st}_{X,Y}:X\times MY\to M(X\times Y).

这是 strength。Moggi Definition 3.2 正式加入该结构，前面的讨论恰好解释了为什么环境与绑定需要它。

Set 中以及你已经写出的延续、列表实现中，这种结构有自然定义；但在“一般 CCC 上任意伴随”的定理里，不能省略。

最后，附件写“前七篇不出现范畴术语，范畴总结归第二部”，又说“第六篇揭示框架”。我会理解为：第六篇揭示共同接口和规律，第二部才命名伴随。这样两项安排相容。

⸻

10．“同构”与“尽量靠上”怎样兼容？〔推导〕

它们可以是不同层次的目标，但不能是同一个命题的两种说法。

对应	可以主张的关系
Set 上的幂集 Kleisli 与 Rel	严格同构
有限幂集 Kleisli 与有限分支关系	严格同构
纯延续世界 \mathcal K_R 与反向延续世界 \mathcal U_R	经 flip 严格同构
纯、有限、保留顺序与重复的 amb 片段，与相应可定义列表箭头	在固定程序等式并验证往返后，可得同构
列表世界到有限分支关系	保持复合，但遗忘顺序与重复；不忠实
有限源码到 Set 中全部语义箭头	一般不满
第二篇原样包装的 effectful CPS 与纯 \mathcal D 上的 Kleisli	目前未建立；空答案的忠实版本还存在上述反例
完整 Racket 与单独的延续/列表单子模型	不能直接宣称同构

“尽量靠上”如果要成为数学目标，应换成具体要求，例如：

* 保持复合与恒等；
* 区分哪些源程序；
* 能表示哪些目标箭头；
* 是否准确反映所选的观察等价；
* 是否恰好表示目标范畴的某个子范畴或商。

尤其需要区分：

* 满性：模型中的每支箭头是否有程序实现；
* 忠实性：被模型识别的程序是否已经在选定的源等式下相等；
* 充分抽象性：模型相等是否恰好等于所选的上下文观察等价。

若 J 对象恒等且 J\dashv U 真已成立，Kleisli 同构就是结论，不再只是“尽量靠上”。保留“靠上”的余地，意味着具体实例中某些假设尚未满足。

⸻

11．文献里叫什么，最值得读哪些？〔已核对文献；用途判断〕

没有必要为整个想法寻找一个唯一专名。最直接的名称是：

* Kleisli adjunction / Kleisli comparison functor：抽象定理；
* monadic semantics of computation：计算效应的统一语义；
* monadic reflection and reification：直接写法与编码写法之间的桥；
* Freyd categories / closed Freyd categories：把纯计算、效应计算、环境和高阶结构一起考虑。

优先读下面五项。

1. Emily Riehl，Category Theory in Context，§5.2。
    作者版 PDF⁠￼。重点是当前版本 Definition 5.2.10、Lemma 5.2.12、Proposition 5.2.13。用来核对这次框架的抽象骨架。不同版本的编号可能不同。
2. Eugenio Moggi，Notions of Computation and Monads，1991。
    论文 PDF⁠￼。先读 §1，特别是 Definitions 1.2–1.3、Proposition 1.6：从延拓操作得到单子；Remark 1.7 直接指出纯到部分计算的包含函子需要右伴随，才有相应 Kleisli 表示。再读 §3 的环境与高阶部分。
3. Andrzej Filinski，Representing Monads，POPL 1994。
    作者摘要及原文入口⁠￼。这是第五篇 gather/scatter，以及后续统一 reflect/reify 叙事最贴近的来源。关键是“可表达单子”的条件；我核对了作者摘要，不冒报尚未核实的内部定理编号。
4. Paul Blain Levy、John Power、Hayo Thielecke，Modelling Environments in Call-by-Value Programming Languages，2003。
    出版页⁠￼。它讨论细粒度按值调用语言、环境，以及 closed Freyd categories 的模型。适合解决“纯宿主如何嵌入效应世界，而且还要支持高阶编程”这个更完整的问题。
5. Yukiyoshi Kameyama、Masahito Hasegawa，A Sound and Complete Axiomatization of Delimited Continuations，ICFP 2003。
    作者版 PDF⁠￼。§2 给出语言与 CPS；§3 是等式及可靠性；§4 分析目标语言与逆翻译；§5–6 处理完备性。它说明真正的直接式/CPS 对应需要怎样限定语法和等式，不能直接视为任意 Set 箭头的可定义性定理。

两项补充：

* Selinger，Control Categories and Duality，2001：PDF⁠￼。用于第二部研究经典控制、高阶结构与 CPS 的范畴模型；不要把其中的控制范畴直接当作你现在没有限定的 Racket 世界。
* Plotkin–Power，Algebraic Operations and Generic Effects，2003：PDF⁠￼。用于厘清“广义的代数结构”与“代数效应”的边界。

我的取舍建议是：保留伴随框架作为第二部的严格解释；第一部第六篇先认出表示、包入、复合与延拓这套共同结构。第二篇的同构、纯性和空类型问题应先独立修正，不能让后面的伴随定理替它们背书。