#lang racket
;;; amb 的三种实现草图（2026-10-02，创作者笔记的素材，不进第五篇正文）
;;; 运行：raco test notes/amb-sketches.rkt
;;; 期望值取自 Noah 的 amb 库 v2.0（README 与 scribblings 里的例子；我用库的 private/amb.rkt 实际跑过）。
;;;
;;; 一、第五篇的 choose / fail / collect 上面加三行，就是一个最小的 amb（急切、深度优先、只能有限）
;;; 二、把「谁来调用 k」从 choose 挪到边界上的循环，就是库的做法（惰性、策略可换）
;;; 三、control-context 文档里 call/cc 的写法，以及在它上面补一个 in-amb 要添什么

(require racket/control racket/stream rackunit data/queue)

(define (pyth? a b c) (= (+ (* a a) (* b b)) (* c c)))
(define triples '((3 4 5) (5 12 13) (6 8 10) (8 15 17) (9 12 15) (12 16 20)))


;;; ═══════════════════════════════════════════════════════════════════
;;; 一、最小的 amb：第五篇的三个定义，加三行语法
;;; ═══════════════════════════════════════════════════════════════════
(module minimal racket
  (require racket/control)
  (provide (all-defined-out))
  ;; 第五篇「擦除延续参数」一节的原样定义
  (define (choose p*) (shift k (append-map k p*)))
  (define (fail) (choose '()))
  (define (collect thunk) (reset (list (thunk))))
  ;; amb 的备选是表达式，选中了才求值，所以各包一层 λ，选出来再调用
  (define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
  (define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
  (define-syntax-rule (in-amb e) (collect (λ () e))))       ; 交出列表，不是流

(module+ test
  (require (prefix-in m: (submod ".." minimal)))
  ;; 库文档里有限、深度优先的例子，结果逐字相同
  (check-equal? (m:in-amb (m:amb 1 2 3)) '(1 2 3))
  (check-equal? (m:in-amb (let ([n (m:amb 1 2 3 4 5)]) (unless (odd? n) (m:amb)) (* n n))) '(1 9 25))
  (check-equal? (m:in-amb (m:amb (m:amb 1 2) (m:amb) (m:amb 'a 'b))) '(1 2 a b))
  (check-equal? (m:in-amb (m:amb 1 (m:amb 2 3) (m:amb 4 5 6) 7 8)) '(1 2 3 4 5 6 7 8))
  (check-equal? (m:in-amb (let* ([x (m:amb 1 2)] [y (m:amb 'a 'b)] [z (m:amb x y)]) z))
                '(1 a 1 b 2 a 2 b))
  (check-equal? (m:in-amb (m:for/amb ([c "hello"]) c)) '(#\h #\e #\l #\l #\o))
  (check-equal? (m:in-amb (m:for/amb ([x '(1 2)]) (m:amb x (- x)))) '(1 -1 2 -2))
  ;; 做不到的三件事（都是第五篇「未解的线索」）：
  ;; 1. 只要第一组：整个搜索做完才交出列表，1540 组候选一组不少
  (let ([tried 0])
    (define (tri l h)
      (define a (m:for/amb ([a (inclusive-range l h)]) a))
      (define b (m:for/amb ([b (inclusive-range a h)]) b))
      (define c (m:for/amb ([c (inclusive-range b h)]) c))
      (set! tried (add1 tried))
      (unless (pyth? a b c) (m:amb))
      (list a b c))
    (check-equal? (first (m:in-amb (tri 1 20))) '(3 4 5))
    (check-equal? tried 1540))
  ;; 2. 无穷的备选：(m:for/amb ([i (in-naturals)]) i) 的 for/list 永远不结束（不运行）
  ;; 3. 换搜索策略：顺序由 append-map 的调用顺序定死，只有深度优先
  )


;;; ═══════════════════════════════════════════════════════════════════
;;; 二、把调用 k 的事交给边界：库的做法，压到最小
;;; ═══════════════════════════════════════════════════════════════════
;;; 第五篇：(define (choose p*) (shift k (append-map k p*)))   choose 自己调用 k，等待的工作留在宿主栈上
;;; 这里：  (define (choose p*) (shift k (branch k p*)))        choose 不调用 k，把 k 连同备选交到边界
;;; 边界上的循环手里有一张待办列表（库里叫 frontier，第四篇的「前沿」）：
;;; 每次运行排在最前的一项，得到一个答案就交出并停下，得到一项新的待办就排进去。
;;; 往前排是深度优先，往后排是广度优先；交出答案后停在流里，所以取第一个就不再往下搜。
;;; 协议照库的来（一项待办留在原处，每次走它的下一个备选），所以广度优先的顺序与库相同。
;;; 库里另有的东西这里都没有：公平（current-amb-fair?）、多值、shuffler、向量压缩、
;;; 不定长 for/amb 的协程写法、专门的 prompt tag。
(module frontier racket
  (require racket/control racket/stream)
  (provide (all-defined-out))
  ;; 一项待办：拿着 k 和还没走过的备选；每运行一次，走下一个备选。
  ;; 交出 #f（备选用完）、(list 答案)（这条时间线走到了头），或者一项新的待办（又遇到了 choose）。
  (define (make-todo k alts)                                 ; alts 是一个流，可以无穷
    (λ ()
      (and (not (stream-empty? alts))
           (let ([p (stream-first alts)])
             (set! alts (stream-rest alts))
             (k p)))))
  (define (choose p*) (shift k (make-todo k p*)))            ; 不调用 k，把它交到边界上
  (define (fail) (choose '()))
  (define current-depth-first? (make-parameter #t))
  (define (in-amb* thunk)
    (define depth-first? (current-depth-first?))
    (define root (make-todo (λ (_) (reset (list (thunk)))) '(start)))
    (let loop ([todo* (list root)])
      (if (null? todo*)
          empty-stream
          (let ([r ((car todo*))])
            (cond
              [(not r) (loop (cdr todo*))]                   ; 这一项的备选用完了，丢掉
              [(procedure? r)                                ; 新的待办：排到前面是深度优先，排到后面是广度优先
               (loop (if depth-first? (cons r todo*) (append todo* (list r))))]
              [else (stream-cons (car r) (loop todo*))])))))  ; 答案：交出去；下一个要了才找
  (define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
  (define-syntax-rule (for/amb clauses body ...) ((choose (for/stream clauses (λ () body ...)))))
  (define-syntax-rule (in-amb e) (in-amb* (λ () e))))

(module+ test
  (require (prefix-in f: (submod ".." frontier)))
  (check-equal? (stream->list (f:in-amb (f:amb 1 2 3))) '(1 2 3))
  (check-equal? (stream->list (f:in-amb (let ([n (f:amb 1 2 3 4 5)]) (unless (odd? n) (f:amb)) (* n n))))
                '(1 9 25))
  (check-equal? (stream->list (f:in-amb (f:amb (f:amb 1 2) (f:amb) (f:amb 'a 'b)))) '(1 2 a b))
  (check-equal? (stream->list (f:in-amb (f:amb 1 (f:amb 2 3) (f:amb 4 5 6) 7 8))) '(1 2 3 4 5 6 7 8))
  (check-equal? (stream->list (f:in-amb (let* ([x (f:amb 1 2)] [y (f:amb 'a 'b)] [z (f:amb x y)]) z)))
                '(1 a 1 b 2 a 2 b))
  (check-equal? (stream->list (f:in-amb (f:for/amb ([x '(1 2)]) (f:amb x (- x))))) '(1 -1 2 -2))
  ;; 最小版做不到的三件事，这里都做得到
  ;; 1. 只要第一组：试到第 420 组候选就停（库是同一个数）
  (let ([tried 0])
    (define (tri l h)
      (define a (f:for/amb ([a (inclusive-range l h)]) a))
      (define b (f:for/amb ([b (inclusive-range a h)]) b))
      (define c (f:for/amb ([c (inclusive-range b h)]) c))
      (set! tried (add1 tried))
      (unless (pyth? a b c) (f:amb))
      (list a b c))
    (check-equal? (stream-first (f:in-amb (tri 1 20))) '(3 4 5))
    (check-equal? tried 420)
    (set! tried 0)
    (check-equal? (stream->list (f:in-amb (tri 1 20))) triples)
    (check-equal? tried 1540))
  ;; 2. 无穷的备选
  (check-equal? (for/list ([x (f:in-amb (f:for/amb ([i (in-naturals)]) i))] [_ 5]) x) '(0 1 2 3 4))
  ;; 3. 换搜索策略：广度优先（期望值是库在 current-amb-depth-first? 为 #f 时的结果）
  (check-equal? (parameterize ([f:current-depth-first? #f])
                  (stream->list (f:in-amb (f:amb 1 (f:amb 2 3) (f:amb 4 5 6) 7 8))))
                '(1 7 8 2 3 4 5 6)))


;;; ═══════════════════════════════════════════════════════════════════
;;; 三、control-context 文档里的 call/cc 写法，再补一个 in-amb
;;; ═══════════════════════════════════════════════════════════════════
;;; 文档里的 amb 没有边界：call/cc 捕获的是到程序尽头的全部延续，搜索找到第一个答案就带着它往下走，
;;; 想要下一个答案得再调用一次 (amb)。所以它天然是「只要第一组」，却没有地方把所有答案收起来。
;;; 要补出 in-amb，得亲手搭一个边界：进入时存下逃逸延续，答案用可变状态一个个记下，
;;; 每记一个就 (amb) 逼搜索回溯，待办空了再从存下的延续跳出去。
(module callcc racket
  (require data/queue racket/sequence racket/stream)
  (provide (all-defined-out))
  ;; ── 以下到 for/amb 为止，是文档「Ambiguous Operator」一节的代码，取 call/cc 的那一版 ──
  (define amb-frontier (make-queue))
  (define empty-handler (λ () (error "Amb tree exhausted")))
  (define (run amb-tree) (amb-tree))
  (define (make-amb-tree)
    (call/cc
     (λ (amb-tree)
       (enqueue-front! amb-frontier amb-tree)
       (search))))
  (define (search)
    (if (queue-empty? amb-frontier)
        (empty-handler)
        (let ([amb-tree (dequeue! amb-frontier)])
          (enqueue-front! amb-frontier amb-tree)
          (run amb-tree))))
  (define (make-amb more? get)
    (make-amb-tree)
    (if (more?) (get) (begin (dequeue! amb-frontier) (search))))
  (define sequence->amb (compose make-amb sequence-generate))
  (define-syntax-rule (amb e* ...) (sequence->amb (stream e* ...)))
  (define-syntax-rule (for/amb c b* ...) (sequence->amb (for/stream c b* ...)))
  ;; ── 补上的 in-amb：一个逃逸延续加两处可变状态 ──
  (define (in-amb* thunk)
    (define answers '())
    (define saved-frontier amb-frontier)
    (define saved-handler empty-handler)
    (begin0
      (let/cc return                                         ; 手搭的边界
        (set! amb-frontier (make-queue))
        (set! empty-handler (λ () (return (reverse answers))))
        (let ([v (thunk)])
          (set! answers (cons v answers))                    ; 记下一个答案
          (amb)))                                            ; 再逼搜索回溯去找下一个
      (set! amb-frontier saved-frontier)
      (set! empty-handler saved-handler)))
  (define-syntax-rule (in-amb e) (in-amb* (λ () e))))

(module+ test
  (require (prefix-in c: (submod ".." callcc)))
  ;; 文档里的例子：不包 in-amb，直接得到第一个答案
  (check-equal?
   (let ([w-1 (c:amb "the" "that" "a")]
         [w-2 (c:amb "frog" "elephant" "thing")]
         [w-3 (c:amb "walked" "treaded" "grows")]
         [w-4 (c:amb "slowly" "quickly")])
     (define (joins? left right)
       (equal? (string-ref left (sub1 (string-length left))) (string-ref right 0)))
     (unless (joins? w-1 w-2) (c:amb))
     (unless (joins? w-2 w-3) (c:amb))
     (unless (joins? w-3 w-4) (c:amb))
     (list w-1 w-2 w-3 w-4))
   '("that" "thing" "grows" "slowly"))
  ;; 补上的 in-amb：收齐所有答案
  (check-equal? (c:in-amb (c:amb 1 2 3)) '(1 2 3))
  (check-equal? (c:in-amb (let ([n (c:amb 1 2 3 4 5)]) (unless (odd? n) (c:amb)) (* n n))) '(1 9 25))
  (check-equal? (c:in-amb (let* ([x (c:amb 1 2)] [y (c:amb 'a 'b)] [z (c:amb x y)]) z))
                '(1 a 1 b 2 a 2 b))
  ;; 文档那一版的一个限制（与补上的 in-amb 无关，单独用 (amb) 逐个要答案也一样）：
  ;; 备选本身又是 amb 时会丢答案。库 v2 的结果是 (1 2 3 4 5 6 7 8)，这里丢了 4 5 6。
  ;; 原因：(amb e …) 写成 (sequence->amb (stream e …))，内层的 amb 在外层生成器的 get 里面求值，
  ;; 捕获的延续里带着 get 的后半截 (set! s (stream-rest s))；内层有几个备选，这半截就重入几次，
  ;; 外层的流也就多前进几格。把备选换成 thunk、选出来以后再调用，就不丢了。
  (check-equal? (c:in-amb (c:amb 1 (c:amb 2 3) (c:amb 4 5 6) 7 8)) '(1 2 3 7 8))
  (check-equal? (c:in-amb (let* ([a (c:for/amb ([a (inclusive-range 1 20)]) a)]
                                 [b (c:for/amb ([b (inclusive-range a 20)]) b)]
                                 [c (c:for/amb ([c (inclusive-range b 20)]) c)])
                            (unless (pyth? a b c) (c:amb))
                            (list a b c)))
                triples))
