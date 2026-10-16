#lang typed/racket/no-check
;; 10/16 两份独立评审里的验证代码：Astra 的（原样）与 Argon 的（最后一条去掉多余的一层括号）。
;; 依赖同级目录下的文章仓库，底本 dev。Racket 8.10。
(require rackunit racket/port (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt"))
;; Astra
(define extend (∘ neg flip))
(define m (cps:id 3))
(check-equal? (anf:eval ((neg² add1) m)) 4)
(check-equal? (anf:eval ((extend (cps add1)) m)) 4)
(check-equal? (anf:eval ((extend (cps add1)) m)) (anf:eval (anf:let* ([x m]) ((cps add1) x))))
(check-true (procedure? (anf:eval ((neg² (cps add1)) m))))
(define shared (extend (λ (v) (cps:+ v v))))
(define ((repeated m) k) (m (λ (a) (m (λ (b) (k (+ a b)))))))
(define (probe k) (display "!") (k 1))
(define (observe transform) (with-output-to-string (λ () (check-equal? (anf:eval (transform probe)) 2))))
(check-equal? (observe shared) "!")
(check-equal? (observe repeated) "!!")
;; Argon
(define cps->neg² (∘ neg flip))
(define (ext-via-K cps:kv) (define (id-K kkp) kkp) (∘𝒦 cps:kv id-K))
(let ([kkv (cps:+ 1 2)] [cps:kv (λ (v) (cps:* v 3))])
  (check-equal? (anf:eval ((cps->neg² cps:kv) kkv)) 9)
  (check-equal? (anf:eval ((ext-via-K cps:kv) kkv)) 9))
(let ([kkv (cps:+ 1 2)] [f (λ (x) (* x 3))] [g (λ (y) (+ y 10))])
  (check-equal? (anf:eval ((neg² f) kkv)) (anf:eval (((∘ cps->neg² cps) f) kkv)))
  (check-equal? (anf:eval ((neg² id) kkv)) 3)
  (check-equal? (anf:eval ((neg² (∘ g f)) kkv)) (anf:eval ((∘ (neg² g) (neg² f)) kkv))))
(displayln "astra+argon ok")
