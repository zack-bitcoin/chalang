;(+ 4 5)

;(/ 100 19)

;(() def dup * end_fun square !)

;(define (double x) (+ x x))
;(() 5 double @ call )
;(double 30)

;(define (second a y z d) (y))
;(() 1 2 3 4 second @ call )
;(second 10 20 30 40 )
;(+ 2 3)
;(let ((a 2)
;      (b (+ a 1)))
;  (+ a b))

(define (f1 a b d)
  (let ((c (+ a b))
        (e (+ d c)))
    e))
;(= 15 (f1 4 5 6))

;(= 3
;   (let ((a 1)
;      (b (* a 2))
;      (c (+ b a)))
;     c))
;and

(set! N 9)
(= 9 (N @))
;and

;(= 4 4)
;and

;(= 4 5) not
;and

(= 7 (cond (((= 4 5) 6)
            (true 7))))
and

;(tree (((10)) 11 (12)))
(let ((y 5))
  y)

;(let (((x y) (car@ (cons 8 (cons 9 nil)))))
;  (y))
;(cons 9 nil)
(+ 4 5)
(+ 4 5)

(let (((x z) (6 5)))
  (+ x z))
