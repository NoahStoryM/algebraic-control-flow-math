#lang typed/racket/base
;; 知乎回答「miniKanren 的实现方式」的代码之二：目标交出流，《The Reasoned Schemer》第二版的做法。
;; 运行：racket 2-streams.rkt（Racket 9.3，不需要任何包）
;; append-inf、append-map-inf、take-inf、defrel 改写自第二版的代码；出处与许可见 0-terms.rkt 与 NOTICE。
(require racket/include "0-terms.rkt")
(require/typed "timeout.rkt" [within-2s (→ (→ Any) Any)])

;; ---- 流：空；一个答案，后面还有；还没算出来 ----
(define-type (Streamof a) (∪ Null (Pair a (Streamof a)) (→ (Streamof a))))

;; ---- 第三个类型 ----
(define-type Goal (→ Substitution (Streamof Substitution)))

(: == (→ Term Term Goal))
(define ((== u v) s)
  (let ([s (unify u v s)])
    (if s (list s) '())))

(: succeed Goal)
(define (succeed s) (list s))

(: fail Goal)
(define (fail s) '())

(: append-inf (→ (Streamof Substitution) (Streamof Substitution) (Streamof Substitution)))
(define (append-inf s-inf t-inf)
  (cond [(null? s-inf) t-inf]
        [(pair? s-inf) (cons (car s-inf) (append-inf (cdr s-inf) t-inf))]
        [else (λ () (append-inf t-inf (s-inf)))]))

(: append-map-inf (→ Goal (Streamof Substitution) (Streamof Substitution)))
(define (append-map-inf g s-inf)
  (cond [(null? s-inf) '()]
        [(pair? s-inf) (append-inf (g (car s-inf)) (append-map-inf g (cdr s-inf)))]
        [else (λ () (append-map-inf g (s-inf)))]))

(: take-inf (→ (Option Natural) (Streamof Substitution) (Listof Substitution)))
(define (take-inf n s-inf)
  (cond [(and n (zero? n)) '()]
        [(null? s-inf) '()]
        [(pair? s-inf) (cons (car s-inf) (take-inf (and n (sub1 n)) (cdr s-inf)))]
        [else (take-inf n (s-inf))]))

(: disj2 (→ Goal Goal Goal))
(define ((disj2 g1 g2) s)
  (append-inf (g1 s) (g2 s)))

(: conj2 (→ Goal Goal Goal))
(define ((conj2 g1 g2) s)
  (append-map-inf g2 (g1 s)))

(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (take-inf n (g empty-s)))

(include "wires.rkt")

;; 关系的入口处不往下算，交出一个 thunk
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) (λ () ((conj g ...) s)))))

;; ---- 试一试 ----
(define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))

(defrel (appendo l t out)
  (conde
    [(== l '()) (== t out)]
    [(fresh (a d res)
       (== l (cons a d))
       (== out (cons a res))
       (appendo d t res))]))
(show (run* (x y) (appendo x y '(1 2 3))))

(defrel (alwayso)
  (conde [succeed] [(alwayso)]))

;; 流本身：先是一个还没算的函数；调用它，得到一个答案和接着取的函数
(define s0 ((alwayso) empty-s))
(show (procedure? s0))
(define s1 (if (procedure? s0) (s0) s0))
(show (and (pair? s1) (list (car s1) (procedure? (cdr s1)))))

(show (run 3 q (alwayso)))
(show (run 4 (x y z) (appendo x y z)))

;; 左边没有尽头，一个答案也不交
(defrel (nevero) (nevero))
(show (run 1 q (conde [(nevero)] [(== q 'here)])))
;; 两边都没有答案：轮流走也等不到
(show (within-2s (λ () (run 1 q (conde [(nevero)] [(nevero)])))))
