#lang racket
;; issue #72 原型一：开场的失败现场，与「一个标记一个变量」的路线为什么不够。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-1-failure.rkt
(require (prefix-in rc: racket/control))

;; ---------- A. 第五章的零件，原样 ----------
(module ch5 racket
  (require racket/control)
  (provide (all-defined-out) reset shift abort)
  (define (choose p*) (shift k (append-map k p*)))
  (define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
  (define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
  (define-syntax-rule (in-amb e) (reset (list e)))
  (define (between lo hi) (for/amb ([n (inclusive-range lo hi)]) n))
  (define (check ok?) (unless ok? (amb)))
  (define (triangle l h)
    (let* ([a (between l h)] [b (between a h)] [c (between b h)])
      (check (= (+ (* a a) (* b b)) (* c c)))
      (list a b c))))
(require 'ch5)

(printf "A1 全部答案            ~s\n" (in-amb (triangle 1 20)))
;; 想要：找到第一组就走。照第三章的办法，外面划一条边界，里面 abort。
(printf "A2 外面 reset 里面 abort ~s\n" (reset (in-amb (abort (triangle 1 20)))))
;; 把 abort 写在分支里也一样
(printf "A3 Astra 的两行（#69）  ~s\n"
        (reset (in-amb (let ([x (amb 1 2)]) (shift _ (list x))))))
(define runs 0)
(void (reset (in-amb (let ([t (triangle 1 20)]) (set! runs (add1 runs)) (abort t)))))
(printf "A4 abort 执行了 ~a 次\n" runs)

;; ---------- B. 照第三章「用 call/cc 造定界延续」推广：每个标记一个变量 ----------
;; 第三章：meta-k 是一个变量。这里换成一张表，标记 ↦ 元延续。
(define meta (make-hasheq))
(define (meta-ref t) (hash-ref meta t (λ () (λ v* (error 'abort-at "没有 ~a 的边界" t)))))
(define (abort-at t . v*) (apply (meta-ref t) v*))
(define (call/prompt-at t thk)
  (define k0 (meta-ref t))
  (let/cc k1
    (hash-set! meta t (λ v* (hash-set! meta t k0) (apply k1 v*)))
    (call-with-values thk (λ v* (apply abort-at t v*)))))
(define-syntax-rule (reset-at t b ...) (call/prompt-at t (λ () b ...)))
(define (call/lc-at t proc)
  (let/cc k
    (define (local-k . v*) (reset-at t (apply k v*)))
    (proc local-k)))
(define-syntax-rule (shift-at t k b ...)
  (call/lc-at t (λ (k) (call-with-values (λ () b ...) (λ v* (apply abort-at t v*))))))

;; B1 单个标记：第三章的四个例子照旧
(define (ex body) (let ([v (reset-at 'a (let* ([x (body)] [y (+ 2 x)]) (abort-at 'a y)))]) (+ 10 v)))
(printf "B1 四个例子 ~s\n"
        (list (ex (λ () 3)) (ex (λ () (shift-at 'a k 3))) (ex (λ () (shift-at 'a k (k 3))))
              (ex (λ () (shift-at 'a k (let ([r (k 3)]) (k r)))))))

;; B2 两个标记，从里面越过 b 的边界中止到 a：a 的条目换回去了，b 的条目没有人换回去
(define log '())
(define (note x) (set! log (cons x log)))
;; 两条边界都离开以后再中止到 b，本该报「没有 b 的边界」
(define (try thunk) (with-handlers ([exn:fail? (λ (e) (list 'error (exn-message e)))]) (thunk)))
(define b2
  (try (λ ()
         (let ([r (reset-at 'a
                    (note 'in-a)
                    (reset-at 'b (note 'in-b) (abort-at 'a 'done))
                    (note 'after-b))])
           (note r)
           (abort-at 'b 'ghost)))))
(printf "B2 日志 ~s 结果 ~s\n" (reverse log) b2)

;; B3 捕获越过别人的边界：切下来的一段里有 b 的边界，再调用时它用的是哪一条元延续？
(printf "B3 表        ~s\n"
        (try (λ () (reset-at 'a (list 'a: (reset-at 'b (list 'b: (shift-at 'a k (list (k 1) (k 2))))))))))
(define ta (make-continuation-prompt-tag 'a)) (define tb (make-continuation-prompt-tag 'b))
(printf "B3 racket/control ~s\n"
        (rc:reset-at ta (list 'a: (rc:reset-at tb (list 'b: (rc:shift-at ta k (list (k 1) (k 2))))))))
