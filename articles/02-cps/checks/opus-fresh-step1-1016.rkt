#lang typed/racket/no-check
;; 第一步的验证代码：在 Racket 8.10 下运行，直接 require 第二篇的 code.rkt。
;; 收进数学仓库时只改了上一行的 require 路径（原为 /root/acf/...），并补上 racket/port。
(require (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt") rackunit racket/port)

;; 把 𝒦 箭头经 𝒰 落到 𝒟：先 flip 到 𝒰，再用 neg 的第二种读法。
;; 正文里它是练习的答案；这里给个临时名字 ext，只为了写测试。
(: ext (∀ (p q) (→ (→𝒦 p q) (→𝒟 (¬¬ p) (¬¬ q)))))
(define ext (∘ neg flip))

;; 一些 𝒦 箭头：两支纯的，一支会经 cps:call/cc 捕获的出口跳走。
(define cps:add1   (cps add1))
(define cps:double (cps (λ (x) (* 2 x))))

;; ---------------------------------------------------------------
;; 1. 宏里每个绑定做的事，就是 ext：(∘𝒦 cps:kv id) = (ext cps:kv)
(define (cps:kv v) (cps:* v 3))
(define (id* kkv) kkv)                       ; 宏里那个类型为 (¬¬a →𝒦 a) 的 id
(check-equal? (anf:eval ((∘𝒦 cps:kv id*) (cps:+ 1 2))) 9)
(check-equal? (anf:eval ((ext cps:kv)    (cps:+ 1 2))) 9)
(check-equal? (anf:eval (anf:let* ([v (cps:+ 1 2)]) (cps:* v 3))) 9)

;; ---------------------------------------------------------------
;; 2. neg² = (∘ ext cps)：纯的一步落到 𝒟，就是 neg²
(check-equal? (anf:eval ((neg² add1)       (cps:+ 1 2))) 4)
(check-equal? (anf:eval ((ext (cps add1))  (cps:+ 1 2))) 4)

;; 3. cps 拆成「先包起来，再在包里做」：(cps f) = (∘ (neg² f) cps:id)
(check-equal? (anf:eval ((cps add1) 5))                  6)
(check-equal? (anf:eval ((∘ (neg² add1) cps:id) 5))      6)

;; 4. neg² 搬过去的箭头照原样接得上
(check-equal? (anf:eval ((neg² (∘ add1 (λ (x) (* 2 x)))) (cps:id 5)))
              (anf:eval ((∘ (neg² add1) (neg² (λ (x) (* 2 x)))) (cps:id 5))))
(check-equal? (anf:eval ((neg² id) (cps:id 5))) (anf:eval (cps:id 5)))

;; ---------------------------------------------------------------
;; 5. ∘𝒦 落到 𝒟 之后就是普通的 ∘
;;    (∘𝒦 g f) = (∘ (ext g) f)，(ext (∘𝒦 g f)) = (∘ (ext g) (ext f))
;;    g 用一支会跳走的箭头，确认带控制的箭头也成立。
(define (escape-if-big cps:return)
  (λ (y) (if (> y 5) (cps:return 'too-big) (cps:id y))))
(check-equal? (anf:eval (anf:let/cc cps:return
                          ((∘𝒦 (escape-if-big cps:return) cps:double) 3)))
              'too-big)
(check-equal? (anf:eval (anf:let/cc cps:return
                          ((∘ (ext (escape-if-big cps:return)) cps:double) 3)))
              'too-big)
(check-equal? (anf:eval (anf:let/cc cps:return
                          ((ext (∘𝒦 (escape-if-big cps:return) cps:double)) (cps:id 3))))
              (anf:eval (anf:let/cc cps:return
                          ((∘ (ext (escape-if-big cps:return)) (ext cps:double)) (cps:id 3)))))
(check-equal? (anf:eval ((∘𝒦 cps:add1 cps:double) 2)) 5)

;; 6. 单位律：(ext cps:id) 什么也不做；(∘ (ext f) cps:id) 回到 f
(check-equal? (anf:eval ((ext cps:id) (cps:+ 1 2))) 3)
(check-equal? (anf:eval ((∘ (ext cps:double) cps:id) 21)) 42)

;; ---------------------------------------------------------------
;; 7. 反过来不行：¬¬a → ¬¬b 的纯函数比 𝒦 箭头多。
;;    discard 不管交来的计算，直接交出 0；它不是任何 𝒦 箭头的 ext。
(define ((discard kka) kb) (kb 0))
(define cps:zero-ish (∘ discard cps:id))     ; 先包再 discard，得到的 𝒦 箭头
;; 交来的计算会跳走：discard 把跳转丢了，ext 版本保留了它
(check-equal? (anf:eval (anf:let/cc cps:return (discard (cps:return 'escaped)))) 0)
(check-equal? (anf:eval (anf:let/cc cps:return ((ext cps:zero-ish) (cps:return 'escaped))))
              'escaped)

;;    twice 把交来的计算启动两次，前面的工作也就做两次。
(define ((twice kka) kb)
  (kka (λ (a1) (kka (λ (a2) (kb (+ a1 a2)))))))
(define cps:dbl (∘ twice cps:id))            ; = (λ (a) (cps:id (+ a a)))
(define noisy (anf:let* ([_ (cps:display "x")]) (cps:id 1)))
(check-equal? (with-output-to-string (λ () (anf:eval (twice noisy))))           "xx")
(check-equal? (with-output-to-string (λ () (anf:eval ((ext cps:dbl) noisy))))   "x")
(check-equal? (parameterize ([current-output-port (open-output-nowhere)]) (list (anf:eval (twice noisy)) (anf:eval ((ext cps:dbl) noisy)))) (list 2 2))     ; 答案相同，工作不同

;; ---------------------------------------------------------------
;; 8. neg² 不翻译程序：交给它一支用了宿主 call/cc 的函数，
;;    包出来的照样调用宿主 call/cc。
(define call/cc-count 0)
(define (my-call/cc proc) (set! call/cc-count (add1 call/cc-count)) (call/cc proc))
(define (f/cc x) (my-call/cc (λ (k) (k (+ x 1)))))
(check-equal? (anf:eval ((neg² f/cc) (cps:id 1))) 2)
(check-equal? call/cc-count 1)

(displayln "all step-1 checks ran")
