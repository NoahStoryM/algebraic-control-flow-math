#lang typed/racket/no-check
;;; 第五篇正文代码（按正文出现顺序；全篇七节，v4.9）
;;; 依据：art5-plan.md v4.9（2026-10-01）、定稿中文第一至四篇
;;; 运行：raco test art5-code.rkt
;;; 第六篇（单子）的代码已拆到 art6-code.rkt。
;;;
;;; 约定
;;; ・每段代码前的标题行写作「§节-编号〔用途〕 标题」：
;;;     〔正文〕       读者会看到的代码
;;;     〔正文·等式〕 正文里的代码等式，本身不运行；紧跟其后的检查验证它
;;;     〔正文·伪代码〕 §2 假想语言的代码；以注释写出，§6 用同样的文本真的运行
;;;                   （test 子模块逐个比对两处读成的 S 表达式；不是逐字比对，也不检查 Markdown 正文）
;;;     〔验证〕       只用于验证，不进正文
;;;     〔前文〕       前四篇的原样定义，正文不重复展示
;;;   「步骤」标出它在「问题 → 代码 → 现象 → 概念」中的位置；
;;;   「回指」标出前文对应处（只列正文可能用到的，最终取舍写散文时定）。
;;; ・〔正文〕块写成 (check-equal? 表达式 结果) 时，正文取第一个参数，
;;;   第二个参数就是正文里 ;; => 注释给出的结果。
;;; ・类型标注只作设计说明，不经类型检查（与前四篇一致）。
;;; ・本篇只讨论纯的、有限的搜索（整个搜索过程能够完成）。
;;; ・同名函数在正文里出现多次（如 right-triangles）时，本文件加下标区分，正文仍用原名。

(require rackunit
         (except-in racket/control abort))   ; abort 用第三篇自己的定义


;;; ═══════════════════════════════════════════════════════════════════
;;; §0〔前文〕 前四篇的原样定义（第五篇只用到这两个）
;;; ═══════════════════════════════════════════════════════════════════
;;; 第二篇「完整代码参考」与第三篇「定界延续」，逐字。其余前文定义随第六篇移到 art6-code.rkt。

(define ∘ compose)

(define (abort . v*) (shift _ (apply values v*)))


;;; ═══════════════════════════════════════════════════════════════════
;;; §1 遍历搜索树
;;; ═══════════════════════════════════════════════════════════════════


;;; ─── §1-0〔验证〕 期望结果 ───
(define triples '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; ─── §1-a〔正文〕 嵌套循环枚举勾股数：给定边长范围，交出所有直角三角形 ───
;;; 步骤：问题 → 代码（一棵搜索树：每层对每个备选都走下去）
;;; 回指：第四篇「未解的线索」的「搜索树」；第二篇 fact / fib 的类型写法
;;; 9/30 改：写成函数 (right-triangles l h)，边界 l、h 作参数；范围用 inclusive-range（列表，含两端），
;;;        与 §2 的 betweeno 对齐。§5 的程序已统一成同一个函数形式（10/1）。
(: pyth? (→ Natural Natural Natural Boolean))
(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))

