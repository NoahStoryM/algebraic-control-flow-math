#lang racket/base
;; 第二篇试验之二（Claude 10/16，Noah 要的）：用 let* + neg²:let/cc + neg²:if + neg²: 逐字改写 anf:let* + anf:let/cc + anf:if + cps: 的程序。
;; 依赖同级目录下的文章仓库，底本 dev。Racket 8.10。
(require (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt") rackunit racket/port)

;;; 工具：neg²:f 收计算、交计算；多个参数时从左到右运行
(define ((neg²:lift f) . kk*)
  (λ (k)
    (let loop ([kk* kk*] [v* '()])
      (if (null? kk*)
          (k (apply f (reverse v*)))
          ((car kk*) (λ (v) (loop (cdr kk*) (cons v v*))))))))
(define-syntax-rule (neg²:let/cc neg²:k b* ...)
  (λ (ka) (let ([neg²:k (neg² ka)]) ((let () b* ...) ka))))
(define ((neg²:if kkb kk1 kk2) k) (kkb (λ (b) ((if b kk1 kk2) k))))
(define ((neg²:begin kk . kk*) k)
  (if (null? kk*) (kk k) (kk (λ _ ((apply neg²:begin kk*) k)))))
(define ((neg²:app kkf . kkx*) k) (kkf (λ (f) ((apply f kkx*) k))))

(define neg²:*       (neg²:lift *))
(define neg²:car     (neg²:lift car))
(define neg²:cdr     (neg²:lift cdr))
(define neg²:null?   (neg²:lift null?))
(define neg²:zero?   (neg²:lift zero?))
(define neg²:display (neg²:lift display))
(define neg²:+       (neg²:lift +))

;;; 例二 mul：逐字对照原文
(define (orig-mul r*)
  (anf:eval
   (anf:let/cc cps:return
     (define (cps:loop r*)
       (anf:if (cps:null? r*) (cps:*)
               (anf:let* ([r (cps:car r*)])
                 (anf:if (cps:zero? r) (cps:return r)
                         (anf:let* ([r* (cps:cdr r*)] [res (cps:loop r*)])
                           (cps:* res r))))))
     (cps:loop r*))))
(define (cbn-mul r*)
  (anf:eval
   (neg²:let/cc neg²:return
     (define (neg²:loop kkr*)
       (neg²:if (neg²:null? kkr*) (neg²:*)
                (let* ([kkr (neg²:car kkr*)])
                  (neg²:if (neg²:zero? kkr) (neg²:return kkr)
                           (let* ([kkr* (neg²:cdr kkr*)] [kkres (λ (k) ((neg²:loop kkr*) k))])   ; 递归调用要延迟，否则宿主先无限展开
                             (neg²:* kkres kkr))))))
     (neg²:loop (cps:id r*)))))
(for ([r* '((1 2 0 3 4) (1 2 3 4) ())])
  (printf "mul ~s  原文 ~a  按名 ~a\n" r* (orig-mul r*) (cbn-mul r*))
  (check-equal? (cbn-mul r*) (orig-mul r*)))

;;; 例一
(check-equal? (anf:eval (let* ([kkv (neg²:+ (cps:id 1) (cps:id 2))]) (neg²:* kkv (cps:id 3)))) 9)
(printf "(1+2)*3 按名 ~a\n" (anf:eval (let* ([kkv (neg²:+ (cps:id 1) (cps:id 2))]) (neg²:* kkv (cps:id 3)))))

;;; 名字用几次就运行几次：原文与按名对照
(define cps:say1 (λ () (λ (k) (display "!") (k 1))))
(define (count-anf) (anf:let* ([v (cps:say1)]) (cps:+ v v)))
(define (count-cbn) (let* ([kkv (cps:say1)]) (neg²:+ kkv kkv)))
(printf "名字用两次：原文 ~s  按名 ~s\n"
        (with-output-to-string (λ () (anf:eval (count-anf))))
        (with-output-to-string (λ () (anf:eval (count-cbn)))))

;;; 例三 阴阳谜题
(define (neg²:label) (neg²:let/cc k (cps:id k)))
(define (prefix thunk)
  (define out (open-output-string))
  (define th (thread (λ () (parameterize ([current-output-port out]) (thunk)))))
  (sleep 0.5) (kill-thread th)
  (define s (get-output-string out))
  (substring s 0 (min 24 (string-length s))))
(define (cbn-yinyang)
  (anf:eval
   (let* ([yin (neg²:label)])
     (neg²:begin (neg²:display (cps:id #\@))
                 (let* ([yang (neg²:label)])
                   (neg²:begin (neg²:display (cps:id #\*))
                               (neg²:app yin yang)))))))
(printf "阴阳谜题 按名：~s\n" (prefix cbn-yinyang))

;;; 补一个按值的绑定：先把 e 跑一次，名字绑定到「交出这个结果」的计算
(define-syntax-rule (neg²:let1 ([kkv e]) b* ...)
  ((neg (flip (λ (v) (let ([kkv (cps:id v)]) b* ...)))) e))
(define (cbv-yinyang)
  (anf:eval
   (neg²:let1 ([yin (neg²:label)])
     (neg²:begin (neg²:display (cps:id #\@))
                 (neg²:let1 ([yang (neg²:label)])
                   (neg²:begin (neg²:display (cps:id #\*))
                               (neg²:app yin yang)))))))
(printf "阴阳谜题 补按值绑定：~s\n" (prefix cbv-yinyang))
(define (cbv-count) (neg²:let1 ([kkv (cps:say1)]) (neg²:+ kkv kkv)))
(printf "名字用两次 补按值绑定：~s\n" (with-output-to-string (λ () (anf:eval (cbv-count)))))
