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
