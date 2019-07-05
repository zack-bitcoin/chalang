(import (rationals.scm))

(define (to_zero N M X)
  (cond (((< N 1) M);M is 1, X is 5
         (true (recurse (- N 1)
                        M
                        X)))))
(define (F_zero A B C)
  (cond (((< A 1) B);B is 1, C is 5
         (true (recurse (- A 1)
                        B
                        C)))))
;(F_zero 3 6 5)

1
