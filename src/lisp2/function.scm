(import (eqs_lib.scm let_lib.scm function_lib.scm))
(and 
 (= 6 
    (execute (define (x) (+ x x)) % anonymous function
	     (3)))
 (= 22
    (let ((Square (define (x) (* x x)))
	  (DoubleAdd (define (z y) (* 2 (+ z y )))))
      (execute DoubleAdd '((execute Square '(3))
			   2)))))
  
