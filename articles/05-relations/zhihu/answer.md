`append` 把两个列表接成一个。把它改写成 **关系**（*relation*）`appendo`，就可以倒过来问：哪两个列表接起来是 `(1 2 3)`？

```racket
> (run* (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
```

四种拆法，一种不少。定义 `appendo` 的时候，没有人写过「拆」这件事。

问 miniKanren 是怎样实现的，问的就是这四组答案从哪里来。读《The Reasoned Schemer》的时候，很容易在 term、substitution、goal 这几个术语之间迷失：书里天天用它们，却要翻到最后的实现才看得见它们是什么。它们是三个类型。

```racket
(define-type Term (∪ Literal Var (Pair Term Term)))
(define-type Substitution (Listof (Pair Var Term)))
(define-type Goal (→ Substitution (Listof Substitution)))
```

**项**（*term*）是程序里谈论的东西，里面可以有还不知道的部分。**代换**（*substitution*）是一张表，记着眼下对这些不知道的部分知道了什么。**目标**（*goal*）是一个函数，收一张代换，交出一列代换。代码用 Typed Racket 写，名字照这本书的第二版。

## 项：还不知道的东西

倒着问的时候，`x` 和 `y` 都还没有值。它们不是哪个数的名字，只是两个记号；可同一个记号出现在几处，指的必须是同一个东西。没有值可比，就按身份来认：

```racket
(define-type Literal (∪ Boolean Number Char String Null Symbol))

(struct var ([name : Symbol])
  #:type-name Var
  #:property prop:custom-write                    ; 只为打印：显示成它的名字
  (λ ([v : Var] [port : Output-Port] [mode : (∪ Boolean 0 1)])
    (write (var-name v) port)))
```

每调用一次 `(var 'x)`，得到一个新的东西；名字不参与计算，只在打印时露面。这样的东西叫 **未知项**（*logic variable*），也就是常说的逻辑变量。数、符号、空列表这些字面量，未知项，以及它们组成的 **序对**（*pair*），合起来就是 `Term`。下面的例子里，`x`、`y` 都是这样造出来的未知项。

## 代换：一张记着等式的表

搜索往前走，我们对未知项知道得越来越多。知道的事记在一张表里，每行是一条等式：

```racket
(list (cons y 5) (cons x y))    ; y = 5，x = y
```

想知道 `x` 现在是什么，就顺着等式查下去，查到表里没有的东西为止：

```racket
(: walk (→ Term Substitution Term))
(define (walk v s)
  (let ([a (and (var? v) (assq v s))])
    (if a (walk (cdr a) s) v)))
```

```racket
> (walk x (list (cons y 5) (cons x y)))
5
```

代换记的是等式，不是赋值：`x = y` 这一行只说两者相等，谁也没说它们是几。它也不是变量环境：环境里每个名字都有值，这张表的右边可以是另一个还不知道的东西。

## 合一：往表里添等式

往表里添等式的只有一个函数。它收两个项和一张表，想办法让两个项相等：

```racket
(: unify (→ Term Term Substitution (Option Substitution)))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (ext-s u v s)]
          [(var? v) (ext-s v u s)]
          [(and (pair? u) (pair? v))
           (let ([s (unify (car u) (car v) s)])
             (and s (unify (cdr u) (cdr v) s)))]
          [(equal? u v) s]
          [else #f])))
```

先把两边都查到底。已经是同一个东西，表不用动；有一边是未知项，添一行；两边都是序对，头对头、尾对尾地做下去；都是字面量，相等就过，不等就交出 `#f`。

```racket
> (unify (list x 2) (list 1 y) empty-s)
((y . 2) (x . 1))
> (unify (list x 2) (list 1 x) empty-s)
#f
```

第一次，两边各有一个洞，各从对面得到了填法。第二次，`x` 先等于 `1`，又被要求等于 `2`，做不到。这件事叫 **合一**（*unification*）。它像模式匹配，只是两边都可以有洞。

添一行的 `ext-s` 先做一个检查：

