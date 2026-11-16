#lang racket
;; 知乎回答「miniKanren 的实现方式」的代码之二：把列表换成流，这是两本书与 microKanren 的做法。
;; 运行：racket 2-streams.rkt（Racket 9.3，不需要任何包）
;;
;; mplus、bind、take 改写自 microKanren 的 microKanren.scm 与 miniKanren-wrappers.scm：
;;   https://github.com/jasonhemann/microKanren
;;   Copyright (C) 2013 Jason Hemann and Daniel P. Friedman, MIT License（见 NOTICE）。
;; 未知项、walk、unify、reify 原样取自 1-lists.rkt。
(require (only-in "1-lists.rkt" var walk unify reify))

;; 流有三种样子：
;;   '()                 没有了
;;   (cons 代换 流)      一个答案，后面还有
;;   (λ () 流)           还没算出来；要的时候再调用
(define ((== u v) s)
  (define s1 (unify u v s))
  (if s1 (list s1) '()))

(define (mplus $1 $2)                        ; 列表版的 append
  (cond [(null? $1) $2]
        [(procedure? $1) (λ () (mplus $2 ($1)))]      ; 左边还没算出来：换右边先走
        [else (cons (car $1) (mplus (cdr $1) $2))]))

(define (bind $ g)                           ; 列表版的 append-map
  (cond [(null? $) '()]
        [(procedure? $) (λ () (bind ($) g))]
        [else (mplus (g (car $)) (bind (cdr $) g))]))

(define ((disj . g*) s) (foldr (λ (g $) (mplus (g s) $)) '() g*))
(define ((conj . g*) s) (for/fold ([$ (list s)]) ([g g*]) (bind $ g)))

(define-syntax-rule (fresh (x ...) g ...)
  (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))

;; 关系的入口处不往下算，交出一个 thunk
(define-syntax-rule (defrel (name x ...) g ...)
  (define ((name x ...) s)
    (λ () ((conj g ...) s))))

(define (take n $)
  (cond [(eqv? n 0) '()]
        [(null? $) '()]
        [(procedure? $) (take n ($))]
        [else (cons (car $) (take (and n (sub1 n)) (cdr $)))]))

(define-syntax-rule (run n (x ...) g ...)
  (let ([x (var 'x)] ...)
    (for/list ([s (take n ((conj g ...) '()))])
      (reify (list x ...) s))))

(module+ main
  (define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))
  (defrel (appendo l t out)
    (disj (conj (== l '()) (== t out))
          (fresh (a d res)
            (== l (cons a d))
            (== out (cons a res))
            (appendo d t res))))
  (show (run #f (x y) (appendo x y '(1 2 3))))

  (defrel (alwayso) (disj (== 1 1) (alwayso)))
  (show (run 3 (q) (alwayso) (== q 'again)))

  (defrel (nevero) (nevero))
  (show (run 1 (q) (disj (nevero) (== q 'here)))))
