#lang racket
;; 知乎回答「miniKanren 的实现方式」的代码之三：把流换成 amb。
;; 运行：racket 3-amb.rkt（Racket 9.3；需要 amb 3.0）
;; 未知项、walk、unify、reify 原样取自 1-lists.rkt（改写自 microKanren，见那里的说明）。
(require amb amb/merge
         (only-in "1-lists.rkt" var walk unify reify))

;; ---- 目标：收一张代换，交出一张代换；别的可能由 amb 记着 ----
(define ((== u v) s) (or (unify u v s) (amb-fail)))
(define ((disj . g*) s) ((for/amb ([g g*]) g) s))
(define ((conj . g*) s) (for/fold ([s s]) ([g g*]) (g s)))

(define-syntax-rule (fresh (x ...) g ...)
  (λ (s) (let ([x (var 'x)] ...) ((conj g ...) s))))

;; n 是要几组答案，#f 是全要
(define-syntax-rule (run n (x ...) g ...)
  (let ([x (var 'x)] ...)
    (for/list ([_ (or n (in-naturals))]             ; 先数数：够了就不再去找下一组
               [s (in-amb ((conj g ...) '()))])
      (reify (list x ...) s))))

;; 关系的入口处让出一步
(define-syntax-rule (defrel (name x ...) g ...)
  (define ((name x ...) s)
    (amb-pause)
    ((conj g ...) s)))

(module+ main
  (define-syntax-rule (show e) (begin (write 'e) (display "\n  ⇒ ") (writeln e)))
  (define (within-2s thunk)
    (define ch (make-channel))
    (define th (thread (λ () (channel-put ch (thunk)))))
    (define v (sync/timeout 2 ch))
    (unless v (kill-thread th))
    (or v '两秒内没有答案))

  ;; amb 本身
  (show (for/list ([p (in-amb (let ([a (amb 1 2 3)] [b (amb 1 2 3)])
                                (unless (= (+ a b) 4) (amb-fail))
                                (list a b)))])
          p))

  (defrel (appendo l t out)
    (disj (conj (== l '()) (== t out))
          (fresh (a d res)
            (== l (cons a d))
            (== out (cons a res))
            (appendo d t res))))
  (show (run #f (x y) (appendo x y '(1 2 3))))

  ;; 写不完的答案
  (defrel (alwayso) (disj (== 1 1) (alwayso)))
  (show (run 3 (q) (alwayso) (== q 'again)))

  ;; 左边没有尽头，一个答案也不交
  (defrel (nevero) (nevero))
  (show (within-2s (λ () (run 1 (q) (disj (nevero) (== q 'here))))))
  (show (within-2s (λ () (parameterize ([current-amb-merger amb-interleave])
                           (run 1 (q) (disj (nevero) (== q 'here)))))))

  ;; 换了合并的办法，可这一支从不让出
  (define ((spino) s) ((spino) s))
  (show (within-2s (λ () (parameterize ([current-amb-merger amb-interleave])
                           (run 1 (q) (disj (spino) (== q 'here)))))))

  ;; 一次搜索，一步一步地问
  (define (count-from n)
    (amb n (begin (amb-pause) (count-from (add1 n)))))
  (let*-values ([(v1 next) (amb-generate* (λ () (count-from 0)))]
                [(v2 next) (next)]
                [(v3 next) (next)])
    (show (list v1 v2 v3)))

  ;; 合取的两种写法：答案相同，顺序可能不同
  (define ((conj/local g1 g2) s) (g2 (amb-local (g1 s))))
  (define x (var 'x)) (define y (var 'y))
  (define three (disj (disj (== x 1) (== x 2)) (== x 3)))
  (define later (λ (s) (amb-pause) ((== y 'p) s)))
  (define (xs goal) (for/list ([s (in-amb (goal '()))]) (walk x s)))
  (parameterize ([current-amb-merger amb-interleave])
    (show (list (xs (conj three later))
                (xs (conj/local three later))))))