```racket
(: ext-s (→ Var Term Substitution (Option Substitution)))
(define (ext-s x v s)
  (if (occurs? x v s)
      #f
      (cons (cons x v) s)))

(: occurs? (→ Var Term Substitution Boolean))
(define (occurs? x v s)
  (let ([v (walk v s)])
    (cond [(var? v) (eq? v x)]
          [(pair? v) (or (occurs? x (car v) s)
                         (occurs? x (cdr v) s))]
          [else #f])))
```

```racket
> (unify x (list x) empty-s)
#f
```

`x` 不能等于一个里面装着 `x` 自己的列表。没有这个检查，表里会多出一行绕回自己的等式，顺着它查就查不到头。

## 目标：代换之间的关系

`(== x 1)` 写在程序里的时候，表还不在场；它得等一张表来了，才知道该往哪里添等式。所以它是一个函数，收一张表。交出什么呢？合一可能成功，也可能失败，交出一张表或者 `#f` 似乎就行。可是马上会遇到「x 是 1 或者 2」这样的条件：两种可能都对，各自要添的等式不同，一张表装不下。

那就交出一列代换。成功是一张，失败是零张，两种可能是两张。这就是开头的第三个类型：

```racket
(define-type Goal (→ Substitution (Listof Substitution)))

(: == (→ Term Term Goal))
(define ((== u v) s)
  (let ([s (unify u v s)])
    (if s (list s) '())))

(: succeed Goal)
(define (succeed s) (list s))

(: fail Goal)
(define (fail s) '())

(: disj2 (→ Goal Goal Goal))
(define ((disj2 g1 g2) s)
  (append (g1 s) (g2 s)))

(: conj2 (→ Goal Goal Goal))
(define ((conj2 g1 g2) s)
  (append-map g2 (g1 s)))
```

`disj2` 是「或者」：把同一张表交给两个目标，交回来的接在一起。`conj2` 是「并且」：第一个目标交出的每一张表，都交给第二个目标再添一遍。`succeed` 原样交回那张表，`fail` 一张也不交；书里把它们写成 `#s` 和 `#u`。

```racket
> ((disj2 (== x 1) (== x 2)) empty-s)
(((x . 1)) ((x . 2)))
> ((conj2 (disj2 (== x 1) (== x 2)) (== y x)) empty-s)
(((y . 1) (x . 1)) ((y . 2) (x . 2)))
> ((conj2 (== x 1) (== x 2)) empty-s)
()
```

一个目标说的是：哪张代换能变成哪张代换。一张可以变成好几张，也可以一张都变不成，所以它不是代换到代换的函数，是代换与代换之间的一个 **二元关系**（*binary relation*）。交出列表的函数只是这个关系的一种写法。照这个读法，「并且」把两个关系首尾相接，是关系的复合；「或者」把两个关系并在一起；`succeed` 是恒等关系，接在谁前后都不改变谁；`fail` 是空关系，跟谁并都不改变谁。miniKanren 的核心就是这一样东西：用合一造出来、用这两种接法拼起来的，代换之间的二元关系。

逻辑式语言常被说成会 **回溯**（*backtracking*）：一条路走不通，就退回上一个岔口换一条。这里找不到哪一行在退。岔口是 `disj2`，它把两条路都走了；走不通的那条交回一个空列表，`append-map` 接它的时候什么也没接上，它就这样不见了。回溯没有写成一个动作，它是「空列表接上去等于没接」这件事。

两个以上的条件，用几个宏接成两个两个的：`(disj g1 g2 g3)` 是 `(disj2 g1 (disj2 g2 g3))`，`conj` 同理。书里最常写的 `conde` 是这两样合起来，每个子句是一组「并且」，子句之间是「或者」：

```racket
(define-syntax-rule (conde [g ...] ...)
  (disj (conj g ...) ...))
```

## 关系，与每次都是新的未知项

关系的定义里常要用到只在内部出现的未知项，比如拆开一个列表时的头一项和剩下那一截。`fresh` 造出它们，再把名字交给里面的条件：

