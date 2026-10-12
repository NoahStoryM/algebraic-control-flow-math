#lang racket
;; 试验（10/4 22:10）：不要合一、不要 fresh，只靠「环境 + 两个抬」的最小关系语言
(require racket/control racket/dict)
(define ∘ compose)
;; B 的三个定义（amb）
(define (choose p*) (shift k (append-map k p*)))
(define (fail) (choose '()))
(define (collect thunk) (reset (list (thunk))))
(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))
(define between (∘ choose inclusive-range))

;; ── 这门小语言的全部 ──
(struct var (name))                                   ; 未知项，按身份区分
;; 环境：以未知项为键的字典，就是第一节的 Dict（关联列表）
(define (value-of t s)                                ; 项现在的值；还没确定就报错
  (cond [(not (var? t)) t]
        [(dict-has-key? s t) (dict-ref s t)]
        [else (error 'value-of "~a 还没有确定" (var-name t))]))
(define (record x v s)                                ; 记下 x 是 v；已经有记录或本身是值，就核对
  (cond [(not (var? x)) (if (equal? x v) s (fail))]
        [(dict-has-key? s x) (if (equal? (dict-ref s x) v) s (fail))]
        [else (dict-set s x v)]))

(define (conj . g*) (apply ∘ (reverse g*)))           ; 合取：依次复合
(define ((disj . g*) s) ((choose g*) s))              ; 析取：amb

(define (((function->relation f) . t*) s)             ; 最后一个参数是结果
  (define-values (in* out*) (split-at-right t* 1))
  (record (car out*) (apply f (for/list ([t in*]) (value-of t s))) s))
(define (((predicate->relation p?) . t*) s)
  (if (apply p? (for/list ([t t*]) (value-of t s))) s (fail)))

(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (collect (λ () (let ([s ((conj g ...) '())]) (list (value-of x s) ...))))))

;; ── 用它 ──
(define betweenᵒ (function->relation  between))
(define pythᵒ    (predicate->relation pyth?))
(define +ᵒ       (function->relation  +))

(define (right-triangles l h)
  (run* (a b c)
    (betweenᵒ l h a)     ; l ≤ a ≤ h
    (betweenᵒ a h b)     ; a ≤ b ≤ h
    (betweenᵒ b h c)     ; b ≤ c ≤ h
    (pythᵒ a b c)))      ; a² + b² = c²

(printf "1. ~s\n" (right-triangles 1 20))
(printf "2. 环境长什么样：~s\n"
        (let ([a (var 'a)] [b (var 'b)])
          (collect (λ () (for/list ([(k v) (in-dict ((conj (betweenᵒ 1 2 a) (betweenᵒ a 2 b)) '()))])
                           (cons (var-name k) v))))))
(printf "3. 同一个未知项被两个条件提到：~s\n"
        (run* (a) (betweenᵒ 1 5 a) (betweenᵒ 3 9 a)))
(printf "4. 析取：~s\n" (run* (a) (disj (betweenᵒ 1 2 a) (betweenᵒ 8 9 a))))
(printf "5. (conj) 与 (disj)：~s ~s\n" (run* () (conj)) (run* () (disj)))
(printf "6. 普通函数：~s\n" (run* (x y) (betweenᵒ 1 3 x) (+ᵒ x 10 y)))
(printf "7. 顺序写反：~s\n"
        (with-handlers ([exn:fail? exn-message])
          (run* (a b c) (pythᵒ a b c) (betweenᵒ 1 20 a) (betweenᵒ a 20 b) (betweenᵒ b 20 c))))
