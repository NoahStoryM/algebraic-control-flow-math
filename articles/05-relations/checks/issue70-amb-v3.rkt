#lang racket
;; issue #70：在 amb v3（master，11/16）上比较两种合取，并核对几条关于暂停与合并的说法。
;; Racket 9.3；运行：LC_ALL=C.UTF-8 racket issue70-amb-v3.rkt
(require amb amb/merge racket/stream)

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
          [else (amb-fail)])))
(define ((== u v) s) (unify u v s))
(define ((disj g1 g2) s) ((amb g1 g2) s))
(define ((conj/compose g1 g2) s) (g2 (g1 s)))
(define ((conj/local   g1 g2) s) (g2 (amb-local (g1 s))))
(define current-conj (make-parameter conj/compose))
(define ((conj g1 g2) s) (((current-conj) g1 g2) s))
(define ((pause g) s) (amb-pause) (g s))          ; 关系入口处的暂停

(define x (var 'x)) (define y (var 'y))
(define (answers goal [n #f])
  (define st (in-amb (walk* (list x y) (goal '()))))
  (stream->list (if n (stream-take st n) st)))

(define a (pause (== x 1))) (define b (== x 2))
(define g (disj (pause (== y 'p)) (== y 'q)))
(define lhs (λ () (conj (disj a b) g)))
(define rhs (λ () (disj (conj a g) (conj b g))))

(for* ([m (list amb-append amb-interleave amb-alternate amb-level)]
       [c (list conj/compose conj/local)])
  (parameterize ([current-amb-merger m] [current-conj c])
    (define l (answers (lhs))) (define r (answers (rhs)))
    (printf "~a ~a\n  (conj (disj a b) g)            ~s\n  (disj (conj a g) (conj b g))   ~s  相同: ~a\n"
            (object-name m) (object-name c) l r (equal? l r))))

;; 两种合取之间：amb-append 下同序；amb-interleave 下，上面的例子分不开，
;; 下面这个最小的例子（穷举小目标找到的）分得开：三个备选嵌成 ((a1 a2) a3)，后一个目标入口处暂停。
(define (x= v) (== x v))
(define a3 (disj (disj (x= 1) (x= 2)) (x= 3)))
(define g1 (pause (== y 'p)))
(for ([m (list amb-append amb-interleave)])
  (parameterize ([current-amb-merger m])
    (define c (parameterize ([current-conj conj/compose]) (answers (conj a3 g1))))
    (define l (parameterize ([current-conj conj/local])   (answers (conj a3 g1))))
    (define d (parameterize ([current-conj conj/local])
                (answers (disj (disj (conj (x= 1) g1) (conj (x= 2) g1)) (conj (x= 3) g1)))))
    (printf "~a\n  复合 ~s\n  局部 ~s\n  局部、把合取分配进去以后 ~s\n" (object-name m) c l d)))

;; 「只要第一组」：v3 的 in-amb 是惰性的流，默认的 amb-append 就够，不需要暂停
(define (nat n) (amb n (nat (add1 n))))
(printf "第一组（amb-append，无暂停）: ~s\n" (stream-first (in-amb (nat 0))))

;; 「轮流走」：左支没有尽头
(define (forever/pause) (amb-pause) (forever/pause))
(define (forever) (forever))
(define (try label thunk)
  (define ch (make-channel))
  (define th (thread (λ () (channel-put ch (thunk)))))
  (define v (sync/timeout 2 ch))
  (unless v (kill-thread th))
  (printf "~a: ~a\n" label (or v "2 秒内没有答案")))
(try "amb-append，左支有暂停     " (λ () (stream-first (in-amb (amb (forever/pause) 'right)))))
(try "amb-interleave，左支有暂停 " (λ () (parameterize ([current-amb-merger amb-interleave])
                                          (stream-first (in-amb (amb (forever/pause) 'right))))))
(try "amb-interleave，左支无暂停 " (λ () (parameterize ([current-amb-merger amb-interleave])
                                          (stream-first (in-amb (amb (forever) 'right))))))
