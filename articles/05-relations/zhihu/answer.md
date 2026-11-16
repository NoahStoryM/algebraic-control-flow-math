`append` 把两个列表接成一个。把它改写成 **关系**（*relation*）`appendo`，就可以倒过来问：哪两个列表接起来是 `(1 2 3)`？

```racket
> (run* (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
```

四种拆法，一种不少。定义 `appendo` 的时候，没有人写过「拆」这件事。

问 miniKanren 是怎样实现的，问的就是这四组答案从哪里来。答案比想象的短：下面四十来行 Racket 就能把上面的程序跑出来。再往后，是这四十来行不够用的地方，以及《The Reasoned Schemer》和几个库各自怎样补上。

## 还不知道的东西

倒着问的时候，`x` 和 `y` 都还没有值。它们不是哪个数的名字，只是两个记号；可同一个记号出现在几处，指的必须是同一个东西。没有值可比，就按身份来认：

```racket
(struct var (name)
  #:property prop:custom-write                    ; 只为打印：显示成它的名字
  (λ (v port mode) (write (var-name v) port)))
```

每调用一次 `(var 'x)`，得到一个新的东西；名字不参与计算，只在打印时露面。这样的东西叫 **未知项**（*logic variable*），也就是常说的逻辑变量。数、符号、空列表、未知项，以及它们组成的 **序对**（*pair*），统称 **项**（*term*）。下面的例子里，`x`、`y` 都是这样造出来的未知项。

搜索往前走，我们对未知项知道得越来越多。知道的事记在一张表里，每行是一条等式：

```racket
(list (cons y 5) (cons x y))    ; y = 5，x = y
```

想知道 `x` 现在是什么，就顺着等式查下去，查到表里没有的东西为止：

```racket
(define (walk t s)
  (define p (and (var? t) (assq t s)))
  (if p (walk (cdr p) s) t))
```

```racket
> (walk x (list (cons y 5) (cons x y)))
5
```

这张表叫 **代换**（*substitution*）。它记的是等式，不是赋值：`x = y` 这一行只说两者相等，谁也没说它们是几。

## 让两边相等

往表里添等式的只有一个函数。它收两个项和一张表，想办法让两个项相等：

```racket
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (cons (cons u v) s)]
          [(var? v) (cons (cons v u) s)]
          [(and (pair? u) (pair? v))
           (let ([s (unify (car u) (car v) s)])
             (and s (unify (cdr u) (cdr v) s)))]
          [(equal? u v) s]
          [else #f])))
```

先把两边都查到底。已经是同一个东西，表不用动；有一边是未知项，添一行；两边都是序对，头对头、尾对尾地做下去；都是值，相等就过，不等就交出 `#f`。

```racket
> (unify (list x 2) (list 1 y) '())
((y . 2) (x . 1))
> (unify (list x 2) (list 1 x) '())
#f
```

第一次，两边各有一个洞，各从对面得到了填法。第二次，`x` 先等于 `1`，又被要求等于 `2`，做不到。这件事叫 **合一**（*unification*）。它像模式匹配，只是两边都可以有洞。

## 岔路

`(== x 1)` 写在程序里的时候，表还不在场；它得等一张表来了，才知道该往哪里添等式。所以它是一个函数，收一张表。交出什么呢？合一可能成功，也可能失败，交出一张表或者 `#f` 似乎就行。可是马上会遇到「x 是 1 或者 2」这样的条件：两种可能都对，各自要添的等式不同，一张表装不下。

那就交出一列代换。成功是一张，失败是零张，两种可能是两张：

```racket
(define ((== u v) s)
  (define s1 (unify u v s))
  (if s1 (list s1) '()))

(define ((disj . g*) s) (append-map (λ (g) (g s)) g*))

(define ((conj . g*) s)
  (for/fold ([s* (list s)]) ([g g*])
    (append-map g s*)))
```