```racket
(: call/fresh (∀ (g) (→ Symbol (→ Var g) g)))
(define (call/fresh name f)
  (f (var name)))

(define-syntax fresh
  (syntax-rules ()
    [(_ () g ...) (conj g ...)]
    [(_ (x0 x ...) g ...)
     (call/fresh 'x0 (λ ([x0 : Var]) (fresh (x ...) g ...)))]))
```

用户写的关系，是一个收几个项、交出目标的函数。`defrel` 定义它，并让它的主体等代换来了才展开：

```racket
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) ((conj g ...) s))))
```

现在可以写 `appendo` 了。`l` 是空的，`out` 就是 `t`；或者 `l` 有头 `a` 和尾 `d`，`out` 的头也是 `a`，尾 `res` 是 `d` 接上 `t`：

```racket
(defrel (appendo l t out)
  (conde
    [(== l '()) (== t out)]
    [(fresh (a d res)
       (== l (cons a d))
       (== out (cons a res))
       (appendo d t res))]))
```

第二个子句里 `appendo` 调用了自己。它没有一头扎下去，靠两件事。`defrel` 的那层 `(λ (s) …)` 让主体等代换来了才展开，所以调用 `(appendo d t res)` 只是造出一个目标，不会接着往下调用。真跑起来，在开头那两个问法里，已知的列表每深一层就短一截，短到空，第二个子句的等式就再也成立不了。

## run：从代换读回项

一张代换是给程序看的。给人看，要把问的那个项沿着表换到底；换不动的未知项，按出现的先后起名 `_0`、`_1`：

```racket
(: walk* (→ Term Substitution Term))
(define (walk* v s)
  (let ([v (walk v s)])
    (if (pair? v)
        (cons (walk* (car v) s) (walk* (cdr v) s))
        v)))

(: reify-s (→ Term Substitution Substitution))
(define (reify-s v r)
  (let ([v (walk v r)])
    (cond [(var? v) (cons (cons v (reify-name (length r))) r)]
          [(pair? v) (reify-s (cdr v) (reify-s (car v) r))]
          [else r])))

(: reify (→ Term (→ Substitution Term)))
(define ((reify v) s)
  (let* ([v (walk* v s)]
         [r (reify-s v empty-s)])
    (walk* v r)))
```

`reify-s` 一边往下走，一边把遇到的、还没起名的未知项记进 `r`；`r` 里已经有几个，下一个就叫几号（`reify-name` 把号码写成 `_0` 这样的符号）。这一步在书里叫 **reify**。

`run` 把两头接起来：

```racket
(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (let ([s* (g empty-s)])
    (if (and n (< n (length s*))) (take s* n) s*)))

(define-syntax run
  (syntax-rules ()
    [(_ n (x0 x ...) g ...)
     (run n q (fresh (x0 x ...) (== (list x0 x ...) q) g ...))]
    [(_ n q g ...)
     (let ([q (var 'q)])
       (map (reify q) (run-goal n (conj g ...))))]))

(define-syntax-rule (run* q g ...) (run #f q g ...))
```

它造出要问的未知项 `q`，把所有条件接成一个目标，从空代换出发交给它；目标交回一列代换，再拿 `q` 到每一张里去查，读成一个项。`n` 是要几组，`run*` 是全要。开头那个程序，到这里原样能跑：

```racket
> (run* z (appendo '(1 2) '(3) z))
((1 2 3))
> (run* (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
```

答案里也可以留着不知道的东西：

```racket
> (run* (x y) (== x y))
((_0 _0))
> (run* (x y) (== x x))
((_0 _1))
```

第一组说 `x` 与 `y` 是同一个东西，是什么都行；第二组什么也没说，条件里根本没提到 `y`，两者各自是什么都行，相同也行。一组这样的答案顶得上无穷多组具体的答案。

