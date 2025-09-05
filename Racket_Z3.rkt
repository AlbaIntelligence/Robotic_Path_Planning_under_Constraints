#lang rosette/safe

(define-symbolic v boolean?)

;; Documentation
;; https://docs.racket-lang.org/rosette-guide/ch_essentials.html
;; Section 2.3

(clear-vc!)

; int32? is a shorthand for the type (bitvector 32).
(define int32? (bitvector 32))

; int32 takes as input an integer literal and returns
; the corresponding 32-bit bitvector value.
(define (int32 i)
  (bv i int32?))

;; (int32? 1)         ; 1 is not a 32-bit integer
;; (int32? (int32 1)) ; but (int32 1) is.
;; (int32 1)

; Returns the midpoint of the interval [lo, hi].
(define (bvmid lo hi)  ; (lo + hi) / 2
  (bvsdiv (bvadd lo hi) (int32 2)))

(define (check-mid impl lo hi)     ; Assuming that
  (assume (bvsle (int32 0) lo))    ; 0 ≤ lo and
  (assume (bvsle lo hi))           ; lo ≤ hi,
  (define mi (impl lo hi))         ; and letting mi = impl(lo, hi) and
  (define diff                     ; diff = (hi - mi) - (mi - lo),
    (bvsub (bvsub hi mi)
           (bvsub mi lo)))         ; we require that
  (assert (bvsle lo mi))           ; lo ≤ mi,
  (assert (bvsle mi hi))           ; mi ≤ hi,
  (assert (bvsle (int32 0) diff))  ; 0 ≤ diff, and
  (assert (bvsle diff (int32 1)))) ; diff ≤ 1.