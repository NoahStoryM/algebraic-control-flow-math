#lang racket
;; issue #70：用第五章正文自己的 amb（choose 加 reset，in-amb 先收齐）核对
;; 「合取是直接复合」与「合取是局部 bind」在本章条件下交出同一张列表。
;; Racket 9.3；运行：LC_ALL=C.UTF-8 racket issue70-ch5-own.rkt
(require racket/control)

(define (choose p*) (shift k (append-map k p*)))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (reset (list e)))
(define (list->amb v*) (for/amb ([v (in-list v*)]) v))
(define (scatter f) (compose list->amb f))
(define ((gather g) . x*) (in-amb (apply g x*)))

(struct var (name) #:transparent)
(define (walk t s) (define p (and (var? t) (assq t s))) (if p (walk (cdr p) s) t))
(define (walk* t s) (let ([t (walk t s)]) (if (pair? t) (cons (walk* (car t) s) (walk* (cdr t) s)) t)))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(and (var? u) (eq? u v)) s]
          [(var? u) (cons (cons u v) s)]
          [(var? v) (cons (cons v u) s)]
          [(and (pair? u) (pair? v)) (unify (cdr u) (cdr v) (unify (car u) (car v) s))]
          [(equal? u v) s]
          [else (amb)])))
(define (reify t)
  (define (name t s)
    (let ([t (walk t s)])
      (cond [(var? t) (cons (cons t (string->symbol (format "_.~a" (length s)))) s)]
            [(pair? t) (name (cdr t) (name (car t) s))]
            [else s])))
  (walk* t (name t '())))
(define ((== u v) s) (unify u v s))
(define (succeed s) s)
(define ((disj . g*) s) ((list->amb g*) s))

;; 两种合取。conj 是参数，其余代码共用。
(define (conj/compose . g*) (apply compose (reverse g*)))
(define ((conj2/local g1 g2) s) (g2 (list->amb (in-amb (g1 s)))))   ; = (g2 ((scatter (gather g1)) s))
(define (conj/local . g*) (if (null? g*) succeed (foldl (λ (g acc) (conj2/local acc g)) (car g*) (cdr g*))))

(define current-conj (make-parameter conj/compose))
(define (conj . g*) (λ (s) ((apply (current-conj) g*) s)))
(define-syntax-rule (fresh (x ...) g ...) (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))
(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...) (in-amb (reify (walk* (list x ...) ((conj g ...) '()))))))

(define (appendᵒ l t out)
  (disj (conj (== l '()) (== t out))
        (fresh (a d res) (== l (cons a d)) (== out (cons a res)) (appendᵒ d t res))))
(define (memberᵒ x l)
  (fresh (a d) (== l (cons a d)) (disj (== x a) (memberᵒ x d))))

(define-syntax-rule (both e)
  (let ([a (parameterize ([current-conj conj/compose]) e)]
        [b (parameterize ([current-conj conj/local]) e)])
    (printf "~a\n  复合: ~s\n  局部: ~s\n  相同: ~a\n" 'e a b (equal? a b))))

(both (run* (x y) (appendᵒ x y '(1 2 3))))
(both (run* (x y z) (appendᵒ x y '(1 2)) (appendᵒ y z '(2 2))))
;; 有重复答案、合取套析取、析取套合取
(both (run* (x y) (disj (== x 1) (== x 2) (== x 1)) (disj (== y 'a) (== y 'b))))
(both (run* (x y) (memberᵒ x '(1 2 1)) (memberᵒ y '(a b)) (disj (== x 1) (== y 'b))))

;; 分配律，先后与重复都算（按列表比）
(define-syntax-rule (same? e1 e2) (printf "~a\n" (equal? e1 e2)))
(for ([c (list conj/compose conj/local)] [n '(复合 局部)])
  (parameterize ([current-conj c])
    (define x (var 'x)) (define y (var 'y))
    (define a (== x 1)) (define b (== x 2)) (define g (disj (== y 'p) (== y 'q)))
    (define (ans goal) (in-amb (reify (walk* (list x y) (goal '())))))
    (printf "~a 左分配 (conj (disj a b) g) = (disj (conj a g) (conj b g)): ~a\n" n
            (equal? (ans (conj (disj a b) g)) (ans (disj (conj a g) (conj b g)))))
    (printf "~a 右分配 (conj g (disj a b)) = (disj (conj g a) (conj g b)): ~a  ~s / ~s\n" n
            (equal? (ans (conj g (disj a b))) (ans (disj (conj g a) (conj g b))))
            (ans (conj g (disj a b))) (ans (disj (conj g a) (conj g b))))))