这里有两层关系。里面一层是 `Goal`，代换与代换之间的，实现靠它。外面一层是用户写的 `appendo`，类型是 `(→ Term Term Term Goal)`，它是三个项之间的一张三列的表。一次查询定住其中几列，读出另外几列：

```racket
(: split (→ Term (Listof Term)))
(define (split out) (run* (x y) (appendo x y out)))

(: join (→ Term Term (Listof Term)))
(define (join l t) (run* z (appendo l t z)))
```

```racket
> (split '(1 2 3))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
> (join '(1 2) '(3))
((1 2 3))
```

`split` 和 `join` 是同一张表的两个方向，各是一个交出列表的普通函数，也就是项与项之间的二元关系。传进去的 `out`、`l`、`t` 是定住的项。`run*` 后面的 `(x y)` 不是参数，是名字：它给要读出的列起名，作用如同集合写法 { (x, y) | … } 竖线左边的那一对，也如同 `λ` 的参数表。函数收不了一个名字当参数，所以 `run` 只能是宏，由它自己造出这几个未知项。两层就这样接上：`run` 从空代换出发，里面一层把它送到所有走得通的代换，再拿查询的未知项去查表；连起来，代换之间的关系就成了项之间的关系。

提问的答案到这里就齐了。项里可以有未知项；代换是一张记着等式的表；合一往表里添等式；目标是代换之间的关系，「或者」把它们并起来，「并且」把它们接起来；`run` 从空代换出发，最后把代换读回项。整个语言就是这几个普通的函数，加上几个只管起名字和接线的宏，所以它能嵌在 Racket 里。没有一行是专门为「倒着算」写的：`appendo` 的每一行都是等式，等式不分哪边是输入。

## 写不完的答案

列表有一个地方不够用。

```racket
(defrel (alwayso)
  (conde [succeed] [(alwayso)]))
```

`alwayso` 成功一次，或者再来一遍，所以它有无穷多个答案。`(run* q (alwayso))` 不会回来，这不奇怪；麻烦在于，`(run 3 q (alwayso))` 也不回来，因为列表要整个造好才交得出来。其实不用这么极端：开头的 `appendo` 三个位置都不给，`(run 4 (x y z) (appendo x y z))` 同样回不来。

书上的办法，是让列表可以只造一半。除了「空」和「一个答案，后面还有」，再添第三种样子：一个不带参数的函数，表示这里往后的还没算，要的时候再调用。这就是 **流**（*stream*）：

```racket
(define-type (Streamof a) (∪ Null (Pair a (Streamof a)) (→ (Streamof a))))

(define-type Goal (→ Substitution (Streamof Substitution)))
```

三个类型里只有 `Goal` 变了，`Term`、`Substitution` 和 `walk`、`unify`、`reify` 一个字不动。

第三种样子接在一个答案后面，流就是「一个答案，和接着取的函数」。Racket 里有一样现成的东西是这个形状：

```racket
> (list v1 v2 v3)     ; (sequence-generate* (in-naturals)) 交出 v1 与 next1，(next1) 交出 v2 与 next2，依此类推
((0) (1) (2))
> (list w1 w2)        ; 对只有一个元素的 '(a) 做同样的事
((a) #f)
```

`sequence-generate*` 每次交出两样：一个值（放在列表里），和接着取的函数；取完了交出 `#f`。把这两个返回值用 `cons` 装成一个序对，就是流。只有一处要留意：那个函数每调用一次就重算一次，不记结果。

从流里取答案，要几个就往下取几个，遇到还没算的就调用它：

```racket
(: take-inf (→ (Option Natural) (Streamof Substitution) (Listof Substitution)))
(define (take-inf n s-inf)
  (cond [(and n (zero? n)) '()]
        [(null? s-inf) '()]
        [(pair? s-inf) (cons (car s-inf) (take-inf (and n (sub1 n)) (cdr s-inf)))]
        [else (take-inf n (s-inf))]))

(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (take-inf n (g empty-s)))
```

## 暂停

第三种样子还可以出现在一个答案也没有的地方。第二版让每个关系在入口处不往下算，只交出这样一个函数：

