#lang racket
;; 试验（10/5 18:21 Noah 的想法）：除去合一，conj / disj / fresh / succeed / fail 都很简单；
;; fresh 对应 07 复合定义里的「存在」；succeed、fail 由两个零元谓词抬出来；附录改用流。
(require racket/control racket/dict racket/stream)
(define ∘ compose)
(define-syntax-rule (match-λ clause ...) (match-lambda clause ...))
;; 05、06 的定义
(define (choose p*) (shift k (append-map k p*)))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (in-amb e) (reset (list e)))
(define (between lo hi) (for/amb ([n (inclusive-range lo hi)]) n))
(define (check ok?) (unless ok? (amb)))
(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))
(define pick-a (match-λ [(list l   h) (list (between l h)   h)]))
(define pick-b (match-λ [(list a   h) (list a (between a h) h)]))
(define pick-c (match-λ [(list a b h) (list a b (between b h))]))
(define (check-right t) (check (apply pyth? t)) t)

;; ── 关系语言 ──
(struct var (name))
(define (value-of t s)
  (cond [(not (var? t)) t]
        [(dict-has-key? s t) (dict-ref s t)]
        [else (error 'value-of "~a 还没有确定" (var-name t))]))
(define (record x v s)
  (cond [(not (var? x)) (check (equal? x v)) s]
        [(dict-has-key? s x) (check (equal? (dict-ref s x) v)) s]
        [else (dict-set s x v)]))
(define (((function->relation f) . t*) s)
  (define-values (in* out*) (split-at-right t* 1))
  (record (car out*) (apply f (for/list ([t in*]) (value-of t s))) s))
(define (((predicate->relation p?) . t*) s)
  (check (apply p? (for/list ([t t*]) (value-of t s)))) s)

(define (conj . g*) (apply ∘ (reverse g*)))                 ; ∧：复合
(define ((disj . g*) s) ((for/amb ([g g*]) g) s))           ; ∨：amb
(define-syntax-rule (fresh (x ...) g ...)                   ; ∃：新的未知项
  (let ([x (var 'x)] ...) (conj g ...)))
(define succeed ((predicate->relation (λ () #t))))          ; ⊤：零元关系 {()}
(define fail    ((predicate->relation (λ () #f))))          ; ⊥：零元关系 {}
(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (in-amb (let ([s ((conj g ...) '())]) (list (value-of x s) ...)))))

(define betweenᵒ (function->relation between))
(define pythᵒ    (predicate->relation pyth?))
(define pick-aᵒ  (function->relation pick-a))
(define pick-bᵒ  (function->relation pick-b))
(define pick-cᵒ  (function->relation pick-c))
(define check-rightᵒ (function->relation check-right))

;; ── 10/5 18:31：在关系语言里定义二元关系的复合；function->relation 把 ℬ 的箭头搬过来 ──
(define idᵒ (function->relation values))                     ; 复合的单位：方向固定的「相等」
(define ∘ᵒ
  (case-lambda
    [() idᵒ]
    [(R) R]
    [(Q . P*) (let ([P (apply ∘ᵒ P*)])
                (λ (x z) (fresh (y) (P x y) (Q y z))))]))     ; {(x, z) | ∃y, (x, y) ∈ P ∧ (y, z) ∈ Q}
(define ((relation->function R) x)                           ; 搬回来：关系当函数用（方向要对）
  (let ([z (var 'z)]) (value-of z ((R x z) '()))))

(module+ test
  (require (except-in rackunit fail))   ; rackunit 也导出一个 fail，会盖住目标 fail
  ;; 三角形
  (check-equal? (run* (a b c) (betweenᵒ 1 20 a) (betweenᵒ a 20 b) (betweenᵒ b 20 c) (pythᵒ a b c))
                '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
  ;; 07 的三列表：y 列出来，就是三列（这里显示后两列）；包进 fresh，中间一列被遮住
  (check-equal? (run* (y z) (pick-aᵒ '(1 2) y) (pick-bᵒ y z))
                '(((1 2) (1 1 2)) ((1 2) (1 2 2)) ((2 2) (2 2 2))))
  ;; 复合的定义逐字翻译：{(x, z) | ∃y, (x, y) ∈ P ∧ (y, z) ∈ Q}
  (check-equal? (run* (z) ((∘ᵒ pick-bᵒ pick-aᵒ) '(1 2) z))
                '(((1 1 2)) ((1 2 2)) ((2 2 2))))
  ;; 与函数的复合一致
  (check-equal? (map car (run* (z) ((∘ᵒ pick-bᵒ pick-aᵒ) '(1 2) z)))
                (in-amb ((∘ pick-b pick-a) '(1 2))))
  ;; fresh 套两层、同名不冲突
  (check-equal? (run* (z) (fresh (y) (betweenᵒ 1 2 y) (fresh (y) (betweenᵒ 7 8 y)) ((function->relation +) y 10 z)))
                '((11) (11) (12) (12)))
  ;; 析取
  (check-equal? (run* (a) (disj (betweenᵒ 1 2 a) (betweenᵒ 8 9 a))) '((1) (2) (8) (9)))
  ;; succeed / fail：单位元，且与 (conj)、(disj) 一致
  (define g (betweenᵒ 1 3 (var 'tmp)))
  (define (same? g1 g2) (let ([x (var 'x)])
                          (equal? (in-amb (value-of x ((conj (betweenᵒ 1 3 x) g1) '())))
                                  (in-amb (value-of x ((conj (betweenᵒ 1 3 x) g2) '()))))))
  (check-equal? (run* () succeed) '(()))      ; {()}：一行，零列
  (check-equal? (run* () fail)    '())        ; {}：没有行
  (check-equal? (run* () (conj))  '(()))
  (check-equal? (run* () (disj))  '())
  (check-equal? (run* (a) (conj succeed (betweenᵒ 1 2 a))) (run* (a) (betweenᵒ 1 2 a)))
  (check-equal? (run* (a) (conj (betweenᵒ 1 2 a) succeed)) (run* (a) (betweenᵒ 1 2 a)))
  (check-equal? (run* (a) (disj fail (betweenᵒ 1 2 a)))    (run* (a) (betweenᵒ 1 2 a)))
  (check-equal? (run* (a) (disj (betweenᵒ 1 2 a) fail))    (run* (a) (betweenᵒ 1 2 a)))
  (check-equal? (run* (a) (conj fail (betweenᵒ 1 2 a))) '())           ; ⊥ 是 ∧ 的零元
  ;; 没有合一做不到的事：方向固定
  (check-exn exn:fail? (λ () (run* (l) (betweenᵒ l 3 2))))
  ;; ── 18:31 ──
  (define (rows R x) (map car (run* (z) (R x z))))            ; 关系 R 在输入 x 上的全部输出
  ;; 四步在关系语言里复合，得到的还是那六组
  (define right-triangleᵒ (∘ᵒ check-rightᵒ pick-cᵒ pick-bᵒ pick-aᵒ))
  (check-equal? (rows right-triangleᵒ '(1 20))
                '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))
  ;; 搬运保持复合：先复合再搬 = 先搬再复合
  (for ([x '((1 2) (1 5) (3 3))])
    (check-equal? (rows (function->relation (∘ pick-b pick-a)) x)
                  (rows (∘ᵒ pick-bᵒ pick-aᵒ) x)))
  (check-equal? (rows (function->relation (∘ check-right pick-c pick-b pick-a)) '(1 20))
                (rows right-triangleᵒ '(1 20)))
  ;; 搬运保持单位：恒等函数搬过去是 idᵒ，它是 ∘ᵒ 的单位
  (for ([x '((1 2) (1 5))])
    (check-equal? (rows (∘ᵒ pick-aᵒ idᵒ) x) (rows pick-aᵒ x))
    (check-equal? (rows (∘ᵒ idᵒ pick-aᵒ) x) (rows pick-aᵒ x)))
  (check-equal? (rows (∘ᵒ) '(1 2)) '((1 2)))
  ;; 结合
  (check-equal? (rows (∘ᵒ pick-cᵒ (∘ᵒ pick-bᵒ pick-aᵒ)) '(1 3)) (rows (∘ᵒ (∘ᵒ pick-cᵒ pick-bᵒ) pick-aᵒ) '(1 3)))
  ;; 搬过去再搬回来
  (check-equal? (in-amb ((relation->function pick-aᵒ) '(1 5))) (in-amb (pick-a '(1 5))))
  (check-equal? (in-amb ((relation->function right-triangleᵒ) '(1 20))) (in-amb ((∘ check-right pick-c pick-b pick-a) '(1 20))))
  ;; 关系比函数多的东西：反过来问。写得出来（参数换个位置），没有合一就跑不动
  (define ((converse R) x z) (R z x))
  (check-exn exn:fail? (λ () (rows (converse pick-aᵒ) '(2 3)))))

