#lang typed/racket/no-check

(provide (all-defined-out))

(define ∘ compose)
(define (list->values v*) (apply values v*))


;;; 类型别名

(define-type ⊥ (∪))
(define-type (¬  a) (→ a ⊥))
(define-type (¬¬ a) (¬ (¬ a)))
(define-type (← q p) (→ p q))


;;; 答案类型（通过 raise 实现初始延续）

(struct (r) ans ([a* : (Listof r)]) #:type-name Ans)
(: a->⊥ (∀ (a) (¬ a)))
(define (a->⊥ . a*) (raise (ans a*)))
(define-syntax-rule (⊥->a exp)
  (with-handlers ([ans? (∘ list->values ans-a*)]) exp))


;;; 宿主世界

(define-type (→𝒟 p q) (→ p q))
(define-type (→𝒞 p q) (→ p q))

(: inj (∀ (p q) (→ (→𝒟 p q) (→𝒞 p q))))
(define (inj f) f)

;;; 逆否世界

(define-type (→𝒰 p q) (← (¬ p) (¬ q)))
(define-type (¬𝒰 p)   (→𝒰 p ⊥))

(: neg (∀ (p q) (→ (→𝒞 p q) (→𝒰 p q))))
(: neg¹ (∀ (p q) (→ (→𝒰 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define ((neg f) kq) (∘ kq f))
(define neg¹ neg)

(: ∘𝒰 (∀ (p ...) (→ (→𝒰 pn-1 pn) ... (→𝒰 p1 p2) (→𝒰 p1 pn))))
(define (∘𝒰 . neg:f*) (apply ∘ (reverse neg:f*)))


;;; CPS 世界

(define-type (→𝒦 p q) (→ p (¬¬ q)))
(define-type (¬𝒦 p)   (→𝒦 p ⊥))

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


;;; Clavius 律

(: neg:call/cc  (∀ (p) (→𝒰 (→𝒰 (¬𝒰 p) p) p)))
(: cps:call/cc  (∀ (p) (→𝒦 (→𝒦 (¬𝒦 p) p) p)))

(define ((neg:call/cc kp) neg:proc) ((neg:proc kp) (neg kp)))
(define ((cps:call/cc cps:proc) kp) ((cps:proc (cps kp)) kp))


;;; 否定翻译

(: neg² (∀ (p q) (→ (→𝒞 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define neg² (∘ neg¹ neg))

(: cps->neg² (∀ (p q) (→ (→𝒦 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define cps->neg² (∘ neg¹ flip¹))


;;; anf: 宏

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

(define-syntax-rule (anf:let/cc cps:k b* ...)
  (cps:call/cc (λ (cps:k) b* ...)))


;;; 解释器

(: anf:eval (∀ (a) (→ (¬¬ a) a)))
(define (anf:eval kka) (⊥->a (kka a->⊥)))


;;; CPS 提升的基本操作

(define cps:id        (cps values))
(define cps:+         (cps +))
(define cps:*         (cps *))
(define cps:zero?     (cps zero?))
(define cps:car       (cps car))
(define cps:cdr       (cps cdr))
(define cps:null?     (cps null?))
(define cps:display   (cps display))
(define cps:displayln (cps displayln))

;;; ===== 10/6 16:57 核对：新版第二篇新增的各段化简，逐行 =====
(module+ test
  (require rackunit)
  (define (run kka) (anf:eval kka))
  (define (obs thunk) (⊥->a (thunk)))
  ;; 手写的 fact/k（第一版，非尾递归）与 fib/k
  (define (fact/k n k) (if (= n 0) (k 1) (fact/k (- n 1) (λ (v) (k (* n v))))))
  (define (fib/k n k) (if (< n 2) (k n) (fib/k (- n 1) (λ (v) (fib/k (- n 2) (λ (w) (k (+ v w))))))))
  (check-equal? (⊥->a (fact/k 5 a->⊥)) 120)
  (check-equal? (⊥->a (fib/k 10 a->⊥)) 55)

  ;; 「否定的层次」：接两次
  (define fs (list add1 (λ (x) (* x x)) (λ (x) (- 10 x))))
  (define gs (list (λ (y) (list 'three y)) (λ (y) (cons 'g y)) values))
  (define xs '(0 1 2 5 -3))
  (for* ([f fs] [g gs] [x xs])
    (define k (λ (v) (list 'k v)))
    (define e (k (g (f x))))
    (check-equal? (((∘ (neg f) (neg g)) k) x) e)
    (check-equal? (((neg f) ((neg g) k)) x) e)
    (check-equal? (((neg g) k) (f x)) e)
    (check-equal? ((∘ k g f) x) e))
  ;; (fact/k 3 k) 递归到底时手里的延续：记录下来，与 (∘ k mul3 mul2 mul1) 比较
  (let ()
    (define bottom #f)
    (define (fact/k* n k) (if (= n 0) (begin (set! bottom k) (k 1)) (fact/k* (- n 1) (λ (v) (k (* n v))))))
    (define k (λ (v) (list 'k v)))
    (check-equal? (fact/k* 3 k) '(k 6))
    (define mul3 (λ (v) (* 3 v))) (define mul2 (λ (v) (* 2 v))) (define mul1 (λ (v) (* 1 v)))
    (for ([v '(1 2 7 -4)])
      (check-equal? (bottom v) ((∘ k mul3 mul2 mul1) v))
      (check-equal? (bottom v) ((∘ k (λ (v) (* 3 v)) (λ (v) (* 2 v)) (λ (v) (* 1 v))) v))))

  ;; 「三种箭头」与「否定翻译」：任意的 𝒦 箭头（包括用了 cps:call/cc 的）
  (define (cps:esc x) (cps:call/cc (λ (cps:k) (anf:let* ([_ (cps:k (list 'escaped x))]) (cps:id 'unreachable)))))
  (define (cps:dup x) (λ (k) (k (list x x))))
  (define cps:fs (list cps:esc cps:dup (cps add1) (cps (λ (x) (list x 'f)))))
  (define cps:gs (list cps:dup cps:esc (cps (λ (y) (cons 'g y)))))
  (for* ([cps:f cps:fs] [cps:g cps:gs] [x '(1 2 3)])
    (define neg:f (flip¹ cps:f)) (define neg:g (flip¹ cps:g))
    (define neg²:g (cps->neg² cps:g))
    (define k a->⊥)
    (define e (obs (λ () (((∘𝒦 cps:g cps:f) x) k))))
    (check-equal? (obs (λ () (((flip (∘𝒰 neg:g neg:f)) x) k))) e)
    (check-equal? (obs (λ () (((flip (∘ neg:f neg:g)) x) k))) e)
    (check-equal? (obs (λ () (((∘ neg:f neg:g) k) x))) e)
    (check-equal? (obs (λ () ((neg:f (neg:g k)) x))) e)
    (check-equal? (obs (λ () ((cps:f x) (neg:g k)))) e)
    (check-equal? (obs (λ () ((cps:f x) (λ (y) ((cps:g y) k))))) e)
    ;; 换一个方向
    (check-equal? (obs (λ () (((neg¹ neg:g) (cps:f x)) k))) e)
    (check-equal? (obs (λ () ((neg²:g (cps:f x)) k))) e)
    (check-equal? (obs (λ () (((∘ neg²:g cps:f) x) k))) e)
    ;; anf:let* 一段，逐行
    (check-equal? (run (anf:let* ([y (cps:f x)] [z (cps:g y)]) (cps:id z))) e)
    (check-equal? (run ((cps->neg² (λ (y) ((cps->neg² (λ (z) (cps:id z))) (cps:g y)))) (cps:f x))) e)
    (check-equal? (run ((cps->neg² (λ (y) ((cps->neg² cps:id) (cps:g y)))) (cps:f x))) e)
    (check-equal? (run ((cps->neg² (λ (y) ((neg² values) (cps:g y)))) (cps:f x))) e)
    (check-equal? (run ((cps->neg² (λ (y) (cps:g y))) (cps:f x))) e)
    (check-equal? (run ((cps->neg² cps:g) (cps:f x))) e)
    (check-equal? (run (neg²:g (cps:f x))) e)
    (check-equal? (run ((∘ neg²:g cps:f) x)) e)
    ;; 单个绑定：(anf:let* ([v e]) b) = ((cps->neg² (λ (v) b)) e)
    (check-equal? (run (anf:let* ([v (cps:f x)]) (cps:g v))) (run ((cps->neg² (λ (v) (cps:g v))) (cps:f x))))
    ;; 正文没写、但「连同它们的复合」隐含的一条：搬运保持复合
    (check-equal? (run ((cps->neg² (∘𝒦 cps:g cps:f)) (cps:id x))) (run ((∘ (cps->neg² cps:g) (cps->neg² cps:f)) (cps:id x)))))
  ;; (1 + 2) × 3 的例子与它的展开
  (check-equal? (run (anf:let* ([v (cps:+ 1 2)]) (cps:* v 3))) 9)
  (check-equal? (run (let ([kkv (cps:+ 1 2)]) (define (cps:kv v) (cps:* v 3)) (define neg²:kv (cps->neg² cps:kv)) (neg²:kv kkv))) 9)
  ;; 宿主的 let* 一段
  (for* ([f fs] [g gs] [x xs])
    (define e ((∘ g f) x))
    (check-equal? (let* ([y (f x)] [z (g y)]) z) e)
    (check-equal? ((λ (y) ((λ (z) z) (g y))) (f x)) e)
    (check-equal? ((λ (y) (g y)) (f x)) e)
    (check-equal? (g (f x)) e))
  ;; 「计算的位置」：kp = ((neg f) kq) = (∘ kq f)，以及 fib 的四个位置
  (define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
  (for ([n '(2 3 6 9)])
    (define k (λ (v) (list 'exit v)))
    (define n-1 (- n 1)) (define v (fib n-1)) (define n-2 (- n 2))
    (define k-w   ((neg (λ (w) (+ v w))) k))
    (define k-n-2 ((neg fib) k-w))
    (check-equal? (k-w (fib n-2)) (k (fib n)))
    (check-equal? (k-n-2 n-2) (k (fib n)))
    (check-equal? (k-n-2 n-2) (k-w (fib n-2))))   ; (kp p) = (kq (f p))
  ;; mul 与阴阳（只取前若干字符）
  (check-equal?
   (anf:eval (anf:let/cc cps:return
     (let cps:loop ([r* '(1 2 0 3 4)])
       (anf:if (cps:null? r*) (cps:*)
               (anf:let* ([r (cps:car r*)])
                 (anf:if (cps:zero? r) (cps:return r)
                         (anf:let* ([r* (cps:cdr r*)] [res (cps:loop r*)]) (cps:* res r))))))))
   0))
