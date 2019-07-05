(import (eqs_lib.scm rationals.scm cond_lib.scm))

(define average (x y)
  (mul_rat (add_rat x y)
           (makerat 1 2)))
                                        ;(average (makerat 1 2))
                                        ;             (makerat 1 3))))
(define improve (x guess)
  (average guess (div_rat x guess)))
;(improve (makerat 2 1))
;             (makerat 2 1))))
(define good_enough (guess x)
  (<rat (pos_diff_rat
         (square_rat guess)
         x)
        (makerat 1 100)))
;(good_enough (makerat 20001 15000))
;                  (makerat 4 1))))

(macro sqrt_h (x g) (improve x g));one improve
(macro sqrt_h2 (x g) (sqrt_h x (sqrt_h x g)));two improves
(define sqrt2 (guess x)
  (sqrt_h2 x (sqrt_h2 x (sqrt_h2 x guess))))
(define sqrt6 (x);this does 6 iterations.
  (sqrt2 x x))
;(sqrt6 (makerat 144 100))))


(define sqrt_times_helper (N guess x)
  (cond (((< N 1) guess)
         (true (sqrt_times_helper (- N 1)
                               (improve x guess)
                               x
                               )))))
(define sqrt_times (N X);this is so you can choose to do more any number of iterations
  (sqrt_times_helper N X X))
;(sqrt_times 4 (makerat 2 1))
                

(define sqrt3 (X guess)
  (cond (((good_enough guess X) guess)
         (true (sqrt3 X
                      (improve X guess))))))
;(sqrt3 (makerat 10 1) (makerat 10 1))
(define sqrt (x);this one keeps iterating until the answer is good enough
  (sqrt3 x x))
;(sqrt (sqrt (makerat 10 1)))
1                
