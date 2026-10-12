#lang racket
;; 第五篇的三个定义，加三行语法（in-amb 交出列表，急切）
(require racket/control)
(provide amb for/amb in-amb)
(define (choose p*) (shift k (append-map k p*)))
(define (fail) (choose '()))
(define (collect thunk) (reset (list (thunk))))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (collect (λ () e)))
