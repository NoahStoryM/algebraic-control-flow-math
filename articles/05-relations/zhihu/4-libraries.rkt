#lang racket/base
;; 知乎回答「miniKanren 的实现方式」的代码之四：同一段程序交给两个库。
;; 运行：racket 4-libraries.rkt
;; 需要 Racket 9.3 与 amb 3.0、typed-amb 3.0、ambKanren 3.0、miniKanren-typed 1.1。

;; 用流：miniKanren-typed，照《The Reasoned Schemer》第二版的代码写成
(module streams typed/racket/base
  (require typed/miniKanren/trs2)
  (provide answers)
  (defrel (appendo l t out)
    (conde
      [(== l '()) (== t out)]
      [(fresh (a d res)
         (== l (cons a d))
         (== out (cons a res))
         (appendo d t res))]))
  (define answers
    (list (run* (x y) (appendo x y '(1 2 3)))
          (run 4 (x y z) (appendo x y z)))))

;; 用 amb：ambKanren，同一门语言
(module ambs typed/racket/base
  (require typed/miniKanren/amb/trs2 typed/amb typed/amb/merge)
  (provide answers)
  (defrel (appendo l t out)
    (conde
      [(== l '()) (== t out)]
      [(fresh (a d res)
         (== l (cons a d))
         (== out (cons a res))
         (appendo d t res))]))
  (define answers
    (parameterize ([current-amb-merger amb-interleave])
      (list (run* (x y) (appendo x y '(1 2 3)))
            (run 4 (x y z) (appendo x y z))))))

(require (prefix-in s: 'streams) (prefix-in a: 'ambs))
(for ([s s:answers] [a a:answers])
  (printf "流   ~s\namb  ~s\n相同 ~a\n\n" s a (equal? s a)))
