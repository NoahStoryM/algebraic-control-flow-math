#lang racket/base
;; Racket 自带的 sequence-generate*：一个值的列表，和接着取的函数。
(require racket/sequence)
(define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))
(define-values (v1 next1) (sequence-generate* (in-naturals)))
(define-values (v2 next2) (next1))
(define-values (v3 next3) (next2))
(show (list v1 v2 v3))
(define-values (w1 more1) (sequence-generate* '(a)))
(define-values (w2 more2) (more1))
(show (list w1 w2))
