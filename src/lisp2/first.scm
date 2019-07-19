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
(f1 4 5 6)

(let ((a 1)
      (b (* a 2))
      (c (+ b a)))
  c)
