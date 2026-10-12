#lang racket
(require racket/control)
;; 第五篇的三个定义
(define (choose p*) (shift k (append-map k p*)))
(define (fail) (choose '()))
(define (collect thunk) (reset (list (thunk))))
;; ℛ：用 amb 的过程当作关系；conj 是普通复合，disj 是 amb
(define ((conj . g*) s) (foldl (λ (g s) (g s)) s g*))
(define ((disj . g*) s) ((choose g*) s))
(define (run g s) (collect (λ () (g s))))
;; 三个多结果的小目标（状态就是一个列表，往前面添东西）
(define g1 (λ (s) (cons (choose '(a b)) s)))
(define g2 (λ (s) (cons (choose '(c d)) s)))
(define h  (λ (s) (cons (choose '(x y)) s)))
(define (show name v) (printf "~a\n  ~s\n" name v))
;; 左侧分配：先 disj 后 h
(show "(conj (disj g1 g2) h)"           (run (conj (disj g1 g2) h) '()))
(show "(disj (conj g1 h) (conj g2 h))"  (run (disj (conj g1 h) (conj g2 h)) '()))
;; 右侧分配：先 h 后 disj
(show "(conj h (disj g1 g2))"           (run (conj h (disj g1 g2)) '()))
(show "(disj (conj h g1) (conj h g2))"  (run (disj (conj h g1) (conj h g2)) '()))
(define (same-set? a b) (equal? (list->set a) (list->set b)))
(printf "左侧逐字相同: ~a\n" (equal? (run (conj (disj g1 g2) h) '()) (run (disj (conj g1 h) (conj g2 h)) '())))
(printf "右侧逐字相同: ~a；作为集合相同: ~a\n"
        (equal? (run (conj h (disj g1 g2)) '()) (run (disj (conj h g1) (conj h g2)) '()))
        (same-set? (run (conj h (disj g1 g2)) '()) (run (disj (conj h g1) (conj h g2)) '())))
;; 单位与零
(printf "(conj) 是单位: ~a   (disj) 是零: ~a   零吸收: ~a ~a\n"
        (equal? (run (conj (conj) g1) '()) (run g1 '()))
        (equal? (run (disj (disj) g1) '()) (run g1 '()))
        (run (conj (disj) g1) '()) (run (conj g1 (disj)) '()))
;; 幂等与交换只在集合意义下成立
(printf "(disj g1 g1): ~s\n(disj g2 g1): ~s\n" (run (disj g1 g1) '()) (run (disj g2 g1) '()))
