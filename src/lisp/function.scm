(import (eqs_lib.scm let_lib.scm function_lib2.scm))
(and 
 (= 6 
    (execute (lambda (x) (+ x x)) ; anonymous function
	     (3)))
 (= 22
    (let ((Square (lambda (x) (* x x)))
	  (DoubleAdd (lambda (z y) (* 2 (+ z y )))))
      (execute DoubleAdd '((execute Square '(3))
			   2)))))
  
