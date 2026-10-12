# 自由单子从 struct 语法树引出：草稿代码（2026-10-07，Claude 写，Racket 8.10 实测）

## typed.rkt（`#lang typed/racket`，真的过类型检查）

```racket
#lang typed/racket
;; 真的过类型检查的部分（系列正文用 no-check，这里只是确认类型写得出来）

;; ---- 一、算术表达式：叶子是变量 ----
(struct (a) var ([name : a]) #:transparent)
(struct lit ([n : Integer]) #:transparent)
(struct (a) add ([l : (Expr a)] [r : (Expr a)]) #:transparent)
(struct (a) mul ([l : (Expr a)] [r : (Expr a)]) #:transparent)
(define-type (Expr a) (U (var a) lit (add a) (mul a)))

;; 代入：把每个变量换成一棵树
(: subst (∀ (a b) (→ (→ a (Expr b)) (→ (Expr a) (Expr b)))))
(define ((subst f) e)
  (cond [(var? e) (f (var-name e))]
        [(lit? e) e]
        [(add? e) (add ((subst f) (add-l e)) ((subst f) (add-r e)))]
        [else     (mul ((subst f) (mul-l e)) ((subst f) (mul-r e)))]))

;; 求值：给每种节点一个运算（一个「代数」），再给变量一个值
(: fold-expr (∀ (a r) (→ (→ a r) (→ Integer r) (→ r r r) (→ r r r) (→ (Expr a) r))))
(define ((fold-expr on-var on-lit on-add on-mul) e)
  (let loop ([e e])
    (cond [(var? e) (on-var (var-name e))]
          [(lit? e) (on-lit (lit-n e))]
          [(add? e) (on-add (loop (add-l e)) (loop (add-r e)))]
          [else     (on-mul (loop (mul-l e)) (loop (mul-r e)))])))

(define e1 : (Expr Symbol) (add (var 'x) (mul (lit 2) (var 'y))))
(define env : (→ Symbol Integer) (λ (s) (if (eq? s 'x) 10 3)))
(define eval-int ((inst fold-expr Symbol Integer) env (λ (n) n) + *))
(define show ((inst fold-expr Symbol String) symbol->string number->string
              (λ (l r) (format "(~a + ~a)" l r)) (λ (l r) (format "~a * ~a" l r))))
(eval-int e1)   ; 16
(show e1)       ; "(x + 2 * y)"
;; 代入后求值 = 先求出每个变量的值再求值
(define s : (→ Symbol (Expr Symbol)) (λ (v) (if (eq? v 'x) (add (var 'y) (lit 1)) (var v))))
(eval-int ((subst s) e1))                         ; 3+1 + 2*3 = 10
(((inst fold-expr Symbol Integer) (λ (v) (eval-int (s v))) (λ (n) n) + *) e1) ; 10

;; ---- 二、孩子按「操作的返回值」索引：字段是函数 ----
(struct (a) ret ([val : a]))
(struct (a) get ([k : (→ Integer (Prog a))]))
(struct (a) put ([s : Integer] [k : (→ (Prog a))]))
(define-type (Prog a) (U (ret a) (get a) (put a)))

(: graft (∀ (a b) (→ (→ a (Prog b)) (→ (Prog a) (Prog b)))))
(define ((graft f) m)
  (cond [(ret? m) (f (ret-val m))]
        [(get? m) (get (λ ([s : Integer]) ((graft f) ((get-k m) s))))]
        [else     (put (put-s m) (λ () ((graft f) ((put-k m)))))]))

;; 两个解释器读同一棵树
(: run-state (∀ (a) (→ (Prog a) Integer (Pairof a Integer))))
(define (run-state m s)
  (cond [(ret? m) (cons (ret-val m) s)]
        [(get? m) (run-state ((get-k m) s) s)]
        [else     (run-state ((put-k m)) (put-s m))]))
(: trace (∀ (a) (→ (Prog a) Integer (Listof Integer))))   ; 只记下每次写入了什么
(define (trace m s)
  (cond [(ret? m) '()]
        [(get? m) (trace ((get-k m) s) s)]
        [else     (cons (put-s m) (trace ((put-k m)) (put-s m)))]))

;; 手写的 CPS 形状：(op arg (λ (v) rest))
(define tick : (Prog Integer)
  (get (λ ([s : Integer]) (put (+ s 1) (λ () (ret s))))))
(define twice ((graft (λ ([a : Integer]) ((graft (λ ([b : Integer]) (ret (list a b)))) tick))) tick))
(run-state twice 5)   ; ((5 6) . 7)
(trace twice 5)       ; (6 7)
```

