(import (eqs_lib.scm rationals.scm cond_lib.scm))

(define average (x y)
  (ex (mul_rat (ex (add_rat x y))
               (ex (makerat 1 2)))))
;(ex (average (ex (makerat 1 2))
;             (ex (makerat 1 3))))
(define improve (x guess)
  (ex (average guess (ex (div_rat x guess)))))
;(ex (improve (ex (makerat 2 1))
;             (ex (makerat 2 1))))
(define good_enough (guess x);unused
  (ex (<rat (ex (pos_diff_rat
                 (ex (square_rat guess))
                 x))
            (ex (makerat 1 100)))))
;(ex (good_enough (ex (makerat 20001 15000))
;                  (ex (makerat 4 1))))

(macro sqrt_h (x g) (ex (improve x g)));one improve
(macro sqrt_h2 (x g) (sqrt_h x (sqrt_h x g)));two improves
(define sqrt2 (guess x)
  (sqrt_h2 x (sqrt_h2 x (sqrt_h2 x guess))))
(define sqrt6 (x);this does 6 iterations.
  (ex (sqrt2 x x)))
;(ex (sqrt6 (ex (makerat 144 100))))


(define sqrt_times_helper (N guess x)
  (cond (((< N 1) guess)
         (true (ex (sqrt_times_helper (- N 1)
                               (ex (improve x guess))
                               x
                               ))))))
(define sqrt_times (N X);this is so you can choose to do more any number of iterations
  (ex (sqrt_times_helper N X X)))
;(ex (sqrt_times 4 (ex (makerat 2 1))))
                

(define sqrt3 (X guess)
  (cond (((ex (good_enough guess X)) guess)
         (true (ex (sqrt3 X
                          (ex (improve X guess))
                          ))))))
(define sqrt (x);this one keeps iterating until the answer is good enough
  (ex (sqrt3 x x)))
;(ex (sqrt (ex (makerat 9 1))))
1                
