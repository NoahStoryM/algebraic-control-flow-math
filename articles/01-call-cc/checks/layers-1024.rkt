#lang typed/racket
;; 第一篇「层数版」大纲的类型核对（Opus 10/24，Typed Racket 8.10）。对应 math/background.md 第 10 组。
;; Typed Racket 8.10 里 ∪ 没有绑定，这里只用 →、Nothing、Rec。
(define-type (¬ p) (→ p Nothing))
;; 10.3 三重否定律
(: tne (∀ (q) (→ (¬ (¬ (¬ q))) (¬ q))))
(define ((tne kkkq) q) (kkkq (λ ([kq : (¬ q)]) (kq q))))
;; 10.4 反例：¬¬Byte → Byte 有居民
(: dne-byte (→ (¬ (¬ Byte)) Byte))
(define (dne-byte kk) 0)
;; 10.8 wait/fc 第二版接口的纯实现
(: wait2 (∀ (q) (→ (→ (¬ q) q) (¬ (¬ q)))))
(define ((wait2 proc) kq) (kq (proc kq)))
;; 第一版接口 ¬p → ¬p
(: wait1 (∀ (p) (→ (¬ p) (¬ p))))
(define (wait1 k) k)
;; 10.6 奇偶：0 与 3 层，先 DNI 再调用
(: meet03 (∀ (p) (→ p (¬ (¬ (¬ p))) Nothing)))
(define (meet03 p kkkp) (kkkp (λ ([kp : (¬ p)]) (kp p))))
;; 10.7 Label：L = ¬L，d d 有类型 ⊥
(define-type Label (Rec L (→ L Nothing)))
(: d Label)
(define (d x) (x x))
(: loop (→ Nothing))
(define (loop) (d d))
;; 标准 DNI 在 Label 上类型成立，但不是恒等函数
(: dni (∀ (p) (→ p (¬ (¬ p)))))
(define ((dni p) k) (k p))
(: dni-label (→ Label Label))
(define dni-label (inst dni Label))
(displayln 'typechecked)
