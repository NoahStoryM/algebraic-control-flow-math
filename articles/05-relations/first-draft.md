# 第五篇正文草稿（标题待定）

大家好，

这是控制流系列的第五篇，前四篇是[《标签成为逻辑之时》](https://zhuanlan.zhihu.com/p/2019516690904401803)、[《箭头指向何方》](https://zhuanlan.zhihu.com/p/2024852076593694078)、[《世界尽头有何物》](https://zhuanlan.zhihu.com/p/2032178684895946051)和[《前沿回望之时》](https://zhuanlan.zhihu.com/p/2049638709486735603)。

第四篇的编译器处理 `if` 时，把同一份剩余工作写进了两个分支，运行时却只走其中一个：测试值在分支之前算出，替我们做了选择。未来写了两次，运行了一次。如果没有这样一个值，每个备选都要走到，同一份剩余工作为每个备选各运行一次呢？第四篇结尾给这样的树起了名字：**搜索树**，一棵拥有不止一条时间线的树。

这样的树其实并不陌生。每当我们用几层嵌套循环把所有可能挨个试一遍，走的就是一棵搜索树。本篇只讨论纯的、有限的搜索。

---

# 遍历搜索

给定边长的范围（上下界都取正整数），比如从 1 到 20，找出所有能构成直角三角形的三条边。最直接的办法是暴力搜索：最短边 `a` 从下界试到上界，`b` 从 `a` 试到上界，`c` 从 `b` 试到上界，满足 a² + b² = c² 的留下。在大多数语言里，暴力搜索是三层嵌套循环；Racket 的 `for*/list` 把三层写在一处。把它包进一个以上下界 `l`、`h` 为参数的函数（`inclusive-range` 交出从一端到另一端、两端都包含在内的整数列表）：

```racket
(: pyth? (→ Natural Natural Natural Boolean))
(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))

(: right-triangles (→ Positive-Integer Positive-Integer
                      (Listof (List Positive-Integer Positive-Integer Positive-Integer))))
(define (right-triangles l h)
  (for*/list ([a (inclusive-range l h)]
              [b (inclusive-range a h)]
              [c (inclusive-range b h)]
              #:when (pyth? a b c))
    (list a b c)))

(right-triangles 1 20)
;; =>
'((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

三层循环逐个生成候选。`a` 每取一个值，`b` 就从 `a` 试到上界；`b` 每取一个值，`c` 又从 `b` 试到上界。`a` = 1 下面的 `b`、`c` 全部试完，才轮到 `a` = 2。每凑齐一组，`#:when` 检查一次：满足条件的由 `(list a b c)` 交出，不满足的什么也不留下。从 1 到 20 一共试了 1540 组，留下六组，按找到的先后接成一张列表。

第四篇的 `if` 把剩余工作写了两次，只运行了一次。这里正相反。`[a (inclusive-range l h)]` 之后的全部代码只写了一次，却为 1 到 20 各运行了一次，每次拿到一个不同的 `a`，彼此互不相干。再往里也一样，`[c (inclusive-range b h)]` 之后的代码为 1540 组候选各运行一次。次数还可以是零：条件不成立，`(list a b c)` 就一次也不运行，这一组到此为止。普通的计算里，剩余工作运行过就成为过去，一次计算只有一条时间线。这里同一份剩余工作运行了许多遍，一次搜索里有不止一条时间线。

---

# 关系

`(right-triangles 1 20)` 交出了六组边。给定上下界，它交出的不是某个答案，而是装有全部答案的容器；换一组边界，答案可能更多，也可能一个都没有。`if` 之后走哪条路由测试值决定，未来是过去的函数。`right-triangles` 也仍是一个函数，同样的边界总得到同一张列表，只是它的值从一个结果扩大成了所有结果。

输出只由输入决定，算过一次的结果就可以记下来，下次遇到同样的边界直接取出，这就是缓存。假设前面已经用三组边界调用过它，缓存里就记着三项，每个 `(l h)` 对应一张答案列表：

```text
(1 4)   ↦  '()
(1 5)   ↦  '((3 4 5))
(1 20)  ↦  '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

缓存里每个边界只出现一次，对应的是一整张列表。把列表摊开，让每组答案各自配上它的边界，一项就成了若干行：

| l | h | a | b | c |
| --- | --- | --- | --- | --- |
| 1 | 5 | 3 | 4 | 5 |
| 1 | 20 | 3 | 4 | 5 |
| 1 | 20 | 5 | 12 | 13 |
| 1 | 20 | 6 | 8 | 10 |
| 1 | 20 | 8 | 15 | 17 |
| 1 | 20 | 9 | 12 | 15 |
| 1 | 20 | 12 | 16 | 20 |

`(1 20)` 原来只是一项，现在占了六行；`(1 5)` 占一行；`(1 4)` 对应的列表是空的，摊开以后一行也没有。

这七行有什么共同点？每一行的五个数都满足同一组条件：`a`、`b`、`c` 从小到大落在 `l` 与 `h` 之间，并且 a² + b² = c²。缓存里再多记几组边界，摊开得到的行也都满足这组条件；反过来，满足这组条件的五个数，只要用它的边界调用过，也一定在摊开的行里。

把所有满足这组条件的行放在一起，是一张完整的**表**。每一行是一组彼此相关的值；行没有先后，也没有重复；边界可以任意取，所以表里有无穷多行。这样一张表，数学上叫做**关系**。程序每次交出的是一张列表，装着表里的若干行：`(right-triangles 1 20)` 交出的，是表里边界为 `(1 20)` 的那六行，每行只留下 `(a b c)`。暂且不计列表的顺序和重复，用集合写就是：

```latex
\text{right-triangles}(l, h) = \{\, (a, b, c) \mid l \le a \le h \,\land\, a \le b \le h \,\land\, b \le c \le h \,\land\, a^2 + b^2 = c^2 \,\}
```

四个条件与第一节 `for*/list` 的三个子句加 `#:when` 一一对应，`pyth?` 检查的是最后一个。

缓存只记得算过的边界。没算过的，还得去跑那三层循环，而循环是我们照着这四个条件一层层写出来的。能不能只写下这些行要满足的条件，让语言去把行找出来？

---

# 描述关系的语言

集合记号写下条件的时候，a、b、c 还不知道是多少。Racket 里的 `pyth?` 不能这样用：它要等三个数都到齐，才能回答是或不是。

设想有这样一门语言，关系的参数可以暂时未知。把关系作用在参数上，不当场回答是或不是，只留下一个条件，等着和别的条件一起求解。这样留下来的条件叫做**目标**（goal）。这门语言里的关系，名字都以 `o` 结尾：`(pytho a b c)` 与 `(pyth? a b c)` 的参数完全相同，交出的却不是 `Boolean`，而是一个目标。上一节集合记号的每一部分，在这门语言里都有对应的写法：

| 数学 | 这门语言 |
| --- | --- |
| l ≤ a ≤ h | `(betweeno l a h)` |
| a² + b² = c² | `(pytho a b c)` |
| 并列的条件 ∧ | 并列的几个目标 |
| {(a, b, c) ∣ …} | `(run* (a b c) …)`，交出时排成一张列表 |

照着集合记号逐项翻译，就得到这门语言里的第一版程序：

```racket
(define (right-triangles l h)
  (run* (a b c)
    (betweeno l a h)    ; l ≤ a ≤ h，最短边
    (betweeno a b h)    ; a ≤ b ≤ h，另一条直角边
    (betweeno b c h)    ; b ≤ c ≤ h，斜边
    (pytho a b c)))     ; a² + b² = c²，直角三角形

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

这门语言眼下只存在于纸上，注释里写的是它应当交出的结果。边界 `l`、`h` 是函数的参数，调用时已经知道。`run*` 声明 `a`、`b`、`c` 是未知的，然后列出四个目标；它找出表里所有满足这些目标的行，把每一行的 `(a b c)` 收进列表交出，正是第一节那个函数交出的列表。四行目标就是集合记号里的四个条件，循环不见了：找出这些行的事，交给了语言。熟悉 SQL 的读者会觉得这种写法眼熟。

---

# 关系的复合

第一版的四个目标是并排写下的。第一节的循环却是一步步挑边的：选定最短边，才知道另一条直角边从哪里试起；选定了它，才知道斜边从哪里试起。每一步都是一个更小的关系，几步首尾相接，才是整道题。函数可以用 `∘` 一段段接起来，关系能不能也这样接？

要接，先得分清哪头接哪头。表本身没有方向，`(l h)` 与 `(a b c)` 只是同一行里的两组数。把一张表的列分成两组，一组算这一头，一组算那一头，就得到一个**二元关系**。函数是其中的特例：这一头的每组值，在那一头恰好对应一组。关系没有这个限制，第二节摊开的那七行里，`(1 20)` 对应着六组边，`(1 4)` 一组也没有。

按挑边的顺序，题目可以拆成四个二元关系：

- `(l h)` 与 `(a h)`：选出最短边，下界 `l` 就用不上了；
- `(a h)` 与 `(a b h)`：选出另一条直角边，`a` 是它的下界；
- `(a b h)` 与 `(a b c)`：选出斜边，上界 `h` 也用不上了；
- `(a b c)` 与 `(a b c)`：只让直角三角形原样通过。

把两个关系 R 与 S 接起来，是说 x 与 z 相关，当且仅当**存在**某个 y，使 x 与 y 在 R 中相关，y 与 z 在 S 中相关。这就是关系的**复合**。R 与 S 都是函数时，给定 x，R 唯一确定 y，S 再唯一确定 z，得到的正是函数的复合。上面四个关系首尾相接，复合起来正是 `(l h)` 与 `(a b c)` 之间的那个关系。

先用手头的 Racket 试试。二元关系最直接的写法是谓词：两头的值都给齐，回答这一行在不在表里。把这种谓词的类型记作 `→ℛ?`，整道题的关系写出来是：

```racket
(define-type (→ℛ? x y) (→ x y Boolean))

(: right-triangle? (→ℛ? (List Positive-Integer Positive-Integer)
                        (List Positive-Integer Positive-Integer Positive-Integer)))
(define (right-triangle? l×h a×b×c)
  (match-define (list l h)   l×h)
  (match-define (list a b c) a×b×c)
  (and (<= l a b c h) (pyth? a b c)))

(right-triangle? '(1 20) '(3 4 5))
;; => #t
(right-triangle? '(1 20) '(4 3 5))
;; => #f
```

谓词的复合应当有这样的类型：

```racket
(: ∘ℛ? (∀ (x y z) (→ (→ℛ? y z) (→ℛ? x y) (→ℛ? x z))))
```

可是只给两个谓词，写不出一个通用的复合。拿到 `x` 和 `z` 以后，要判断是否存在 `y`；两个谓词却都只接收 `y`，不产生 `y`，而 `y` 可以是任意类型，没有现成的办法把候选列出来。在有限的范围里，当然可以把中间项一个个列出来试，但那就回到了第一节手写的循环：搜索由写程序的人来承担。

那门假想的语言不用写程序的人承担这件事。二元关系作用在两头的参数上，同样得到一个目标；复合只写二元情形的等式：

```racket
(define-type (→ℛ x y) (→ x y Goal))

(: ∘ℛ (∀ (x y z) (→ (→ℛ y z) (→ℛ x y) (→ℛ x z))))
((∘ℛ go fo) x z) = (fresh (y) (fo x y) (go y z))
```

这里用到的两样写法，把对照表补全：

| 数学 | 这门语言 |
| --- | --- |
| 存在 ∃y | `(fresh (y) …)` |
| t₁ = t₂ | `(== t₁ t₂)` |

按表逐字读，等式右边就是 ∃y. R(x, y) ∧ S(y, z)，正是复合的定义。`fresh` 只引入中间项，如何找到它，交给这些目标的运行。

上面四个关系各写成一个 `o` 关系，中间项用 `×` 连起各个分量来命名。以第二个为例：

```racket
(define (pick-bo a×h a×b×h)
  (fresh (a b h)
    (== a×h   `(,a ,h))
    (== a×b×h `(,a ,b ,h))
    (betweeno a b h)))
```

`==` 要求两个项相等，这里借它把元组拆成各个分量。`pick-ao`、`pick-co` 形状相同，`righto` 要求两头是同一个满足 `pytho` 的三元组。这样，`right-triangleo` 就是这四个关系的复合，`right-triangles` 再用 `run*` 去查询它：

```racket
(define right-triangleo (∘ℛ righto pick-co pick-bo pick-ao))

(define (right-triangles l h)
  (run* (a b c)
    (right-triangleo `(,l ,h) `(,a ,b ,c))))

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

复合满足结合律，多个关系连续复合时不必说明先接哪两个，所以四个关系可以连着写。按等式逐层展开：

```racket
(define (right-triangleo l×h triangle)
  (fresh (a×h a×b×h a×b×c)
    (pick-ao l×h   a×h)
    (pick-bo a×h   a×b×h)
    (pick-co a×b×h a×b×c)
    (righto  a×b×c triangle)))
```

三个中间的部分解都由 `fresh` 藏了起来；再把它们换成 `(,a ,h)` 这样的模式，就回到了第一版的四行。两种写法说的是同一个关系。第一版的几个条件按共享的未知项随意相连，复合则要把它们接成一条链；为了接成链，后面还要用到的边得打包带下去，`a×h`、`a×b×h` 这些中间元组就是这么来的。

再看 `right-triangles` 这个定义本身。它把 `(l h)` 当作已知，查询所有与它相关的 `(a b c)`；`run*` 把这些答案收进列表。外面的 `right-triangles` 是一个普通的函数：接收一头的值，交出另一头所有相关值的列表。这样的函数不用等那门语言，Racket 现在就写得出来，第一节的 `right-triangles` 就是一个。挑边的四个关系，也能各自写成这样的函数。可是它们要怎样复合？

---

# 列表世界的复合

接收一头的值、交出另一头所有相关值的列表，这种函数的类型记作 `→ℒ`。挑边的前三个关系照这个样子写出来，名字沿用上一节的，因为说的是同一个关系，只是换了一种表示。这里的 `betweeno` 也只是一个普通函数，给定上下界，交出其间所有的数：

```racket
(define-type (→ℒ p q) (→ p (Listof q)))

(: betweeno (→ Natural Natural (Listof Natural)))
(define (betweeno lo hi) (inclusive-range lo hi))

(define (pick-ao t) (match-define (list l h)   t) (map (λ (a) (list a h))   (betweeno l h)))
(define (pick-bo t) (match-define (list a h)   t) (map (λ (b) (list a b h)) (betweeno a h)))
(define (pick-co t) (match-define (list a b h) t) (map (λ (c) (list a b c)) (betweeno b h)))
```

把前两段用普通的 `∘` 接起来：

```racket
((∘ pick-bo pick-ao) '(1 20))
;; match-define: no matching clause for '((1 20) (2 20) … (20 20))
```

`pick-bo` 等的是一个 `(a h)`，收到的却是 `pick-ao` 交出的一整张列表。那就对列表里的每一行各调用一次 `pick-bo`。把范围缩到 1 到 2，看得清楚些：

```racket
(pick-ao '(1 2))
;; => '((1 2) (2 2))
(map pick-bo (pick-ao '(1 2)))
;; => '(((1 1 2) (1 2 2)) ((2 2 2)))
(append-map pick-bo (pick-ao '(1 2)))
;; => '((1 1 2) (1 2 2) (2 2 2))
```

`map` 为每一行各得到一张列表，交出的是列表的列表，下一段 `pick-co` 又接不上了。`append-map` 多做一步，把这些列表接成一张，交出的仍是一行行的部分解，可以照样再接下一段。

列表世界里的复合就是这件事：对上一段交出的每一行调用下一段，再把结果接起来。只有一个值的时候，把它包成单元素的列表，这是复合的单位 `ℒ:id`：

```racket
(: ℒ:id (∀ (p) (→ℒ p p)))
(: ∘ℒ   (∀ (p ...) (→ (→ℒ pn-1 pn) ... (→ℒ p1 p2) (→ℒ p1 pn))))
(define (ℒ:id v) (list v))
(define ((∘ℒ . f*) x) (foldr append-map (list x) f*))
```

`∘ℒ` 从 `(list x)` 出发，由最右边的一段开始，逐段用 `append-map` 接上。第四个关系只让直角三角形原样通过，交出零行或一行。四段接起来：

```racket
(: righto (→ℒ (List Natural Natural Natural) (List Natural Natural Natural)))
(define (righto t) (if (apply pyth? t) (ℒ:id t) '()))

(define right-triangleo (∘ℒ righto pick-co pick-bo pick-ao))
(define (right-triangles l h) (right-triangleo (list l h)))

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

和上一节的第二版对照，`∘ℛ` 换成了 `∘ℒ`，`run*` 不见了：每段函数自己就在交出列表。谓词的复合缺的是中间项的候选，这里上一段把它们直接列了出来，`append-map` 再一个个交给下一段。代价是方向定死了，每段只能从这一头算到那一头。

关系的复合满足结合律，以相等关系为单位；函数是特殊的关系，接进来以后仍按函数的方式复合。`∘ℒ` 用列表模拟关系的复合，这几条它也应当满足：

```racket
(∘ℒ g ℒ:id)          = g
(∘ℒ ℒ:id f)          = f
(∘ℒ f₃ (∘ℒ f₂ f₁))   = (∘ℒ (∘ℒ f₃ f₂) f₁)
(∘ℒ f (∘ ℒ:id h))    = (∘ f h)          ; h 是普通函数
```

检查列表的实现，把答案的顺序和重复次数一起算进去，四条等式仍然成立。

列表毕竟比表多记了一些东西。把最短边倒过来列：

```racket
(define (pick-ao↓ t)
  (match-define (list l h) t)
  (map (λ (a) (list a h)) (reverse (betweeno l h))))

((∘ℒ righto pick-co pick-bo pick-ao↓) '(1 20))
;; => '((12 16 20) (9 12 15) (8 15 17) (6 8 10) (5 12 13) (3 4 5))
```

六组边一组不少，顺序反了。`pick-ao` 与 `pick-ao↓` 描述的是同一个关系，表里的行本来就没有先后。作为关系，这两个程序没有区别；作为列表程序，它们还记着答案以什么顺序、出现了几次。

---

# 认出剩余工作

`∘ℒ` 把四段接起来了，可每一段都得迁就它。`pick-bo` 要做的只是在 `a` 与 `h` 之间取一个 `b` 添进元组，写出来却是把整个范围 `map` 一遍，交出一张列表；普通的 `∘` 接不上，复合也得另写。能不能让每段函数只管一个值，把「为每个备选各做一遍，再把结果接起来」这件事交出去？

眼下做这件事的是 `append-map`：它拿着下一段，对上一段交出的每一行各调用一次。第一节也见过为每个备选各运行一次的东西，是循环里 `[a (inclusive-range l h)]` 之后的全部代码。那三层循环里没有写 `append-map`，它藏在 `for*/list` 里面。

`for*/list` 和 `let*` 写起来几乎一样：一串绑定从上到下排开，后面的绑定可以用前面的名字，`b` 的范围用到了 `a`，`c` 的范围用到了 `b`。两者都把计算的先后写在了绑定的先后里。

差别在绑定的右边。每个绑定配对了两件东西：可归约式和等待其结果的局部延续，也就是绑定之后的全部代码。`let*` 的可归约式算出的是一个值，`for*/list` 的 `(inclusive-range l h)` 算出的却是一个序列，循环变量 `a` 要依次取遍其中每个值。

可是一个局部延续该怎样作用在一整个序列上？先回顾下 `let`，`(let ([v e]) body)` 脱糖后是 `((λ (v) body) e)`，等待结果的延续 `(λ (v) body)` 就摆在眼前。把它命名为 `k`，写成 `((λ (k) (k e)) (λ (v) body))`：`k` 在 `e` 的那一个值上调用一次，而且是最后一步，调用在尾位置。

`for/list` 也能照样写出来。`(for/list ([v e*]) body)` 成了 `((λ (k) (map k e*)) (λ (v) body))`：可归约式 `e*` 生成一个序列，`map` 对其中每个值调用一次 `k`。这些调用不在尾位置：一次调用交出结果以后，`map` 还要接着调用下一个，最后把所有结果收成列表。

但 `for*/list` 和 `let*` 不一样。`let*` 就是嵌套的 `let`，`for*/list` 却不是嵌套的 `for/list`。把 `for/list` 一层层嵌套，外层 `k` 的主体又是一个 `for/list`，交出的是一张列表，外层的 `map` 收起来就成了列表的列表。`for*/list` 在每一层把内层交出的列表接成一张，也就是把 `map` 换成 `append-map`，得到 `((λ (k) (append-map k e*)) (λ (v) body*))`。

这正是上一节 `map` 与 `append-map` 的差别。三种写法并排，其中的 `e*` 都是列表：

```racket
(let ([v e]) body)            = ((λ (k) (k e))            (λ (v) body))
(for/list ([v e*]) body)      = ((λ (k) (map k e*))        (λ (v) body))
(for*/list ([v e*] …) body)   = ((λ (k) (append-map k e*)) (λ (v) body*))
```

`body*` 是其余的子句连同 `body`，交出的是一张列表。

左边的 `(λ (k) (append-map k e*))` 只依赖序列 `e*`。把序列抽成参数，就得到一个函数：给它一张列表，它等着剩余工作 `k`，从列表里逐个取出元素交给 `k` 完成后续计算，再将结果接起来。给它取个名字 `choose/k`：

```racket
(: choose/k (∀ (p q) (→ (Listof p) (→ (→ p (Listof q)) (Listof q)))))
(define ((choose/k p*) k) (append-map k p*))
```

`(append-map k p*)` 站在了 `let` 里 `(k e)` 的位置上。`k` 拿到一个备选，交出一张列表；按第三篇的记法，它是局部延续 ¬ₐp，答案类型取 `(Listof q)`。每层都要接列表，所以摊开以后，最内层也要自己把结果包成列表：

```racket
(define (right-triangles l h)
  ((choose/k (inclusive-range l h))
   (λ (a)
     ((choose/k (inclusive-range a h))
      (λ (b)
        ((choose/k (inclusive-range b h))
         (λ (c)
           (if (pyth? a b c) (list (list a b c)) '()))))))))

(right-triangles 1 20)
;; =>
'((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

输出与 `for*/list` 逐字相同。

剩余工作有了名字，它被调用了几次就数得出来。`let*` 的 `k` 只在一个值上运行一次，运行过就成为过去，一次计算只有一条时间线。`for*` 不同：以 `(right-triangles 1 20)` 为例，最外层的 `(append-map k (inclusive-range 1 20))` 摊开就是 `(append (k 1) (k 2) … (k 20))`，同一个 `k` 运行了二十次，每次拿到一个不同的 `a`，各次调用互不依赖，交出的列表最后接成一张。第一节数出来的那二十次，就是这二十次调用。

参数从左到右求值，`(k 1)` 连同它下面所有的 `b`、`c` 算完才轮到 `(k 2)`，所以这是一次深度优先遍历。序列也可以是空的，这时只剩下 `(append)`，也就是 `'()`，`k` 一次也不调用。`#:when` 过滤掉的组合就是这样：把过滤条件写成再往下一层绑定，条件成立时生成只有一个值的序列，不成立时生成空序列。

上一节的 `∘ℒ` 用的也是 `append-map`，不过它收到的函数只有下一段：先对所有的 `(a h)` 运行 `pick-bo`，得到的整张列表再交给 `pick-co`。上一节的结合律允许换一种括法：

```racket
(append-map g (append-map f xs))
=
(append-map (λ (x) (append-map g (f x))) xs)
```

两边交出同一张列表。右边把后面的段一起包进了函数，这个函数承载的才是一行的全部剩余工作。`for*/list` 里藏着的 `(λ (v) body*)` 正是这样一个函数：等着一个备选，交出一张列表，是一条局部延续。

---

# 擦除延续参数

摊开后的 `right-triangles` 是一段 CPS 程序：每一层的剩余工作都写成 λ，作为参数交给 `choose/k`。第四篇的编译器也是这个形状，`anf1` 带着延续参数 `ctx` 走遍语法树；那里擦掉参数的办法，是让 `shift` 在原来的位置把它取出来。照样做一遍，每个调用点这样改写：

```racket
((choose/k p*) (λ (v) body))
;; =>
(reset (let ([v (shift k ((choose/k p*) k))]) body))
```

`(shift k ((choose/k p*) k))` 在每个调用点都会出现。给它起个名字，再按 `choose/k` 的定义展开一步：

```racket
(: choose (∀ (p) (→ (Listof p) p)))
(define (choose p*) (shift k (append-map k p*)))
```

三层逐一改写：

```racket
(define (right-triangles l h)
  (reset
   (let ([a (choose (inclusive-range l h))])
     (reset
      (let ([b (choose (inclusive-range a h))])
        (reset
         (let ([c (choose (inclusive-range b h))])
           (if (pyth? a b c) (list (list a b c)) '()))))))))

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

看 `choose` 的类型：收进一张列表，交出其中的一个元素。从调用处看，它只返回了一个值，后面的代码照常往下走；`shift` 取得的 `k` 却在 `append-map` 里为每个元素各运行了一遍。同一个 `k` 被调用了不止一次，只能调用一次的延续做不到这件事。

三个 `reset` 层层相套。按第三篇的规约规则，`shift` 取得的 `k` 每次调用都在自己的一层 `reset` 里运行；这层边界与里面的那个 `reset` 紧挨着，中间没有别的工作，而 `(reset (reset e)) = (reset e)`。第四篇化简编译器时，内层的 `reset` 就是这样坍缩的，这里也一样：

```racket
(define (right-triangles l h)
  (reset
   (let* ([a (choose (inclusive-range l h))]
          [b (choose (inclusive-range a h))]
          [c (choose (inclusive-range b h))])
     (if (pyth? a b c) (list (list a b c)) '()))))
```

主体已经是普通的 `let*`，只剩最后一行还带着列表的痕迹：成功时交出 `(list (list a b c))`，失败时交出 `'()`。

先看失败。交出 `'()`，是让这一个备选一行也不留下。从零个备选里选，做的是同一件事：`(choose '())` 就是 `(shift k (append-map k '()))`，`k` 一次也不调用，交出的正是 `'()`。`k` 既然没有用到，按第三篇的等式 `(shift _ e) = (abort e)`，它就是 `(abort '())`：丢掉剩余工作，把空列表作为答案交出。给它起名 `fail`。

再看成功。结果包成单元素列表，是因为每条走到头的时间线都得交出一张列表，好让 `append-map` 去接。这一步与题目无关，把它连同 `reset` 一起移到外面，起名 `collect`：

```racket
(: fail (∀ (p) (→ p)))
(define (fail) (choose '()))

(: collect (∀ (q) (→ (→ q) (Listof q))))
(define (collect thunk) (reset (list (thunk))))

(define (right-triangles l h)
  (collect
   (λ ()
     (let* ([a (choose (inclusive-range l h))]
            [b (choose (inclusive-range a h))]
            [c (choose (inclusive-range b h))])
       (if (pyth? a b c) (list a b c) (fail))))))

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

主体不用再把结果包成单元素列表，失败时也不用自己交出空列表。`a`、`b`、`c` 各选一个，不满足条件就失败，满足就交出这一组边；读起来是一次只有一个值的普通计算。

「为每个备选各运行一遍」并没有消失。在 `choose` 前后各记一笔日志（`note!` 把参数追加到日志末尾）：

```racket
(collect
 (λ ()
   (note! 'before)
   (let ([x (choose '(1 2 3))])
     (note! (list 'after x))
     x)))
;; => '(1 2 3)
;; 日志：before (after 1) (after 2) (after 3)
```

`before` 只记了一次，`after` 记了三次。`choose` 之前的代码已成过去，只运行一次；之后的代码就是 `k`，三个备选各运行一遍。`(k 1)` 返回的时候，其余的备选还在 `append-map` 里等着：`k` 的调用不在尾位置。

`collect` 圈出了一次搜索。边界之内，程序只看得见自己这一条时间线，手里的 `a`、`b`、`c` 各是一个值；走通的时间线各交出一行，`append-map` 把它们接起来，在边界上摆成一张列表。把所有走通的时间线并排摆出来，得到的就是这张列表；不计顺序和重复，它装的正是表里的行。

现在，挑边的四段可以直接交出一个值了：

```racket
(define (pick-a t) (match-define (list l h)   t) (list (choose (betweeno l h)) h))
(define (pick-b t) (match-define (list a h)   t) (list a (choose (betweeno a h)) h))
(define (pick-c t) (match-define (list a b h) t) (list a b (choose (betweeno b h))))

(define (right t) (if (apply pyth? t) t (fail)))

(define right-triangle (∘ right pick-c pick-b pick-a))
(define (right-triangles l h) (collect (λ () (right-triangle (list l h)))))

(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

与 `pick-ao` 相比，差别只在一处：那里把范围 `map` 成一张列表，这里从范围里 `choose` 一个数。每段函数直接交出一个值；遇到备选列表，就交给 `choose`；所有分支的结果，由外面的 `collect` 收起来。先前接不上的普通 `∘`，又接上了。

## amb

`choose` 与 `fail` 这一对操作早有名字，就是 McCarthy 的 `amb`：`(amb 1 2 3)` 从几个备选里选一个，一个备选也不给的 `(amb)` 就是失败。Racket 里的容器大都有一对惯用的写法，比如 `for/list` 把循环的结果收成列表，`in-list` 让循环取遍列表的元素。照这个样子，给 `amb` 也配上一对：

```racket
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (collect (λ () e)))
```

`amb` 的备选是表达式，选中了才求值，所以各包一层 λ，选出来以后再调用。`for/amb` 把循环的每一轮当作一个备选，从中选一个；`in-amb` 把一段计算的全部结果交出来，供循环取遍。有了这一对，第五节交出列表的写法和这一节直接交出一个值的写法，可以互相得到：

```racket
(pick-ao t) = (for/list ([s (in-amb  (pick-a t))])  s)
(pick-a t)  = (for/amb  ([s (in-list (pick-ao t))]) s)
```

形状和列表与向量之间的转换一模一样。第二条说的是，把任一边放进同样的后续计算，再由 `in-amb` 收集，会得到同一张列表。`amb` 与真正的容器只有一处不同：调用处拿到的是其中一个结果，全部结果要到 `in-amb` 的边界上才一起交出。

这几个操作我做成了一个 Racket 包 [amb](https://github.com/noahstorym/amb)。包里的 `in-amb` 交出的是惰性的流，这里的三行简化成了一次算完的列表。

---

# 让关系语言跑起来

有了 `choose` 和 `collect`，回头看第三节那门假想的语言。第一版里的 `(betweeno l a h)`，看起来就是从范围里选一个 `a`：`(choose (inclusive-range l h))`。可是 `a` 不止出现在这一个目标里，`(betweeno a b h)` 也提到了它。如果每个目标只管为自己提到的未知项各选各的，会怎样？

```racket
(define independent
  (collect
   (λ ()
     (let* ([a₁ (choose (inclusive-range 1 20))]    ; (betweeno l a h) 里的 a
            [a₂ (choose (inclusive-range 1 20))]    ; (betweeno a b h) 里的 a，各选各的
            [b  (choose (inclusive-range a₂ 20))]
            [c  (choose (inclusive-range b 20))])
       (if (pyth? a₁ b c) (list a₁ b c) (fail))))))

(take independent 7)
;; => '((3 4 5) (3 4 5) (3 4 5) (3 4 5) (4 3 5) (4 3 5) (4 3 5))
(length independent)
;; => 110
```

六组答案成了 110 个，里面还有 `(4 3 5)`，最短边比另一条直角边还长。两处的 `a` 本是同一个未知项，拆成两次互不相干的选择，a ≤ b 这个约束就丢了。

这个例子里，把 `a` 只绑定一次就能共享。关系语言里的未知项却没法这样处理。`fresh` 引入中间项的时候，它的值还没有着落；`pick-bo` 的第二个 `==` 更是把中间元组和 `b` 这两个都还不知道的项先联系起来，`b` 的值要等下一行的 `betweeno` 去找。几个目标得能共享一个还不知道值的项，之后不管是谁找到了关于它的信息，对所有提到它的目标都要生效。

所以未知项自己得是一个值，可以先交到各个目标手里；目前对它们知道了什么，另外记在一处，叫做**代换**（substitution）：

```racket
(struct var ([name : Symbol]) #:type-name Var)   ; 未知项，按 eq? 区分
(define-type Term (∪ Var Number Symbol Null (Pair Term Term)))
(define-type Substitution (Immutable-HashTable Var Term))

(define empty-s (hasheq))

(define (walk t s)
  (if (and (var? t) (hash-has-key? s t))
      (walk (hash-ref s t) s)
      t))
```

代换记下未知项已知的值。记下的值可以是另一个未知项，`walk` 顺着代换一路查下去，查到当前能知道的为止。

`==` 要求两个项相等。做到这一点的过程叫做**合一**（unification）：

```racket
(define (occurs? x t s)
  (let ([t (walk t s)])
    (or (eq? x t)
        (and (pair? t)
             (or (occurs? x (car t) s) (occurs? x (cdr t) s))))))

(define (ext-s x t s)
  (if (occurs? x t s) (fail) (hash-set s x t)))

(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (ext-s u v s)]
          [(var? v) (ext-s v u s)]
          [(and (pair? u) (pair? v))
           (unify (cdr u) (cdr v) (unify (car u) (car v) s))]
          [(equal? u v) s]
          [else (fail)])))
```

`unify` 先查出两边当前的值。已经是同一个项，代换原样交出；有一边是未知项，就在代换里记下它等于另一边；两边都是序对，就逐个分量合一；否则这两个项不可能相等，`(fail)`，这条时间线到此为止。`ext-s` 记下之前多查一步，不让未知项等于含有它自己的项。

第三节说，目标是留下来等着求解的条件。现在它有了具体的形状：一个从代换到代换的函数，收到目前已知的信息，交出添上自己这个条件之后的信息。

```racket
(define-type Goal (→ Substitution Substitution))
(define-type (→ℛ x y) (→ x y Goal))

(define ((== u v) s) (unify u v s))
(define ((conj . g*) s) (foldl (λ (g s) (g s)) s g*))
(define ((disj . g*) s) ((choose g*) s))

(define-syntax-rule (fresh (x ...) g ...)
  (λ (s)
    (let ([x (var 'x)] ...)
      ((conj g ...) s))))

(define (walk* t s)
  (let ([t (walk t s)])
    (if (pair? t)
        (cons (walk* (car t) s) (walk* (cdr t) s))
        t)))

(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (collect (λ () (walk* (list x ...) ((conj g ...) empty-s))))))
```

目标是用 `choose` 和 `fail` 写的函数，所以它「交出一个代换」，也可能是失败，或者分成几条时间线各交出一个。把前面两张对照表合起来，再添上析取和两个常量，每一行都有了实现：

| 数学 | 这门语言 | 实现 |
| --- | --- | --- |
| t₁ = t₂ | `(== t₁ t₂)` | 合一，把结果记进代换 |
| ∧ | 并列的目标，`conj` | 代换依次流过每个目标 |
| ∨ | `disj` | 用 `choose` 选一个目标 |
| ∃ | `fresh` | 收到代换时分配新的未知项 |
| ⊤ | `(conj)` | 代换原样交出 |
| ⊥ | `(disj)` | 从零个目标里选，失败 |
| {… ∣ …} | `run*` | 从空代换出发，用 `collect` 收集 |

`conj` 就是上一节那种普通函数的复合。前一个目标交出满足自身条件的代换，后一个在这些代换上继续求解；最后留下的答案，就同时满足两个条件。代换是不可变的哈希表，每条分支带着自己的代换往下走；一条分支失败，不会改动其他分支手里的代换。`run*` 为要查询的项分配未知项，让空代换流过所有目标，再用 `walk*` 把查询项里的未知项都换成查到的值。

两个目标共享一个还不知道值的项，现在做得到了：

```racket
(run* (x y)
  (== x y)
  (== y 3))
;; => '((3 3))
```

第一个目标运行时，`x` 和 `y` 都还不知道，代换里只记下 `x` 就是 `y`。第二个目标找到 `y` 是 3，`x` 也跟着确定了。

还差 `betweeno` 和 `pytho`。第五节借用过 `betweeno` 这个名字，这里才是第三节伪代码里的那一个：

```racket
(define ((betweeno lo x hi) s)
  ((== x (choose (inclusive-range (walk lo s) (walk hi s)))) s))

(define ((pytho a b c) s)
  (if (pyth? (walk a s) (walk b s) (walk c s)) s (fail)))
```

`betweeno` 从范围里 `choose` 一个数，要求 `x` 与它相等；`pytho` 查出三条边当前的值，交给 `pyth?`。这两个目标只认已经确定的数：轮到 `betweeno` 时上下界必须已知，轮到 `pytho` 时三条边必须已知。目标的先后因此有关系，第三节那四行的顺序恰好满足要求。数据库会把顺序交给查询优化器去安排，这门语言只会按写出的顺序深度优先地找。

第三节的第一版，一字不改，可以运行了：

```racket
(right-triangles 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

复合按第四节的等式写成变参函数：每接一段，`fresh` 一个中间项；一段也没有，就是相等关系。

```racket
(: ∘ℛ (∀ (p ...) (→ (→ℛ pn-1 pn) ... (→ℛ p1 p2) (→ℛ p1 pn))))
(define ((∘ℛ . r*) x z)
  (match r*
    ['() (== x z)]
    [(list r ... f) (fresh (y) (f x y) ((apply ∘ℛ r) y z))]))
```

`pick-bo` 在第四节已经写过，另外三个关系补上：

```racket
(define (pick-ao l×h a×h)
  (fresh (l a h)
    (== l×h `(,l ,h))
    (== a×h `(,a ,h))
    (betweeno l a h)))

(define (pick-co a×b×h a×b×c)
  (fresh (a b c h)
    (== a×b×h `(,a ,b ,h))
    (== a×b×c `(,a ,b ,c))
    (betweeno b c h)))

(define (righto a×b×c triangle)
  (fresh (a b c)
    (== a×b×c  `(,a ,b ,c))
    (== triangle a×b×c)
    (pytho a b c)))
```

第二版同样一字不改，`(right-triangles 1 20)` 交出同样的六组边。

第四节说过，表本身没有方向。只用 `==` 写成的关系兑现了这一点：

```racket
(define (swapo p q)
  (fresh (x y)
    (== p (list x y))
    (== q (list y x))))

(run* (q) (swapo '(1 2) q))
;; => '(((2 1)))
(run* (p) (swapo p '(2 1)))
;; => '(((1 2)))
```

每个答案是查询项的值排成的列表，这里只查询一项，它的值本身是一个二元组。同一个 `swapo`，给这一头就求出那一头，给那一头就求出这一头。`betweeno` 和 `pytho` 做不到，因为它们要求数已经确定。

这门语言是 miniKanren 的一个精简版。表里的行，现在由 `choose` 和代换一起去找：`choose` 管分支，代换管每条分支上已经知道了什么。同一个内核用 amb 包写成的样子，见 [ambKanren](https://github.com/noahstorym/ambKanren) 里的 `demo.rkt`：`choose` 的位置上是 `amb`，`collect` 的位置上是 `in-amb`，另外添了 `conde` 和答案的重整。

---

# 只要第一组答案

`run*` 找出所有的答案。有时候一组就够了：边长在 1 到 20 之间，有没有直角三角形？找到第一组就可以停下。第三篇的 `abort` 丢掉剩余的局部工作，把一个值作为这段局部计算的答案交出，听上去正合适。`run*` 里的 `collect` 展开是 `(reset (list …))`；最直接的写法，是在 `list` 外面加一个 `abort`，拿到第一个答案就交出去：

```racket
(define-syntax-rule (run1 (x ...) g ...)
  (let ([x (var 'x)] ...)
    (reset (abort (list (walk* (list x ...) ((conj g ...) empty-s)))))))

(define (first-triangle l h)
  (run1 (a b c)
    (betweeno l a h)
    (betweeno a b h)
    (betweeno b c h)
    (pytho a b c)))

(first-triangle 1 20)
;; => '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
```

六组全来了，也没有报错。把 `abort` 去掉，`run1` 就是 `run*`，结果一模一样。`abort` 并不是什么都没做，换一个小例子能看见它：

```racket
(reset (let ([x (choose '(1 2 3))])
         (abort (list x))
         (error 'unreachable)))
;; => '(1 2 3)
```

`abort` 后面的 `error` 一次也没有执行，三个备选却都走到了。

`choose` 取得的 `k`，是从它到 `reset` 之间的剩余工作。前面说过，每次调用 `k`，这份工作都在自己的一层边界里运行；`abort` 丢掉的是到最近的边界为止的工作，也就是这一次 `(k 1)` 里还没做的部分。于是 `(k 1)` 交出 `'(1)`，正常返回到 `append-map` 手里，`append-map` 接着调用 `(k 2)` 和 `(k 3)`。`abort` 结束了当前备选的计算，却没有丢掉等待其他备选的 `append-map`。`run1` 里的 `abort` 本来就在这段工作的最后一步，后面没有东西可丢，所以去掉它也没有区别。

我们想退出的是整个搜索，`abort` 退出的是当前这一个备选。两种退出的目标不同，手头的接口却只说得出「到最近的边界为止」。

---

# 结论

全篇谈的是同一张表。第二节从缓存里摊开了它的几行，认出这些行满足同一组条件；第三、四节只把条件写下来。从第五节起，条件没有再变，变的是由谁把行一行行列出来。

第一节是手写的三层循环。第五节把循环拆成四段，每段交出一张列表，`append-map` 把下一段用在每一行上。接着在 `for*/list` 里认出同一个 `append-map`，它在那里收到的函数是全部的剩余工作；再让 `shift` 在原处取得这个函数，每段函数就只交出一个值，「为每个备选各运行一遍」交给了 `choose`。最后在 `choose` 之上添了代换，让几个目标共享还不知道值的项，第三节那门只写条件的语言就运行了起来。

几种写法里，被反复运行的始终是同一份剩余工作。第四篇结尾问，什么样的树会打破「恰好使用一次」。这里的做法是把局部延续交给 `append-map`，答案类型取成列表：走通的时间线各交出一行，在 `reset` 的边界上接成一张。边界之内，程序读起来是一次只有一个值的普通计算；边界之外，拿到的是装着若干行的列表。

## 未解的线索

`run1` 留下的问题还在。`choose` 每调用一次 `k`，就多出一层边界；想退出整个搜索的 `abort`，只到得了最近的这一层。`append-map` 也定死了搜索的走法：当前备选后面的工作不全部做完，下一个备选就轮不到。倘若某个备选下面有无穷多条时间线，后面的备选永远等不到，本篇因此只讨论了有限的搜索。amb 包里的 `in-amb` 取到第一个答案就能停下，ambKanren 的 `run 1` 靠的就是它；这里的三行定义还做不到。

怎样才能退出整个搜索？那是后续文章的故事了。
