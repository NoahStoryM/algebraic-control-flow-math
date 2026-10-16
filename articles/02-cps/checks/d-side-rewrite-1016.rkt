#lang racket/base
;; 第二篇「嵌入语言」的例子，改用宿主的 let* 与 neg²: 箭头重写（Claude 10/16，Noah 要的试验）。
;; 依赖同级目录下的文章仓库 algebraic-control-flow，底本 dev。
;; 运行：LC_ALL=C.UTF-8 racket articles/02-cps/checks/d-side-rewrite-1016.rkt
;;
;; 两档工具：
;;   第一档：只有 neg²（把纯函数搬成 ¬¬p → ¬¬q）、cps:id、Noah 的 neg²:call/cc，外加宿主的 let*。
;;   第二档：再加「落回」(neg (flip h))，把一支 𝒦 箭头 h : p → ¬¬q 变成 ¬¬p → ¬¬q。
;;           按旧的命名约定，h 落回以后记作 neg²:h；对纯函数 f，neg²:f 就是 (neg² f)。
(require (file "../../../../algebraic-control-flow/zh/02-cps/code.rkt")
         (file "../../../../algebraic-control-flow/tools/check-output-prefix.rkt")
         rackunit racket/port)

(define (落回 h) (neg (flip h)))
(define (absurd bot) bot)                       ; ⊥ → a，永远不会真的被调用

;; Noah 10/16 的定义（类型里 proc 的返回改成 ¬¬a）
;; (: neg²:call/cc (∀ (a) (→ (¬¬ (→ (¬¬ (→ (¬¬ a) (¬¬ ⊥))) (¬¬ a))) (¬¬ a))))
(define ((neg²:call/cc kkneg²:proc) ka)
  (kkneg²:proc (λ (neg²:proc) ((neg²:proc (cps:id (neg² ka))) ka))))

(define (section s) (printf "\n== ~a ==\n" s))

;;; ------------------------------------------------------------------
(section "例一：(1 + 2) × 3")

;; 原文
(define orig1 (anf:eval (anf:let* ([v (cps:+ 1 2)]) (cps:* v 3))))
;; 第一档：let* 绑定的是编码好的计算；3 只能写进纯函数里
(define d1
  (anf:eval
   (let* ([kkv ((neg² +) (cps:id 1 2))]
          [kkw ((neg² (λ (v) (* v 3))) kkv)])
     kkw)))
(printf "原文 ~a   第一档 ~a\n" orig1 d1)
(check-equal? d1 orig1)

;;; ------------------------------------------------------------------
(section "例二：mul，遇零跳出")

;; 原文
(define (orig-mul r*)
  (anf:eval
   (anf:let/cc cps:return
     (define (cps:loop r*)
       (anf:if (cps:null? r*)
               (cps:*)
               (anf:let* ([r (cps:car r*)])
                 (anf:if (cps:zero? r)
                         (cps:return r)
                         (anf:let* ([r* (cps:cdr r*)]
                                    [res (cps:loop r*)])
                           (cps:* res r))))))
     (cps:loop r*))))

;; 第一档的尝试：列表在宿主里，分支用宿主的 if，正常路径都能写；
;; 卡在跳出：kkesc 是 ¬¬(¬¬a → ¬¬⊥)，要用里面的 esc，(neg² g) 会多出一层 ¬¬。
(define (try-tier1 r*)
  (neg²:call/cc
   (cps:id
    (λ (kkesc)
      (let loop ([r* r*])
        (cond [(null? r*) (cps:id 1)]
              [(zero? (car r*))
               ;; g : (¬¬a → ¬¬⊥) → ¬¬a，本身就是一支 𝒦 箭头
               (define (g esc) ((neg² absurd) (esc (cps:id 0))))
               ((neg² g) kkesc)]            ; 类型是 ¬¬¬¬a，多一层
              [else
               (define r (car r*))
               ((neg² (λ (res) (* res r))) (loop (cdr r*)))]))))))
