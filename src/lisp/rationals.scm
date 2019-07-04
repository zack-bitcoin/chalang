(import (function_lib3.scm cond_lib.scm))


(define makerat (a b)
  (cons a (cons b nil)))
(define divisor (r)
  (car (cdr r)))
(define numerator (r)
  (car r))
;(ex (numerator (ex (makerat 10 20))))

(macro int_limit () 16384)

(define max (a b)
  (cond (((> a b) a)
         (true b))))
(define min (a b)
  (cond (((< a b) a)
         (true b))))
;(ex (max 6 5))
(define bigger (r)
  (ex (max (ex (numerator r)) (ex (divisor r)))))
;(ex (bigger (ex (makerat 4 5))))
(define simplify_more (S R)
  (ex (makerat (/ (ex (numerator R)) S)
               (/ (ex (divisor R)) S))))
;(ex (simplify_more 12 (ex (makerat 100000 200000))))
(define simplify (R)
  (ex (simplify_more
       (ex (max (/
                 (ex (bigger R))
                 (int_limit))
                1))
       R)))
;(ex (simplify (ex (makerat 100000 200000))))
(define add_rat (a b)
   (ex (simplify
        (ex (makerat
             (+ (* (ex (numerator a))
                   (ex (divisor b)))
                (* (ex (numerator b))
                   (ex (divisor a))))
             (* (ex (divisor a))
                (ex (divisor b))))))))
;(ex (add_rat (ex (makerat 1 2))
;             (ex (makerat 3 4))))
(define additive_inverse_rat (r)
  (ex (makerat
       (- 0 (ex (numerator r)))
       (ex (divisor r)))))
;(ex (additive_inverse_rat (ex (makerat 5 6))))
(define sub_rat (a b)
  (ex (add_rat a (ex (additive_inverse_rat b)))))
;(ex (sub_rat (ex (makerat 5 4)) (ex (makerat 1 10))))
(define multiplicative_inverse (r)
  (ex (makerat
       (ex (divisor r))
       (ex (numerator r)))))
;(ex (multiplicative_inverse (ex (makerat 4 5))))
(define mul_rat (a b)
  (ex (simplify
       (ex (makerat
            (* (ex (numerator a))
               (ex (numerator b)))
            (* (ex (divisor a))
               (ex (divisor b))))))))
;(ex (mul_rat (ex (makerat 3 4)) (ex (makerat 1 2))))
(define div_rat (a b)
  (ex (mul_rat a (ex (multiplicative_inverse b)))))
;(ex (div_rat (ex (makerat 1 2)) (ex (makerat 2 1))))

(define <rat (a b)
  (< (* (ex (numerator a))
        (ex (divisor b)))
     (* (ex (divisor a))
        (ex (numerator b)))))
;(ex (<rat (ex (makerat 4 2))
;          (ex (makerat 3 4))))
(define >rat (a b)
  (not (ex (<rat a b))))

(define square_rat (a)
  (ex (mul_rat a a)))
;(ex (mul_rat (ex (makerat 1 4))
;             (ex (makerat 3 4))))

(define pos_diff_rat (a b)
  (cond (((ex (>rat a b)) (ex (sub_rat a b)))
         (true (ex (sub_rat b a))))))
;(ex (pos_diff_rat (ex (makerat 1 2))
;                  (ex (makerat 5 4))))
;1
;4 4 4
;1
