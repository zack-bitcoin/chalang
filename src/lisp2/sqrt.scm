
(define (average x y)
  (mul_rat (add_rat x y)
           (makerat 1 2)))
                                        ;(average (makerat 1 2))
                                        ;             (makerat 1 3))))
(define (improve x guess)
  (average guess (div_rat x guess)))
;(improve (makerat 2 1))
;             (makerat 2 1))))
(define (good_enough guess x)
  (<rat (pos_diff_rat
         (square_rat guess)
         x)
        (makerat 1 100)))
;(good_enough (makerat 20001 15000))
                                        ;                  (makerat 4 1))))

(define (sqrt2 X Guess)
  (cond ((good_enough Guess X) Guess)
        (true (sqrt2 X (improve X Guess)))))
(define (sqrt X)
  (sqrt2 X 1))
(sqrt 9)
