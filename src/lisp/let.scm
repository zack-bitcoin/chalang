(import (eqs_lib.scm let_lib.scm))

% this is happening at run time.
(macro test ()
    (let ((x 5)
	  (y (- x 2)))
      '(+ x y)))

(= 8 (test))


% now to do it at compile time
(macro Fun1 () 5)
(macro Fun2 () (- (Fun1) 2))
(macro test2 () (= 8 (+ (Fun1) (Fun2))))
(test2)

and

