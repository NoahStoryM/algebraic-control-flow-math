#lang racket
;; 试验：Noah 10/4 21:21 的整理（disj / conj / fail / succeed / predicate->relation）
(require racket/control)
(define (list->amb p*) (shift k (append-map k p*)))        ; 即正文的 choose
(define-syntax-rule (in-amb e) (reset (list e)))            ; 即正文的 collect

(struct var (name))
(define empty-s '())
(define (walk v s)
  (cond [(and (var? v) (assq v s)) => (λ (a) (walk (cdr a) s))] [else v]))
(define (walk* v s)
  (let ([v (walk v s)]) (if (pair? v) (cons (walk* (car v) s) (walk* (cdr v) s)) v)))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (cons (cons u v) s)]
          [(var? v) (cons (cons v u) s)]
          [(and (pair? u) (pair? v)) (unify (cdr u) (cdr v) (unify (car u) (car v) s))]
          [(equal? u v) s]
          [else (list->amb '())])))
(define ((≡ u v) s) (unify u v s))
(define-syntax-rule (run* (x ...) g ...)
  (let ([x (var 'x)] ...)
    (in-amb (walk* (list x ...) ((conj g ...) empty-s)))))

(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))
(define ((betweenᵒ₀ lo x hi) s)
  ((≡ x (list->amb (inclusive-range (walk lo s) (walk hi s)))) s))

;; ── Noah 的原样（只把内层的 v* 改名，否则是「先用后定义」）──
(define ((disj . g*) s) ((list->amb g*) s))
(define conj₀ compose)                                       ; 原样：compose
(define (conj . g*) (apply compose (reverse g*)))            ; 改：从左到右
(define fail    (disj))
(define succeed (conj))

(define (((predicate->relation p?) . t*) s)
  (define v* (for/list ([t (in-list t*)]) (walk t s)))
  (define g (if (apply p? v*) succeed fail))
  (g s))
(define pythᵒ (predicate->relation pyth?))

(define (try thunk) (with-handlers ([exn:fail? (λ (e) (list 'error (exn-message e)))]) (thunk)))

(printf "1. succeed / fail：~s ~s\n" (in-amb (succeed 's0)) (in-amb (fail 's0)))
(printf "2. 三角形（conj 从左到右）：\n   ~s\n"
        (run* (a b c) (betweenᵒ₀ 1 a 20) (betweenᵒ₀ a b 20) (betweenᵒ₀ b c 20) (pythᵒ a b c)))
(printf "3. conj 直接用 compose（从右到左，pythᵒ 先跑）：\n   ~s\n"
        (try (λ () (let ([a (var 'a)] [b (var 'b)] [c (var 'c)])
                     (in-amb (walk* (list a b c)
                                    ((conj₀ (betweenᵒ₀ 1 a 20) (betweenᵒ₀ a b 20) (betweenᵒ₀ b c 20) (pythᵒ a b c))
                                     empty-s)))))))
(printf "4. 参数还没确定：~s\n" (try (λ () (run* (c) (pythᵒ 3 4 c)))))
(printf "5. 全是值：~s ~s\n" (run* () (pythᵒ 3 4 5)) (run* () (pythᵒ 3 4 6)))

;; walk 只查一层：变量绑到的结构里还有变量时，谓词拿到的东西里夹着 var
(define (sum3? t) (= 3 (apply + t)))
(define sum3ᵒ (predicate->relation sum3?))
(printf "6. 结构里的变量（用 walk）：~s\n"
        (try (λ () (run* (x p) (≡ x 1) (≡ p (list x 2)) (sum3ᵒ p)))))

;; ── 改法：walk* 查到底；仍有变量就报出清楚的错 ──
(define (ground? t) (cond [(var? t) #f] [(pair? t) (and (ground? (car t)) (ground? (cdr t)))] [else #t]))
(define (((predicate->relation* p?) . t*) s)
  (define v* (for/list ([t (in-list t*)]) (walk* t s)))
  (unless (andmap ground? v*)
    (error 'predicate->relation "参数还没有确定，谓词无法判断"))
  ((if (apply p? v*) succeed fail) s))
(define sum3ᵒ* (predicate->relation* sum3?))
(define pythᵒ* (predicate->relation* pyth?))
(printf "7. 结构里的变量（用 walk*）：~s\n" (run* (x p) (≡ x 1) (≡ p (list x 2)) (sum3ᵒ* p)))
(printf "8. 参数还没确定（改后）：~s\n" (try (λ () (run* (c) (pythᵒ* 3 4 c)))))

;; ── 10/4 21:33：不用 ≤ᵒ，改用 inclusive-rangeᵒ ──
;; 两个「抬」：谓词抬成只做检查的关系；函数（可以用 amb）抬成关系，最后一个参数是结果
(define ∘ compose)
(define (((function->relation f) . t*) s)
  (define-values (in* out*) (split-at-right t* 1))
  (define v* (for/list ([t (in-list in*)]) (walk* t s)))
  (unless (andmap ground? v*)
    (error 'function->relation "输入还没有确定，函数无法计算"))
  ((≡ (car out*) (apply f v*)) s))

(define inclusive-rangeᵒ (function->relation (∘ list->amb inclusive-range)))
(define +ᵒ               (function->relation +))

(printf "\n9. 新的程序（与第一节的循环逐行对应）：\n   ~s\n"
        (run* (a b c)
          (inclusive-rangeᵒ 1 20 a)
          (inclusive-rangeᵒ a 20 b)
          (inclusive-rangeᵒ b 20 c)
          (pythᵒ* a b c)))
(printf "10. (inclusive-rangeᵒ 1 3 x)：~s\n" (run* (x) (inclusive-rangeᵒ 1 3 x)))
(printf "11. 结果位置已经是值，变成检查：~s ~s\n"
        (run* () (inclusive-rangeᵒ 1 5 3)) (run* () (inclusive-rangeᵒ 1 5 9)))
(printf "12. 普通函数也能抬：(+ᵒ 1 2 x) ~s；(+ᵒ 1 2 3) ~s；(+ᵒ 1 2 4) ~s\n"
        (run* (x) (+ᵒ 1 2 x)) (run* () (+ᵒ 1 2 3)) (run* () (+ᵒ 1 2 4)))
(printf "13. 输入没确定：~s\n" (try (λ () (run* (x y) (inclusive-rangeᵒ x 3 y)))))
(printf "14. 顺序反过来（pythᵒ 在前）：~s\n"
        (try (λ () (run* (a b c) (pythᵒ* a b c) (inclusive-rangeᵒ 1 20 a) (inclusive-rangeᵒ a 20 b) (inclusive-rangeᵒ b 20 c)))))

;; ── 10/4 21:49 Noah：between 是用 amb 的函数，betweenᵒ 由它抬出来 ──
(define between  (∘ list->amb inclusive-range))
(define betweenᵒ (function->relation between))
(define inclusive-rangeᵒ/TRS (function->relation inclusive-range))   ; 按 TRS 的规矩：结果是整张列表

(printf "\n15. TRS 式的 inclusive-rangeᵒ：~s\n" (run* (r) (inclusive-rangeᵒ/TRS 1 3 r)))
(printf "16. B 末尾的 amb 版（用 between）：\n    ~s\n"
        (in-amb (let* ([a (between 1 20)] [b (between a 20)] [c (between b 20)])
                  (unless (pyth? a b c) (list->amb '()))
                  (list a b c))))
(printf "17. C 的关系版（用 betweenᵒ）：\n    ~s\n"
        (run* (a b c)
          (betweenᵒ 1 20 a)     ; l ≤ a ≤ h
          (betweenᵒ a 20 b)     ; a ≤ b ≤ h
          (betweenᵒ b 20 c)     ; b ≤ c ≤ h
          (pythᵒ* a b c)))      ; a² + b² = c²
