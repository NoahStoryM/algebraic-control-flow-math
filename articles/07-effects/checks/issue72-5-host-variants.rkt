#lang racket
;; issue #72 第二版：原型只有一种界桩；Racket 有两种。
;; reset-at / prompt-at 是一种（不肯被拿走），reset0-at / prompt0-at 是另一种（肯被拿走）。
;; 这份程序把原型（issue72-2-stack.rkt 的机器，照抄）与宿主在两种界桩下逐项对照。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-5-host-variants.rkt
(require (prefix-in rc: racket/control))

;; ---------- 原型的机器（与 issue72-2-stack.rkt 相同） ----------
(struct tag (name))
(define (apply-cont k v)
  (match k
    ['() v]
    [(cons (? tag?) k) (apply-cont k v)]
    [(cons f k) ((f v) k)]))
(define ((unit v) k) (apply-cont k v))
(define-syntax let*/s
  (syntax-rules ()
    [(_ () b) b]
    [(_ ([v e] more ...) b) (λ (k) (e (cons (λ (v) (let*/s (more ...) b)) k)))]))
(define (run e) (e '()))
(define (split k t)
  (let loop ([k k] [seg '()])
    (match k
      ['() (error 'split "栈里没有界桩 ~a" (tag-name t))]
      [(cons x rest) #:when (eq? x t) (values (reverse seg) rest)]
      [(cons x rest) (loop rest (cons x seg))])))
(define ((prompt0-at t e) k) (e (cons t k)))
(define ((control0-at t f) k)
  (define-values (seg rest) (split k t))
  ((f seg) rest))
(define (((resume seg) v) k) (apply-cont (append seg k) v))
(define ((variant outer? inner?) t f)
  (control0-at t
    (λ (seg)
      (define (k v) (if inner? (prompt0-at t ((resume seg) v)) ((resume seg) v)))
      (if outer? (prompt0-at t (f k)) (f k)))))
(define m:shift (variant #t #t)) (define m:control (variant #t #f))
(define m:shift0 (variant #f #t)) (define m:control0 (variant #f #f))
(define ta (tag 'a))
(define-syntax-rule (try e) (with-handlers ([exn:fail? (λ (x) 'error)]) e))

;; 程序一：遍历列表，每一步把剩下的遍历取出来
(define ((m:visit op) l)
  (if (null? l) (unit '())
      (let*/s ([rest (op ta (λ (k) (let*/s ([r (k (cdr l))]) (unit (cons (car l) r)))))])
        ((m:visit op) rest))))
;; 程序二：两层同名界桩，里面连用两次同一个算子
(define (m:two op)
  (prompt0-at ta
    (let*/s ([x (prompt0-at ta
                  (let*/s ([y (op ta (λ (k) (op ta (λ (j) (unit '())))))])
                    (unit (cons 'inner y))))])
      (unit (cons 'outer x)))))

;; ---------- 宿主：同样两个程序，界桩种类作参数 ----------
(define t (make-continuation-prompt-tag 'a))
(define-syntax-rule (define-host name op-at)
  (define (name boundary)
    (define (visit l)
      (if (null? l) '() (visit (op-at t k (cons (car l) (k (cdr l)))))))
    (list (try (boundary (λ () (visit '(1 2 3)))))
          (try (boundary (λ () (cons 'outer (boundary (λ () (cons 'inner (op-at t k (op-at t j '()))))))))))))
(define-host h:shift rc:shift-at) (define-host h:control rc:control-at)
(define-host h:shift0 rc:shift0-at) (define-host h:control0 rc:control0-at)
(define (plain thunk) (rc:reset-at t (thunk)))      ; reset-at 与 prompt-at 是同一个
(define (zero thunk) (rc:reset0-at t (thunk)))      ; reset0-at 与 prompt0-at 是同一个

(printf "~a ~a ~a ~a\n" "算子    " "原型                    " "宿主，reset0/prompt0     " "宿主，reset/prompt")
(for ([name '(shift control shift0 control0)]
      [m (list m:shift m:control m:shift0 m:control0)]
      [h (list h:shift h:control h:shift0 h:control0)])
  (define proto (list (try (run (prompt0-at ta ((m:visit m) '(1 2 3))))) (try (run (m:two m)))))
  (printf "~a ~s  ~s  ~s  ~a\n" (~a name #:min-width 8) proto (h zero) (h plain)
          (cond [(and (equal? proto (h zero)) (equal? proto (h plain))) "三者相同"]
                [(equal? proto (h zero)) "原型同 reset0，不同 reset"]
                [else "原型与 reset0 也不同"])))

;; Astra 的反例（#73 B3）
(printf "\n#73 B3：(reset (cons 'outer (reset (shift0 k (shift0 j '())))))\n")
(printf "  宿主 reset-at  ~s\n" (rc:reset-at t (cons 'outer (rc:reset-at t (rc:shift0-at t k (rc:shift0-at t j '()))))))
(printf "  宿主 reset0-at ~s\n" (rc:reset0-at t (cons 'outer (rc:reset0-at t (rc:shift0-at t k (rc:shift0-at t j '()))))))
(printf "  原型           ~s\n"
        (run (prompt0-at ta (let*/s ([x (prompt0-at ta (m:shift0 ta (λ (k) (m:shift0 ta (λ (j) (unit '()))))))])
                              (unit (cons 'outer x))))))
