#lang racket
;; 核对（10/5 21:43 Noah 问）：choose 与 list->amb 是不是同一个函数
(require racket/control rackunit)
(define (choose p*) (shift k (append-map k p*)))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (reset (list e)))
(define (list->amb v*) (for/amb ([v (in-list v*)]) v))
(define (check ok?) (unless ok? (amb)))

;; 1. 放进各种上下文，两者交出的列表相同（先后、重复都相同）
(define lists '(() (1) (1 2 3) (3 1 3 2) ((1 2) (3 4)) (a a a)))
(for ([v* lists])
  (check-equal? (in-amb (list->amb v*)) (in-amb (choose v*)))
  (check-equal? (in-amb (list->amb v*)) v*)
  (check-equal? (in-amb (list 'x (list->amb v*) 'y)) (in-amb (list 'x (choose v*) 'y)))
  (for ([w* lists])
    (check-equal? (in-amb (let* ([a (list->amb v*)] [b (list->amb w*)]) (cons a b)))
                  (in-amb (let* ([a (choose v*)]    [b (choose w*)])    (cons a b))))
    ;; 混着用
    (check-equal? (in-amb (let* ([a (list->amb v*)] [b (choose w*)]) (cons a b)))
                  (in-amb (let* ([a (choose v*)] [b (list->amb w*)]) (cons a b))))))
;; 带失败的
(check-equal? (in-amb (let ([n (list->amb '(1 2 3 4 5 6))]) (check (even? n)) (* n n)))
              (in-amb (let ([n (choose    '(1 2 3 4 5 6))]) (check (even? n)) (* n n))))
;; 嵌套的 in-amb
(check-equal? (in-amb (list (list->amb '(1 2)) (in-amb (list->amb '(a b)))))
              (in-amb (list (choose '(1 2))    (in-amb (choose '(a b))))))
;; 后面的计算各走一遍，次数与先后相同
(define (trace pick)
  (define log '())
  (define r (in-amb (let* ([a (pick '(1 2))] [_ (set! log (cons (list 'a a) log))]
                           [b (pick '(x y))] [_ (set! log (cons (list 'b a b) log))])
                      (list a b))))
  (list r (reverse log)))
(check-equal? (trace list->amb) (trace choose))

;; 2. 推导的每一行（放在同一个上下文 E = (list 'x [] 'y) 里比较）
(for ([v* lists])
  (define-syntax-rule (E e) (in-amb (list 'x e 'y)))
  (define l1 (E (list->amb v*)))
  (define l2 (E (for/amb ([v (in-list v*)]) v)))
  (define l3 (E ((choose (for/list ([v (in-list v*)]) (λ () v))))))
  (define l4 (E ((choose (map (λ (v) (λ () v)) v*)))))
  (define l5 (E ((shift k (append-map k (map (λ (v) (λ () v)) v*))))))
  (define l6 (E (shift k (append-map (λ (t) (k (t))) (map (λ (v) (λ () v)) v*)))))   ; 「调用一次」并进延续
  (define l7 (E (shift k (append-map (λ (v) (k ((λ () v)))) v*))))
  (define l8 (E (shift k (append-map k v*))))
  (define l9 (E (choose v*)))
  (for ([l (list l2 l3 l4 l5 l6 l7 l8 l9)]) (check-equal? l l1)))
(displayln "ok")
