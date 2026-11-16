#lang racket
;; issue #72 第二版，第 7 节的落点：第五章的内核里手工传着的代换，改成第六章的状态。
;; 目标不再收发代换：== 改状态，「并且」是顺序执行，「或者」是 amb。
;; 状态与选择各有自己的界桩；两种排法，一种得到第五章的答案，另一种不是。
;; Racket 9.3；LC_ALL=C.UTF-8 racket issue72-6-kernel-state.rkt
(require racket/control)

;; ---------- 第五章的选择（多一个名字） ----------
(define tl (make-continuation-prompt-tag 'choose))
(define (choose p*) (shift-at tl k (append-map k p*)))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (in-amb e) (reset-at tl (list e)))

;; ---------- 第六章的状态（多一个名字） ----------
(define ts (make-continuation-prompt-tag 'state))
(define (get) (shift-at ts k (λ (s) ((k s) s))))
(define (put! s1) (shift-at ts k (λ (s) ((k (void)) s1))))
(define-syntax-rule (with-state s0 e) ((reset-at ts (let ([v e]) (λ (s) v))) s0))

;; ---------- 第五章的项、代换、合一、读出，原样 ----------
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
          [else (amb)])))
(define (reify t)
  (define (name t s)
    (let ([t (walk t s)])
      (cond [(var? t) (cons (cons t (string->symbol (format "_.~a" (length s)))) s)]
            [(pair? t) (name (cdr t) (name (car t) s))]
            [else s])))
  (walk* t (name t '())))

;; ---------- 目标：不收代换，也不交代换 ----------
(define (== u v) (put! (unify u v (get))))
(define-syntax-rule (conj g ...) (begin g ...))
(define-syntax-rule (disj g ...) (amb g ...))
(define-syntax-rule (fresh (x ...) g ...) (let ([x (var 'x)] ...) g ...))

(define (appendo l t out)
  (disj (conj (== l '()) (== t out))
        (fresh (a d res)
          (== l (cons a d))
          (== out (cons a res))
          (appendo d t res))))

(define-syntax-rule (query (x ...) g ...)          ; 一次查询的主体：造未知项，运行条件，读出答案
  (let ([x (var 'x)] ...) g ... (reify (walk* (list x ...) (get)))))

(define-syntax-rule (show label e) (printf "~a\n  ~s\n" label e))
;; 排法一：状态的界桩在每一支里面
(show "代换的界桩在里，搜索在外：(appendo x y '(1 2 3))"
      (in-amb (with-state '() (query (x y) (appendo x y '(1 2 3))))))
;; 排法二：状态的界桩在整次搜索外面
(show "搜索的界桩在里，代换在外：(appendo x y '(1 2 3))"
      (with-state '() (in-amb (query (x y) (appendo x y '(1 2 3))))))
;; 更小的例子
(show "代换在里：x 是 1 或者 2" (in-amb (with-state '() (query (x) (disj (== x 1) (== x 2))))))
(show "代换在外：x 是 1 或者 2" (with-state '() (in-amb (query (x) (disj (== x 1) (== x 2))))))
;; 正着问只有一条路，两种排法没有差别
(show "代换在里：(appendo '(1 2) '(3) z)" (in-amb (with-state '() (query (z) (appendo '(1 2) '(3) z)))))
(show "代换在外：(appendo '(1 2) '(3) z)" (with-state '() (in-amb (query (z) (appendo '(1 2) '(3) z)))))

;; ---------- 发编号与选择：两种排法都说得通 ----------
(define tn (make-continuation-prompt-tag 'counter))
(define (fresh!) (shift-at tn k (λ (n) ((k n) (add1 n)))))
(define-syntax-rule (with-counter e) ((reset-at tn (let ([v e]) (λ (n) v))) 0))
(define (prog) (let* ([x (amb 'a 'b)] [n (fresh!)] [m (fresh!)]) (list x n m)))
(show "编号的界桩在里" (in-amb (with-counter (prog))))
(show "编号的界桩在外" (with-counter (in-amb (prog))))

;; 用计数器给未知项编号的内核：两种排法下 appendo 倒着问
(struct nvar (n) #:transparent)
(define (nwalk t s) (define p (and (nvar? t) (assoc t s))) (if p (nwalk (cdr p) s) t))
(define (nwalk* t s) (let ([t (nwalk t s)]) (if (pair? t) (cons (nwalk* (car t) s) (nwalk* (cdr t) s)) t)))
(define (nunify u v s)
  (let ([u (nwalk u s)] [v (nwalk v s)])
    (cond [(and (nvar? u) (equal? u v)) s]
          [(nvar? u) (cons (cons u v) s)]
          [(nvar? v) (cons (cons v u) s)]
          [(and (pair? u) (pair? v)) (nunify (cdr u) (cdr v) (nunify (car u) (car v) s))]
          [(equal? u v) s]
          [else (amb)])))
(define (n== u v) (put! (nunify u v (get))))
(define-syntax-rule (nfresh (x ...) g ...) (let* ([x (nvar (fresh!))] ...) g ...))
(define (nappendo l t out)
  (disj (conj (n== l '()) (n== t out))
        (nfresh (a d res)
          (n== l (cons a d))
          (n== out (cons a res))
          (nappendo d t res))))
(define-syntax-rule (nquery (x ...) g ...)
  (nfresh (x ...) g ... (list (nwalk* (list x ...) (get)) '用到的编号 (fresh!))))
(show "未知项按计数器编号，计数器在每一支里"
      (in-amb (with-counter (with-state '() (nquery (x y) (nappendo x y '(1 2)))))))
(show "未知项按计数器编号，计数器在整次搜索外"
      (with-counter (in-amb (with-state '() (nquery (x y) (nappendo x y '(1 2)))))))
