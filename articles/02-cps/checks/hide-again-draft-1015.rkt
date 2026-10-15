#lang racket/base
;; 第二篇试写稿（drafts/再次隐藏延续-试写-2026-10-15.md）的等式核对。
;; 假定文章仓库 algebraic-control-flow 与本仓库放在同一个目录下；底本 dev b7a6ec7。
;; 运行：LC_ALL=C.UTF-8 racket checks/hide-again-draft-1015.rkt
(require (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt")
         rackunit)

(define (cps:f x) (λ (k) (k (* 2 x))))
(define (cps:g y) (λ (k) (k (+ y 1))))
(define (cps:h z) (λ (k) (k (list 'h z))))
(define k (λ (v) (list 'k v)))
(define x 5)

;; 甲：cps:id 的行为
(check-equal? ((cps:id x) k) (k x))

;; 甲：单位律
(check-equal? (((∘𝒦 cps:id cps:f) x) k) ((cps:f x) k))
(check-equal? (((∘𝒦 cps:f cps:id) x) k) ((cps:f x) k))

;; 甲：结合律，两种括号与不分括号的写法都化成同一条延续链
(define chain ((cps:f x) (λ (y) ((cps:g y) (λ (z) ((cps:h z) k))))))
(check-equal? (((∘𝒦 cps:h (∘𝒦 cps:g cps:f)) x) k) chain)
(check-equal? (((∘𝒦 (∘𝒦 cps:h cps:g) cps:f) x) k) chain)
(check-equal? (((∘𝒦 cps:h cps:g cps:f) x) k) chain)

;; 乙：一个绑定。宏展开的结果与「应该发生的事」相同
(define cps:kv (λ (v) (cps:* v 3)))
(define kkv (cps:+ 1 2))
(check-equal? (((∘𝒦 cps:kv id) kkv) k)
              ((λ (k) (kkv (λ (v) ((cps:* v 3) k)))) k))
(check-equal? (anf:eval (anf:let* ([v (cps:+ 1 2)]) (cps:* v 3))) 9)

;; 乙：连接等式
(check-equal? (((∘𝒦 cps:kv id) (cps:+ 1 2)) k)
              (((∘𝒦 cps:kv cps:+) 1 2) k))
(check-equal? (((∘𝒦 cps:h id) (cps:g x)) k)
              (((∘𝒦 cps:h cps:g) x) k))

;; 乙：两个绑定的三站
(define two-0 (anf:let* ([y (cps:f x)] [z (cps:g y)]) (cps:id z)))
(define two-1 ((∘𝒦 (λ (y) ((∘𝒦 (λ (z) (cps:id z)) id) (cps:g y))) id)
               (cps:f x)))
(define two-2 ((∘𝒦 (λ (y) ((∘𝒦 cps:id cps:g) y)) cps:f) x))
(define two-3 ((∘𝒦 cps:g cps:f) x))
(for ([e (list two-1 two-2 two-3)])
  (check-equal? (e k) (two-0 k)))

;; 乙：三个绑定得到 (∘𝒦 (∘𝒦 h g) f)，与不分括号的写法相同
(define three (anf:let* ([y (cps:f x)] [z (cps:g y)] [w (cps:h z)]) (cps:id w)))
(check-equal? (three k) (((∘𝒦 (∘𝒦 cps:h cps:g) cps:f) x) k))
(check-equal? (three k) (((∘𝒦 cps:h cps:g cps:f) x) k))

(displayln "all checks passed")