(define tier1-zero
  (with-handlers ([exn:fail? (λ (e) (list 'error (exn-message e)))])
    (anf:eval (try-tier1 '(1 2 0 3 4)))))
(printf "第一档遇零：~s\n" tier1-zero)

;; 第二档：同样的 g，用落回代替 neg²，多出来的那层就不在了
(define (d2-mul r*)
  (anf:eval
   (neg²:call/cc
    (cps:id
     (λ (kkesc)
       (let loop ([r* r*])
         (cond [(null? r*) (cps:id 1)]
               [(zero? (car r*))
                (define (g esc) ((neg² absurd) (esc (cps:id 0))))
                ((落回 g) kkesc)]
               [else
                (define r (car r*))
                ((neg² (λ (res) (* res r))) (loop (cdr r*)))])))))))
(for ([r* '((1 2 0 3 4) (1 2 3 4) ())])
  (printf "~s   原文 ~a   第二档 ~a\n" r* (orig-mul r*) (d2-mul r*))
  (check-equal? (d2-mul r*) (orig-mul r*)))

;; 跳出时后面的乘法确实没有执行：在乘法里打印
(define (d2-mul/trace r*)
  (with-output-to-string
    (λ ()
      (anf:eval
       (neg²:call/cc
        (cps:id
         (λ (kkesc)
           (let loop ([r* r*])
             (cond [(null? r*) (cps:id 1)]
                   [(zero? (car r*))
                    ((落回 (λ (esc) ((neg² absurd) (esc (cps:id 0))))) kkesc)]
                   [else
                    (define r (car r*))
                    ((neg² (λ (res) (printf "*~a " r) (* res r))) (loop (cdr r*)))])))))))))
(printf "跳出时打印的乘法：~s；不跳出时：~s\n"
        (d2-mul/trace '(1 2 0 3 4)) (d2-mul/trace '(1 2 3)))

;;; ------------------------------------------------------------------
(section "例三：阴阳谜题")

(define (cps:label) (cps:call/cc cps:id))   ; 原文「嵌入语言」的定义

;; 原文
(define (orig-yinyang)
  (anf:eval
   (anf:let* ([cps:yin (cps:label)])
     (cps:display #\@)
     (anf:let* ([cps:yang (cps:label)])
       (cps:display #\*)
       (cps:yin cps:yang)))))

;; 只用 neg² 写不出：neg² 只能改一段计算的结果，连「先运行这一段、再运行那一段」都做不到。
;; 照字面用宿主 let* 给四段计算起名字，先后要靠落回接；四个结果都没有名字可用，
;; 最后那一步 (cps:yin cps:yang) 写不出来，只能丢掉结果：
(define (tier1-yinyang)
  (anf:eval
   (let* ([kkyin  (cps:label)]
          [kk@    ((neg² display) (cps:id #\@))]
          [kkyang (cps:label)]
          [kk*    ((neg² display) (cps:id #\*))])
     ((neg² (λ _ 'done))
      ((落回 (λ _ ((落回 (λ _ ((落回 (λ _ kk*)) kkyang))) kk@))) kkyin)))))
(define tier1-out
  (with-output-to-string (λ () (printf "~a" (tier1-yinyang)))))
(printf "宿主 let* 照字面：~s（四段各跑一次，没有阶梯）\n" tier1-out)

;; 第二档：用落回把每一步接起来；结果的名字只能在 λ 里起，正是 anf:let* 展开后的样子
(define (d2-yinyang)
  (anf:eval
   ((落回 (λ (cps:yin)
            ((落回 (λ (_)
                     ((落回 (λ (cps:yang)
                              ((落回 (λ (_) (cps:yin cps:yang)))
                               (cps:display #\*))))
                      (cps:label))))
             (cps:display #\@))))
    (cps:label))))
(define prefix "@*@**@***@****@*****@")
(printf "原文前缀对得上：~a   第二档前缀对得上：~a\n"
        (output-starts-with? orig-yinyang prefix)
        (output-starts-with? d2-yinyang prefix))
(check-true (output-starts-with? d2-yinyang prefix))

;;; ------------------------------------------------------------------
(section "附：名字用两次")

(define cps:say1 (λ () (λ (k) (display "!") (k 1))))
(define out-anf
  (with-output-to-string (λ () (anf:eval (anf:let* ([v (cps:say1)]) (cps:+ v v))))))
;; 宿主 let*：kkv 是一段计算；把它和自己配成一对，要运行两次
(define (pair2 kka kkb) (λ (k) (kka (λ (a) (kkb (λ (b) (k a b)))))))
(define out-d
  (with-output-to-string (λ () (anf:eval (let* ([kkv (cps:say1)]) ((neg² +) (pair2 kkv kkv)))))))
(printf "anf:let* 打印 ~s；宿主 let* 打印 ~s\n" out-anf out-d)
(check-equal? out-anf "!")
(check-equal? out-d "!!")

;; 落回与 neg² 的关系
(section "附：落回与 neg²")
(define k (λ v (cons 'k v)))
(check-equal? (((落回 (cps add1)) (cps:id 1)) k) (((neg² add1) (cps:id 1)) k))
(check-equal? (((落回 (∘𝒦 (cps add1) (cps add1))) (cps:id 1)) k)
              (((∘ (落回 (cps add1)) (落回 (cps add1))) (cps:id 1)) k))
(printf "落回 (cps f) = neg² f；先接再落回 = 先落回再接：通过\n")
