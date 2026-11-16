#lang typed/racket/base
;; 知乎回答「miniKanren 的实现方式」的代码之零：项、代换、合一、读出答案。
;; 三个版本（列表、流、amb）共用这一个文件，一个字不变。
;;
;; 改写自《The Reasoned Schemer》第二版的代码（trs2-impl.scm）：
;;   https://github.com/TheReasonedSchemer2ndEd/CodeFromTheReasonedSchemer2ndEd
;;   Daniel P. Friedman, William E. Byrd, Oleg Kiselyov, and Jason Hemann,
;;   The Reasoned Schemer, second edition, MIT Press, 2018，第 10 章与附录 A。
;;   Copyright (c) 2018 Daniel P. Friedman, William E. Byrd, Oleg Kiselyov,
;;   and Jason Hemann，MIT License；全文见同目录的 NOTICE。
;; 改动：加了类型；未知项是结构体，按身份区分，名字取自 fresh 里写的标识符；
;; 字面量用 equal? 比较。

(provide (all-defined-out))

;; ---- 三个类型里的前两个 ----
(define-type Literal (∪ Boolean Number Char String Null Symbol))
(define-type Term (∪ Literal Var (Pair Term Term)))
(define-type Substitution (Listof (Pair Var Term)))

(struct var ([name : Symbol])
  #:type-name Var
  #:property prop:custom-write                    ; 只为打印：显示成它的名字
  (λ ([v : Var] [port : Output-Port] [mode : (∪ Boolean 0 1)])
    (write (var-name v) port)))

(: empty-s Substitution)
(define empty-s '())

;; ---- 查表 ----
(: walk (→ Term Substitution Term))
(define (walk v s)
  (let ([a (and (var? v) (assq v s))])
    (if a (walk (cdr a) s) v)))

;; ---- 合一 ----
(: ext-s (→ Var Term Substitution (Option Substitution)))
(define (ext-s x v s)
  (if (occurs? x v s)
      #f
      (cons (cons x v) s)))

(: occurs? (→ Var Term Substitution Boolean))
(define (occurs? x v s)
  (let ([v (walk v s)])
    (cond [(var? v) (eq? v x)]
          [(pair? v) (or (occurs? x (car v) s)
                         (occurs? x (cdr v) s))]
          [else #f])))

(: unify (→ Term Term Substitution (Option Substitution)))
(define (unify u v s)
  (let ([u (walk u s)] [v (walk v s)])
    (cond [(eq? u v) s]
          [(var? u) (ext-s u v s)]
          [(var? v) (ext-s v u s)]
          [(and (pair? u) (pair? v))
           (let ([s (unify (car u) (car v) s)])
             (and s (unify (cdr u) (cdr v) s)))]
          [(equal? u v) s]
          [else #f])))

;; ---- 读出答案 ----
(: walk* (→ Term Substitution Term))
(define (walk* v s)
  (let ([v (walk v s)])
    (if (pair? v)
        (cons (walk* (car v) s) (walk* (cdr v) s))
        v)))

(: reify-name (→ Index Symbol))
(define (reify-name n)
  (string->symbol (format "_~a" n)))

(: reify-s (→ Term Substitution Substitution))
(define (reify-s v r)
  (let ([v (walk v r)])
    (cond [(var? v) (cons (cons v (reify-name (length r))) r)]
          [(pair? v) (reify-s (cdr v) (reify-s (car v) r))]
          [else r])))

(: reify (→ Term (→ Substitution Term)))
(define ((reify v) s)
  (let* ([v (walk* v s)]
         [r (reify-s v empty-s)])
    (walk* v r)))

;; ---- 造一个新的未知项 ----
(: call/fresh (∀ (g) (→ Symbol (→ Var g) g)))
(define (call/fresh name f)
  (f (var name)))
