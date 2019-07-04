(import (eqs_lib.scm rationals.scm))

(define average (x y)
  (ex (mul_rat (ex (add_rat x y))
               (ex (makerat 1 2)))))
;(ex (average (ex (makerat 1 2))
;             (ex (makerat 1 3))))
(define improve (x guess)
  (ex (average guess (ex (div_rat x guess)))))
;(ex (improve (ex (makerat 2 1))
;             (ex (makerat 2 1))))

;(ex (improve (ex (improve (ex (improve (ex (makerat 2 1))
;                                       (ex (makerat 2 1))))
;                          (ex (makerat 2 1))))
;             (ex (makerat 2 1))))
                 
(define good_enough (guess x)
  (ex (<rat (ex (pos_diff_rat
                 (ex (square_rat guess))
                 x))
            (ex (makerat 1 30)))))
;(ex (good_enough (ex (makerat 20001 10000))
;                  (ex (makerat 4 1))))

(define sqrt2 (guess x)
  (ex (improve
       x
       (ex (improve
            x
            (ex (improve
                 x
                 (ex (improve
                      x
                      (ex (improve
                           x
                           (ex (improve x guess)))))))))))))

(define sqrt (x);works
  (ex (sqrt2 x x)))

;(ex (sqrt (ex (makerat 144 100))))


(define sqrt_times (N guess x);broken
  (cond (((< N 1) guess)
         (true (ex (sqrt_times (- N 1)
                               (ex (improve x guess))
                               x
                               ))))))

(define sqrt3 (x guess);broken
  (cond (((good_enough guess x) guess)
         (true (ex (sqrt3 x
                          (ex (improve x guess))
                          ))))))
;(ex (sqrt3 (ex (makerat 4 1))
;           (ex (makerat 2 1))))
1                
