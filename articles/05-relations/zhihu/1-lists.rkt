#lang racket
;; 知乎回答「miniKanren 的实现方式」的代码之一：只用列表的内核。
;; 运行：racket 1-lists.rkt（Racket 9.3，不需要任何包）
;;
;; walk、unify 与读出答案的 reify 改写自 microKanren：
;;   https://github.com/jasonhemann/microKanren
;;   Jason Hemann and Daniel P. Friedman, "μKanren: A Minimal Functional
;;   Core for Relational Programming", Scheme Workshop 2013.
;;   Copyright (C) 2013 Jason Hemann and Daniel P. Friedman, MIT License.
;;   许可全文见同目录的 NOTICE。
;; 改动：未知项是结构体，按身份区分，不用计数器；目标交出列表，不交出流。

(provide var walk unify reify)

;; ---- 未知项与代换 ----
(struct var (name)
  #:property prop:custom-write                      ; 只为打印：未知项显示成它的名字
  (λ (v port mode) (write (var-name v) port)))

(define (walk t s)
  (define p (and (var? t) (assq t s)))
  (if p (walk (cdr p) s) t))

;; ---- 合一 ----
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (cons (cons u v) s)]
          [(var? v) (cons (cons v u) s)]
          [(and (pair? u) (pair? v))
           (let ([s (unify (car u) (car v) s)])
             (and s (unify (cdr u) (cdr v) s)))]
          [(equal? u v) s]
          [else #f])))

;; ---- 目标：收一张代换，交出一列代换 ----
(define ((== u v) s)
  (define s1 (unify u v s))
  (if s1 (list s1) '()))

(define ((disj . g*) s) (append-map (λ (g) (g s)) g*))
(define ((conj . g*) s)
  (for/fold ([s* (list s)]) ([g g*])
    (append-map g s*)))

(define-syntax-rule (fresh (x ...) g ...)
  (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))

;; ---- 读出答案 ----
(define (walk* t s)
  (let ([t (walk t s)])
    (if (pair? t) (cons (walk* (car t) s) (walk* (cdr t) s)) t)))

(define (reify t s)
  (define (name t r)
    (let ([t (walk t r)])
      (cond [(var? t) (cons (cons t (string->symbol (format "_.~a" (length r)))) r)]
            [(pair? t) (name (cdr t) (name (car t) r))]
            [else r])))
  (let ([t (walk* t s)])
    (walk* t (name t '()))))

(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (for/list ([s ((conj g ...) '())])
      (reify (list x ...) s))))

;; ---- 试一试 ----
(module+ main
  (define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))
  (define x (var 'x))
  (define y (var 'y))
  (show (walk x (list (cons y 5) (cons x y))))
  (show (unify (list x 2) (list 1 y) '()))
  (show (unify (list x 2) (list 1 x) '()))
  (show ((== x 1) '()))
  (show ((disj (== x 1) (== x 2)) '()))
  (show ((conj (disj (== x 1) (== x 2)) (== y x)) '()))
  (show ((conj (== x 1) (== x 2)) '()))

  (define (appendo l t out)
    (disj (conj (== l '()) (== t out))
          (fresh (a d res)
            (== l (cons a d))
            (== out (cons a res))
            (appendo d t res))))
  (show (run* (z) (appendo '(1 2) '(3) z)))
  (show (run* (x y) (appendo x y '(1 2 3))))
  (show (run* (x y) (== x y)))
  (show (run* (x y) (== x x)))
  (show (run* (x y) (== x (list y 1 y))))

  ;; 零个目标
  (show ((conj) '()))
  (show ((disj) '()))

  ;; { x | ∃y. (y = 5 ∨ y = 6) ∧ y = x }
  (define (P x y) (conj (disj (== y 5) (== y 6)) (== y x)))
  (show (run* (x) (fresh (y) (P x y))))

  ;; 写不完的答案：列表要收齐才交得出
  (define (alwayso) (disj (== 1 1) (fresh () (alwayso))))
  (define ch (make-channel))
  (define th (thread (λ () (channel-put ch (run* (q) (alwayso))))))
  (write '(run* (q) (alwayso))) (display "\n  ⇒ ")
  (writeln (or (sync/timeout 2 ch) (begin (kill-thread th) '两秒内没有答案))))
