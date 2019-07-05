(import (core/eqs.scm core/let_lib.scm))

; this is happening at run time.
(macro test ()
    (let ((x 5)
	  (y (- x 2)))
      '(+ x y)))

(= 8 (test))

(macro let_replace (old new code)
       (cond (((= code ()) ())
	      ((= code old) new)
	      ((is_list code)
	       (cons (let_replace old new (car code))
		     (let_replace old new (cdr code))))
	      (true code))))

;(macro let_test ()
       ;(unchanged '(+ 1 2)))
;(+ 1 5)
       ;(let_replace z '(5) '(+ 1 z)))
       ;(= '(+ 5 2) (test)))
;(let_test)

; now to do it at compile time
(macro Fun1 () 5)
(macro Fun2 () (- (Fun1) 2))
(macro test2 () (= 8 (+ (Fun1) (Fun2))))
(test2)

and

;0
