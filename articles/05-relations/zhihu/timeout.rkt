#lang racket/base
;; 只为演示「不回来」：等两秒，等不到就说等不到。
(provide within-2s)
(define (within-2s thunk)
  (define ch (make-channel))
  (define th (thread (λ () (channel-put ch (thunk)))))
  (define v (sync/timeout 2 ch))
  (unless v (kill-thread th))
  (or v '两秒内没有答案))