收一张代换、交出一列代换的函数，叫 **目标**（*goal*）。`disj` 是「或者」：把同一张表交给每个目标，交回来的接在一起。`conj` 是「并且」：第一个目标交出的每一张表，都交给第二个目标再添一遍，一路传下去。书里把这两样合写成 `conde`：每个子句是一组「并且」，子句之间是「或者」。

```racket
> ((disj (== x 1) (== x 2)) '())
(((x . 1)) ((x . 2)))
> ((conj (disj (== x 1) (== x 2)) (== y x)) '())
(((y . 1) (x . 1)) ((y . 2) (x . 2)))
> ((conj (== x 1) (== x 2)) '())
()
```

逻辑式语言常被说成会 **回溯**（*backtracking*）：一条路走不通，就退回上一个岔口换一条。这里找不到哪一行在退。岔口是 `disj`，它把两条路都走了；走不通的那条交回一个空列表，`append-map` 接它的时候什么也没接上，它就这样不见了。回溯没有写成一个动作，它是「空列表接上去等于没接」这件事。

## 每次都是新的

关系的定义里常要用到只在内部出现的未知项，比如拆开一个列表时的头一项和剩下那一截。它们要在用到的时候才造：

```racket
(define-syntax-rule (fresh (x ...) g ...)
  (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))
```

`fresh` 交出的也是目标。表来了，它才造出新的未知项，再运行里面的条件；用一次，造一批新的。

现在可以写 `appendo` 了。`l` 是空的，`out` 就是 `t`；或者 `l` 有头 `a` 和尾 `d`，`out` 的头也是 `a`，尾 `res` 是 `d` 接上 `t`：

```racket
(define (appendo l t out)
  (disj (conj (== l '()) (== t out))
        (fresh (a d res)
          (== l (cons a d))
          (== out (cons a res))
          (appendo d t res))))
```

第二支里 `appendo` 调用了自己。它没有一头扎下去，靠两件事。递归那一行包在 `fresh` 的 `λ` 里，定义 `appendo`、构造这个目标的时候都不会往下调用，表来了才运行。真跑起来，在开头那两个问法里，已知的列表每深一层就短一截，短到空，第二支的等式就再也成立不了。这层推迟眼下只是顺带的，后面它会变成主角。

## 把表读成答案

一张代换是给程序看的。给人看，要把问的那几个未知项沿着表换到底；换不动的未知项，按出现的先后起名 `_.0`、`_.1`：

```racket
(define (walk* t s)
  (let ([t (walk t s)])
    (if (pair? t) (cons (walk* (car t) s) (walk* (cdr t) s)) t)))

(define (reify t s)
  (define (name t r)
    (let ([t (walk t r)])
      (cond [(var? t) (cons (cons t (string->symbol (format "_.~a" (length r)))) r)]
            [(pair? t) (name (cdr t) (name (car t) r))]
            [else r])))
  (let ([t (walk* t s)])
    (walk* t (name t '()))))

(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (for/list ([s ((conj g ...) '())])
      (reify (list x ...) s))))
```

`name` 一边往下走，一边把遇到的、还没起名的未知项记进 `r`；`r` 里已经有几个，下一个就叫几号。这一步在 miniKanren 里叫 `reify`。`run*` 造出要问的未知项，从一张空表出发，把所有条件接成一个目标运行，再把交回来的每张表读成一组答案。开头那个程序，到这里原样能跑：

```racket
> (run* (z) (appendo '(1 2) '(3) z))
(((1 2 3)))
> (run* (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
```

正着问和倒着问，走的是同一段代码。`appendo` 的每一行都是等式，等式不分哪边是输入；`disj` 把「空的」和「有头有尾的」两种情形都试了，于是 `(1 2 3)` 在每个位置上都被切过一刀。

答案里也可以留着不知道的东西：

```racket
> (run* (x y) (== x y))
((_.0 _.0))
> (run* (x y) (== x x))
((_.0 _.1))
```

第一组说 `x` 与 `y` 是同一个东西，是什么都行；第二组什么也没说，条件里根本没提到 `y`，两者各自是什么都行，相同也行。一组这样的答案顶得上无穷多组具体的答案。

