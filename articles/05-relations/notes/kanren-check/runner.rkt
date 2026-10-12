#lang racket
;; 用法：racket runner.rkt <miniKanren-typed 仓库的路径>
;; 先运行 make-demos.sh 生成 demo-minimal.rkt 与 demo-frontier.rkt。
;; 用 miniKanren-typed 的 TRS 测试（ambKanren 的 tests/demo.rkt 选的那六章）去跑两份副本。
;; 每个顶层形式限时 3 秒，记下通过 / 结果不符 / 出错 / 超时。
(define T (build-path (vector-ref (current-command-line-arguments) 0) "miniKanren" "tests" "trs2"))
(define chapters '("ch1" "ch2" "ch3" "ch4" "ch5" "ch9"))
(define limit 3)
(define (run-demo demo-file)
  (define ns (make-base-empty-namespace))
  (parameterize ([current-namespace ns]) (namespace-require 'typed/racket/base/no-check))
  (define pass 0) (define wrong '()) (define errs '()) (define hangs '())
  (parameterize ([current-namespace ns])
    (eval '(require (except-in racket/match ==)) ns)
    (eval `(require (file ,demo-file)) ns)
    (define mismatch #f)
    (namespace-set-variable-value!
     'check-equal?
     (λ (actual expected . _)
       (if (equal? actual expected) (set! pass (add1 pass)) (set! mismatch (list actual expected))))
     #t)
    (namespace-set-variable-value! 'displayln void #t)
    (for ([ch chapters])
      (define forms
        (with-input-from-file (build-path T (string-append ch ".rktl"))
          (λ () (for/list ([e (in-port read)]) e))))
      (for ([form forms] [i (in-naturals)])
        (set! mismatch #f)
        (define result 'ok)
        (define th
          (thread (λ ()
                    (with-handlers ([(λ (e) #t) (λ (e) (set! result (if (exn? e) (exn-message e) e)))])
                      (eval form ns)))))
        (cond
          [(sync/timeout limit th)
           (cond [(not (eq? result 'ok)) (set! errs (cons (list ch i result) errs))]
                 [mismatch (set! wrong (cons (list ch i form mismatch) wrong))])]
          [else (kill-thread th) (set! hangs (cons (list ch i form) hangs))]))))
  (values pass (reverse wrong) (reverse errs) (reverse hangs)))
(define (short form)
  (let ([s (format "~s" form)]) (if (> (string-length s) 110) (string-append (substring s 0 110) "…") s)))
(for ([v '("minimal" "frontier")])
  (define-values (pass wrong errs hangs)
    (run-demo (path->string (build-path (current-directory) (format "demo-~a.rkt" v)))))
  (printf "== ~a：通过 ~a，结果不符 ~a，出错 ~a，超时 ~a\n" v pass (length wrong) (length errs) (length hangs))
  (for ([w wrong]) (printf "  不符 ~a#~a ~a\n" (first w) (second w) (short (third w))))
  (for ([e errs]) (printf "  出错 ~a#~a ~a\n" (first e) (second e) (third e)))
  (for ([h hangs]) (printf "  超时 ~a#~a ~a\n" (first h) (second h) (short (third h)))))
