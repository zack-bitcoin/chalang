(import (function_lib3.scm cond_lib.scm))


;(define identity (x) x)
;(define Sum (a b) (+ a b))

;(ex (Sum 4 (ex (Sum 2 3))))

;(define F (a b)
;  (ex (Sum (ex (Sum a b))
;           (ex (Sum b a)))))

;(define doop (x)
;  (cons x (cons x nil)))
;(ex (doop (ex (doop 5))))

;(define F2 (x)
;  (ex (Sum (ex (Sum x x))
;           x)))
                                        ;(ex (F2 3))
;(define F3 (R)
;  (ex (Sum
;       (ex (Sum 0 0))
;       (ex (Sum 0 R)))))

(define to_zero (N M X)
  (cond (((< N 1) M)
         (true (ex (to_zero (- N 1)
                            M X))))))
;(ex (Sum M 1))))))))

;(ex (to_zero 5 (cons 7 nil) 5))
;(ex (to_zero 5 5 7))
;(ex (F3 6))

;(ex (F 2 (ex (Sum 2 3))))

;(ex (Sum (ex (Sum 4 5)) 6))

;(define simplify (a b)
;  (ex (first 5
;             (ex (first 5
;                        0)))))

;(ex (simplify 6 5))
;(define add3 (A)
;  (ex (Sum A 3)))
;(ex (Sum 3 2))
;(ex (add3 2))
;
;(execute (@ add3) (2))


;(define makerat (a b)
;  (cons a (cons b nil)))
;(define divisor (r)
;  (car (cdr r)))
;(define numerator (r)
;  (car r))
;(ex (divisor (ex (makerat 2 3))))
;(car (cdr (cons 2 (cons 3 nil))))
 ;3 ! 20 10 1 @ call 3 @ call
;(define simplify_more (R S)
;  (ex (makerat (/ (ex (numerator R)) S)
;               (/ (ex (divisor R)) S))))
;(macro int_limit () 16384)
;(define max (a b)
;  (cond (((> a b) a)
;         (true b))))
;(define bigger (r)
;  (ex (max (ex (numerator r)) (ex (divisor r)))))
;(define simplify (R)
;  (ex (simplify_more
;       R
;       (ex (max (/
;                 (ex (bigger R))
;                 (int_limit))
;                1)))))

;def dup r@ ! 6 @ call 16384 / 1 5 @ call r@ @ 4 @ r@ 1 + >r call r> drop ;
;(ex (numerator (ex (makerat 3 4))))

1