提问的答案到这里就齐了。项里可以有未知项；代换是一张记着等式的表；合一往表里添等式；目标把一张代换变成一列代换，「或者」把它们接起来，「并且」把它们一张张传下去；`run*` 从空表出发，最后把表读成答案。整个语言就是这几个普通的函数，加上 `fresh`、`run*` 两个只管起名字的宏，所以它能嵌在 Racket 里。四十来行，没有一行是专门为「倒着算」写的。

这里还省了一件事：`unify` 添等式之前，不检查那个未知项是否出现在另一边。`(== q (list q))` 会照收不误，读答案时 `walk*` 就停不下来了。第二版书里的 `ext-s` 先做这个检查，microKanren 和这里一样省掉了。

## 写不完的答案

列表有一个地方不够用。

```racket
(define (alwayso) (disj (== 1 1) (fresh () (alwayso))))
```

`alwayso` 成功一次，或者再来一遍，所以它有无穷多个答案。`(run* (q) (alwayso))` 不会回来，这不奇怪；麻烦在于，想只取前三组也办不到，因为列表要整个造好才交得出来。其实不用这么极端：开头的 `appendo` 三个位置都不给，`(run* (x y z) (appendo x y z))` 也有无穷多组答案，同样回不来。

《The Reasoned Schemer》和 microKanren 的办法，是让列表可以只造一半。除了「空」和「一个答案，后面还有」，再添第三种样子：一个不带参数的函数，表示后面的还没算，要的时候再调用。这就是 **流**（*stream*）。`append` 与 `append-map` 相应地各多一个分支：

```racket
(define (mplus $1 $2)
  (cond [(null? $1) $2]
        [(procedure? $1) (λ () (mplus $2 ($1)))]
        [else (cons (car $1) (mplus (cdr $1) $2))]))

(define (bind $ g)
  (cond [(null? $) '()]
        [(procedure? $) (λ () (bind ($) g))]
        [else (mplus (g (car $)) (bind (cdr $) g))]))
```

这两个函数在 microKanren 里就叫 `mplus` 和 `bind`。「或者」与「并且」照旧，只把 `append` 和 `append-map` 换成它们：

```racket
(define ((disj . g*) s) (foldr (λ (g $) (mplus (g s) $)) '() g*))
(define ((conj . g*) s) (for/fold ([$ (list s)]) ([g g*]) (bind $ g)))
```

再让每个关系在入口处不往下算，只交出这样一个函数。前面 `fresh` 顺带做的那次推迟，现在成了规矩：

```racket
(define-syntax-rule (defrel (name x ...) g ...)
  (define ((name x ...) s)
    (λ () ((conj g ...) s))))
```

别的都不动。`alwayso` 照新的规矩重写，递归的那一次不再靠 `fresh` 垫着：

```racket
(defrel (alwayso) (disj (== 1 1) (alwayso)))
```

取答案的 `run` 多收一个数，要几组就沿着流往下取几次，遇到还没算出来的就调用它；写 `#f` 是全要，相当于原来的 `run*`：

```racket
(define (take n $)
  (cond [(eqv? n 0) '()]
        [(null? $) '()]
        [(procedure? $) (take n ($))]
        [else (cons (car $) (take (and n (sub1 n)) (cdr $)))]))
```

```racket
> (run 3 (q) (alwayso) (== q 'again))
((again) (again) (again))
```

`mplus` 的第二个分支里藏着一个小动作：左边还没算出来的时候，它交回的是 `(mplus $2 ($1))`，两个参数换了位置。左边每推迟一次，就轮到右边走一步。于是下面这个程序也有答案，尽管左边那一支永远在原地打转：

```racket
(defrel (nevero) (nevero))
```

```racket
> (run 1 (q) (disj (nevero) (== q 'here)))
((here))
```

这叫 **交错**（*interleaving*）。这个岔口上的两条路轮流走：左边每推迟一次，右边就走一步，左边没有尽头也拖不住右边。入口处的那次推迟因此有了第二个用处：它是这条路把轮次让出去的地方。

