#lang racket/base
;; 第七篇素材（Claude 10/15 草，#21）：状态与异常各用一个 prompt-tag，两种嵌套，结果不同。
;; tag 都没认错，边界怎样嵌套就是在选择效应之间怎样相互作用。Racket 8.10 实测。
(require racket/control rackunit)

(define st (make-continuation-prompt-tag 'state))
(define ex (make-continuation-prompt-tag 'exn))

;; 状态：答案类型是「等着状态的函数」
(define (run-state thunk s0)
  ((reset-at st (let ([v (thunk)]) (λ (s) (cons v s)))) s0))
(define (get)    (shift-at st k (λ (s) ((k s) s))))
(define (put s1) (shift-at st k (λ (s) ((k (void)) s1))))

;; 异常：答案类型是「正常值或错误」
(define (run-exn thunk) (reset-at ex (cons 'ok (thunk))))
(define (raise* e) (shift-at ex k (cons 'err e)))

(define (prog) (put 1) (raise* 'e) (get))

;; 状态在外、异常在内：失败了，状态还在
(define a (run-state (λ () (run-exn prog)) 0))
;; 异常在外、状态在内：失败了，状态一起丢掉
(define b (run-exn (λ () (run-state prog 0))))

(printf "state outside: ~s\nexn outside:   ~s\n" a b)
(check-equal? a '((err . e) . 1))
(check-equal? b '(err . e))

;; 没有异常时两种嵌套一致（只是外形不同）
(define (prog2) (put 1) (+ (get) 41))
(check-equal? (run-state (λ () (run-exn prog2)) 0) '((ok . 42) . 1))
(check-equal? (run-exn (λ () (run-state prog2 0))) '(ok . (42 . 1)))
