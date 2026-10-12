#lang racket
;; 试验（10/5 18:21）：把 for/list、append-map、inclusive-range 换成 for/stream、in-inclusive-range，
;; amb 版的搜索是不是就成了惰性的？「只要第一组答案」是不是就做到了？
(require racket/control racket/stream)
(define tried 0)
(define (pyth? a b c) (set! tried (add1 tried)) (= (+ (* a a) (* b b)) (* c c)))

;; 正文的版本（列表）
(define (choose p*) (shift k (append-map k p*)))
(define-syntax-rule (for/amb clauses body ...) ((choose (for/list clauses (λ () body ...)))))
(define-syntax-rule (amb e ...) ((choose (list (λ () e) ...))))
(define-syntax-rule (in-amb e) (reset (list e)))
(define (between lo hi) (for/amb ([n (inclusive-range lo hi)]) n))
(define (check ok?) (unless ok? (amb)))
(define (right-triangles l h)
  (in-amb (let* ([a (between l h)] [b (between a h)] [c (between b h)])
            (check (pyth? a b c)) (list a b c))))

;; 流的版本：只换四个词
(define (choose/s p*) (shift k (for*/stream ([p (in-stream p*)] [v (in-stream (k p))]) v)))
(define-syntax-rule (for/amb/s clauses body ...) ((choose/s (for/stream clauses (λ () body ...)))))
(define-syntax-rule (amb/s e ...) ((choose/s (list (λ () e) ...))))
(define-syntax-rule (in-amb/s e) (reset (list e)))
(define (between/s lo hi) (for/amb/s ([n (in-inclusive-range lo hi)]) n))
(define (check/s ok?) (unless ok? (amb/s)))
(define (right-triangles/s l h)
  (in-amb/s (let* ([a (between/s l h)] [b (between/s a h)] [c (between/s b h)])
              (check/s (pyth? a b c)) (list a b c))))

(set! tried 0)
(printf "列表版 全部：~s，试了 ~a 组\n" (right-triangles 1 20) tried)
(set! tried 0)
(printf "列表版 取第一组：~s，试了 ~a 组\n" (first (right-triangles 1 20)) tried)
(set! tried 0)
(define s (right-triangles/s 1 20))
(printf "流版 还没取：试了 ~a 组\n" tried)
(printf "流版 取第一组：~s，试了 ~a 组\n" (stream-first s) tried)
(printf "流版 全部：~s，试了 ~a 组\n" (stream->list s) tried)
(set! tried 0)
(printf "流版 边界 3 到一百万，取第一组：~s，试了 ~a 组\n"
        (stream-first (right-triangles/s 3 1000000)) tried)
;; 第二组要等 a = 3 的候选全部试完（约 5×10¹¹ 组）：惰性了，但走法还是深度优先
(define th2 (thread (λ () (stream-first (stream-rest (right-triangles/s 3 1000000))))))
(sleep 1.5)
(printf "  取第二组，1.5 秒后还在算：~a\n" (thread-running? th2))
(kill-thread th2)
;; 上界无穷：深度优先走不出 a = 1（a = 1、b = 1 时 c 永远试不完）
(define (from n) (for/amb/s ([k (in-naturals n)]) k))
(define s∞ (in-amb/s (let* ([a (from 1)] [b (from a)] [c (from b)])
                       (check/s (pyth? a b c)) (list a b c))))
(printf "上界无穷：流本身立刻交出（~a），但取第一组不会停（深度优先卡在 a = 1、b = 1）\n" (stream? s∞))
(define th (thread (λ () (stream-first s∞))))
(sleep 1.5)
(printf "  1.5 秒后还在算：~a\n" (thread-running? th))
(kill-thread th)
