#lang typed/racket/no-check
;; 账本 1.10：自伴随 ¬ ⊣ ¬ 的两种给法互推，以及 neg、flip 的两两复合。依赖同级目录下的文章仓库，底本 dev。
(require rackunit (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt"))
;; 由 neg 与 cps 重新得到 flip：flip h = (∘ (neg h) cps:id)，cps:id 取在 ¬q 上
(define (flip′ h) (∘ (neg h) cps:id))
(define h (λ (x) (cps:+ x 1)))
(check-equal? (anf:eval (anf:let/cc k (((flip′ h) (λ (v) (k v))) 41))) 42)
(check-equal? (anf:eval (anf:let/cc k (((flip h) (λ (v) (k v))) 41))) 42)
;; 反过来 cps = (∘ flip neg)；三种两两复合
(check-equal? (anf:eval (((∘ neg flip) h) (cps:id 1))) 2)
(check-equal? (anf:eval (((∘ neg neg) add1) (cps:id 1))) 2)
(check-equal? (anf:eval (((∘ flip neg) add1) 1)) 2)
(displayln "ok")

;; 10/17 补（Argon 指出上面只测了 𝒦 → 𝒰 一个方向）：同一个式子用在 𝒰 箭头上，
;; 就是 𝒰 → 𝒦，其中 (neg g) 正是 neg 的第二种读法 ¬q→¬p ⟶ ¬¬p→¬¬q。
(define g (neg (λ (x) (+ x 1))))            ; 一支 𝒰 箭头 ¬q → ¬p
(check-equal? (anf:eval ((flip′ g) 41)) 42)  ; (flip′ g) 是 𝒦 箭头 p → ¬¬q
(check-equal? (anf:eval ((flip g) 41)) 42)

;; 10/17 补（Sol 的反例）：答案类型取 Boolean，H(m)(k) = (not (m k)) 只运行交来的计算一次，
;; 却不是任何 𝒦 箭头落回的结果：对 m0(k) = #f，任何落回都交出 #f，H 交出 #t。
(define ((H m) k) (not (m k)))
(define (m0 k) #f)
(check-equal? ((H m0) (λ (b) b)) #t)
(check-equal? ((((∘ neg flip) (λ (x) (λ (k) (k #t)))) m0) (λ (b) b)) #f)
(displayln "ok 10/17")
