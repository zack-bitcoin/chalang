(import (eqs_lib.scm let_lib.scm))

% this is happening at compile time.

(eqs 8 
     (let ((x 5)
	    (y (- x 2)))
       '(+ x y)))