```racket
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) (λ () ((conj g ...) s)))))
```

和列表的版本比，只多了中间那个 `(λ () …)`。`alwayso` 的定义不用改。它交出的流 `s0`，先是一个还没算的函数；调用它得到 `s1`，是一个答案（那张空代换）和又一个还没算的函数：

```racket
> (procedure? s0)
#t
> (and (pair? s1) (list (car s1) (procedure? (cdr s1))))
(() #t)
```

`append` 与 `append-map` 相应地各多一个分支：

```racket
(: append-inf (→ (Streamof Substitution) (Streamof Substitution) (Streamof Substitution)))
(define (append-inf s-inf t-inf)
  (cond [(null? s-inf) t-inf]
        [(pair? s-inf) (cons (car s-inf) (append-inf (cdr s-inf) t-inf))]
        [else (λ () (append-inf t-inf (s-inf)))]))

(: append-map-inf (→ Goal (Streamof Substitution) (Streamof Substitution)))
(define (append-map-inf g s-inf)
  (cond [(null? s-inf) '()]
        [(pair? s-inf) (append-inf (g (car s-inf)) (append-map-inf g (cdr s-inf)))]
        [else (λ () (append-map-inf g (s-inf)))]))
```

`disj2` 用 `append-inf` 接，`conj2` 用 `append-map-inf` 传；`==`、`succeed`、`fail` 的写法没有变，一个列表本来就是一条流。

```racket
> (run 3 q (alwayso))
(_0 _0 _0)
> (run 4 (x y z) (appendo x y z))
((() _0 _0) ((_0) _1 (_0 . _1)) ((_0 _1) _2 (_0 _1 . _2)) ((_0 _1 _2) _3 (_0 _1 _2 . _3)))
```

`append-inf` 的最后一个分支里藏着一个小动作：左边还没算出来的时候，它交回的是 `(append-inf t-inf (s-inf))`，两个参数换了位置。左边每停一次，就轮到右边走一步。于是下面这个程序也有答案，尽管左边那一支永远在原地打转：

```racket
(defrel (nevero) (nevero))
```

```racket
> (run 1 q (conde [(nevero)] [(== q 'here)]))
(here)
```

这叫 **交错**（*interleaving*）。这个岔口上的两条路轮流走：左边每停一次，右边就走一步，左边没有尽头也拖不住右边。入口处交出的那个函数因此有两个用处：它让流可以只造一半，它也是这条路把轮次让出去的地方。后一个用处叫 **暂停**（*suspension*）。

## 另一种写法：amb

到上一节为止，是《The Reasoned Schemer》第二版的 miniKanren，提问问的就是它。这一节是同一样东西的另一种写法，不是 miniKanren 必须的部分。

回头看 `Goal` 的两个版本，有一样东西到处都是：`==` 要把结果包进列表，`disj2` 要 `append`，`conj2` 要 `append-map`，换成流以后是 `append-inf` 与 `append-map-inf`。每个目标都在亲手搬运「好几种可能」。可我们心里想的要简单得多：一个目标交出一张代换，只是有时候它会交出好几次，有时候一次也不交。

