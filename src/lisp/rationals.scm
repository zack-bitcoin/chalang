(import (core/math.scm))

(define makerat (a b)
  (cons a (cons b nil)))
(define divisor (r)
  (car (cdr r)))
(define numerator (r)
  (car r))
;(numerator (makerat 10 20))

(macro int_limit () 16384)

(define bigger (r)
  ((max (numerator r) (divisor r))))
;(bigger (makerat 4 5))
(define simplify_more (S R)
  (makerat (/ (numerator R) S)
           (/ (divisor R) S)))
;(simplify_more 12 (makerat 100000 200000))
(define simplify (R)
  (simplify_more
       (max (/
             (bigger R)
             (int_limit))
            1)
       R))
;(simplify (makerat 100000 200000))
(define add_rat (a b)
  (simplify
   (makerat
    (+ (* (numerator a)
          (divisor b))
       (* (numerator b)
          (divisor a)))
    (* (divisor a)
       (divisor b)))))
;(add_rat (makerat 1 2)
;             (makerat 3 4))
(define additive_inverse_rat (r)
  (makerat
       (- 0 (numerator r))
       (divisor r)))
;(additive_inverse_rat (makerat 5 6))))
(define sub_rat (a b)
  (add_rat a (additive_inverse_rat b)))
;(sub_rat (makerat 5 4)) (makerat 1 10))))
(define multiplicative_inverse (r)
  (makerat
   (divisor r)
   (numerator r)))
;(multiplicative_inverse (makerat 4 5))))
(define mul_rat (a b)
  (simplify
   (makerat
    (* (numerator a)
       (numerator b))
    (* (divisor a)
       (divisor b)))))
;(mul_rat (makerat 3 4)) (makerat 1 2))))
(define div_rat (a b)
  (mul_rat a (multiplicative_inverse b)))
;(div_rat (makerat 1 2) (makerat 2 1)

(define <rat (a b)
  (< (* (numerator a)
        (divisor b))
     (* (divisor a)
        (numerator b))))
;(ex (<rat (ex (makerat 4 2))
;          (ex (makerat 3 4))))
(define >rat (a b)
  (not (<rat a b)))

(define square_rat (a)
  (mul_rat a a))
;(mul_rat (makerat 1 4))
;             (makerat 3 4))))

(define pos_diff_rat (a b)
  (cond (((>rat a b) (sub_rat a b))
         (true (sub_rat b a)))))
;(pos_diff_rat (makerat 1 2)
;              (makerat 5 4))
;1
;4 4 4
;1
