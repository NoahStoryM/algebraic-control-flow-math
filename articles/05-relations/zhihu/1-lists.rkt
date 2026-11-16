#lang typed/racket/base
;; 知乎回答「miniKanren 的实现方式」的代码之一：目标交出列表。
;; 运行：racket 1-lists.rkt（Racket 9.3，不需要任何包）
;; 名字照《The Reasoned Schemer》第二版；出处与许可见 0-terms.rkt 与 NOTICE。
(require racket/list racket/include "0-terms.rkt")
(require/typed "timeout.rkt" [within-2s (→ (→ Any) Any)])

;; ---- 第三个类型 ----
(define-type Goal (→ Substitution (Listof Substitution)))

(: == (→ Term Term Goal))
(define ((== u v) s)
  (let ([s (unify u v s)])
    (if s (list s) '())))

(: succeed Goal)
(define (succeed s) (list s))

(: fail Goal)
(define (fail s) '())

(: disj2 (→ Goal Goal Goal))
(define ((disj2 g1 g2) s)
  (append (g1 s) (g2 s)))

(: conj2 (→ Goal Goal Goal))
(define ((conj2 g1 g2) s)
  (append-map g2 (g1 s)))

(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (let ([s* (g empty-s)])
    (if (and n (< n (length s*))) (take s* n) s*)))

(include "wires.rkt")

;; 关系的主体等代换来了才展开
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) ((conj g ...) s))))

;; ---- 试一试 ----
(define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))
(define x (var 'x))
(define y (var 'y))
(show (walk x (list (cons y 5) (cons x y))))
(show (unify (list x 2) (list 1 y) empty-s))
(show (unify (list x 2) (list 1 x) empty-s))
(show (unify x (list x) empty-s))

(show ((== x 1) empty-s))
(show ((disj2 (== x 1) (== x 2)) empty-s))
(show ((conj2 (disj2 (== x 1) (== x 2)) (== y x)) empty-s))
(show ((conj2 (== x 1) (== x 2)) empty-s))
(show (succeed empty-s))
(show (fail empty-s))

(defrel (appendo l t out)
  (conde
    [(== l '()) (== t out)]
    [(fresh (a d res)
       (== l (cons a d))
       (== out (cons a res))
       (appendo d t res))]))
(show (run* z (appendo '(1 2) '(3) z)))
(show (run* (x y) (appendo x y '(1 2 3))))
(show (run* (x y) (== x y)))
(show (run* (x y) (== x x)))

;; 第二层：定住几列，读出另外几列
(: split (→ Term (Listof Term)))
(define (split out) (run* (x y) (appendo x y out)))
(: join (→ Term Term (Listof Term)))
(define (join l t) (run* z (appendo l t z)))
(show (split '(1 2 3)))
(show (join '(1 2) '(3)))

;; { x | ∃y. (y = 5 ∨ y = 6) ∧ y = x }
(defrel (P x y)
  (conde [(== y 5)] [(== y 6)])
  (== y x))
(show (run* x (fresh (y) (P x y))))

;; 写不完的答案：列表要收齐才交得出
(defrel (alwayso)
  (conde [succeed] [(alwayso)]))
(show (within-2s (λ () (run 3 q (alwayso)))))
(show (within-2s (λ () (run 4 (x y z) (appendo x y z)))))