有一个运算符，做的正是「交出好几次」。它叫 `amb`；这里用我写的 [amb](https://github.com/NoahStoryM/amb) 库：

```racket
> (for/list : (Listof (Listof Integer))
      ([p (in-amb (let ([a (amb 1 2 3)] [b (amb 1 2 3)])
                    (unless (= (+ a b) 4) (amb-fail))
                    (list a b)))])
    p)
((1 3) (2 2) (3 1))
```

`(amb 1 2 3)` 返回了三次，它后面的程序为每个值各运行一遍。它做得到，是因为它能把「自己后面的程序」当成一个函数拿到手，每个备选各调用一次；这样的函数叫 **延续**（*continuation*）。`(amb-fail)` 让眼下这一遍到此为止，退回最近的岔口换下一个值；`in-amb` 在外面把走通的结果收起来。回溯在这里成了一个动作，只是它住在 `amb` 里，目标里仍然看不见。

把搬运交给它，`Goal` 再换一次：

```racket
(define-type Goal (→ Substitution Substitution))

(: == (→ Term Term Goal))
(define ((== u v) s)
  (or (unify u v s) (amb-fail)))

(: succeed Goal)
(define (succeed s) s)

(: fail Goal)
(define (fail s) (amb-fail))

(: disj2 (→ Goal Goal Goal))
(define ((disj2 g1 g2) s)
  ((amb g1 g2) s))

(: conj2 (→ Goal Goal Goal))
(define ((conj2 g1 g2) s)
  (g2 (g1 s)))
```

目标成了收一张代换、交出一张代换的普通函数。「或者」是从两个目标里选一个，选哪个都算数。「并且」最干脆：前一个目标交出的代换交给后一个，这就是函数的复合。`succeed` 是恒等函数。前面说目标是代换之间的二元关系，「并且」是复合，「或者」是并；在这个版本里，这几句话就是代码本身。

三个版本只差 `Goal` 这一个类型。换一次类型，下面这几个函数跟着改写，别的一个字不动：

| | 列表 | 流（第二版） | `amb` |
| --- | --- | --- | --- |
| `Goal` 交出 | `(Listof Substitution)` | `(Streamof Substitution)` | `Substitution` |
| `succeed` | `(list s)` | `(list s)` | `s` |
| `fail` | `'()` | `'()` | `(amb-fail)` |
| `disj2` | `append` | `append-inf` | `amb` |
| `conj2` | `append-map` | `append-map-inf` | 函数复合 |
| `defrel` 的入口 | 不停 | 交出一个 `(λ () …)` | `(amb-pause)` |
| `run-goal` | 取列表的前 n 个 | `take-inf` | `take-amb` |

倒数第二行是关系入口处的暂停。在这里它是一次调用：

```racket
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) (amb-pause) ((conj g ...) s))))
```

`appendo`、`alwayso`、`nevero` 的定义与前面一字不差。同样的程序：

```racket
> (run* (x y) (appendo x y '(1 2 3)))
((() (1 2 3)) ((1) (2 3)) ((1 2) (3)) ((1 2 3) ()))
> (run 3 q (alwayso))
(_0 _0 _0)
> (run 1 q (conde [(nevero)] [(== q 'here)]))
;; 不回来
```

前两个照旧。第三个卡住了：`amb` 默认先把左边走完，而 `nevero` 永远走不完。流的版本里，轮流走是 `append-inf` 交换参数做到的；这里，两个备选的结果怎样合成一条，是一个可以换的参数：

```racket
> (parameterize ([current-amb-merger amb-interleave])
    (run 1 q (conde [(nevero)] [(== q 'here)])))
(here)
```

`amb-interleave` 在一条路暂停的时候换另一条走。它只能在暂停处换：一条路要是从不暂停，换了合并的办法也还是等不到。流的版本其实一样，没有入口处交出的那个函数，`append-inf` 也无从交换。**公平**（*fairness*）不是白来的，要每条没有尽头的路自己肯停下来让一让。

流真的不见了吗？看 `run-goal` 在这个版本里怎样取答案：

```racket
(: take-amb (→ (Option Natural) (Generatorof (List Substitution)) (Listof Substitution)))
(define (take-amb n gen)
  (if (and n (zero? n))
      '()
      (let-values ([(v next) (gen)])
        (cond [(not v) '()]                                            ; 没有了
              [(pair? v) (cons (car v) (take-amb (and n (sub1 n)) next))]  ; 一个答案，后面还有
              [else (take-amb n next)]))))                             ; 暂停了 v 次

(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (take-amb n (λ () (amb-generate* (λ () (g empty-s))))))
```

`amb-generate*` 把一次搜索交到外面，让人一步一步地问。每问一次，得到两样东西：这一步的结果，和接着问的函数。拿一个小例子看结果的样子：

```racket
(: count-from (→ Integer Integer))
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

结果有三种：一个列表是一个答案，值放在列表里；一个正整数 n 是连着 n 次暂停；`#f` 是没有了。所以 `((0) 1 (1))` 读作：答案 `0`，暂停一次，答案 `1`。这和 `sequence-generate*` 是同一个形状，多出来的正整数就是暂停。`take-amb` 的三个分支，对着 `take-inf` 的三个分支：没有了，一个答案后面还有，还没算出来。

所以这就是第二版的流，`cons` 换成了两个返回值，「还没算出来」的那种样子换成了一个记着暂停次数的数。流没有消失。它不再是每个目标都要经手的数据，而是搜索本身被人从外面一步一步问出来时的样子。（它比流多一处限制：一次搜索只能这样问一遍。）

## 顺序与两个库

「并且」写成函数复合，还有一处要交代。它和 `append-map-inf` 找到的答案相同，可是在轮流走的时候，先后可能不同。`append-map-inf` 先把前一个目标的几种可能合成一条，再按答案的先后交给后一个；amb 库里做这件事的是 `amb-local`，「并且」就写成 `(g2 (amb-local (g1 s)))`。函数复合则让后一个目标在前一个的每条岔路里面各自运行，轮次跟着岔路的形状走。前一个目标取嵌成 ((x = 1 或 x = 2) 或 x = 3) 的三个备选，后一个目标进门先暂停一次，用 `amb-interleave` 跑，读出的 `x` 依次是：函数复合 `(3 1 2)`，`amb-local` `(1 2 3)`（代码在 `3-amb.rkt`）。复合有个省心的地方：(A 或 B) 并且 C 与 (A 并且 C) 或 (B 并且 C) 连先后都一样。`amb-local` 换来的是与书上逐项相同的顺序。

照这两条路，我各写了一个库。[miniKanren-typed](https://github.com/NoahStoryM/miniKanren-typed) 照两版书的代码逐个定义，用流，写成 Typed Racket。当初写它，是因为读那两本书的时候，我手边的几个 miniKanren 包，有的缺运算符，有的跑出来的例子和书上对不上；照着书抄一遍，再配上类型，才算把上面这些弄明白。[ambKanren](https://github.com/NoahStoryM/ambKanren) 是 `amb` 的那一条：microKanren 与两版书的语言各占一个模块，目标都是直接写成的普通函数，收一张代换，交出一张代换，只有 microKanren 那个模块多带一个给未知项编号的计数器。为了能拿书上的输出当标准答案核对，它的「并且」用的是 `amb-local` 那一种。同一段 `appendo`，三个位置都不给，交给两个库的第二版模块各取前四组：

```racket
> (run 4 (x y z) (appendo x y z))
流   ((() _0 _0) ((_0) _1 (_0 . _1)) ((_0 _1) _2 (_0 _1 . _2)) ((_0 _1 _2) _3 (_0 _1 _2 . _3)))
amb  ((() _0 _0) ((_0) _1 (_0 . _1)) ((_0 _1) _2 (_0 _1 . _2)) ((_0 _1 _2) _3 (_0 _1 _2 . _3)))
```

## 两个常量，三个运算

《The Reasoned Schemer》第一版的序言里说，做关系式编程只需要两个常量 `#s`、`#u`，和三个运算 `==`、`fresh`、`conde`。手里的东西对得上吗？

`#s` 和 `#u` 是 `succeed` 和 `fail`，`==` 与 `conde` 都在。它们各是什么，前面已经说过：恒等关系与空关系，添一条等式，并与复合。剩下 `fresh`。它造出的未知项不在 `run*` 要读的名字里，答案里也就没有它：

```racket
(defrel (P x y)
  (conde [(== y 5)] [(== y 6)])
  (== y x))
```

```racket
> (run* x (fresh (y) (P x y)))
(5 6)
```

`P` 说的是 (y = 5 ∨ y = 6) ∧ y = x，这段程序算的是 { x | ∃y. P(x, y) }。把满足 `P` 的 `x`、`y` 列成一张两列的表，`fresh` 做的，就是把 `y` 那一列遮住。这样的表只管有没有这一行，不管先后，也不留重复；搜索两样都管，前面几节说的就是它们。

| miniKanren | 逻辑 | 在表上 |
| --- | --- | --- |
| `#s` | ⊤ | 只有一行、没有列的表 |
| `#u` | ⊥ | 一行也没有的表 |
| `(== t1 t2)` | t1 = t2 | 两项相等的那些行 |
| `(conde [g1] [g2])` | g1 ∨ g2 | 两张表并起来 |
| `(fresh () g1 g2)` | g1 ∧ g2 | 两张表按共有的列拼起来 |
| `(fresh (x) g)` | ∃x. g | 遮住一列 |
| `(run* x g)` | { x \| g } | 把表读出来 |

零个未知项的 `fresh` 就是 `conj`。这套核心里只有等式、或者、并且、存在这几样，没有「不」，也没有「所有」。这样的句子成立，就有让它成立的那组值；`run*` 交回来的每一组答案，就是这样一组值。至于找不找得到，是另一回事：搜索可能停不下来。

回到开头。`appendo` 的定义里没有人写过「拆」，是因为它根本没有写「接」。它写的是三个列表之间的一张表，哪三个摆在一起算数。`join` 定住前两列，读第三列；`split` 定住第三列，读前两列。两个函数，两个方向，表还是那一张。

---

**代码。** 文中的程序与各自的运行输出在 [这里]（发布时换成仓库链接）：`0-terms.rkt`（项、代换、合一、读出答案，三个版本共用），`wires.rkt`（接线的宏，三个版本共用），`1-lists.rkt`（列表），`2-streams.rkt`（流），`3-amb.rkt`（`amb`），`4-libraries.rkt`（两个库）；另有两个小文件，`2a-sequence-generate.rkt` 是 `sequence-generate*` 的那个例子，`timeout.rkt` 只用来演示「不回来」。前四个只要 Racket；后两个要 amb 3.0、ambKanren 3.0 与 miniKanren-typed 1.1，可以用 `raco pkg install --auto amb typed-amb ambKanren miniKanren-typed` 从包目录装上；文中的输出是在 Racket 9.3 上跑出来的。ambKanren 配上 `amb-interleave`，测试覆盖的书中例子（第一版 228 个，第二版 285 个）答案与先后都和书上相同。

**出处与许可。** `walk`、`ext-s`、`occurs?`、`unify`、`walk*`、`reify-s`、`reify`、`call/fresh`，流的 `append-inf`、`append-map-inf`、`take-inf`，以及 `disj`、`conj`、`conde`、`fresh`、`defrel`、`run`、`run*` 这几个宏，改写自《The Reasoned Schemer》第二版的[代码](https://github.com/TheReasonedSchemer2ndEd/CodeFromTheReasonedSchemer2ndEd)，Copyright (c) 2018 Daniel P. Friedman, William E. Byrd, Oleg Kiselyov, and Jason Hemann，MIT License；代码文件的注释与同目录的 NOTICE 里保留了原声明。改动是：加了类型；未知项是结构体，按身份区分；列表与 `amb` 两个版本的 `==`、`succeed`、`fail`、`disj2`、`conj2`、`run-goal` 是照正文的说法另写的。

**延伸。**

- Daniel P. Friedman、William E. Byrd、Oleg Kiselyov，*The Reasoned Schemer*，MIT Press，2005；第二版加上 Jason Hemann，2018。
- Jason Hemann、Daniel P. Friedman，*μKanren: A Minimal Functional Core for Relational Programming*，Scheme Workshop 2013。
- [amb](https://github.com/NoahStoryM/amb) 的手册里，*Fairness Needs Pauses* 一节讲轮流走需要什么条件；[ambKanren](https://github.com/NoahStoryM/ambKanren) 的手册里，*From Streams to amb* 一节有流与 `amb` 的逐项对照。
