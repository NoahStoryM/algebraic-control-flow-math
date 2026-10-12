# 树与 tag：同一段两族操作的程序，两种写法（2026-10-07，Claude 写，Racket 8.10 实测）

```racket
#lang racket
(require racket/control)
;; 同一段程序，两族操作：choose，以及 get / put
;; ---------- 写法一：树。操作只递包裹，处理者是读树的函数 ----------
(struct leaf (v) #:transparent)
(struct choose-n (alts k)) (struct get-n (k)) (struct put-n (s k))
(define (graft t f)
  (match t
    [(leaf v) (f v)]
    [(choose-n p* k) (choose-n p* (λ (p) (graft (k p) f)))]
    [(get-n k) (get-n (λ (s) (graft (k s) f)))]
    [(put-n s k) (put-n s (λ () (graft (k) f)))]))
;; 只认识 choose 的处理者：get / put 的节点原样转交
(define (h-choose t)
  (match t
    [(leaf v) (leaf (list v))]
    [(choose-n p* k)
     (let loop ([p* p*])
       (if (null? p*) (leaf '())
           (graft (h-choose (k (car p*)))
                  (λ (xs) (graft (loop (cdr p*)) (λ (ys) (leaf (append xs ys))))))))]
    [(get-n k) (get-n (λ (s) (h-choose (k s))))]
    [(put-n s k) (put-n s (λ () (h-choose (k))))]))
;; 只认识 get / put 的处理者：choose 的节点原样转交
(define ((h-state t) s)
  (match t
    [(leaf v) (leaf (cons v s))]
    [(get-n k) ((h-state (k s)) s)]
    [(put-n s2 k) ((h-state (k)) s2)]
    [(choose-n p* k) (choose-n p* (λ (p) ((h-state (k p)) s)))]))

(define tree
  (let ([choose (λ (p*) (shift k (choose-n p* k)))]
        [get (λ () (shift k (get-n k)))]
        [put (λ (s) (shift k (put-n s k)))])
    (reset (leaf (let ([x (choose '(1 2))]) (put (+ (get) x)) (get))))))

(h-choose ((h-state tree) 0))     ; 状态在里，选择在外：每条分支各有一份状态
((h-state (h-choose tree)) 0)     ; 选择在里，状态在外：各分支共用一份状态

;; ---------- 写法二：tag。操作直接切到自己的边界，越过别人的 ----------
(define tc (make-continuation-prompt-tag 'choose))
(define ts (make-continuation-prompt-tag 'state))
(define (choose p*) (shift-at tc k (append-map k p*)))          ; 第五篇原样，多了一个名字
(define (with-choose thunk) (reset-at tc (list (thunk))))
(define (get) (shift-at ts k (λ (s) ((k s) s))))
(define (put s2) (shift-at ts k (λ (_) ((k (void)) s2))))
(define (with-state s thunk) ((reset-at ts (let ([v (thunk)]) (λ (s) (cons v s)))) s))
(define (prog) (let ([x (choose '(1 2))]) (put (+ (get) x)) (get)))

(with-choose (λ () (with-state 0 prog)))
(with-state 0 (λ () (with-choose prog)))
```

输出（前两行是树的写法，后两行是 tag 的写法，两两相同）：

```
(leaf '((1 . 1) (2 . 2)))
(leaf '((1 3) . 3))
'((1 . 1) (2 . 2))
'((1 3) . 3)
```
