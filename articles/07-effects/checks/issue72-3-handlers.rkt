#lang racket
;; issue #72 原型三：回到直接风格（racket/control 的带标记算子），操作只递包裹，
;; 怎样走由边界上的人定；两种作用并存时，边界怎样排列决定结果。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-3-handlers.rkt
(require racket/control)

;; ---------- 1. 把动词从 choose 里拿掉 ----------
;; 第五章：(define (choose p*) (shift k (append-map k p*)))，怎样走写死在操作里。
;; 这里 choose 只把（备选，到边界为止的剩余工作）打成包裹，交到边界上。
(define tc (make-continuation-prompt-tag 'choose))
(struct pkg (alts k))
(define (choose p*) (control0-at tc k (pkg p* k)))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define (start thunk) (λ () (prompt0-at tc (list (thunk)))))   ; 交出一张单元素列表，或一个包裹

;; 边界上的人手里是一张待办表，条目是「接着跑」的 thunk。
;; 交出 (values 一个答案 接着找的 thunk)，没有了交出 (values #f #f)。
(define ((searcher put) agenda)
  (match agenda
    ['() (values #f #f)]
    [(cons th rest)
     (match (th)
       [(pkg p* k)
        ((searcher put) (put (for/list ([p p*]) (λ () (prompt0-at tc (k p)))) rest))]
       [(list v) (values (list v) (λ () ((searcher put) rest)))])]))
(define depth-first   (searcher (λ (new rest) (append new rest))))   ; 新的放前面
(define breadth-first (searcher (λ (new rest) (append rest new))))   ; 新的放后面：只差这一行

(define (take n search thunk)
  (let loop ([n n] [next (λ () (search (list (start thunk))))])
    (if (eqv? n 0)
        '()
        (let-values ([(v next) (next)])
          (if v (cons (car v) (loop (and n (sub1 n)) next)) '())))))
(define (in-amb* thunk) (take #f depth-first thunk))

(define (between lo hi) (choose (for/list ([n (inclusive-range lo hi)]) (λ () n))))
(define-syntax-rule (between* lo hi) ((between lo hi)))
(define (check ok?) (unless ok? (amb)))
(define (triangle l h)
  (let* ([a (between* l h)] [b (between* a h)] [c (between* b h)])
    (check (= (+ (* a a) (* b b)) (* c c)))
    (list a b c)))
(printf "1 全部（深度优先）   ~s\n" (in-amb* (λ () (triangle 1 20))))
(define runs 0)
(printf "1 只要第一组         ~s" (take 1 depth-first (λ () (begin0 (triangle 1 20) (set! runs (add1 runs))))))
(printf "，主体走到头 ~a 次\n" runs)
(printf "1 广度优先的前两组   ~s\n" (take 2 breadth-first (λ () (triangle 1 20))))

;; 写不完的搜索
(define (nat n) (amb n (nat (add1 n))))
(printf "1 自然数的前五个     ~s\n" (take 5 depth-first (λ () (nat 0))))
;; 左边没有尽头：一直在选，一个答案也不交
(define (deep) (amb (deep) (deep)))
(define (try label thunk)
  (define ch (make-channel))
  (define th (thread (λ () (channel-put ch (thunk)))))
  (define v (sync/timeout 2 ch))
  (unless v (kill-thread th))
  (printf "~a ~a\n" label (or v "2 秒内没有答案")))
(try "1 左边没有尽头，深度优先" (λ () (take 1 depth-first   (λ () (amb (deep) 'right)))))
(try "1 左边没有尽头，广度优先" (λ () (take 1 breadth-first (λ () (amb (deep) 'right)))))
;; 一支既不选也不交答案：谁也轮不到
(define (spin) (spin))
(try "1 左边空转，广度优先    " (λ () (take 1 breadth-first (λ () (amb (spin) 'right)))))
;; 让出一步也是一种操作：只有一个备选的选择
(define (pause) (amb (void)))
(define (spin/pause) (pause) (spin/pause))
(try "1 空转但肯让出，广度优先" (λ () (take 1 breadth-first (λ () (amb (spin/pause) 'right)))))

;; ---------- 2. 两种作用并存：发编号与选择 ----------
;; 第六章的状态，直接风格；答案是「等着编号的函数」
(define ts (make-continuation-prompt-tag 'state))
(define (fresh!) (shift-at ts k (λ (n) ((k n) (add1 n)))))
(define (with-counter thunk) ((reset-at ts (let ([v (thunk)]) (λ (n) v))) 0))
(define (prog) (let* ([x (amb 'a 'b)] [n (fresh!)] [m (fresh!)]) (list x n m)))
(printf "2 编号的边界在里，搜索在外 ~s\n" (in-amb* (λ () (with-counter prog))))
(printf "2 搜索的边界在里，编号在外 ~s\n" (with-counter (λ () (in-amb* prog))))

;; 第五章原样的 choose（shift 加 append-map）只多一个名字，结果相同
(define tl (make-continuation-prompt-tag 'list))
(define (choose5 p*) (shift-at tl k (append-map k p*)))
(define-syntax-rule (in-amb5 e) (reset-at tl (list e)))
(define (prog5) (let* ([x (choose5 '(a b))] [n (fresh!)] [m (fresh!)]) (list x n m)))
(printf "2 第五章的 choose 加名字   ~s ~s\n" (in-amb5 (with-counter prog5)) (with-counter (λ () (in-amb5 (prog5)))))

;; 提前返回与选择（#69 Astra 的两行，把 shift _ 换成带名字的）
(define tu (make-continuation-prompt-tag 'user))
(define (body) (let ([x (amb 1 2 3)]) (if (= x 2) (shift-at tu _ 'boom) x)))
(printf "2 返回的边界在里 ~s\n" (in-amb* (λ () (reset-at tu (body)))))
(printf "2 返回的边界在外 ~s\n" (reset-at tu (in-amb* body)))

;; ---------- 3. 私有的标记：开场的程序不用改，改的是库 ----------
;; in-amb 的边界用自己的标记，用户的 reset、abort 照旧用没有名字的那一条
(define (between5 lo hi) (choose5 (inclusive-range lo hi)))
(define (triangle5 l h)
  (let* ([a (between5 l h)] [b (between5 a h)] [c (between5 b h)])
    (when (not (= (+ (* a a) (* b b)) (* c c))) (choose5 '()))
    (list a b c)))
(printf "3 开场的程序原样 ~s\n" (reset (in-amb5 (abort (triangle5 1 20)))))
