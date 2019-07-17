(import (core/let.scm basics.scm))
;3 7 11
;(let ((x 5))
;  (define (plusn y) (+ x y)))
;(plusn 10)

(! 5 c)
(define (G a b)
  (+ a (* b (@ c))))

(! (@ c) d)
(define (F a b)
  (+ a (* b (@ d))))

(= 5
   (F 0 1)
)
(= 5
   (G 0 1)
)
(! 2 c)
(= 5
   (F 0 1)
)
(= 2
   (G 0 1)
)
and and and 


;(macro bar () 1)
;(macro foo () (+ (bar) 5))
;(foo)
;(macro bar () 2)
;(foo)
;9
;1
