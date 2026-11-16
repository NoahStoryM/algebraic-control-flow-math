#lang racket
;; issue #72 原型二：自己维护的栈。帧是活的箭头，脊柱是列表，界桩是列表里的条目。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-2-stack.rkt
(require (prefix-in rc: racket/control))

;; ---------- 1. 不折起来的延续 ----------
;; 计算：栈 → 答案。帧：值 → 计算。栈：帧的列表。
;; 第二章把延续写成 (∘ k g f)，每接一步就折进闭包；这里只记下来，值到了再一个个用。
(struct tag (name))
(define (apply-cont k v)
  (match k
    ['() v]
    [(cons (? tag?) k) (apply-cont k v)]           ; 第 2 步才用到：走到界桩，这一段做完了
    [(cons f k) ((f v) k)]))
(define ((unit v) k) (apply-cont k v))
(define-syntax let*/s
  (syntax-rules ()
    [(_ () b) b]
    [(_ ([v e] more ...) b)
     (λ (k) (e (cons (λ (v) (let*/s (more ...) b)) k)))]))   ; 压栈，对 (∘ k f)
(define (run e) (e '()))

;; 第四章开头的 fib，帧从带标签的数据变回活的箭头
(define (fib n)
  (if (< n 2)
      (unit n)
      (let*/s ([a (fib (- n 1))] [b (fib (- n 2))]) (unit (+ a b)))))
(printf "1 fib 20 = ~a\n" (run (fib 20)))

;; ---------- 2. 栈里的界桩 ----------
(define (split k t)                 ; 在第一个 t 处切开：(values 切下的一段 剩下的栈)，t 两边都不留
  (let loop ([k k] [seg '()])
    (match k
      ['() (error 'split "栈里没有界桩 ~a" (tag-name t))]
      [(cons x rest) #:when (eq? x t) (values (reverse seg) rest)]
      [(cons x rest) (loop rest (cons x seg))])))
(define ((prompt0-at t e) k) (e (cons t k)))
(define ((control0-at t f) k)       ; f：切下的一段 → 计算
  (define-values (seg rest) (split k t))
  ((f seg) rest))
(define (((resume seg) v) k) (apply-cont (append seg k) v))   ; 把切下的一段拼回栈顶

;; 两个决定，各一行：切开以后界桩放不放回剩下的栈；拼回去时垫不垫一个界桩
(define ((variant outer? inner?) t f)
  (control0-at t
    (λ (seg)
      (define (k v) (if inner? (prompt0-at t ((resume seg) v)) ((resume seg) v)))
      (if outer? (prompt0-at t (f k)) (f k)))))
(define shift-at    (variant #t #t))
(define control-at  (variant #t #f))
(define shift0-at   (variant #f #t))
(define control0*   (variant #f #f))     ; = control0-at，只是把一段包成了函数
(define reset-at prompt0-at)
(define (abort-at t v) (control0-at t (λ (seg) (unit v))))

;; 第三章的四个例子
(define ta (tag 'a))
(define (ex body)
  (run (let*/s ([v (reset-at ta (let*/s ([x body] [y (unit (+ 2 x))]) (abort-at ta y)))])
         (unit (+ 10 v)))))
(printf "2 四个例子 ~s\n"
        (list (ex (unit 3))
              (ex (shift-at ta (λ (k) (unit 3))))
              (ex (shift-at ta (λ (k) (k 3))))
              (ex (shift-at ta (λ (k) (let*/s ([r (k 3)]) (k r)))))))

;; 四种变体分得开的一个程序：遍历列表，每一步把剩下的遍历取出来
(define ((visit op) l)
  (if (null? l)
      (unit '())
      (let*/s ([rest (op ta (λ (k) (let*/s ([r (k (cdr l))]) (unit (cons (car l) r)))))])
        ((visit op) rest))))
(for ([op (list shift-at control-at shift0-at control0*)]
      [name '(shift control shift0 control0)])
  (printf "2 ~a ~s\n" name
          (with-handlers ([exn:fail? (λ (e) (exn-message e))])
            (run (reset-at ta ((visit op) '(1 2 3)))))))
;; 对照宿主
(define rt (make-continuation-prompt-tag 'a))
(define ((rvisit/shift) l) (if (null? l) '() ((rvisit/shift) (rc:shift-at rt k (cons (car l) (k (cdr l)))))))
(define ((rvisit/control) l) (if (null? l) '() ((rvisit/control) (rc:control-at rt k (cons (car l) (k (cdr l)))))))
(printf "2 宿主 shift ~s control ~s\n"
        (rc:reset-at rt ((rvisit/shift) '(1 2 3))) (rc:prompt-at rt ((rvisit/control) '(1 2 3))))

;; ---------- 3. 两条前沿各认各的界桩 ----------
(define tc (tag 'choose))
(define (choose p*)
  (shift-at tc
    (λ (k)
      (let loop ([p* p*])
        (if (null? p*)
            (unit '())
            (let*/s ([xs (k (car p*))] [ys (loop (cdr p*))]) (unit (append xs ys))))))))
(define (in-amb e) (reset-at tc (let*/s ([v e]) (unit (list v)))))
(define (between lo hi) (choose (inclusive-range lo hi)))
(define (check ok?) (if ok? (unit (void)) (choose '())))
(define (triangle l h)
  (let*/s ([a (between l h)] [b (between a h)] [c (between b h)]
           [_ (check (= (+ (* a a) (* b b)) (* c c)))])
    (unit (list a b c))))
(printf "3 全部 ~s\n" (run (in-amb (triangle 1 20))))

(define tu (tag 'user))
(define runs 0)
(printf "3 第一组（结束整次搜索） ~s"
        (run (reset-at tu (in-amb (let*/s ([t (triangle 1 20)])
                                    (begin (set! runs (add1 runs))
                                           (abort-at tu t)))))))
(printf "，主体运行 ~a 次\n" runs)
;; 同一段主体，两条边界换个排法：只结束一支
(printf "3 边界排在里面（只结束一支） ~s\n"
        (run (in-amb (reset-at tu (let*/s ([x (choose '(1 2 3))])
                                    (if (= x 2) (abort-at tu 'boom) (unit x)))))))
(printf "3 边界排在外面（结束整次搜索） ~s\n"
        (run (reset-at tu (in-amb (let*/s ([x (choose '(1 2 3))])
                                    (if (= x 2) (abort-at tu 'boom) (unit x)))))))

;; shift 与 shift0 要两层同名的界桩才分得开
(for ([op (list shift-at shift0-at)] [name '(shift shift0)])
  (printf "2 两层界桩 ~a ~s\n" name
          (run (reset-at ta
                 (let*/s ([x (reset-at ta
                               (let*/s ([y (op ta (λ (k) (op ta (λ (k2) (unit '())))))])
                                 (unit (cons 'inner y))))])
                   (unit (cons 'outer x)))))))
