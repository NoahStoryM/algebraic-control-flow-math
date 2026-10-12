#lang typed/racket/no-check
;;; 第六篇正文代码（单子）。由 art5-code.rkt v3.7.4 拆出（10/1），块的内容未改，编号按第六篇大纲 v1.2 的节重标。
;;; 依据：art6-plan.md v1.2；正文写作前按第六篇叙事重排（大纲待办 E）。
;;; 运行：raco test art6-code.rkt
;;;
;;; 约定同 art5-code.rkt：〔正文〕〔正文·等式〕〔验证〕〔前文〕。
;;; 块标题里的「原§2-d」等是第五篇 v3.5 的编号；「原5§5-h」等是第五篇 v3.7.4 的编号。
;;; 「第七篇素材」现为第八篇（范畴论总结）素材。

(require rackunit
         (except-in racket/control abort))   ; abort 用第三篇自己的定义


;;; ═══════════════════════════════════════════════════════════════════
;;; §0〔前文〕 前四篇的原样定义
;;; ═══════════════════════════════════════════════════════════════════
;;; 逐字取自第二篇、第三篇的「完整代码参考」与正文。
;;; 第二、三篇里 neg / flip / cps / ∘𝒰 / ∘𝒦 / neg² / cps->neg² / cps:id
;;; 的代码逐字相同，只是类型分别写作 ¬ 与 ¬ₐ；这里的类型取第二篇。
;;; 求值用第三篇的 anf:eval（平凡表示，a->⊥ᵃ = values），
;;; 不用第二篇借 raise 的版本：两篇的 ans 结构体同名不同形，
;;; §3 需要的是第三篇的那一个。

;; ── 第二篇「完整代码参考」 ──
(define ∘ compose)

(define-type ⊥ (∪))
(define-type (¬  a) (→ a ⊥))
(define-type (¬¬ a) (¬ (¬ a)))
(define-type (← q p) (→ p q))

(define-type (→𝒟 p q) (→ p q))
(define-type (→𝒞 p q) (→ p q))

(define-type (→𝒰 p q) (← (¬ p) (¬ q)))