;; 边长的上下界取正整数（9/30：下界为 0 会收进 (0 1 1) 这类退化三角形）
(: right-triangles (→ Positive-Integer Positive-Integer (Listof (List Positive-Integer Positive-Integer Positive-Integer))))
(define (right-triangles l h)
  (for*/list ([a (inclusive-range l h)]
              [b (inclusive-range a h)]
              [c (inclusive-range b h)]
              #:when (pyth? a b c))
    (list a b c)))

(check-equal? (right-triangles 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; ─── §1-b〔正文〕 把 for*/list 摊开：每层的剩余工作写成显式的 k ───
;;; 步骤：代码 → 现象（输出与 §1-a 逐字相同；k 对每个备选各跑一次）
;;; 回指：第四篇 if 分支「未来写了两次、运行了一次」（对照：这里每个备选都运行）；
;;;       第四篇 rand* 的兄弟各有各的延续（对照：这里的备选共享同一个 k）；
;;;       第三篇「局部延续」：k 的答案类型是列表，即 ¬ₐp 取 a = (Listof q)
(: choose/k (∀ (p q) (→ (Listof p) (→ (→ p (Listof q)) (Listof q)))))
(define ((choose/k p*) k) (append-map k p*))

;; 正文里仍叫 right-triangles（「摊开后的同一个函数」）；同一模块不能定义两次，这里叫 right-triangles₁。
(define (right-triangles₁ l h)
  ((choose/k (inclusive-range l h))
   (λ (a)
     ((choose/k (inclusive-range a h))
      (λ (b)
        ((choose/k (inclusive-range b h))
         (λ (c)
           (if (pyth? a b c) (list (list a b c)) '()))))))))

(check-equal? (right-triangles₁ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
;; 〔验证〕两种写法在多组边界上一致
(for* ([l (in-range 1 8)] [h (in-range 0 31)])
  (check-equal? (right-triangles₁ l h) (right-triangles l h)))

;;; ─── §1-c〔验证〕 过去只算一次，未来每个备选各跑一遍（显式 k 版） ───
;;; 正文 §1 只指着 (append-map k p*) 说这件事，不展示日志；日志放在 §5-g。
(let ([log '()])
  (define (note! x) (set! log (cons x log)))
  (note! 'before)
  ((choose/k '(1 2 3)) (λ (x) (note! (list 'after x)) (list x)))
  (check-equal? (reverse log) '(before (after 1) (after 2) (after 3))))

;;; ─── §1-d〔验证〕 过滤就是零个备选：#:when、返回 '() 的分支、零个备选是同一件事 ───
;;; fail 这个名字 §1 不出现，到 §5-d 与定义一起出现。
;;; 过滤条件改写成「从零个或一个备选里选」，结果不变；零个备选时 k 不被调用。
(check-equal?
 ((choose/k (inclusive-range 1 20))
  (λ (a)
    ((choose/k (inclusive-range a 20))
     (λ (b)
       ((choose/k (inclusive-range b 20))
        (λ (c)
          ((choose/k (if (pyth? a b c) '(ok) '()))
           (λ (_) (list (list a b c))))))))))
 (right-triangles 1 20))
(check-equal? ((choose/k '()) (λ (x) (error 'k "不应被调用"))) '())



;;; ═══════════════════════════════════════════════════════════════════
;;; §2 关系（v4.8，10/2，Noah 定：从显式的搜索树入手；两种表示都是函数的表）
;;; ═══════════════════════════════════════════════════════════════════
;;; 叙事（v4.7，10/2）：§1 的代码里没有树这份数据 → 把树造出来（嵌套的 for/list）→ 压平成表，行的先后就是
;;; 遍历的先后，一条时间线就是一行 → 这些行的共同点：都满足条件，满足条件的也都在；表是「所有可能的行」
;;; （笛卡尔积，大表）的子集（小表），这就是关系；n 列即 n 元 → pyth? 是检查一行在不在表里的谓词
;;; （§1 的三层循环加 #:when 就是在大表的一块上筛选；SQL 的 WHERE；范围剪枝）→ 函数是有唯一索引的表；关系的表索引不唯一，
;;; 拿哪几列当索引是挑的（二元关系）→ 把关系重新写成函数的两种办法：(1) 拿整行当索引、给大表添一列
;;; 布尔值，即谓词（标着 #t 的那张就是关系；大表列不完，所以谓词交不出答案）；(2) 拿一部分列当索引、
;;; 存容器，即 §1 的 right-triangles（摊开容器回到关系的表，与把树压平是同一件事）；集合记号
;;; → 同一张五列小表的谓词表示 right-triangle?；不对称 → 节尾：能不能只写条件，让语言去找出所有行？
;;; 全篇主线是「表」：把所有时间线并排摆出来的样子。本节没有伪代码；不出现「单子」，不提 miniKanren。

;;; ─── §2-0〔验证〕 参照实现与样例 ───
;;; 用集合写的关系，作独立的参照：关系 r 表示成「元素 → 它关联到的元素集合」。
(define ((rel∘ s r) x) (for*/set ([y (in-set (r x))] [z (in-set (s y))]) z))
(define (rel:id x) (list->set (list x)))
(define ((as-rel f) x) (list->set (f x)))       ; 列表世界的箭头读作关系
(define (forget p*) (list->set p*))             ; 忘掉顺序与重数
;; 验证用的样例箭头（divisors 只用于验证，不进正文）
(define (divisors n)
  (filter (λ (d) (zero? (remainder n d))) (range 1 (add1 n))))
(check-equal? (divisors 4) '(1 2 4))

;;; §2-0′〔验证〕 正文散文里用到的事实
;; §1 的三层循环加 #:when，就是在大表的一块上用 pyth? 筛选
(check-equal? (filter (λ (t) (apply pyth? t))
                      (for*/list ([a (inclusive-range 1 20)] [b (inclusive-range a 20)] [c (inclusive-range b 20)])
                        (list a b c)))
              (right-triangles 1 20))
;; 提前剪枝：b 从 a、c 从 b 开始取。1 到 20：大表的 8000 个组合 → 1540 个候选 → pyth? 留下六个答案
(check-equal? (length (for*/list ([a (inclusive-range 1 20)] [b (inclusive-range 1 20)] [c (inclusive-range 1 20)])
                        (list a b c)))
              8000)
(check-equal? (length (for*/list ([a (inclusive-range 1 20)] [b (inclusive-range a 20)] [c (inclusive-range b 20)])
                        (list a b c)))
              1540)
(check-equal? (length (right-triangles 1 20)) 6)
;; 读成 (a b) → c：有解时斜边唯一
(for* ([a (in-range 1 40)] [b (in-range a 40)])
  (check-true (<= (length (for/list ([c (in-range 1 60)] #:when (pyth? a b c)) c)) 1)))
;; 读成 c → (a b)：斜边 25 对应两组直角边，不是函数
(check-equal? (for*/list ([a (in-range 1 25)] [b (in-range a 25)] #:when (pyth? a b 25)) (list a b))
              '((7 24) (15 20)))
;; 一行也没有的输入，合并出空列表
(check-equal? (right-triangles 1 4) '())

;;; §2-0″〔正文·数学〕 按左边合并的数学写法（正文以公式块给出，不是代码）
;;;   right-triangles(l, h) = { (a, b, c) ∣ l ≤ a ≤ h ∧ a ≤ b ≤ h ∧ b ≤ c ≤ h ∧ a² + b² = c² }
;;; 散文：四个条件与 §1 for*/list 的三个子句加 #:when 一一对应。

;;; ─── §2-a〔正文〕 把搜索树造成数据：嵌套的 for/list ───
;;; 步骤：问题（§1 的代码里没有树这份数据，树只是 k 被调用的形状）→ 代码（§1 说过嵌套的 for/list
;;;       交出列表的列表：它保留了这棵树的分支层次）→ 现象（绝大多数分支是空的；压平即 §1 的结果）
;;;       → 概念（每条走通的路径是表里的一行；表是并排摆出的所有走通的时间线）
;;; 准确性（Astra 第三轮）：它已经执行了 #:when，是「保留了分支层次的结果树」，不是整个搜索过程的记录；
;;;       走不通的时间线同样运行过，却没有留下行。数字的说法：8000 个组合 → 1540 个候选 → 六个答案。
;;;       压平这棵树与「摊开存容器的表」都是展开嵌套容器，但这里每片叶子已记下路径上的三个值
;;;       （所以叶子写成 (list a b c) 而不只是 c），后者则要把索引 (l h) 配到每个答案上。
;;; 回指：§1「for*/list 不是嵌套的 for/list」（map 与 append-map 之别 = 树与表之别）；开篇「不止一条时间线」
(: right-triangles/tree
   (→ Positive-Integer Positive-Integer
      (Listof (Listof (Listof (List Positive-Integer Positive-Integer Positive-Integer))))))
(define (right-triangles/tree l h)
  (for/list ([a (inclusive-range l h)])
    (for/list ([b (inclusive-range a h)])
      (for/list ([c (inclusive-range b h)]
                 #:when (pyth? a b c))
        (list a b c)))))

(check-equal? (right-triangles/tree 1 5)
              '((() () () () ()) (() () () ()) (() ((3 4 5)) ()) (() ()) (())))

;;; §2-a′〔验证〕 压平这棵树就是 §1 的表；行的先后就是叶子被走到的先后
(check-equal? (right-triangles 1 5) '((3 4 5)))
(for* ([l (in-range 1 6)] [h (in-range 0 26)])
  (check-equal? (append* (append* (right-triangles/tree l h))) (right-triangles l h)))
;; 这棵树的叶子都在同一层，深度优先与逐层展开交出的顺序相同（§4-d″、§5-g‴）；
;; 叶子深度不齐时两种走法的顺序才不同
(let ([ragged '(1 (2 3) 4)])
  (check-equal? (flatten ragged) '(1 2 3 4))                       ; 深度优先
  (check-equal? (let loop ([level ragged])                          ; 逐层
                  (if (null? level)
                      '()
                      (append (filter (negate list?) level)
                              (loop (append* (filter list? level))))))
                '(1 4 2 3)))

;;; ─── §2-b〔正文〕 同一张小表的谓词表示 ───
;;; 步骤：概念（谓词：给齐一行 ((l h) (a b c))，回答在不在表里）→ 代码
;;; 散文：right-triangle? 与 right-triangles 说的是同一张小表；不对称：前者由后者只需一次 member，
;;;       后者由前者要替它列出大表的一块（§1 的三层循环）。
(define-type (→ℛ? x y) (→ x y Boolean))

(: right-triangle? (→ℛ? (List Positive-Integer Positive-Integer)
                        (List Positive-Integer Positive-Integer Positive-Integer)))
(define (right-triangle? l×h a×b×c)
  (match-define (list l h)   l×h)
  (match-define (list a b c) a×b×c)
  (and (<= l a b c h) (pyth? a b c)))

(check-equal? (right-triangle? '(1 20) '(3 4 5)) #t)
(check-equal? (right-triangle? '(1 20) '(4 3 5)) #f)   ; 不满足 a ≤ b
(check-equal? (right-triangle? '(1 4)  '(3 4 5)) #f)   ; 超出上界

;;; §2-b′〔验证〕 谓词与按左边合并的函数描述同一张小表（每组边界汇总成一次比较）
(for* ([l (in-range 1 4)] [h (in-range 1 21)])
  (check-equal? (for*/list ([a (in-inclusive-range 0 (add1 h))]
                            [b (in-inclusive-range 0 (add1 h))]
                            [c (in-inclusive-range 0 (add1 h))]
                            #:when (right-triangle? (list l h) (list a b c)))
                  (list a b c))
                (right-triangles l h)))
;; 由合并的版本得到谓词，只需一次 member
(for* ([t '((3 4 5) (4 3 5) (5 12 13) (6 8 10))])
  (check-equal? (right-triangle? '(1 12) t) (and (member t (right-triangles 1 12)) #t)))

;;; §2-0‴〔验证·v5.0 的 §2 素材〕 缓存与摊开（v5.0 重排时升为〔正文〕的数据展示）
;;; 同样的边界总得到同一张列表，所以可以按边界记下来；哈希表的键唯一。
(let ([cache (make-hash)])
  (define (right-triangles/cached l h)
    (hash-ref! cache (list l h) (λ () (right-triangles l h))))   ; 没查到才算，算完存进去
  (right-triangles/cached 1 20)
  (right-triangles/cached 1 5)
  (right-triangles/cached 1 4)
  ;; 缓存里的三项：一个边界对应零组、一组或多组答案
  (check-equal? (sort (hash->list cache) < #:key cadar)
                '(((1 4))
                  ((1 5) (3 4 5))
                  ((1 20) (3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))))
  ;; 摊开：每组答案配上它的边界，得到关系的表里的行；(1 4) 一行也没有，(1 20) 出现六次
  (define rows (for*/list ([k '((1 4) (1 5) (1 20))] [v (hash-ref cache k)]) (list k v)))
  (check-equal? rows
                '(((1 5) (3 4 5))
                  ((1 20) (3 4 5)) ((1 20) (5 12 13)) ((1 20) (6 8 10))
                  ((1 20) (8 15 17)) ((1 20) (9 12 15)) ((1 20) (12 16 20))))
  ;; 每一行都满足同一组条件（即 right-triangle?）
  (for ([r rows]) (check-true (right-triangle? (car r) (cadr r)))))


;;; ═══════════════════════════════════════════════════════════════════
;;; §3 描述关系的语言（v4.4）
;;; ═══════════════════════════════════════════════════════════════════
;;; 叙事：填列就是部分应用：填一部分剩一元关系，全填剩零元关系，零元谓词即 (→ Boolean)，纯的只有两种，
;;; 正是两个布尔值；谓词的 Boolean 是填满所有列后剩下的零列的表 → 想要只填一部分，让剩下的表成为答案
;;; → 假设有一门能直接写下条件的语言：关系作用在参数上得到目标（Goal 代替 Boolean）
;;; → 数学 ↔ 语言对照表（四行）→ 第一版 (a)，run* 用列表装答案（SQL：共享未知项 ~ JOIN，run* ~ SELECT）
;;; → 拆开再接：按挑边的顺序拆成四个二元关系；函数能复合，关系也应当能；复合的定义（∃）
;;; → 谓词写不出复合 → 这门语言里：∘ℛ 的等式，对照表补 ∃ 与 = 两行 → 第二版 (b) → 展开回到 (a)
;;; → run* 交出的正是 §2 那种按左边合并的函数 → 这样的函数怎样复合？（交给 §4）
;;; 伪代码不在本节运行；§6 用同样的文本真的运行（结果注释取自 §6）。

;;; §3-0〔验证〕 填列就是部分应用（正文只在散文里写这几个 λ，不放代码块）
;; 填两列，剩一列：一元关系 {c ∣ 3² + 4² = c²}，表里只有一行 5
(check-equal? (filter (λ (c) (pyth? 3 4 c)) (inclusive-range 1 100)) '(5))
;; 三列全填，一列不剩：零元关系，类型 (→ Boolean)，纯的只有两种
(check-equal? ((λ () (pyth? 3 4 5))) #t)
(check-equal? ((λ () (pyth? 3 4 6))) #f)

;;; ─── §3-a〔正文·伪代码〕 关系作用在参数上得到目标 ───
;;; 步骤：问题（§2 节尾：只写条件，让语言去找）→ 概念（Goal 代替 Boolean；参数里可以有未知项，
;;;       由整组目标共同求出；不承诺单个关系能反向求解）
;;; (define-type (→ℛ x y) (→ x y Goal))           ; 关系作用在参数上得到目标

;;; ─── §3-b〔正文·伪代码〕 第一版：照着集合记号逐项翻译 ───
;;; 步骤：代码（数学 ↔ 语言：l ≤ a ≤ h ↔ (betweeno l a h)；a² + b² = c² ↔ (pytho a b c)；
;;;       并列的条件 ∧ ↔ 并列的关系；{(a, b, c) ∣ …} ↔ (run* (a b c) …)，交出时排成列表）
;;;       → 现象（run* 找出所有行，用列表装，与 §1 交出同一张列表）
;;; 散文：关系不限于两组列；betweeno、pytho 各有三个参数。pytho 与 pyth? 参数完全相同。
;;;       熟悉数据库的读者：并列的关系共享未知项 ~ 在相同的列上 JOIN；run* 列出的未知项 ~ SELECT 的列。
;;; ┌伪代码 a
;;; (define (right-triangles l h)
;;;   (run* (a b c)
;;;     (betweeno l a h)    ; l ≤ a ≤ h，最短边
;;;     (betweeno a b h)    ; a ≤ b ≤ h，另一条直角边
;;;     (betweeno b c h)    ; b ≤ c ≤ h，斜边
;;;     (pytho a b c)))     ; a² + b² = c²，直角三角形
;;; └
;;; (right-triangles 1 20)
;;; ;; => ((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))

;;; ─── §3-c〔正文·类型〕 谓词的复合：只有类型，写不出 ───
;;; 步骤：问题（按挑边的顺序拆成四个二元关系，再接起来：存在中间的 y；函数能复合，关系也应当能）
;;;       → 现象（只给两个谓词，写不出通用的复合程序）
;;; 论证（Astra 收紧）：两个谓词都只接收 y、不产生 y，没有中间类型的枚举方式；
;;; 能为当前输入找到有限且完备的候选范围也够，但那是写程序的人承担的搜索（§1 的循环）。
;;   (: ∘ℛ? (∀ (x y z) (→ (→ℛ? y z) (→ℛ? x y) (→ℛ? x z))))

;;; ─── §3-d〔正文·伪代码〕 这门语言里的复合：二元等式 ───
;;; 步骤：概念（∃ 写作 fresh）
;;; 散文：中间项由 fresh 引入，如何找到它交给这些目标的运行（fresh 本身不搜索）。
;;;       对照表补两行：∃y ↔ (fresh (y) …)；t₁ = t₂ ↔ (== t₁ t₂)。
;;; (: ∘ℛ (∀ (x y z) (→ (→ℛ y z) (→ℛ x y) (→ℛ x z))))
;;; ((∘ℛ go fo) x z) = (fresh (y) (fo x y) (go y z))   ; 〔等式〕二元情形；结合律允许连写多个

;;; ─── §3-e〔正文·伪代码〕 第二版：四段二元关系的复合 ───
;;; 步骤：代码（选一条边，就确定了下一个选择的范围）
;;; 只示范 pick-bo；pick-ao、pick-co 形状相同，righto 只让直角三角形原样通过（§6-f 有全部四段）。
;;; ┌伪代码 pick-bo
;;; (define (pick-bo a×h a×b×h)
;;;   (fresh (a b h)
;;;     (== a×h   `(,a ,h))
;;;     (== a×b×h `(,a ,b ,h))
;;;     (betweeno a b h)))
;;; └
;;; ┌伪代码 b
;;; (define right-triangleo (∘ℛ righto pick-co pick-bo pick-ao))
;;;
;;; (define (right-triangles l h)
;;;   (run* (a b c)
;;;     (right-triangleo `(,l ,h) `(,a ,b ,c))))
;;; └
;;; (right-triangles 1 20)
;;; ;; => ((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
;;;
;;; 名字：righto 是 (a b c) 与 (a b c) 之间的关系，与 (a) 里三元的 pytho 区分开。

;;; ─── §3-f〔正文·伪代码〕 展开回到第一版 ───
;;; 步骤：现象（中间元组被 fresh 藏起来；换成模式即回到 (a)）→ 概念（复合是合取的特例：
;;;       合取可以任意接线，复合是接成一条链；为了接成链，后面要用的列得打包带下去）
;;; ┌伪代码 c
;;; (define (right-triangleo l×h triangle)
;;;   (fresh (a×h a×b×h a×b×c)
;;;     (pick-ao l×h   a×h)
;;;     (pick-bo a×h   a×b×h)
;;;     (pick-co a×b×h a×b×c)
;;;     (righto  a×b×c triangle)))
;;; └
;;; §3 收尾（散文，无新代码）：run* 交出的，正是 §2 那种把输入相同的行合并起来的函数；
;;; 停在「这样的函数怎样复合？」。

;;; ═══════════════════════════════════════════════════════════════════
;;; §4 列表世界的复合（v3.7.3，9/30；v4.2 改 §4-e、§4-f 的说法）
;;; ═══════════════════════════════════════════════════════════════════
;;; 开场问题：关系表示成收集答案的函数以后，怎样复合？

;;; ─── §4-a〔正文〕 列表世界的箭头、单位与复合 ───
;;; 步骤：概念（两种表示中选「收集所有答案的函数」；数学上是集合，这里用列表）→ 代码
;;; 与第二篇 →𝒦 的并排挪到 §4。
(define-type (→ℒ p q) (→ p (Listof q)))

(: ℒ:id (∀ (p) (→ℒ p p)))
(: ∘ℒ   (∀ (p ...) (→ (→ℒ pn-1 pn) ... (→ℒ p1 p2) (→ℒ p1 pn))))
(define (ℒ:id v) (list v))
(define ((∘ℒ . f*) x) (foldr append-map (list x) f*))   ; 从最右边的箭头起，逐个用 append-map 接上
;; 9/30 改为变参（与第二篇的 ∘𝒦 一致）；一个箭头也不给时就是 ℒ:id。规则仍按二元陈述，结合律保证变参无歧义。

;;; ─── §4-b〔正文〕 ℒ 实现：四个关系，各是一支箭头 ───
;;; 只按写出的顺序、从已知推出未知：betweeno 在两端已知时枚举，righto 在三者已知时检验。
;;; betweeno 在列表世界里只表示关系「lo ≤ x ≤ hi」：给定 lo、hi，交出所有 x。
(: betweeno (→ Natural Natural (Listof Natural)))
(define (betweeno lo hi) (inclusive-range lo hi))

(define (pick-ao t) (match-define (list l h)   t) (map (λ (a) (list a h))   (betweeno l h)))
(define (pick-bo t) (match-define (list a h)   t) (map (λ (b) (list a b h)) (betweeno a h)))
(define (pick-co t) (match-define (list a b h) t) (map (λ (c) (list a b c)) (betweeno b h)))

;; 谓词读作关系：只让满足它的三元组原样通过，交出零个或一个
(: righto (→ℒ (List Natural Natural Natural) (List Natural Natural Natural)))
(define (righto t) (if (apply pyth? t) (ℒ:id t) '()))

;;; ─── §4-c〔正文〕 普通 ∘ 接不上 ───
;;; 步骤：现象（第二段收到的是整张部分解的列表，不是一个部分解）
(check-exn #rx"match-define: no matching clause"
           (λ () ((∘ pick-bo pick-ao) '(1 20))))
;; 正文：((∘ pick-bo pick-ao) '(1 20))
;; ;; match-define: no matching clause for '((1 20) (2 20) … (20 20))

;;; ─── §4-d〔正文〕 复合：候选全集，再筛选 ───
;;; 步骤：代码 → 现象（与 §1 结果相同）
;;; 正文里叫 right-triangles；与 §1 同名的函数不能在同一模块定义两次，这里叫 right-triangles₂。
(define right-triangleo (∘ℒ righto pick-co pick-bo pick-ao))
(define (right-triangles₂ l h) (right-triangleo (list l h)))

(check-equal? (right-triangles₂ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;; 候选全集（正文可选）：去掉 righto
(define sides (∘ℒ pick-co pick-bo pick-ao))
(check-equal? (length (sides '(1 20))) 1540)

;;; §4-d″〔验证〕 ∘ℒ 逐层展开：先交出一整张 (a h) 表，再整张变成 (a b h) 表……（与 §5-g‴ 的深度优先对照）
(let ([log '()])
  (define (note! x) (set! log (cons x log)))
  (define (pick-ao* t) (match-define (list l h) t) (note! 'A) (pick-ao t))
  (define (pick-bo* t) (match-define (list a h) t) (note! (list 'B a)) (pick-bo t))
  (define (pick-co* t) (match-define (list a b h) t) (note! (list 'C a b)) (pick-co t))
  (check-equal? ((∘ℒ pick-co* pick-bo* pick-ao*) '(1 2)) '((1 1 1) (1 1 2) (1 2 2) (2 2 2)))
  (check-equal? (reverse log) '(A (B 1) (B 2) (C 1 1) (C 1 2) (C 2 2))))

;;; §4-d′〔验证〕
;; 候选全集恰是 l ≤ a ≤ b ≤ c ≤ h
(for* ([l (in-range 1 6)] [h (in-range 0 16)])
  (check-equal? (sides (list l h))
                (for*/list ([a (inclusive-range l h)] [b (inclusive-range a h)] [c (inclusive-range b h)])
                  (list a b c))))
;; 与 §1 的结果相同（多组边界）
(for* ([l (in-range 1 8)] [h (in-range 0 31)])
  (check-equal? (right-triangles₂ l h) (right-triangles l h)))
;; 结合方式不影响结果（逐字相等）：变参与两种二元结合方式一致；零个箭头即单位
(check-equal? ((∘ℒ righto (∘ℒ pick-co (∘ℒ pick-bo pick-ao))) '(1 20)) (right-triangleo '(1 20)))
(check-equal? ((∘ℒ (∘ℒ (∘ℒ righto pick-co) pick-bo) pick-ao) '(1 20)) (right-triangleo '(1 20)))
(for ([x '(0 5 (1 2))]) (check-equal? ((∘ℒ) x) (ℒ:id x)))
(for* ([x '(1 4 6 12)])
  (check-equal? ((∘ℒ divisors) x) (divisors x)))
;; 函数的逆不一定是函数：平方的逆关系交出零个或一个（正文可选的旁证）
(define (sqrt-rel m) (let ([c (integer-sqrt m)]) (if (= (* c c) m) (list c) '())))
(check-equal? (map sqrt-rel '(25 26 0 144)) '((5) () (0) (12)))
;; 直角三角形自动满足三角形不等式
(for ([t triples]) (match-define (list a b c) t) (check-true (> (+ a b) c)))

;;; ─── §4-e〔正文·等式〕 关系的规则，列表实现逐字满足 ───
;;; 步骤：概念（关系的复合满足结合律、以相等关系为单位；函数是一种关系，嵌进来以后复合方式不变）
;;;       → 检查（列表的实现：即使把答案的顺序和重复次数也算进去，这些等式仍然成立）
;;; v4.2（Astra）：不说「从关系世界继承，所以逐字成立」。忘掉顺序与重数的映射看不见这些差别，
;;;       推不出列表侧逐字成立；依据是 list、append-map 的定义，关系侧给的是设计要求与解释。
;;; 分层：前三条是任何世界都要满足的规则；第四条是模拟特有的要求。
;;; 字母：h 全篇留给宿主函数；结合律的三支箭头写作 f₁ f₂ f₃。
;;
;; (∘ℒ g ℒ:id)          = g
;; (∘ℒ ℒ:id f)          = f
;; (∘ℒ f₃ (∘ℒ f₂ f₁))   = (∘ℒ (∘ℒ f₃ f₂) f₁)
;; (∘ℒ f (∘ ℒ:id h))    = (∘ f h)          ; h 是宿主函数
;;
;;; §4-e′〔验证〕 列表世界逐字成立（equal? 比较列表，不经 forget）
(define (tens x) (list x (* 10 x)))
(define (pm x) (list x (- x)))
(define (twice n) (list n (* 2 n)))
(define ℒ-arrows (list divisors tens pm twice ℒ:id))
(define hosts (list add1 - (λ (x) (* x x))))
(for* ([x '(1 4 6 12)] [g ℒ-arrows] [f ℒ-arrows])
  (check-equal? ((∘ℒ g ℒ:id) x) (g x))
  (check-equal? ((∘ℒ ℒ:id f) x) (f x))
  (for ([f₃ ℒ-arrows])
    (check-equal? ((∘ℒ f₃ (∘ℒ g f)) x) ((∘ℒ (∘ℒ f₃ g) f) x))))
(for* ([x '(1 4 6 12)] [f ℒ-arrows] [h hosts])
  (check-equal? ((∘ℒ f (∘ ℒ:id h)) x) ((∘ f h) x)))
;; 勾股程序里的箭头同样满足（部分解作输入）
(define tri-arrows (list pick-co righto ℒ:id))
(for ([t '((3 4 5) (5 5 5) (1 2 3))])
  (for* ([g tri-arrows] [f tri-arrows])
    (check-equal? ((∘ℒ g ℒ:id) t) (g t))
    (check-equal? ((∘ℒ ℒ:id f) t) (f t))))

;;; §4-e″〔验证〕 同样的四条在关系世界（集合）里成立：这是设计要求的来处
(define rel-arrows (map as-rel ℒ-arrows))
(for* ([x '(1 4 6 12)] [r rel-arrows] [s rel-arrows])
  (check-equal? ((rel∘ r rel:id) x) (r x))
  (check-equal? ((rel∘ rel:id s) x) (s x))
  (for ([t rel-arrows])
    (check-equal? ((rel∘ t (rel∘ r s)) x) ((rel∘ (rel∘ t r) s) x))))
;; 普通函数是一种特殊的关系：抬进关系世界后照常复合
(for* ([x '(1 4 6 12)] [r rel-arrows] [h hosts])
  (check-equal? ((rel∘ r (∘ rel:id h)) x) ((∘ r h) x)))

;;; ─── §4-f〔正文〕 §4 收尾：作为关系没有区别，作为列表还记着顺序 ───
;;; 步骤：现象（倒过来列出最短边，关系没变，列表的顺序反了）
;;;       → 概念「作为关系，它们没有区别；作为列表程序，它们还记着答案以什么顺序、出现了几次。」
;;; v4.2：不再说「模拟得过于忠实」。重数在正文只用一句话说（(x x) 的例子随第六篇移走）。
(define (pick-ao↓ t) (match-define (list l h) t) (map (λ (a) (list a h)) (reverse (betweeno l h))))

(check-equal?
 ((∘ℒ righto pick-co pick-bo pick-ao↓) '(1 20))
 '((12 16 20) (9 12 15) (8 15 17) (6 8 10) (5 12 13) (3 4 5)))

;;; §4-f′〔验证〕 忘掉顺序与重数，列表世界的复合就是关系的复合
(check-equal?
 (forget ((∘ℒ righto pick-co pick-bo pick-ao↓) '(1 20)))
 (forget (right-triangles₂ 1 20)))
(for* ([x '(4 6 12)] [g ℒ-arrows] [f ℒ-arrows])
  (check-equal? (forget ((∘ℒ g f) x)) ((rel∘ (as-rel g) (as-rel f)) x)))
;; 重数 = 到达方式的计数（v3.5 的 §3-a′、§3-a″，改为验证）
(check-equal? ((∘ℒ divisors divisors) 4) '(1 1 2 1 2 4))
(check-equal? (length (filter (λ (d) (= d 1)) ((∘ℒ divisors divisors) 4))) 3)
(check-equal? (forget ((∘ℒ divisors divisors) 4))
              ((rel∘ (as-rel divisors) (as-rel divisors)) 4))
;; 倒序的 divisors↓（v3.5 的 §2-m，改为验证）
(define (divisors↓ n) (reverse (divisors n)))
(check-not-equal? (divisors 12) (divisors↓ 12))
(check-equal? (forget (divisors 12)) (forget (divisors↓ 12)))
(check-not-equal? ((∘ℒ twice divisors) 6) ((∘ℒ twice divisors↓) 6))
(check-equal? (forget ((∘ℒ twice divisors) 6)) (forget ((∘ℒ twice divisors↓) 6)))


;;; ═══════════════════════════════════════════════════════════════════
;;; §5 擦除延续参数：choose、fail、collect（v3.7 的 §5 前半）
;;; ═══════════════════════════════════════════════════════════════════
;;; 动机：§4 的 ∘ℒ 能复合，但每段关系都得自己把输出装进列表。
;;; 10/1：程序统一成 §1 的函数形式 (right-triangles l h)；正文同名，这里加下标。

(define-syntax-rule (same-as-§1 f)                       ; 〔验证〕多组边界上与 §1 一致
  (for* ([l (in-range 1 6)] [h (in-range 0 26)])
    (check-equal? (f l h) (right-triangles l h))))

;;; ─── §5-a〔正文〕 给「用 shift 取得 k」起名：choose ───
;;; 步骤：代码（choose/k 本身是 CPS 程序，逐点做第四篇的擦除）
;;; 回指：第四篇「查表」(define (anf0 exp) (shift ctx (anf1 exp ctx)))，
;;;       以及模式 1：(anf1 sub (λ (w) body)) 变成 (reset (let ([w (anf0 sub)]) body))
;;; 正文先写未化简的一行，再按 choose/k 的定义化简：
;;;   (define (choose p*) (shift k ((choose/k p*) k)))
;;;   (define (choose p*) (shift k (append-map k p*)))
;;; 同一模块不能定义两次，这里只留化简后的；未化简的一行以 choose₀ 验证。
;;; 散文：同一个 k 被反复调用是实现前提（一次性延续做不到），一句带过，不点具体语言。
(: choose (∀ (p) (→ (Listof p) p)))
(define (choose p*) (shift k (append-map k p*)))

(define (choose₀ p*) (shift k ((choose/k p*) k)))   ; 〔验证〕

;;; ─── §5-b〔正文〕 原样程序：三层嵌套的 reset，主体自己返回列表 ───
;;; 步骤：代码 → 现象（与 §1 相同）
;;; 回指：§1-b 的 choose/k 程序，逐层按模式 1 改写
(define (right-triangles₃ l h)
  (reset
   (let ([a (choose (inclusive-range l h))])
     (reset
      (let ([b (choose (inclusive-range a h))])
        (reset
         (let ([c (choose (inclusive-range b h))])
           (if (pyth? a b c) (list (list a b c)) '()))))))))

(check-equal? (right-triangles₃ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; §5-b′〔验证〕 多组边界；未化简的 choose₀
(same-as-§1 right-triangles₃)
(check-equal?
 (reset
  (let ([a (choose₀ (inclusive-range 1 20))])
    (reset
     (let ([b (choose₀ (inclusive-range a 20))])
       (reset
        (let ([c (choose₀ (inclusive-range b 20))])
          (if (pyth? a b c) (list (list a b c)) '())))))))
 triples)

;;; ─── §5-c〔正文〕 内层 reset 坍缩 ───
;;; 步骤：代码 → 现象（仍相同）
;;; 回指：第四篇「化简」：(reset (reset e)) = (reset e)，内层 reset 坍缩的理由
(define (right-triangles₄ l h)
  (reset
   (let* ([a (choose (inclusive-range l h))]
          [b (choose (inclusive-range a h))]
          [c (choose (inclusive-range b h))])
     (if (pyth? a b c) (list (list a b c)) '()))))

(check-equal? (right-triangles₄ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
(same-as-§1 right-triangles₄)                            ; 〔验证〕

;;; ─── §5-d〔正文〕 整理第一步：'() 认作 (fail) ───
;;; 步骤：代码（零个备选在这里得名 fail，名字与定义一起首次出现）
;;; 回指：§1 收尾「过滤就是零个备选」
(: fail (∀ (p) (→ p)))
(define (fail) (choose '()))

(define (right-triangles₅ l h)
  (reset
   (let* ([a (choose (inclusive-range l h))]
          [b (choose (inclusive-range a h))]
          [c (choose (inclusive-range b h))])
     (if (pyth? a b c) (list (list a b c)) (fail)))))

(check-equal? (right-triangles₅ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
(same-as-§1 right-triangles₅)                            ; 〔验证〕

;;; ─── §5-e〔正文〕 整理第二步：每个结果上的 list 移进 collect ───
;;; 步骤：代码 → 现象（主体只剩普通的 let* 与 if）
(: collect (∀ (q) (→ (→ q) (Listof q))))
(define (collect thunk) (reset (list (thunk))))

(define (right-triangles₆ l h)
  (collect
   (λ ()
     (let* ([a (choose (inclusive-range l h))]
            [b (choose (inclusive-range a h))]
            [c (choose (inclusive-range b h))])
       (if (pyth? a b c) (list a b c) (fail))))))

(check-equal? (right-triangles₆ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; §5-e′〔验证〕 多组边界；define / unless 写法同样成立
(same-as-§1 right-triangles₆)
(check-equal?
 (collect (λ ()
            (define a (choose (inclusive-range 1 20)))
            (define b (choose (inclusive-range a 20)))
            (define c (choose (inclusive-range b 20)))
            (unless (pyth? a b c) (fail))
            (list a b c)))
 triples)

;;; ─── §5-f〔正文·等式〕 fail 就是 (abort '()) ───
;;; 步骤：概念（不调用剩余工作，'() 原样交出）
;;; 回指：第三篇「定界延续」(shift _ e) = (abort e)，abort 的定义
;;
;; (fail) = (choose '()) = (shift k (append-map k '())) = (shift _ '()) = (abort '())
;;
;;; §5-f′〔验证〕
(check-equal?
 (collect
  (λ ()
    (let* ([a (choose (inclusive-range 1 20))]
           [b (choose (inclusive-range a 20))]
           [c (choose (inclusive-range b 20))])
      (if (pyth? a b c) (list a b c) (abort '())))))
 triples)
(check-equal? (reset (+ 1 (shift _ 5))) (reset (+ 1 (abort 5))))

;;; ─── §5-g〔正文〕 共享与重放：过去只算一次，未来每个备选各跑一遍 ───
;;; 步骤：现象（直接风格里 before 只写了一次、after 出现三次）
;;; 散文：k 的调用不在尾位置，其余备选在 append-map 里等着（§7 的局部诊断回到这里）。
;;; 回指：§1-b 的 (append-map k p*)
(let ([log '()])
  (define (note! x) (set! log (cons x log)))
  (collect
   (λ ()
     (note! 'before)
     (let ([x (choose '(1 2 3))])
       (note! (list 'after x))
       x)))
  (check-equal? (reverse log) '(before (after 1) (after 2) (after 3))))

;;; §5-g‴〔验证〕 choose 沿路径深度优先：与 §4-d″ 交出同样的行、同样的顺序，干活的顺序不同
(let ([log '()])
  (define (note! x) (set! log (cons x log)))
  (check-equal?
   (collect
    (λ ()
      (let* ([a (begin (note! 'A) (choose (inclusive-range 1 2)))]
             [b (begin (note! (list 'B a)) (choose (inclusive-range a 2)))]
             [c (begin (note! (list 'C a b)) (choose (inclusive-range b 2)))])
        (list a b c))))
   '((1 1 1) (1 1 2) (1 2 2) (2 2 2)))
  (check-equal? (reverse log) '(A (B 1) (C 1 1) (C 1 2) (B 2) (C 2 2))))

;;; §5-g′〔验证〕 各条时间线在宿主上按深度优先依次跑完，不是并行
(let ([log '()])
  (define (note! x) (set! log (cons x log)))
  (collect
   (λ ()
     (let* ([x (choose '(1 2))]
            [y (choose '(a b))])
       (note! (list x y))
       (list x y))))
  (check-equal? (reverse log) '((1 a) (1 b) (2 a) (2 b))))

;;; ─── §5-h〔正文〕 函数又能当关系用：普通的 ∘ 重新接上 ───
;;; 步骤：问题（§4-c 普通 ∘ 接不上）→ 代码（四段都写成普通函数 a → b，装答案的容器交给 choose）
;;;       → 现象（普通 ∘ 复合，外面一层 collect，结果与 §1 相同）
;;; 回指：§4-b 的 pick-ao（map 进列表）与这里的 pick-a（choose 一个值），差别只在一处
;;; 散文：choose / fail 就是 McCarthy 的 amb（名字在现象之后出现）。
;;;       措辞（Astra 第二轮）：「每段函数现在直接交出一个值。遇到备选列表，就交给 choose；
;;;       所有分支的结果，由外面的 collect 收起来。」不说「装答案的容器交给了 choose」。
(define (pick-a t) (match-define (list l h)   t) (list (choose (betweeno l h)) h))
(define (pick-b t) (match-define (list a h)   t) (list a (choose (betweeno a h)) h))
(define (pick-c t) (match-define (list a b h) t) (list a b (choose (betweeno b h))))

(define (right t) (if (apply pyth? t) t (fail)))

(define right-triangle (∘ right pick-c pick-b pick-a))   ; 普通的 ∘
(define (right-triangles₇ l h) (collect (λ () (right-triangle (list l h)))))

(check-equal? (right-triangles₇ 1 20)
              '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; §5-h′〔验证〕 多组边界；collect 收回来的就是 §4 的列表箭头
(same-as-§1 right-triangles₇)
(for ([t '((1 5) (2 2) (3 20))])
  (check-equal? (collect (λ () (pick-a t))) (pick-ao t)))
(for ([t '((3 5) (4 4))])
  (check-equal? (collect (λ () (pick-b t))) (pick-bo t)))
(for ([t '((3 4 5) (3 3 5) (5 12 13) (1 2 3))])
  (check-equal? (collect (λ () (right t))) (righto t)))
;; 整条链：collect 之后等于 §4 的 ∘ℒ 版本
(check-equal? (collect (λ () (right-triangle '(1 20)))) (right-triangleo '(1 20)))


;;; ═══════════════════════════════════════════════════════════════════
;;; §6 让关系语言跑起来
;;; ═══════════════════════════════════════════════════════════════════
;;; §6 新增两件事：choose 管分支；代换管「找到的信息怎样记在未知项之间」。
;;; 代码放在子模块 relational 里：§4 的 betweeno、pick-ao 等名字在这里换成关系语言的版本。

;;; ─── §6-a〔正文〕 同一个未知项，不能各选各的 ───
;;; 步骤：问题（(a) 里的 a 同时出现在两个约束里；若每次出现各自 choose，两个 a 互不相干）→ 现象（答案错且重复）
;;; 散文（Astra 第二轮收紧）：它证明的是「把同一个未知项拆成彼此独立的选择，会丢掉原来的约束」；
;;;       具体拆开的是两处用途，不说成严格模拟了「每次出现都独立选择」。光靠它还不足以说明为什么要代换
;;;       （用 let* 绑定一次就能共享）；真正新增的需求是：两个目标先共享一个尚不知道值的项，之后找到的
;;;       信息要对它们共同生效（§6-c″ 的 (== x y) (== y 3)）。
(define independent
  (collect
   (λ ()
     (let* ([a₁ (choose (inclusive-range 1 20))]    ; (betweeno l a h) 里的 a
            [a₂ (choose (inclusive-range 1 20))]    ; (betweeno a b h) 里的 a，各选各的
            [b  (choose (inclusive-range a₂ 20))]
            [c  (choose (inclusive-range b 20))])
       (if (pyth? a₁ b c) (list a₁ b c) (fail))))))

(check-equal? (take independent 7)
              '((3 4 5) (3 4 5) (3 4 5) (3 4 5) (4 3 5) (4 3 5) (4 3 5)))
(check-equal? (length independent) 110)
;; 〔验证〕去掉重复后有 12 组，每组直角三角形都多出一个两条直角边对调的版本
(check-equal? (length (remove-duplicates independent)) 12)
(check-equal? (forget (filter (λ (t) (<= (car t) (cadr t))) independent)) (forget triples))

(module* relational #f
  (provide (all-defined-out))

  ;;; ─── §6-b〔正文〕 未知项与代换 ───
  ;;; 步骤：代码（代换记下每个未知项已知的值；walk 顺着代换找到当前的值）
  ;;; 完整的序对合一：伪代码 (b) 的 (== a×h `(,a ,h)) 需要拆结构。
  ;;; occurs 检查（v4.2 定）：不让未知项等于含有它自己的项。
  (struct var ([name : Symbol]) #:type-name Var)   ; 未知项，按 eq? 区分
  (define-type Term (∪ Var Number Symbol Null (Pair Term Term)))
  (define-type Substitution (Immutable-HashTable Var Term))

  (define empty-s (hasheq))

  (define (walk t s)
    (if (and (var? t) (hash-has-key? s t))
        (walk (hash-ref s t) s)
        t))

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

  (define (walk* t s)
    (let ([t (walk t s)])
      (if (pair? t)
          (cons (walk* (car t) s) (walk* (cdr t) s))
          t)))

  ;;; ─── §6-c〔正文〕 目标：代换 → 代换 ───
  ;;; 步骤：代码 → 概念
  ;;; 散文：conj 依次应用，与 §5 的普通 ∘ 是同一件事；disj 用 choose 选一个目标；
  ;;;       fresh 在收到代换时才分配新的未知项（Astra 审阅）；run* 用 collect 收集。
  ;;;       「每条分支带着自己的代换往下走；一条分支失败，不会改动其他分支手里的代换。」
  ;;;       conj 与 ∧：前一个目标交出满足自身条件的代换，后一个在这些代换上继续求解；
  ;;;       最后留下的答案，就同时满足两个条件。
  (define-type Goal (→ Substitution Substitution))
  (define-type (→ℛ x y) (→ x y Goal))                   ; §3-a

  (define ((== u v) s) (unify u v s))
  (define ((conj . g*) s) (foldl (λ (g s) (g s)) s g*))
  (define ((disj . g*) s) ((choose g*) s))

  (define-syntax-rule (fresh (x ...) g ...)
    (λ (s)
      (let ([x (var 'x)] ...)
        ((conj g ...) s))))

  (define-syntax-rule (run* (x ...) g ...)
    (let ([x (var 'x)] ...)
      (collect (λ () (walk* (list x ...) ((conj g ...) empty-s))))))

  ;;; ─── §6-c″〔正文〕 未知时也要能共享 ───
  ;;; 步骤：现象（两个目标先共享一个尚不知道值的项，之后找到的信息对它们共同生效）
  ;;; 散文（Astra 第二轮）：§6-a 说明「独立选择为什么不够」；这里说明代换真正新增的能力。
  (check-equal? (run* (x y)
                  (== x y)
                  (== y 3))
                '((3 3)))

  ;;; §6-c′〔验证〕 小例子与边界
  (check-equal? (run* (x) (disj (== x 1) (== x 2))) '((1) (2)))
  (check-equal? (run* (x y) (== `(,x 2) `(1 ,y))) '((1 2)))
  (check-equal? (run* (x) (== 1 2)) '())
  ;; 每条分支带着自己的代换
  (check-equal? (run* (x y) (disj (== x 1) (== x 2)) (== y x)) '((1 1) (2 2)))
  ;; fresh 每次运行都分配新的未知项：同一目标用两次，是两次独立的二选一
  (check-equal? (run* () (let ([g (fresh (x) (disj (== x 1) (== x 2)))]) (conj g g)))
                '(() () () ()))
  ;; occurs 检查：循环项无解
  (check-equal? (run* () (fresh (q) (== q (cons 'a q)))) '())
  ;; 对应表：空合取是 ⊤，空析取是 ⊥；列表层面保留重数
  (check-equal? (run* () (conj)) '(()))
  (check-equal? (run* () (disj)) '())
  (check-equal? (run* () (disj (== 1 1) (== 2 2))) '(() ()))
  ;; conj 按解集是 ∧：交换顺序，答案的集合不变（只含 == 的目标）
  (check-equal? (forget (run* (x y) (disj (== x 1) (== x 2)) (disj (== y x) (== y 3))))
                (forget (run* (x y) (disj (== y x) (== y 3)) (disj (== x 1) (== x 2)))))
  ;; 列表层面 disj 是有序追加：不交换
  (check-not-equal? (run* (x) (disj (== x 1) (== x 2))) (run* (x) (disj (== x 2) (== x 1))))

  ;;; ─── §6-d〔正文〕 两个只认数的目标 ───
  ;;; 限制：上下界、三条边必须已经确定，所以目标的顺序有关系；它们不是完全关系式的。
  ;;; 伪代码里的顺序恰好满足。§2 不承诺 pytho 反向求解。
  (define ((betweeno lo x hi) s)
    ((== x (choose (inclusive-range (walk lo s) (walk hi s)))) s))

  (define ((pytho a b c) s)
    (if (pyth? (walk a s) (walk b s) (walk c s)) s (fail)))

  ;;; §6-d′〔验证〕 pytho 遇到未知的 c 会出错（§2 因此不作反向承诺）
  (check-exn exn:fail? (λ () (run* (c) (pytho 3 4 c))))

  ;;; ─── §6-e〔正文〕 第一版原样运行 ───
  ;;; §3-b 的伪代码逐字（test 子模块比对）。
  (module* a #f
    (provide right-triangles)
    ;; ┌正文 a
    (define (right-triangles l h)
      (run* (a b c)
        (betweeno l a h)    ; l ≤ a ≤ h，最短边
        (betweeno a b h)    ; a ≤ b ≤ h，另一条直角边
        (betweeno b c h)    ; b ≤ c ≤ h，斜边
        (pytho a b c)))     ; a² + b² = c²，直角三角形
    ;; └
    (check-equal? (right-triangles 1 20)
                  '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))))

  ;;; ─── §6-f〔正文〕 复合，以及第二版原样运行 ───
  ;;; ∘ℛ 按 §3-d 的二元等式写成变参函数：每接一段，fresh 一个中间项；零段是相等关系。
  (: ∘ℛ (∀ (p ...) (→ (→ℛ pn-1 pn) ... (→ℛ p1 p2) (→ℛ p1 pn))))
  (define ((∘ℛ . r*) x z)
    (match r*
      ['() (== x z)]
      [(list r ... f) (fresh (y) (f x y) ((apply ∘ℛ r) y z))]))

  (check-equal? (run* (q) ((∘ℛ) 7 q)) '((7)))            ; 〔验证〕零段

  (module* b #f
    (provide pick-ao pick-bo pick-co righto)
    (define (pick-ao l×h a×h)
      (fresh (l a h)
        (== l×h `(,l ,h))
        (== a×h `(,a ,h))
        (betweeno l a h)))
    ;; ┌正文 pick-bo
    (define (pick-bo a×h a×b×h)
      (fresh (a b h)
        (== a×h   `(,a ,h))
        (== a×b×h `(,a ,b ,h))
        (betweeno a b h)))
    ;; └
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

    ;; ┌正文 b
    (define right-triangleo (∘ℛ righto pick-co pick-bo pick-ao))

    (define (right-triangles l h)
      (run* (a b c)
        (right-triangleo `(,l ,h) `(,a ,b ,c))))
    ;; └
    (check-equal? (right-triangles 1 20)
                  '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
    ;; 〔验证〕多组边界上与 §1 一致
    (for* ([l (in-range 1 4)] [h (in-range 1 16)])
      (check-equal? (right-triangles l h) (right-triangles₆ l h))))

  ;;; §6-f′〔验证〕 展开的版本（§3-f 的伪代码 c）同样成立
  (module* c #f
    (require (submod ".." b))
    ;; ┌正文 c
    (define (right-triangleo l×h triangle)
      (fresh (a×h a×b×h a×b×c)
        (pick-ao l×h   a×h)
        (pick-bo a×h   a×b×h)
        (pick-co a×b×h a×b×c)
        (righto  a×b×c triangle)))
    ;; └
    (check-equal? (run* (a b c) (right-triangleo '(1 20) `(,a ,b ,c))) triples))

  ;;; ─── §6-g〔正文〕 倒着跑 ───
  ;;; 步骤：现象（只用 == 写成的关系，给定输出求输入；「不分输入输出」找回来了）
  ;;; 散文：betweeno、pytho 做不到，因为它们要求数已确定。§6 末尾一句：这门语言是 miniKanren 的一个精简版。
  (define (swapo p q)
    (fresh (x y)
      (== p (list x y))
      (== q (list y x))))

  (check-equal? (run* (q) (swapo '(1 2) q)) '(((2 1))))
  (check-equal? (run* (p) (swapo p '(2 1))) '(((1 2))))

  ;;; §6-g′〔验证〕 递归关系正反都能跑（appendo 不进正文）
  (define (appendo l s out)
    (disj (conj (== l '()) (== s out))
          (fresh (a d res)
            (== l (cons a d))
            (== out (cons a res))
            (appendo d s res))))
  (check-equal? (run* (q) (appendo '(1) '(2) q)) '(((1 2))))
  (check-equal? (run* (x y) (appendo x y '(1 2))) '((() (1 2)) ((1) (2)) ((1 2) ())))


  ;;; ═════════════════════════════════════════════════════════════════
  ;;; §7 run 1：退出了当前备选，没退出搜索
  ;;; ═════════════════════════════════════════════════════════════════

  ;;; ─── §7-a〔正文〕 找一组就够了 ───
  ;;; 步骤：问题（用户只要第一组）→ 代码（最直接的写法：拿到第一个答案就 abort）→ 现象（六组全来了，不报错）
  ;;; 与 run* 并排：run* 是 (collect (λ () …))，即 (reset (list …))；run1 只多一个 abort。
  ;;; 回指：第三篇 abort；§5-g「其余备选在 append-map 里等着」
  (define-syntax-rule (run1 (x ...) g ...)
    (let ([x (var 'x)] ...)
      (reset (abort (list (walk* (list x ...) ((conj g ...) empty-s)))))))

  (define (first-triangle l h)
    (run1 (a b c)
      (betweeno l a h)
      (betweeno a b h)
      (betweeno b c h)
      (pytho a b c)))

  (check-equal? (first-triangle 1 20)
                '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

  ;;; ─── §7-b〔正文〕 去掉 abort，结果一模一样 ───
  ;;; 步骤：现象（abort 已在局部计算的尾位置，它根本没碰到想丢弃的工作）
  ;;; 局部诊断（散文）：它结束了当前备选的计算，却没有丢弃等待其他备选的 append-map。
  ;;; 一般结论只说「现有接口没有区分这两种退出目标」；不说「必须用多个边界」。
  (define (all-triangles l h)
    (run* (a b c)
      (betweeno l a h)
      (betweeno a b h)
      (betweeno b c h)
      (pytho a b c)))

  (check-equal? (first-triangle 1 20) (all-triangles 1 20))

  ;;; §7-b′〔验证〕 最小机制：abort 之后的错误被跳过，其他备选照常运行
  (check-equal? (reset (let ([x (choose '(1 2 3))])
                         (abort (list x))
                         (error 'unreachable)))
                '(1 2 3))
  (check-equal? (first-triangle 3 5) '((3 4 5))))


;;; ═══════════════════════════════════════════════════════════════════
;;; test 子模块：运行关系语言的子模块，并核对 §3 伪代码与 §6 代码读成的 S 表达式相同
;;; ═══════════════════════════════════════════════════════════════════
(module+ test
  (require (only-in (submod ".." relational))
           (only-in (submod ".." relational a))
           (only-in (submod ".." relational c)))

  (define src (variable-reference->module-source (#%variable-reference)))
  (define lines (file->lines src))
  ;; 取出以 open 开头、以 close 结尾之间的行，去掉前缀 strip，读成 S 表达式
  (define (block open close strip)
    (define body
      (let loop ([ls lines] [in? #f] [acc '()])
        (cond [(null? ls) (reverse acc)]
              [(and (not in?) (string-prefix? (string-trim (car ls)) open)) (loop (cdr ls) #t acc)]
              [(and in? (string-prefix? (string-trim (car ls)) close)) (reverse acc)]
              [in? (loop (cdr ls) #t (cons (car ls) acc))]
              [else (loop (cdr ls) #f acc)])))
    (define text
      (string-join (for/list ([l body])
                     (let ([t (string-trim l #:right? #f)])
                       (if (string-prefix? t strip) (substring t (string-length strip)) t)))
                   "\n"))
    (with-input-from-string text
      (λ () (for/list ([e (in-port read)]) e))))
  (for ([name '("a" "pick-bo" "b" "c")])
    (define pseudo (block (string-append ";;; ┌伪代码 " name) ";;; └" ";;;"))
    (define real   (block (string-append ";; ┌正文 " name) ";; └" ""))   ; 正文原样读取，不剥注释（Astra 第二轮）
    (check-true (pair? pseudo) name)
    (check-equal? pseudo real name)))
