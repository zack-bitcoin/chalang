(import (eqs_lib.scm let_lib.scm))
(eqs 8 
     (let ((x 5)
	    (y (- x 2)))
       '(+ x y)))
