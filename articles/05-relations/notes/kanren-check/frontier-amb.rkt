#lang racket
;; 把调用 k 的事交给边界上的循环（in-amb 交出惰性的流）；同 notes/amb-sketches.rkt 第二部分
(require racket/control racket/stream)
(provide amb for/amb in-amb)
(define (make-todo k alts)
  (λ ()
    (and (not (stream-empty? alts))
         (let ([p (stream-first alts)])
           (set! alts (stream-rest alts))
           (k p)))))
(define (choose p*) (shift k (make-todo k p*)))
(define (in-amb* thunk)
  (define root (make-todo (λ (_) (reset (list (thunk)))) '(start)))
  (let loop ([todo* (list root)])
    (if (null? todo*)
        empty-stream
        (let ([r ((car todo*))])
          (cond
            [(not r) (loop (cdr todo*))]
            [(procedure? r) (loop (cons r todo*))]
            [else (stream-cons (car r) (loop todo*))])))))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/stream clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (in-amb* (λ () e)))
