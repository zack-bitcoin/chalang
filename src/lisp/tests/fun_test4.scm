(import (basics.scm))

;(define fun (y x) (- x y))
;(apply (@ fun) (() 6 5))

					;0
;(define fun (x y z) (y x z z z))
;(apply (@ fun) (5 4 3))
;1
; start_fun dup >r dup >r >r swap r> r> r> end_fun
; fun ! 5 4 3 fun @ call 0 1

;(define fun (a) (* (+ a (+ a a)) (+ a a)))
					;(apply (@ fun) (0 0))
;(* (+ 0 2) (+ 0 1))

(macro test4 ()
       '(= ,(apply (@ fun) (3))
	   54))
;(test4)
;0
(define func (b a)
  (cond (((> 1 2) a)
	 (true b))))
;(func 4 5)
;(apply (@ func) (5 3))
;0
1
    



