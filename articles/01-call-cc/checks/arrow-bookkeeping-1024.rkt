#lang racket/base
;; 第二篇大纲 7.3 的旧素材：箭头 N_i → N_j 记作 (i . j)。对应 math/background.md 10.9。
;; cps: (i, j+2)；neg: (j+1, i+1)；flip: (j-1, i+1)，要求 j ≥ 1（交换的是柯里化的两个参数）。
;; 只从 id = (0 . 0) 出发、只用这三个变换，列出总层数不超过 4 的结果，看 (2 . 0) 在不在里面。
(require racket/set racket/list)
(define (cps p) (cons (car p) (+ (cdr p) 2)))
(define (neg p) (cons (+ (cdr p) 1) (+ (car p) 1)))
(define (flip p) (and (>= (cdr p) 1) (cons (- (cdr p) 1) (+ (car p) 1))))
(define (total p) (+ (car p) (cdr p)))
(define reached
  (let loop ([seen (set '(0 . 0))] [frontier '((0 . 0))])
    (define new
      (for*/list ([p frontier] [f (list cps neg flip)]
                  #:when (f p)
                  #:unless (set-member? seen (f p))
                  #:when (<= (total (f p)) 12))
        (f p)))
    (if (null? new) seen (loop (set-union seen (list->set new)) (remove-duplicates new)))))
(sort (filter (λ (p) (<= (total p) 4)) (set->list reached))
      (λ (a b) (or (< (car a) (car b)) (and (= (car a) (car b)) (< (cdr a) (cdr b))))))
(set-member? reached '(2 . 0)) ; #f：这套生成办法得不到 DNE 的接口；不是对所有纯 λ 项的不可能性证明