(: neg (∀ (p q) (→ (→𝒞 p q) (→𝒰 p q))))
(: neg¹ (∀ (p q) (→ (→𝒰 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define ((neg f) kq) (∘ kq f))
(define neg¹ neg)

(: ∘𝒰 (∀ (p ...) (→ (→𝒰 pn-1 pn) ... (→𝒰 p1 p2) (→𝒰 p1 pn))))
(define (∘𝒰 . neg:f*) (apply ∘ (reverse neg:f*)))

(define-type (→𝒦 p q) (→ p (¬¬ q)))

(: flip  (∀ (p q) (→ (→𝒰 p q) (→𝒦 p q))))
(: flip¹ (∀ (p q) (→ (→𝒦 p q) (→𝒰 p q))))
(define (((flip f) . y*) . x*) (apply (apply f x*) y*))
(define flip¹ flip)

(: cps   (∀ (p q) (→ (→𝒞 p q) (→𝒦 p q))))
(: uncps (∀ (p q) (→ (→𝒦 p q) (→𝒞 p q))))
(define cps (∘ flip neg))
(define (uncps cps:f) (∘ call/cc cps:f))

(: ∘𝒦 (∀ (p ...) (→ (→𝒦 pn-1 pn) ... (→𝒦 p1 p2) (→𝒦 p1 pn))))
(define (∘𝒦 . cps:f*) (flip (apply ∘𝒰 (map flip¹ cps:f*))))

(: neg² (∀ (p q) (→ (→𝒞 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define neg² (∘ neg¹ neg))

(: cps->neg² (∀ (p q) (→ (→𝒦 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define cps->neg² (∘ neg¹ flip¹))

(define cps:id        (cps values))
(define cps:+         (cps +))
(define cps:*         (cps *))

;; ── 第三篇「完整代码参考」「返回答案」「定界延续」 ──
(define-type ⊥ᵃ a)
(define-type (¬ₐ p) (→𝒟 p ⊥ᵃ))
(define-type (¬ₐ¬ₐ p) (¬ₐ (¬ₐ p)))
(define-type (¬ₐ¬ₐ¬ₐ p) (¬ₐ (¬ₐ¬ₐ p)))

(: a->⊥ᵃ (∀ (a) (¬ₐ a)))
(define a->⊥ᵃ values)

(: anf:eval (∀ (a) (¬ₐ¬ₐ¬ₐ a)))
(define anf:eval (cps:id a->⊥ᵃ))

(struct (r) ans ([a : r]) #:type-name Ans)

(define (abort . v*) (shift _ (apply values v*)))


;;; ═══════════════════════════════════════════════════════════════════
;;; §0′〔前文·第五篇〕 第五篇的定义（拆分时原样复制；第五篇定稿后逐 token 核对）
;;; ═══════════════════════════════════════════════════════════════════
(: pyth? (→ Natural Natural Natural Boolean))
(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))
(define triples '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

(: choose/k (∀ (p q) (→ (Listof p) (→ (→ p (Listof q)) (Listof q)))))
(define ((choose/k p*) k) (append-map k p*))

(define-type (→ℒ p q) (→ p (Listof q)))
(: ℒ:id (∀ (p) (→ℒ p p)))
(: ∘ℒ   (∀ (p ...) (→ (→ℒ pn-1 pn) ... (→ℒ p1 p2) (→ℒ p1 pn))))
(define (ℒ:id v) (list v))
(define ((∘ℒ . f*) x) (foldr append-map (list x) f*))

(: choose (∀ (p) (→ (Listof p) p)))
(define (choose p*) (shift k (append-map k p*)))
(: fail (∀ (p) (→ p)))
(define (fail) (choose '()))
(: collect (∀ (q) (→ (→ q) (Listof q))))
(define (collect thunk) (reset (list (thunk))))

;; 第五篇的验证样例（第六篇的验证沿用）
(define (divisors n)
  (filter (λ (d) (zero? (remainder n d))) (range 1 (add1 n))))
(define (tens x) (list x (* 10 x)))
(define (pm x) (list x (- x)))
(define (twice n) (list n (* 2 n)))
(define ℒ-arrows (list divisors tens pm twice ℒ:id))
(define hosts (list add1 - (λ (x) (* x x))))


;;; ═══════════════════════════════════════════════════════════════════
;;; §2–§3 三个世界与命名（块的内容沿用第五篇 v3.5，顺序与编号待写第六篇时重排；
;;;     标题里的「原§」是第五篇 v3.5 的编号）
;;; ═══════════════════════════════════════════════════════════════════

;;; ─── 原§2-d〔正文·等式〕 连接器由复合推出：values 读作 𝒦 箭头 ───
;;; 步骤：问题（已有一个 ¬¬p，怎样使用只接收 p 的 g？）→ 代码
;;; 回指：第二篇「三种箭头」∘𝒦（绕道 𝒰 定义，里面没有 cps->neg²）；
;;;       第二篇「否定翻译」cps->neg² = (∘ neg¹ flip¹)
;;
;; 别名展开两行：
;; (→𝒦 (¬¬ p) p)
;; = (→ (¬¬ p) (¬¬ p))
;;
;; 所以宿主的 values 就是一支 (¬¬ p) →𝒦 p 的箭头，可以接在 g 前面：
;; (∘𝒦 g values) = (cps->neg² g)

;;; ─── 原§2-d′〔正文〕 紧跟一次具体求值 ───
;;; 步骤：现象（两种写法得到同一个 9）
;;; 回指：第二篇「再次隐藏延续」：(anf:let* ([v (cps:+ 1 2)]) (cps:* v 3)) 的展开，
;;;       kkv、cps:kv、(cps->neg² cps:kv) 三个名字原样取自那里
(check-equal?
 (let ([kkv (cps:+ 1 2)])
   (define (cps:kv v) (cps:* v 3))
   (anf:eval ((∘𝒦 cps:kv values) kkv)))
 9)
(check-equal?
 (let ([kkv (cps:+ 1 2)])
   (define (cps:kv v) (cps:* v 3))
   (anf:eval ((cps->neg² cps:kv) kkv)))
 9)

;;; 原§2-d″〔验证〕 (∘𝒦 g values) = (cps->neg² g)，多种 g 与 ¬¬p
;; 𝒦 箭头样例
(define ((f𝒦 x) k) (k (* x 2)))
(define ((g𝒦 x) k) (if (> x 5) (k (- x)) 'abort))     ; 可能不调用 k
(define ((h𝒦 x) k) (list (k x) (k (+ x 100))))       ; 调用 k 两次
(define 𝒦-arrows (list f𝒦 g𝒦 h𝒦 cps:id))
;; ¬¬p 样例：调用一次、不调用、调用两次
(define ((kk x) k) (k x))
(define (kk-abort k) 'aborted)
(define (kk-twice k) (list (k 1) (k 7)))
(define ¬¬samples (list (kk 7) (kk 2) kk-abort kk-twice))
;; 观察延续：恒等之外再加非恒等，区分「继续」与「中止」
(define observers (list values (λ (x) (list 'seen x))))
(define inputs '(1 3 4 6))
(define-syntax-rule (same-𝒦 e1 e2)
  (for ([o observers]) (check-equal? (e1 o) (e2 o))))
;; 盲区示例：只用 values 观察时，「调用一次」与「中止并返回同值」分不开
(check-equal? ((kk 1) values) ((λ (k) 1) values))
(check-not-equal? ((kk 1) (λ (x) (list 'seen x))) ((λ (k) 1) (λ (x) (list 'seen x))))

(for* ([m ¬¬samples] [g 𝒦-arrows])
  (same-𝒦 ((∘𝒦 g values) m) ((cps->neg² g) m)))

;;; ─── 原§2-e〔正文·等式〕 去程：先运行宿主函数，再接上 cps:id ───
;;; 步骤：代码（单位沿用第二篇的 cps:id）
;;; 回指：第二篇「嵌入语言」(define cps:id (cps values))
;;
;; (∘ cps:id h) = (cps h)          ; h 是宿主函数
;;
;;; 原§2-e′〔验证〕
(for ([x inputs] [h (list add1 - (λ (x) (* x x)) number->string)])
  (same-𝒦 ((∘ cps:id h) x) ((cps h) x)))

;;; ─── 原§2-f〔正文·等式〕 往返一圈：作用在函数上的那一面自己长出来（延续世界） ───
;;; 步骤：现象（从没要求 ¬¬ 能作用在函数上，往返一圈却化成第二篇的 neg²）
;;;       → 概念（这个单子作用在函数上的方式，就是读者早已认识的那个）
;;; 回指：第二篇「否定翻译」neg² = (∘ neg¹ neg)；第二篇「经典与构造」uncps
;;;       （回程不还原原箭头，端点成了 ¬¬p、¬¬q，它不是 uncps）
;;; 列表世界的往返（map）放在 原§2-h，等 connector:ℒ 在 原§2-g 命名之后。
;;
;; (∘ cps->neg² cps)
;; = (∘ neg¹ flip¹ flip neg)
;; = (∘ neg¹ neg)
;; = neg²
;;
;;; 原§2-f′〔验证〕
(for ([m ¬¬samples] [h (list add1 - (λ (x) (* x x)) number->string)])
  (same-𝒦 (((∘ cps->neg² cps) h) m)             (((∘ neg¹ flip¹ flip neg) h) m))
  (same-𝒦 (((∘ neg¹ flip¹ flip neg) h) m)       (((∘ neg¹ neg) h) m))
  (same-𝒦 (((∘ neg¹ neg) h) m)                  ((neg² h) m)))

;;; 原§2-f″〔验证·第七篇素材〕 长出来的 neg² 确实是对函数的作用：保持恒等与复合
(for ([m ¬¬samples])
  (same-𝒦 ((neg² values) m) m)
  (for* ([g hosts] [f hosts])
    (same-𝒦 ((neg² (∘ g f)) m) ((∘ (neg² g) (neg² f)) m))))

;;; ─── 原§2-g〔正文〕 两个世界并排 ───
;;; 步骤：代码 → 概念（append-map 与 cps->neg² 站在同一个位置；列表世界不再重复推导）
;;; 回指：第二篇 ∘𝒦 与 cps->neg²
;;; 注：connector:ℒ 沿用 sketch 的暂名（大纲待办 1）。
(: connector:ℒ (∀ (p q) (→ (→ℒ p q) (→ (Listof p) (Listof q)))))
(define ((connector:ℒ g) p*) (append-map g p*))
;;
;; (∘𝒦 g f) = (∘ (cps->neg² g) f)
;; (∘ℒ g f) = (∘ (connector:ℒ g) f)
;;
;;; 原§2-g′〔验证〕
(for* ([x inputs] [g 𝒦-arrows] [f 𝒦-arrows])
  (same-𝒦 ((∘𝒦 g f) x) ((∘ (cps->neg² g) f) x)))
(for* ([x '(1 4 6 12)] [g ℒ-arrows] [f ℒ-arrows])
  (check-equal? ((∘ℒ g f) x) ((∘ (connector:ℒ g) f) x)))

;;; 原§2-g″〔验证〕 可供选用的观察（不在大纲里，写散文时再定）
;; §1 的 choose/k 就是参数对调的 connector:ℒ：
(for ([g ℒ-arrows])
  (check-equal? ((choose/k '(1 4 6)) g) ((connector:ℒ g) '(1 4 6))))

;;; ─── 原§2-h〔正文·等式〕 往返一圈，两个世界并排：列表世界长出 map ───
;;; 步骤：现象（从没要求 Listof 能作用在函数上，往返一圈正是 map）→ 概念（同 原§2-f）
;;; 回指：原§2-e 的去程 (∘ cps:id h) = (cps h)；原§2-f 的 neg²
;;
;; ((cps->neg² (∘ cps:id h)) m)   = ((neg² h) m)      ; 即 §3-e 的 (∘ cps->neg² cps) = neg²
;; ((connector:ℒ (∘ ℒ:id h)) p*)  = (map h p*)
;;
;;; 原§2-h′〔验证〕
(for ([m ¬¬samples] [h (list add1 - (λ (x) (* x x)) number->string)])
  (same-𝒦 ((cps->neg² (∘ cps:id h)) m) ((neg² h) m)))
(for* ([p* '(() (1) (1 2 3) (4 6 12))] [h hosts])
  (check-equal? ((connector:ℒ (∘ ℒ:id h)) p*) (map h p*)))

;;; 原§2-h″〔验证·第七篇素材〕 长出来的 map 保持恒等与复合
(for ([p* '(() (1) (1 2 3))])
  (check-equal? ((connector:ℒ (∘ ℒ:id values)) p*) p*)
  (for* ([g hosts] [f hosts])
    (check-equal? ((connector:ℒ (∘ ℒ:id (∘ g f))) p*)
                  ((∘ (connector:ℒ (∘ ℒ:id g)) (connector:ℒ (∘ ℒ:id f))) p*))))

;;; ─── 原§2-i〔验证〕 第二篇的宏：同一份文本，𝒦 连接器下的行为 ───
;;; 四个宏一字不改地取自第二篇；本子模块看见的 cps->neg² 是 §0 的第二篇定义。
;;; 用来对照 原§2-j：两个子模块的宏文本相同，差别只在 原§2-j 的连接器一行
;;; （test 子模块在源码层面核对这一点）。
(module* 𝒦-let #f
  (define-syntax anf:let*-values
    (syntax-rules ()
      [(_ () b* ...)
       (anf:begin b* ...)]
      [(_ ([v* e]) b* ...)
       (let ([kkv e])
         (define (cps:kv . v*) (anf:begin b* ...))
         (define neg²:kv (cps->neg² cps:kv))
         (neg²:kv kkv))]
      [(_ ([v* e] [v** e*] ...) b* ...)
       (anf:let*-values ([v* e])
         (anf:let*-values ([v** e*] ...)
           b* ...))]))

  (define-syntax anf:begin
    (syntax-rules ()
      [(_ b) b]
      [(_ b b* ...) (anf:let*-values ([_ b]) b* ...)]))

  (define-syntax-rule (anf:let* ([v e] ...) b* ...)
    (anf:let*-values ([(v) e] ...) b* ...))

  (define-syntax-rule (anf:if test conseq alt)
    (let ([kkb test])
      (define (cps:kb . b*) (if (equal? b* '(#f)) alt conseq))
      (define neg²:kb (cps->neg² cps:kb))
      (neg²:kb kkb)))

  ;; 第二篇「再次隐藏延续」的例子
  (check-equal? (anf:eval (anf:let* ([v (cps:+ 1 2)]) (cps:* v 3))) 9))

;;; ─── 原§2-j〔正文〕 列表世界的 let*：只换连接器那一行 ───
;;; 步骤：代码 → 现象（勾股数第三次得到同样的结果；重数现形）
;;; 回指：第二篇「再次隐藏延续」的完整宏实现（逐字照搬，连 kkv、cps:kv、neg²:kv 都保留）
;;; 正文展示：连接器一行、anf:let* 的勾股程序、anf:begin 的重数例子；
;;; 四个宏的文本不再展示（第二篇原文）。
(module* ℒ-let #f
  (provide anf:let*)

  (define cps->neg² connector:ℒ)           ; ← 与第二篇唯一的差别

  (define-syntax anf:let*-values
    (syntax-rules ()
      [(_ () b* ...)
       (anf:begin b* ...)]
      [(_ ([v* e]) b* ...)
       (let ([kkv e])
         (define (cps:kv . v*) (anf:begin b* ...))
         (define neg²:kv (cps->neg² cps:kv))
         (neg²:kv kkv))]
      [(_ ([v* e] [v** e*] ...) b* ...)
       (anf:let*-values ([v* e])
         (anf:let*-values ([v** e*] ...)
           b* ...))]))

  (define-syntax anf:begin
    (syntax-rules ()
      [(_ b) b]
      [(_ b b* ...) (anf:let*-values ([_ b]) b* ...)]))

  (define-syntax-rule (anf:let* ([v e] ...) b* ...)
    (anf:let*-values ([(v) e] ...) b* ...))

  (define-syntax-rule (anf:if test conseq alt)
    (let ([kkb test])
      (define (cps:kb . b*) (if (equal? b* '(#f)) alt conseq))
      (define neg²:kb (cps->neg² cps:kb))
      (neg²:kb kkb)))

  ;; §2-j〔正文〕 勾股数：主体与 §1-b 最内层相同，须自己返回列表
  (check-equal?
   (anf:let* ([a (range 1 21)]
              [b (range a 21)]
              [c (range b 21)])
     (if (pyth? a b c) (list (list a b c)) '()))
   '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

  ;; §2-j〔正文〕 重数现形
  (check-equal? (anf:begin (list 1 2) (list 'x)) '(x x))

  ;; §2-j′〔验证〕 anf:if 同样照搬可用（测试值须是列表）
  (check-equal?
   (anf:let* ([a (range 1 21)]
              [b (range a 21)]
              [c (range b 21)])
     (anf:if (list (pyth? a b c)) (list (list a b c)) '()))
   triples)
  ;; §2-j′〔验证〕 与 for*/list 的差别：for*/list 自动给主体套单位，这里不套
  (check-exn #rx"append: contract violation" (λ () (anf:let* ([a '(1 2)]) a)))
  (check-equal? (anf:let* ([a '(1 2)]) (ℒ:id a)) '(1 2))
  ;; §2-j′〔验证〕 只支持单值：每个备选只带一个值
  (check-exn exn:fail? (λ () (anf:let*-values ([(x y) '(1 2)]) (list x)))))

;;; ─── 原§2-k〔正文·等式〕 命名：单子；𝒦 就是 Kleisli ───
;;; 步骤：概念（一个类型构造子 T，加上 p → T q 形状箭头的复合与单位，满足三条定律，
;;;       这一整套就是一个单子；「列表单子」指 Listof 连同 ∘ℒ 与 ℒ:id）
;;; 回指：第二篇随手起的 𝒦 与 cps:k、kp 等名字；原§2-c 的相容律
;;
;; (∘𝒦 f (∘ cps:id h)) = (∘ f h)
;;
;;; 原§2-k′〔验证〕 𝒦 的单位律、结合律、相容律（正文形式）
(for ([x inputs])
  (same-𝒦 ((∘𝒦 f𝒦 cps:id) x) (f𝒦 x))
  (same-𝒦 ((∘𝒦 cps:id g𝒦) x) (g𝒦 x))
  (same-𝒦 ((∘𝒦 h𝒦 (∘𝒦 g𝒦 f𝒦)) x) ((∘𝒦 (∘𝒦 h𝒦 g𝒦) f𝒦) x)))
(for* ([x inputs] [f 𝒦-arrows] [h hosts])
  (same-𝒦 ((∘𝒦 f (∘ cps:id h)) x) ((∘ f h) x)))

;;; 原§2-k″〔验证·第七篇素材〕 相容律的原式，以及两种形式在单位律、结合律下互推
;;   原式：(∘𝒦 g (∘ f h)) = (∘ (∘𝒦 g f) h)
;;   原式 ⇒ 新式：(∘𝒦 f (∘ cps:id h)) = (∘ (∘𝒦 f cps:id) h) = (∘ f h)
;;   新式 ⇒ 原式：(∘𝒦 g (∘ f h)) = (∘𝒦 g (∘𝒦 f (∘ cps:id h)))
;;                              = (∘𝒦 (∘𝒦 g f) (∘ cps:id h)) = (∘ (∘𝒦 g f) h)
(for* ([x inputs] [g 𝒦-arrows] [f 𝒦-arrows] [h hosts])
  (same-𝒦 ((∘𝒦 g (∘ f h)) x)                 ((∘ (∘𝒦 g f) h) x))
  (same-𝒦 ((∘𝒦 f (∘ cps:id h)) x)            ((∘ (∘𝒦 f cps:id) h) x))
  (same-𝒦 ((∘𝒦 g (∘ f h)) x)                 ((∘𝒦 g (∘𝒦 f (∘ cps:id h))) x))
  (same-𝒦 ((∘𝒦 g (∘𝒦 f (∘ cps:id h))) x)     ((∘𝒦 (∘𝒦 g f) (∘ cps:id h)) x)))
(for* ([x '(1 4 6 12)] [g ℒ-arrows] [f ℒ-arrows] [h hosts])
  (check-equal? ((∘ℒ g (∘ f h)) x)             ((∘ (∘ℒ g f) h) x))
  (check-equal? ((∘ℒ f (∘ ℒ:id h)) x)          ((∘ (∘ℒ f ℒ:id) h) x))
  (check-equal? ((∘ℒ g (∘ f h)) x)             ((∘ℒ g (∘ℒ f (∘ ℒ:id h))) x))
  (check-equal? ((∘ℒ g (∘ℒ f (∘ ℒ:id h))) x)   ((∘ℒ (∘ℒ g f) (∘ ℒ:id h)) x)))

;;; ─── 原§2-l〔验证〕 想要的世界：𝒞 经 uncps、𝒰 经 flip 与 𝒦 对应 ───
;;; 正文只用第二篇的结论，不展示代码；这里复核。
;;; 回指：第二篇「经典与构造」交换图表与注意框
(for ([x inputs] [f (list add1 - (λ (x) (* x x)))])
  (check-equal? ((uncps (cps f)) x) (f x)))
(for* ([x inputs] [g 𝒦-arrows])
  (same-𝒦 ((flip (flip¹ g)) x) (g x)))

;;; ─── 以下为原 §3（异常）───

;;; 本节说「零个备选」，代码用 §1 已有的 (choose/k '())；fail 到 §5-d 才出现。

;;; ─── 原§3-a〔正文·等式〕 零个备选：不调用剩余工作 ───
;;; 步骤：现象（k 没有被调用，'() 原样交出）→ 问题（这个形状第三篇见过）
;;; 回指：第三篇「定界延续与 CPS」例二的主体 (λ (_) 3)；(shift _ e) = (abort e)
;;
;; (choose/k '())
;; = (λ (k) (append-map k '()))
;; = (λ (_) '())
;;
;;; 原§3-a′〔验证〕
(check-equal? ((choose/k '()) (λ (x) (error 'k "不应被调用"))) '())
(for ([k ℒ-arrows])
  (check-equal? ((choose/k '()) k) ((λ (_) '()) k)))

;;; ─── 原§3-b〔正文〕 异常世界的连接器 ───
;;; 步骤：代码 → 概念（答案路径就是异常单子，模拟提前返回，即逃逸到边界）
;;; 回指：第三篇「否定翻译与 A-翻译」(λ (v) (if (ans? v) v (k v)))，
;;;       (connector:E k) 逐字就是这段代码；
;;;       第三篇「返回答案」的 ans / Ans / ans? 与答案路径 Pᵃ = (∪ P (Ans a))
;;; 注：connector:E 为暂名（与大纲待办 1 同类）。单位是 values：普通值本来就在 Pᵃ 里。
(: connector:E (∀ (p q a) (→ (→ p (∪ q (Ans a))) (→ (∪ p (Ans a)) (∪ q (Ans a))))))
(define ((connector:E k) v) (if (ans? v) v (k v)))

;;; 原§3-b′〔验证〕 观察与复合（ans 结构体沿用第三篇，不透明，按字段观察）
(define (observe:E v) (if (ans? v) (list 'ans (ans-a v)) v))
(define ((∘E g f) x) ((connector:E g) (f x)))
(check-equal? (observe:E ((connector:E (λ (r) (* r 2))) 21)) 42)
(check-equal? (observe:E ((connector:E (λ (r) (* r 2))) (ans 0))) '(ans 0))
(define (e1 x) (if (> x 1) (ans 100) (* x 10)))
(define (e2 x) (if (> x 50) (ans 'big) (+ x 1)))
(define E-arrows (list e1 e2 values))
(for* ([x '(0 1 2 6)] [g E-arrows] [f E-arrows])
  (check-equal? (observe:E ((∘E g values) x)) (observe:E (g x)))          ; 普通值作输入
  (check-equal? (observe:E ((∘E values f) x)) (observe:E (f x)))
  (check-equal? (observe:E ((∘E g (∘ f add1)) x)) (observe:E ((∘ (∘E g f) add1) x)))
  (for ([f₃ E-arrows])
    (check-equal? (observe:E ((∘E f₃ (∘E g f)) x))
                  (observe:E ((∘E (∘E f₃ g) f) x)))))

;;; ─── 原§3-c〔正文〕 适用范围：普通结果不含 ans ───
;;; 步骤：现象（普通结果本身是 ans 时，连接器把它当成答案，g 没被调用）
;;; 回指：第一篇「从类型到逻辑」：Typed Racket 的 ∪ 不是不相交联合，须自行用谓词保证
;;; 注：按 ∘ 的写法，失效的是 (∘E g values) = g，单位写在右边；
;;;     大纲与 sketch 称「左单位律」（按 bind 的读法）。正文宜直接写等式。
(define (g:called v) 'called)
(check-equal? (observe:E ((connector:E g:called) (ans 1))) '(ans 1))
(check-equal? (g:called (ans 1)) 'called)
(check-not-equal? (observe:E ((∘E g:called values) (ans 1)))
                  (observe:E (g:called (ans 1))))


;;; ═══════════════════════════════════════════════════════════════════
;;; §4 再认 choose：捕获的延续是 Kleisli 箭头（原第五篇 §5 后半）
;;; ═══════════════════════════════════════════════════════════════════

;;; ─── §4-a〔原5§5-h·正文·等式〕 再认：reify 与 reflect，k 是 Kleisli 箭头 ───
;;; 步骤：概念（reset 为这段计算选定答案类型 (Listof q)；shift 的 k 调用时重装这层边界，
;;;       k 返回列表，正站在 ∘ℒ 里 g 的位置）
;;; 回指：§3-a 的 ∘ℒ 与 ℒ:id；原§2-g 的 connector:ℒ；第三篇规约规则 (λ (v) (reset E[v]))
;;
;; (collect thunk) = (reset (ℒ:id (thunk)))
;; (choose p*)     = (shift k ((connector:ℒ k) p*))
;;
;;; §4-a′〔验证〕
(for ([p* '((1 2 3) () (4))])
  (check-equal? (collect (λ () (+ 10 (choose p*))))
                (reset (ℒ:id (+ 10 (shift k ((connector:ℒ k) p*)))))))
;; k 返回列表：捕获后调用一次，得到的是 '(11)
(check-equal? (collect (λ () (+ 10 (shift k (k 1))))) '(11))
;; 把 k 带出边界，它仍是一支 →ℒ 箭头，可以用 ∘ℒ 复合
(define k+10 (collect (λ () (+ 10 (shift k k)))))
(check-equal? (k+10 1) '(11))
(check-equal? ((∘ℒ k+10 k+10) 1) '(21))

;;; ─── §4-b〔原5§5-i·正文〕 通用的 reflect / reify ───
;;; 步骤：代码（与 choose / collect 并排）→ 概念（这里遇到的每一个单子）
;;; 回指：原§2-g 两个世界的连接器；原§3-b connector:E；第二篇 cps:id
;;; 注：参数取「连接器」与「单位」，与 §2 的说法一致；sketch 的 bind 形式改掉了
;;;     （系列里没有 bind 这个名字）。类型要用到类型构造子 T，Typed Racket 写不出，
;;;     只在注释里给出：
;;;   reflect : (→ (→ (→ p (T q)) (→ (T p) (T q))) (→ (T p) p))  ; 在答案类型为 (T q) 的 reset 内
;;;   reify   : (→ (→ p (T p)) (→ (→ p) (T p)))
(define ((reflect connector) m) (shift k ((connector k) m)))
(define ((reify unit) thunk) (reset (unit (thunk))))

;; 并排（正文）：
;; choose  = (reflect connector:ℒ)
;; collect = (reify ℒ:id)
(check-equal?
 ((reify ℒ:id)
  (λ ()
    (let* ([a ((reflect connector:ℒ) (range 1 21))]
           [b ((reflect connector:ℒ) (range a 21))]
           [c ((reflect connector:ℒ) (range b 21))])
      (if (pyth? a b c) (list a b c) ((reflect connector:ℒ) '())))))
 '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))

;;; ─── §4-c〔原5§5-j·正文·等式〕 异常：异常分支是 abort，正常分支交给 k ───
;;; 步骤：概念
;;; 回指：第三篇 (shift _ e) = (abort e)、(shift k (k e)) = (let/lc k e)
;;
;; ((reflect connector:E) m) = (shift k (if (ans? m) m (k m)))
;;   m 是答案：(shift _ m)   = (abort m)
;;   m 是普通值：(shift k (k m)) = m
;;
;;; §4-c′〔验证〕
(check-equal? (observe:E ((reify values) (λ () (+ 1 ((reflect connector:E) (ans 42))))))
              '(ans 42))
(check-equal? (observe:E ((reify values) (λ () (+ 1 ((reflect connector:E) 41)))))
              42)
(check-equal? (observe:E ((reify values) (λ () (+ 1 (abort (ans 42))))))
              '(ans 42))

;;; §4-d〔原5§5-k·验证〕 延续单子本身：reflect cps->neg²、reify cps:id
;;; 正文若要一句「延续世界也一样」，可以取第一例。
(check-equal? (anf:eval ((reify cps:id) (λ () (+ 1 ((reflect cps->neg²) (cps:+ 2 3))))))
              6)
(check-equal? (((reify cps:id) (λ () (* 10 ((reflect cps->neg²) kk-twice)))) values)
              '(10 70))
(check-equal? (((reify cps:id) (λ () (* 10 ((reflect cps->neg²) kk-abort)))) values)
              'aborted)


;;; ═══════════════════════════════════════════════════════════════════
;;; §5 巨大单子与事故（原第五篇 §6）
;;; ═══════════════════════════════════════════════════════════════════

;;; ─── §5-a〔原5§6-a·正文，可选〕 宿主的 let* 与列表世界的 anf:let* ───
;;; 不另写代码：原§2-j 的 anf:let* 程序与 §5-c 的 let* 程序逐行对齐，
;;; 前者由宏把连接器写进展开，后者由 choose 在运行时取得 k。两者都已验证等于 triples。
;;; 回指：第四篇「两种函数」：每次调用，要么调用函数并交给它一个延续，要么把延续应用到一个值上

;;; ─── §5-b〔原5§6-b·验证〕 d1：边界认错了人 ───
;;; v1.2：第五篇以 run 1 收尾（方案 i），第六篇不再另造失败现场；本块降为验证，正文是否回指待定。
;;; 步骤：问题（用户要的是整个搜索的答案 '(boom)，在外面包了自己的 reset，从分支内中止）
;;;       → 代码 → 现象（得到混着 boom 的结果列表，第三个分支照跑，没有报错）
;;; 回指：第三篇 abort；§5-h：choose 的 k 自带边界；措辞呼应第四篇「镜子破裂」（不点名）
(check-equal?
 (reset
  (collect
   (λ ()
     (let ([x (choose '(1 2 3))])
       (if (= x 2) (abort '(boom)) x)))))
 '(1 boom 3))

;;; §5-b′〔验证〕
;; 用户的意图没有实现
(check-not-equal?
 (reset (collect (λ () (let ([x (choose '(1 2 3))]) (if (= x 2) (abort '(boom)) x)))))
 '(boom))
;; 直接写 shift 也一样（大纲原话「shift 被 choose 的 k 自带的边界截获」）
(check-equal?
 (reset (collect (λ () (let ([x (choose '(1 2 3))]) (if (= x 2) (shift _ '(boom)) x)))))
 '(1 boom 3))
;; 第三个分支照跑
(let ([log '()])
  (reset (collect (λ () (let ([x (choose '(1 2 3))])
                          (set! log (cons x log))
                          (if (= x 2) (abort '(boom)) x)))))
  (check-equal? (reverse log) '(1 2 3)))
;; 症状随位置而变（报错版可作一句旁证）
(check-exn #rx"append: contract violation"
           (λ () (reset (collect (λ () (let ([x (choose '(1 2 3))])
                                         (if (= x 2) (abort 'boom) x)))))))
(check-equal?
 (reset (collect (λ () (let ([x (choose '(1 2 3))]) (if (= x 3) (abort 'boom) x)))))
 '(1 2 . boom))


;;; ═══════════════════════════════════════════════════════════════════
;;; 第八篇素材（只验证，不进正文）
;;; ═══════════════════════════════════════════════════════════════════
;;; run : 异常 → 延续，保持单位与连接（含正常路径与非恒等观察）；
;;; A-翻译那一步 = 延续世界的连接器作用在 run 上。
(define ((run:E→C v) k) (if (ans? v) (ans-a v) (k v)))
(define observers:E (list values add1 (λ (x) (* 10 x))))
(for* ([v '(1 5)] [o observers:E])
  (check-equal? ((run:E→C (values v)) o) ((cps:id v) o)))              ; 单位
(for* ([v (list 1 3 (ans 9))] [o observers:E])
  (define (k1 x) (if (> x 2) (ans 100) (* x 10)))
  (check-equal? ((run:E→C ((connector:E k1) v)) o)                      ; 连接
                ((λ (kk) ((run:E→C v) (λ (x) ((run:E→C (k1 x)) kk)))) o)))
(define (A-step F) (λ (k) (F (λ (v) ((run:E→C v) k)))))
(for* ([F (list (λ (c) (c 3)) (λ (c) (c (ans 7))) (λ (c) (+ 1 (c 2))))]
       [o (list values (λ (x) (* 10 x)))])
  (check-equal? ((A-step F) o) (((cps->neg² run:E→C) F) o)))


;;; ═══════════════════════════════════════════════════════════════════
;;; test 子模块：运行两个宏子模块，并在源码层面核对「只换连接器一行」
;;; ═══════════════════════════════════════════════════════════════════
(module+ test
  (require (submod ".." 𝒦-let) (submod ".." ℒ-let))

  (define src (variable-reference->module-source (#%variable-reference)))
  (define body
    (parameterize ([read-accept-reader #t] [read-accept-lang #t])
      (match (call-with-input-file src read)
        [`(module ,_ ,_ (#%module-begin . ,forms)) forms]
        [`(module ,_ ,_ . ,forms) forms])))
  (define (submodule-forms name)
    (for/first ([f body] #:when (match f [`(module* ,(== name) #f . ,_) #t] [_ #f]))
      (cdddr f)))
  (define (macro-form? f)
    (and (pair? f) (memq (car f) '(define-syntax define-syntax-rule)) #t))
  (define (define-form? f)
    (and (pair? f) (eq? (car f) 'define)))
  (define 𝒦-forms (submodule-forms '𝒦-let))
  (define ℒ-forms (submodule-forms 'ℒ-let))
  ;; 四个宏在两个子模块里逐字相同
  (check-equal? (length (filter macro-form? 𝒦-forms)) 4)
  (check-equal? (filter macro-form? ℒ-forms) (filter macro-form? 𝒦-forms))
  ;; ℒ-let 比 𝒦-let 多出的定义只有连接器这一行
  (check-equal? (filter define-form? 𝒦-forms) '())
  (check-equal? (filter define-form? ℒ-forms) '((define cps->neg² connector:ℒ))))