## 把流藏起来

回头看那四十行，有一样东西到处都是：`==` 要把结果包进列表，`disj` 和 `conj` 要 `append-map`，换成流以后是 `mplus` 与 `bind`。每个目标都在亲手搬运「好几种可能」。可我们心里想的要简单得多：一个目标交出一张表，只是有时候它会交出好几次，有时候一次也不交。

有一个运算符，做的正是「交出好几次」。它叫 `amb`；这里用我写的 [amb](https://github.com/NoahStoryM/amb) 库：

```racket
> (for/list ([p (in-amb (let ([a (amb 1 2 3)] [b (amb 1 2 3)])
                          (unless (= (+ a b) 4) (amb-fail))
                          (list a b)))])
    p)
((1 3) (2 2) (3 1))
```

`(amb 1 2 3)` 返回了三次，它后面的程序为每个值各运行一遍；`(amb-fail)` 让眼下这一遍到此为止，退回最近的岔口换下一个值；`in-amb` 在外面把走通的结果收起来。回溯在这里成了一个动作，只是它住在 `amb` 里，目标里仍然看不见。把搬运交给它，目标就成了收一张表、交出一张表的普通函数：

```racket
(define ((== u v) s) (or (unify u v s) (amb-fail)))
(define ((disj . g*) s) ((for/amb ([g g*]) g) s))
(define ((conj . g*) s) (for/fold ([s s]) ([g g*]) (g s)))
```

合一失败，这一遍到此为止。「或者」是从几个目标里选一个，选哪个都算数。「并且」最干脆：前一个目标交出的表交给后一个，这就是函数的复合，连 `append-map` 的影子都没有了。未知项、`walk`、`unify`、`reify`、`fresh` 一个字不用改。

| | 列表 | 流 | `amb` |
| --- | --- | --- | --- |
| 目标交出 | 一列代换 | 一条代换的流 | 一张代换 |
| 成功 | `(list s)` | `(list s)` | `s` |
| 失败 | `'()` | `'()` | `(amb-fail)` |
| 或者 | `append-map` | `mplus` | `amb` |
| 并且 | `append-map` | `bind` | 函数复合 |
| 推迟 | 没有 | 交出一个 `λ` | `(amb-pause)` |

最后一行是关系入口处的那次推迟。在这里它是一次调用：

```racket
(define-syntax-rule (defrel (name x ...) g ...)
  (define ((name x ...) s)
    (amb-pause)
    ((conj g ...) s)))
```

三个关系都用这个 `defrel` 定义：`alwayso`、`nevero` 的写法与流的版本一字不差，`appendo` 只把 `define` 换成 `defrel`。同样的三个程序：

```racket
> (run #f (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
> (run 3 (q) (alwayso) (== q 'again))
((again) (again) (again))
> (run 1 (q) (disj (nevero) (== q 'here)))
;; 不回来
```

前两个照旧，`in-amb` 本来就是按需一个一个找。第三个卡住了：`amb` 默认先把左边走完，而 `nevero` 永远走不完。流的版本里，轮流走是 `mplus` 交换参数做到的；这里，几个备选的结果怎样合成一条，是一个可以换的参数：

```racket
> (parameterize ([current-amb-merger amb-interleave])
    (run 1 (q) (disj (nevero) (== q 'here))))
((here))
```

`amb-interleave` 在一条路暂停的时候换另一条走。它只能在暂停处换：把 `nevero` 入口的 `(amb-pause)` 拿掉，换了合并的办法也还是等不到。流的版本其实一样，没有入口处交出的那个 `λ`，`mplus` 也无从交换。**公平**（*fairness*）不是白来的，要每条没有尽头的路自己肯停下来让一让。

流真的不见了吗？向搜索要它的下一件事，看它交出什么：

```racket
(define (count-from n)
  (amb n (begin (amb-pause) (count-from (add1 n)))))
```

```racket
> (let*-values ([(v1 next) (amb-generate* (λ () (count-from 0)))]
                [(v2 next) (next)]
                [(v3 next) (next)])
    (list v1 v2 v3))
((0) 1 (1))
```

每问一次，得到两样东西：这一步的结果，和一个接着往下问的函数。结果有三种样子：一个列表是一个答案，答案的值放在列表里，因为一个答案可以有好几个值；一个正整数 n 是连着 n 次暂停；`#f` 是没有了。所以 `((0) 1 (1))` 读作：答案 `0`，暂停一次，答案 `1`。这就是流：`(cons 答案 (λ () 后面的))` 里的 `cons` 换成了两个返回值，「还没算出来」的那种样子，换成了一个记着暂停次数的数。流没有消失。它不再是每个目标都要经手的数据，而是搜索本身被人从外面一步一步问出来时的样子。

## 顺序与两个库

「并且」写成函数复合，还有一处要交代。它和 `bind` 找到的答案相同，可是在轮流走的时候，先后可能不同。`bind` 先把前一个目标的几种可能合成一条，再按答案的先后交给后一个；amb 库里做这件事的是 `amb-local`，「并且」就写成 `(g2 (amb-local (g1 s)))`。函数复合则让后一个目标在前一个的每条岔路里面各自运行，轮次跟着岔路的形状走。前一个目标取嵌成 ((x = 1 或 x = 2) 或 x = 3) 的三个备选，后一个目标进门先暂停一次，用 `amb-interleave` 跑，读出的 `x` 依次是：函数复合 `(3 1 2)`，`amb-local` `(1 2 3)`（代码在 `3-amb.rkt`）。复合有个省心的地方：(A 或 B) 并且 C 与 (A 并且 C) 或 (B 并且 C) 连先后都一样。`amb-local` 换来的是与书上逐项相同的顺序。

照这两条路，我各写了一个库。[miniKanren-typed](https://github.com/NoahStoryM/miniKanren-typed) 照两版书的代码逐个定义，用流，写成 Typed Racket。当初写它，是因为读那两本书的时候，我手边的几个 miniKanren 包，有的缺运算符，有的跑出来的例子和书上对不上；照着书抄一遍，再配上类型，才算把上面这些弄明白。[ambKanren](https://github.com/NoahStoryM/ambKanren) 是 `amb` 的那一条：microKanren 与两版书的语言各占一个模块，目标都是直接写成的普通函数，收一张代换，交出一张代换，只有 microKanren 那个模块多带一个给未知项编号的计数器。为了能拿书上的输出当标准答案核对，它的「并且」用的是 `amb-local` 那一种。同一段 `appendo`，三个位置都不给，交给两个库各取前四组（用的是第二版的语言，它把没定下来的项写成 `_0`，不带点）：

```racket
> (run 4 (x y z) (appendo x y z))
流   ((() _0 _0) ((_0) _1 (_0 . _1)) ((_0 _1) _2 (_0 _1 . _2)) ((_0 _1 _2) _3 (_0 _1 _2 . _3)))
amb  ((() _0 _0) ((_0) _1 (_0 . _1)) ((_0 _1) _2 (_0 _1 . _2)) ((_0 _1 _2) _3 (_0 _1 _2 . _3)))
```

## 两个常量，三个运算

《The Reasoned Schemer》里说，做关系式编程只需要两个常量 `#s`、`#u`，和三个运算 `==`、`fresh`、`conde`。手里的东西对得上吗？

`conde` 前面说过，是 `disj` 套 `conj`。回到列表的版本，两个常量我们没有定义过，可它们已经在了：

```racket
> ((conj) '())
(())
> ((disj) '())
()
```

零个条件的「并且」，原样交回那张表，总是成功，这是 `#s`。零个条件的「或者」，一张也不交，总是失败，这是 `#u`。

再看目标。它收一张代换，交出零张或多张，所以它是代换与代换之间的一个二元关系：哪张表能变成哪张表。「并且」把两个这样的关系首尾相接，是关系的复合；「或者」把两个关系并在一起；`#s` 是恒等关系，接在谁前后都不改变谁；`#u` 是空关系，跟谁并都不改变谁。`amb` 的版本把这一点写在了明面上：复合就是函数的复合，并就是 `amb`，空就是 `(amb-fail)`。

剩下 `fresh`。它造出的未知项不在 `run*` 的括号里，答案里也就没有它：

```racket
(define (P x y) (conj (disj (== y 5) (== y 6)) (== y x)))
```

```racket
> (run* (x) (fresh (y) (P x y)))
((5) (6))
```

`P` 说的是 (y = 5 ∨ y = 6) ∧ y = x，这段程序算的是 { x | ∃y. P(x, y) }。这里的「表」换了意思：不再是一张代换，而是把满足 `P` 的 `x`、`y` 列成的一张两列的表。这样的表只管有没有这一行，不管先后，也不留重复；搜索两样都管，前面几节说的就是它们。`fresh` 做的，就是把 `y` 那一列遮住。下表里零个未知项的 `fresh` 就是前面的 `conj`。

| miniKanren | 逻辑 | 在表上 |
| --- | --- | --- |
| `#s` | ⊤ | 只有一行、没有列的表 |
| `#u` | ⊥ | 一行也没有的表 |
| `(== t1 t2)` | t1 = t2 | 两项相等的那些行 |
| `(conde [g1] [g2])` | g1 ∨ g2 | 两张表并起来 |
| `(fresh () g1 g2)` | g1 ∧ g2 | 两张表按共有的列拼起来 |
| `(fresh (x) g)` | ∃x. g | 遮住一列 |
| `(run* (x) g)` | { x \| g } | 把表读出来 |

这套核心里只有等式、或者、并且、存在这几样，没有「不」，也没有「所有」。这样的句子成立，就有让它成立的那组值；`run*` 交回来的每一组答案，就是这样一组值。至于找不找得到，是另一回事：搜索可能停不下来。

回到开头。`appendo` 的定义里没有人写过「拆」，是因为它根本没有写「接」。它写的是三个列表之间的一张表，哪三个摆在一起算数。正着问，是定住前两列，读第三列；倒着问，是定住第三列，读前两列。表还是那一张。

---

**代码。** 文中的四段程序与各自的运行输出在 [这里]（发布时换成仓库链接）：`1-lists.rkt`（列表），`2-streams.rkt`（流），`3-amb.rkt`（`amb`），`4-libraries.rkt`（两个库）。前两个只要 Racket；后两个要 amb 3.0、ambKanren 3.0 与 miniKanren-typed 1.1，可以用 `raco pkg install --auto amb ambKanren miniKanren-typed` 从包目录装上；文中的输出是在 Racket 9.3 上跑出来的。ambKanren 配上 `amb-interleave`，测试覆盖的书中例子（第一版 228 个，第二版 285 个）答案与先后都和书上相同。

**出处与许可。** `walk`、`unify`、`reify` 与流的 `mplus`、`bind`、`take` 改写自 Jason Hemann 与 Daniel P. Friedman 的 [microKanren](https://github.com/jasonhemann/microKanren)，Copyright (C) 2013 Jason Hemann and Daniel P. Friedman，MIT License；代码文件的注释与同目录的 NOTICE 里保留了原声明。改动是：未知项按身份区分，不用计数器；`unify` 不变，失败怎样交出去、流怎样写，三个版本各不相同。

**延伸。**

- Daniel P. Friedman、William E. Byrd、Oleg Kiselyov，*The Reasoned Schemer*，MIT Press，2005；第二版加上 Jason Hemann，2018。
- Jason Hemann、Daniel P. Friedman，*μKanren: A Minimal Functional Core for Relational Programming*，Scheme Workshop 2013。
- [amb](https://github.com/NoahStoryM/amb) 的手册里，*Fairness Needs Pauses* 一节讲轮流走需要什么条件；[ambKanren](https://github.com/NoahStoryM/ambKanren) 的手册里，*From Streams to amb* 一节有流与 `amb` 的逐项对照。