输出：

```
16
"(x + 2 * y)"
10
10
'((5 6) . 7)
'(6 7)
```

## direct.rkt（`#lang racket`，直接风格，shift / reset）

```racket
#lang racket
(require racket/control)
;; 第五篇的 choose / in-amb，把动词 append-map 拿掉，只留下名词 (p*, k)
(struct leaf (val) #:transparent)
(struct node (alts k))                       ; 操作 choose：参数 alts，剩余工作 k

(define (choose p*) (shift k (node p* k)))   ; 第五篇：(shift k (append-map k p*))
(define-syntax-rule (in-tree e) (reset (leaf e)))   ; 第五篇：(reset (list e))

(define (between l h) (choose (inclusive-range l h)))
(define (triples l h)
  (in-tree (let* ([a (between l h)] [b (between a h)] [c (between b h)])
             (if (= (+ (* a a) (* b b)) (* c c)) (list a b c) (choose '())))))

;; 解释器一：深度优先，收成列表。正是第五篇的 in-amb
(define (dfs t)
  (match t
    [(leaf v) (list v)]
    [(node p* k) (append-map (λ (p) (dfs (k p))) p*)]))
;; 解释器二：只要第一个解，其余备选的 k 根本不调用
(define calls 0)
(define (first-solution t)
  (match t
    [(leaf v) (list v)]
    [(node p* k) (for/or ([p (in-list p*)])
                   (set! calls (add1 calls))
                   (first-solution (k p)))]))
;; 解释器三：广度优先（按层），同一棵树换一种走法
(define (bfs t)
  (let loop ([level (list t)])
    (if (null? level) '()
        (append (for/list ([t level] #:when (leaf? t)) (leaf-val t))
                (loop (for*/list ([t level] #:when (node? t) [p (node-alts t)]) ((node-k t) p)))))))

(dfs (triples 1 20))
(first-solution (triples 1 20)) calls
(equal? (sort (bfs (triples 1 20)) string<? #:key ~a) (sort (dfs (triples 1 20)) string<? #:key ~a))

;; 深浅不一的树上，两种走法的次序不同
(define (uneven) (in-tree (if (choose '(#t #f)) (+ 10 (choose '(1 2))) 0)))
(dfs (uneven)) (bfs (uneven))

;; 第六篇的 reflect / reify：树世界只是又一个世界
(define ((reflect connector) m) (shift k ((connector k) m)))
(define ((reify unit) thunk) (reset (unit (thunk))))
(define ((graft f) t)                         ; 树世界的连接器：接在 k 后面，什么也不运行
  (match t
    [(leaf v) (f v)]
    [(node p* k) (node p* (λ (p) ((graft f) (k p))))]))
(define (perform p*) ((reflect graft) (node p* leaf)))   ; 一般的「操作」= 反射一个单节点的树
(define t2 ((reify leaf) (λ () (let* ([a (perform '(1 2 3))] [b (perform (list a (* 10 a)))]) (cons a b)))))
(dfs t2)
```

输出：

```
'((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20))
'((3 4 5))
464
#t
'(11 12 0)
'(0 11 12)
'((1 . 1) (1 . 10) (2 . 2) (2 . 20) (3 . 3) (3 . 30))
```
