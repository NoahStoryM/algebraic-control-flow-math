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

;;; ===== 10/6 核对：Noah 的三段推导（第二篇里 ∘𝒦、anf:let*、cps->neg² 的关系） =====
(module+ test
  (require rackunit)
  ;; 观察一个 ¬¬a：交给初始延续，取回答案
  (define (run kka) (anf:eval kka))
  (define fs (list add1 (λ (x) (* x x)) (λ (x) (- 10 x)) (λ (x) (list x x))))
  (define gs (list (λ (y) (list 'three y)) (λ (y) (cons 'g y)) (λ (y) (format "~a" y)) values))
  (define xs '(0 1 2 5 -3))
  (for* ([f fs] [g gs] [x xs])
    (define neg:f (neg f)) (define neg:g (neg g))
    (define cps:f (cps f)) (define cps:g (cps g))
    (define neg²:g (neg² g))
    (define expected (g (f x)))
    ;; 第一段，逐行
    (check-equal? (run ((∘𝒦 cps:g cps:f) x)) expected)
    (check-equal? (run ((flip (∘𝒰 neg:g neg:f)) x)) expected)
    (check-equal? (run ((flip (∘ neg:f neg:g)) x)) expected)
    ;; ??? 处补的四行（带上 x 与 k）
    (check-equal? (⊥->a (((flip (∘ neg:f neg:g)) x) a->⊥)) expected)
    (check-equal? (⊥->a (((∘ neg:f neg:g) a->⊥) x)) expected)
    (check-equal? (⊥->a ((neg:f (neg:g a->⊥)) x)) expected)
    (check-equal? (⊥->a ((cps:f x) (neg:g a->⊥))) expected)
    (check-equal? (⊥->a (((neg¹ neg:g) (cps:f x)) a->⊥)) expected)
    (check-equal? (⊥->a ((neg²:g (cps:f x)) a->⊥)) expected)
    (check-equal? (run ((∘ neg²:g cps:f) x)) expected)
    ;; neg²:g 的两种来历是同一个
    (check-equal? (run ((cps->neg² cps:g) (cps:f x))) expected)
    ;; 第二段（只对 neg 的像成立）：用一个收集型的 k
    (let ([k (λ (v) (list 'k v))])
      (check-equal? (((∘ neg:f neg:g) k) x) (k expected))
      (check-equal? ((neg:f (neg:g k)) x) (k expected))
      (check-equal? ((neg:g k) (f x)) (k expected))
      (check-equal? ((∘ k g f) x) (k expected)))
    ;; 第三段，逐行
    (check-equal? (run (anf:let* ([y (cps:f x)] [z (cps:g y)]) (cps:id z))) expected)
    (check-equal? (run ((cps->neg² (λ (y) ((cps->neg² (λ (z) (cps:id z))) (cps:g y)))) (cps:f x))) expected)
    (check-equal? (run ((cps->neg² (λ (y) ((cps->neg² cps:id) (cps:g y)))) (cps:f x))) expected)
    (check-equal? (run ((cps->neg² (λ (y) ((neg² values) (cps:g y)))) (cps:f x))) expected)
    (check-equal? (run ((cps->neg² (λ (y) (cps:g y))) (cps:f x))) expected)
    (check-equal? (run ((cps->neg² cps:g) (cps:f x))) expected)
    (check-equal? (run (neg²:g (cps:f x))) expected))
  ;; ??? 那一步对 𝒦 里任意的箭头都成立，不只是 cps 的像：拿用了 cps:call/cc 的箭头试
  (define (cps:esc x) (cps:call/cc (λ (cps:k) (anf:let* ([_ (cps:k (list 'escaped x))]) (cps:id 'unreachable)))))
  (define (cps:dup x) (λ (k) (k (list x x))))
  (for* ([cps:f (list cps:esc cps:dup (cps add1))] [cps:g (list cps:dup cps:esc (cps (λ (y) (cons 'g y))))] [x '(1 2 3)])
    (define expected (run ((∘𝒦 cps:g cps:f) x)))
    (check-equal? (run ((∘ (cps->neg² cps:g) cps:f) x)) expected)
    (check-equal? (run (anf:let* ([y (cps:f x)] [z (cps:g y)]) (cps:id z))) expected)
    (check-equal? (⊥->a ((cps:f x) ((flip¹ cps:g) a->⊥))) expected))
  ;; 单位元：(cps->neg² cps:id) 是恒等（外延上），cps:id 是 ∘𝒦 的单位
  (for* ([cps:f (list cps:esc cps:dup (cps add1))] [x '(1 2 3)])
    (check-equal? (run ((cps->neg² cps:id) (cps:f x))) (run (cps:f x)))
    (check-equal? (run ((∘𝒦 cps:id cps:f) x)) (run (cps:f x)))
    (check-equal? (run ((∘𝒦 cps:f cps:id) x)) (run (cps:f x)))
    (check-equal? (run ((cps->neg² cps:f) (cps:id x))) (run (cps:f x)))))
