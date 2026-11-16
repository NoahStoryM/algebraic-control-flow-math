#lang typed/racket/base
;; 知乎回答「miniKanren 的实现方式」的代码之三：目标交出一张代换，别的可能由 amb 记着。
;; 运行：racket 3-amb.rkt（Racket 9.3；需要 amb 3.0 与 typed-amb 3.0）
;; 出处与许可见 0-terms.rkt 与 NOTICE。
(require racket/include typed/amb typed/amb/merge "0-terms.rkt")
(require/typed "timeout.rkt" [within-2s (→ (→ Any) Any)])

;; ---- 第三个类型 ----
(define-type Goal (→ Substitution Substitution))

(: == (→ Term Term Goal))
(define ((== u v) s)
  (or (unify u v s) (amb-fail)))

(: succeed Goal)
(define (succeed s) s)

(: fail Goal)
(define (fail s) (amb-fail))

(: disj2 (→ Goal Goal Goal))
(define ((disj2 g1 g2) s)
  ((amb g1 g2) s))

(: conj2 (→ Goal Goal Goal))
(define ((conj2 g1 g2) s)
  (g2 (g1 s)))

;; 一步一步地问这次搜索；三个分支对着 take-inf 的三个分支
(: take-amb (→ (Option Natural) (Generatorof (List Substitution)) (Listof Substitution)))
(define (take-amb n gen)
  (if (and n (zero? n))
      '()
      (let-values ([(v next) (gen)])
        (cond [(not v) '()]                                            ; 没有了
              [(pair? v) (cons (car v) (take-amb (and n (sub1 n)) next))]  ; 一个答案，后面还有
              [else (take-amb n next)]))))                             ; 暂停了 v 次

(: run-goal (→ (Option Natural) Goal (Listof Substitution)))
(define (run-goal n g)
  (take-amb n (λ () (amb-generate* (λ () (g empty-s))))))

(include "wires.rkt")

;; 关系的入口处让出一步
(define-syntax-rule (defrel (name x ...) g ...)
  (define (name [x : Term] ...) : Goal
    (λ (s) (amb-pause) ((conj g ...) s))))

;; ---- 试一试 ----
(define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))

;; amb 本身
(show (for/list : (Listof (Listof Integer))
          ([p (in-amb (let ([a (amb 1 2 3)] [b (amb 1 2 3)])
                        (unless (= (+ a b) 4) (amb-fail))
                        (list a b)))])
        p))

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
(show (run 3 q (alwayso)))

;; 左边没有尽头：默认先把左边走完
(defrel (nevero) (nevero))
(show (within-2s (λ () (run 1 q (conde [(nevero)] [(== q 'here)])))))
(show (parameterize ([current-amb-merger amb-interleave])
        (run 1 q (conde [(nevero)] [(== q 'here)]))))
(show (parameterize ([current-amb-merger amb-interleave])
        (run 4 (x y z) (appendo x y z))))

;; 换了合并的办法，可这一支从不让出
(: spino (→ Goal))
(define (spino) (λ (s) ((spino) s)))
(show (within-2s (λ () (parameterize ([current-amb-merger amb-interleave])
                         (run 1 q (conde [(spino)] [(== q 'here)]))))))

;; 一次搜索，一步一步地问
(: count-from (→ Integer Integer))
(define (count-from n)
  (amb n (begin (amb-pause) (count-from (add1 n)))))
(show (let*-values ([(v1 next) (amb-generate* (λ () (count-from 0)))]
                    [(v2 next) (next)]
                    [(v3 next) (next)])
        (list v1 v2 v3)))
(show (let*-values ([(v1 next) (amb-generate* (λ () (amb 'a)))]
                    [(v2 next) (next)])
        (list v1 v2)))

;; 「并且」的两种写法：答案相同，轮流走时先后可能不同
(: conj2/local (→ Goal Goal Goal))
(define ((conj2/local g1 g2) s) (g2 (amb-local (g1 s))))
(define x (var 'x))
(define y (var 'y))
(define three (disj2 (disj2 (== x 1) (== x 2)) (== x 3)))
(: later Goal)
(define (later s) (amb-pause) ((== y 'p) s))
(: xs (→ Goal (Listof Term)))
(define (xs g) (map (λ ([s : Substitution]) (walk x s)) (run-goal #f g)))
(parameterize ([current-amb-merger amb-interleave])
  (show (list (xs (conj2 three later))
              (xs (conj2/local three later)))))
