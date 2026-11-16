#lang racket
;; issue #72 补充：第 6 节照 free-tree-sketch-20261007.md 的写法重写。
;; choose 仍用第五章的 shift，只拿掉 append-map；待办表的条目直接是 (k p)。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-4-tree.rkt
(require racket/control)

(struct leaf (val))
(struct node (alts k))                               ; 备选，剩余工作
(define (choose p*) (shift k (node p* k)))           ; 第五章：(shift k (append-map k p*))
(define-syntax-rule (in-tree e) (reset (leaf e)))    ; 第五章：(reset (list e))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))

;; 读法一：深度优先，收成列表。就是第五章的 in-amb
(define (dfs t)
  (match t
    [(leaf v) (list v)]
    [(node p* k) (append-map (λ (p) (dfs (k p))) p*)]))

;; 读法二：一次交出一个答案，和接着找的 thunk；新的待办放表头还是表尾只差一行
(define ((searcher put) agenda)
  (match agenda
    ['() (values #f #f)]
    [(cons th rest)
     (match (th)
       [(node p* k) ((searcher put) (put (for/list ([p p*]) (λ () (k p))) rest))]
       [(leaf v) (values (list v) (λ () ((searcher put) rest)))])]))
(define depth-first   (searcher (λ (new rest) (append new rest))))
(define breadth-first (searcher (λ (new rest) (append rest new))))
(define (take n search thunk)
  (let loop ([n n] [next (λ () (search (list thunk)))])
    (if (eqv? n 0)
        '()
        (let-values ([(v next) (next)])
          (if v (cons (car v) (loop (and n (sub1 n)) next)) '())))))

(define (between lo hi) ((choose (for/list ([n (inclusive-range lo hi)]) (λ () n)))))
(define (triangle l h)
  (let* ([a (between l h)] [b (between a h)] [c (between b h)])
    (unless (= (+ (* a a) (* b b)) (* c c)) (amb))
    (list a b c)))
(define runs 0)
(define (tri) (in-tree (begin0 (triangle 1 20) (set! runs (add1 runs)))))
(printf "dfs            ~s\n" (dfs (tri)))
(set! runs 0)
(printf "第一组         ~s，主体走到头 ~a 次\n" (take 1 depth-first tri) runs)
(printf "待办表取全部   ~s\n" (equal? (take #f depth-first tri) (dfs (tri))))
(define (nat n) (amb n (nat (add1 n))))
(printf "自然数前五个   ~s\n" (take 5 depth-first (λ () (in-tree (nat 0)))))
(define (uneven) (in-tree (if ((choose (list (λ () #t) (λ () #f)))) (+ 10 ((choose (list (λ () 1) (λ () 2))))) 0)))
(printf "深浅不一的树   深度优先 ~s 广度优先 ~s\n" (take #f depth-first uneven) (take #f breadth-first uneven))
(define (deep) (amb (deep) (deep)))
(define (try label thunk)
  (define ch (make-channel))
  (define th (thread (λ () (channel-put ch (thunk)))))
  (define v (sync/timeout 2 ch))
  (unless v (kill-thread th))
  (printf "~a ~a\n" label (or v "2 秒内没有答案")))
(try "左边没有尽头，深度优先" (λ () (take 1 depth-first   (λ () (in-tree (amb (deep) 'right))))))
(try "左边没有尽头，广度优先" (λ () (take 1 breadth-first (λ () (in-tree (amb (deep) 'right))))))
