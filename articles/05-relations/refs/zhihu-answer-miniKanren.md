> In order to do relational programming, we need only two constants: #s and #u, and only three operators: ==, fresh, and conde.

构造性证明具有一个重要特征：比方说 `∀x.∃y. P(x, y)`，这个声明的证明是可构造的，那么对于任意输入 `x`，我们都能给出具体的 `y`，并证明 `y` 满足所需的性质。换句话说，构造性证明本身就包含或对应着一个具体的构造方法（算法），能够实际地产生满足条件的对象。

在`miniKanren`中，我们可以通过以下代码来构造满足条件的集合 `{x | ∃y. P(x, y)}`：

```racket
(define (P x y)
  (fresh ()
    (conde
      [(== y 5)]
      [(== y 6)])
    (== y x)))
(run* (x) (fresh (y) (P x y)))
```

很明显 `P(x, y)` 的定义是 `(y ≡ 5 ∨ y ≡ 6) ∧ y ≡ x`。可以看到 `miniKanren` 与构造性逻辑存在明确的对应关系：

| miniKanren          | Constructive Logic |
|:--------------------|--------------------|
| `#s`                | `⊤ `               |
| `#u`                | `⊥`                |
| `(== t1 t2)`        | `t1 ≡ t2`          |
| `(conde [g1] [g2])` | `g1 ∨ g2`          |
| `(fresh () g1 g2)`  | `g1 ∧ g2`          |
| `(fresh (x) (P x))` | `∃x. P(x)`         |
| `(run* (x) (P x))`  | `{x | P(x)}`       |

`microKanren` 实现很简洁，合一可以看作双向的模式匹配，回溯是用 Stream Monad 实现的，需要显式处理不同的可能。直接使用 `amb` 操作符可以让回溯逻辑更加清爽直观。以下是基于 `amb` 的`microKanren`完整实现：

```racket
;; Jason Hemann and Dan Friedman
;; microKanren, final implementation from paper
#lang typed/racket/base

(require racket/match typed/amb)
(provide (all-defined-out))


(define-type Term
  (∪ Boolean Number Char Bytes String Keyword Null Symbol
     Var (Pair Term Term)))
(define-type Substitution (Listof (Pair Var Term)))
(define-type Goal (→ State State))

(struct var
  ([tag : Any])
  #:type-name Var
  #:transparent)

(struct state
  ([substitution : Substitution]
   [counter : Natural])
  #:type-name State
  #:transparent)


(: var=? (→ Var Var Boolean))
(define (var=? x1 x2) (equal? x1 x2))

(: empty-s Substitution)
(: size-s (→ Substitution Index))
(: ext-s (→ Var Term Substitution Substitution))
(define empty-s '())
(define (size-s s) (length s))
(define (ext-s x v s)
  (when (occurs? x v s) (amb))
  `([,x . ,v] . ,s))

(: occurs? (→ Var Term Substitution Boolean))
(define (occurs? x v s)
  (let ([v (walk v s)])
    (or (and (var? v)
             (var=? x v))
        (and (pair? v)
             (or (occurs? x (car v) s)
                 (occurs? x (cdr v) s))))))

(: walk (→ Term Substitution Term))
(define (walk v s)
  (cond
    [(and (var? v) (assoc v s var=?))
     => (match-λ [(cons _ v) (walk v s)])]
    [else v]))

(: unify (→ Term Term Substitution Substitution))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond
      [(and (var? u) (var? v) (var=? u v)) s]
      [(var? u) (ext-s u v s)]
      [(var? v) (ext-s v u s)]
      [(and (pair? u) (pair? v))
       (unify (cdr u) (cdr v) (unify (car u) (car v) s))]
      [(equal? u v) s]
      [else (amb)])))

(: call/fresh (→ (→ Var Goal) Goal))
(define ((call/fresh f) s/c)
  (match-define (state s c) s/c)
  (define g (f (var c)))
  (g (state s (add1 c))))

(: == (→ Term Term Goal))
(define ((== u v) s/c)
  (match-define (state s c) s/c)
  (state (unify u v s) c))

(: disj (→ Goal Goal Goal))
(: conj (→ Goal Goal Goal))
(define ((disj g1 g2) s/c) ((amb g1 g2) s/c))
(define ((conj g1 g2) s/c) (g2 (g1 s/c)))

(: fail Goal)
(: succeed Goal)
(define (fail s/c) (amb))
(define (succeed s/c) s/c)


(: walk* (→ Term Substitution Term))
(define (walk* v s)
  (let ([v (walk v s)])
    (if (pair? v)
        (cons (walk* (car v) s)
              (walk* (cdr v) s))
        v)))

(: reify-name (→ Index Symbol))
(define (reify-name n)
  (string->symbol (format "_.~a" n)))

(: reify-s (→ Term Substitution Substitution))
(define (reify-s v s)
  (let ([v (walk v s)])
    (cond
      [(var? v) (ext-s v (reify-name (size-s s)) s)]
      [(pair? v) (reify-s (cdr v) (reify-s (car v) s))]
      [else s])))

(: reify (→ Term Term))
(define (reify v) (walk* v (reify-s v empty-s)))


(define-syntax-rule (λG (x) body ...) (ann (λ (x) body ...) Goal))
(define-syntax-rule (Zzz g) (λG (s) (g s)))

(define-syntax-rule (disj+ g1 g2) (disj (Zzz g1) (Zzz g2)))
(define-syntax-rule (conj+ g1 g2) (conj (Zzz g1) (Zzz g2)))

(define-syntax all
  (syntax-rules ()
    [(_) succeed]
    [(_ g) (Zzz g)]
    [(_ g0 g ...) (conj (Zzz g0) (all g ...))]))

(define-syntax fresh
  (syntax-rules ()
    [(_ () g ...) (all g ...)]
    [(_ (x0 x ...) g ...)
     (call/fresh
      (λ (x0)
        (fresh (x ...) g ...)))]))

(define-syntax conde
  (syntax-rules (else)
    [(_) fail]
    [(_ [else g ...]) (all g ...)]
    [(_ [g ...]) (all g ...)]
    [(_ [g ...] c ...)
     (disj+ (all g ...) (conde c ...))]))

(define-syntax-rule (run n^ (x) g* ...)
  (let ([n : Real (or n^ +inf.0)]
        [x (var 0)]
        [g (fresh (x) g* ...)]
        [s/c (state empty-s 0)])
    (for/list : (Listof Term)
              ([_ (in-range n)]
               [s/c (in-amb (g s/c))])
      (match-define (state s c) s/c)
      (reify (walk* x s)))))
(define-syntax-rule (run* (x) g* ...) (run #f (x) g* ...))
```
