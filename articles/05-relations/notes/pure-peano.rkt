#lang racket
;; 试验：只用 ≡、合取、析取、fresh 定义 ≤ᵒ 与 pythᵒ（数写成 Peano 项：z、(s . n)）
;; 内核照第五篇初稿（choose / fail / collect，深度优先，一次算完）
(require racket/control)
(provide (all-defined-out))
(define (choose p*) (shift k (append-map k p*)))
(define (fail) (choose '()))
(define (collect thunk) (reset (list (thunk))))

(struct var (name))
(define empty-s (hasheq))
(define (walk t s) (if (and (var? t) (hash-has-key? s t)) (walk (hash-ref s t) s) t))
(define (occurs? x t s)
  (let ([t (walk t s)])
    (or (eq? x t) (and (pair? t) (or (occurs? x (car t) s) (occurs? x (cdr t) s))))))
(define (ext-s x t s) (if (occurs? x t s) (fail) (hash-set s x t)))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (ext-s u v s)]
          [(var? v) (ext-s v u s)]
          [(and (pair? u) (pair? v)) (unify (cdr u) (cdr v) (unify (car u) (car v) s))]
          [(equal? u v) s]
          [else (fail)])))
(define ((≡ u v) s) (unify u v s))
(define ((conj . g*) s) (foldl (λ (g s) (g s)) s g*))
(define ((disj . g*) s) ((choose g*) s))
(define-syntax-rule (fresh (x ...) g ...)
  (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))
(define (walk* t s)
  (let ([t (walk t s)]) (if (pair? t) (cons (walk* (car t) s) (walk* (cdr t) s)) t)))
(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (collect (λ () (walk* (list x ...) ((conj g ...) empty-s))))))

;; 数与项之间的转换（只在边界上用）
(define (n->p n) (if (zero? n) 'z (cons 's (n->p (sub1 n)))))
(define (p->n p) (cond [(eq? p 'z) 0] [(pair? p) (add1 (p->n (cdr p)))] [else '_]))

;; 三个纯的关系：只用 ≡、合取、析取、fresh 与递归
(define (leᵒ x y)                       ; x ≤ y
  (disj (≡ x 'z)
        (fresh (x1 y1) (≡ x (cons 's x1)) (≡ y (cons 's y1)) (leᵒ x1 y1))))
(define (plusᵒ x y z)                   ; x + y = z
  (disj (conj (≡ x 'z) (≡ y z))
        (fresh (x1 z1) (≡ x (cons 's x1)) (≡ z (cons 's z1)) (plusᵒ x1 y z1))))
(define (timesᵒ x y z)                  ; x × y = z
  (disj (conj (≡ x 'z) (≡ z 'z))
        (fresh (x1 w) (≡ x (cons 's x1)) (timesᵒ x1 y w) (plusᵒ w y z))))
(define (pythᵒ a b c)
  (fresh (a² b² c²) (timesᵒ a a a²) (timesᵒ b b b²) (timesᵒ c c c²) (plusᵒ a² b² c²)))

(define (show rows) (for/list ([r rows]) (map p->n r)))
(module+ main
  (define which (vector-ref (current-command-line-arguments) 0))
  (define L (n->p 1)) (define H (n->p 20))
  (case which
    [("small")
     (printf "3 + x = 5:      ~s\n" (show (run* (x) (plusᵒ (n->p 3) x (n->p 5)))))
     (printf "x + y = 3:      ~s\n" (show (run* (x y) (plusᵒ x y (n->p 3)))))
     (printf "x ≤ 3:          ~s\n" (show (run* (x) (leᵒ x (n->p 3)))))
     (printf "3 × 4 = z:      ~s\n" (show (run* (z) (timesᵒ (n->p 3) (n->p 4) z))))
     (printf "pyth 3 4 c:     ~s\n" (show (run* (c) (leᵒ c (n->p 10)) (pythᵒ (n->p 3) (n->p 4) c))))]
    [("reversed")   ; 先定上界那一头：c ≤ h，b ≤ c，a ≤ b，l ≤ a
     (define t0 (current-inexact-milliseconds))
     (define r (run* (a b c) (leᵒ c H) (leᵒ b c) (leᵒ a b) (leᵒ L a) (pythᵒ a b c)))
     (printf "~s\n~a ms\n" (show r) (round (- (current-inexact-milliseconds) t0)))]
    [("math-order") ; 照数学写法的顺序：l ≤ a ≤ b ≤ c ≤ h
     (printf "~s\n" (show (run* (a b c) (leᵒ L a) (leᵒ a b) (leᵒ b c) (leᵒ c H) (pythᵒ a b c))))]
    [("pyth-first") ; 先写直角条件
     (printf "~s\n" (show (run* (a b c) (pythᵒ a b c) (leᵒ L a) (leᵒ a b) (leᵒ b c) (leᵒ c H))))]))
