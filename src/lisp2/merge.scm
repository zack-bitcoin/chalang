(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm))


(macro merge ()
       (define (x y)
	 '(case (((eqs nil x) y)
		 ((eqs nil y) x)
		 ((> (car x) (car y))
		  (cons (car x)
			(recurse (cdr x) y)))
		 (true
		  (cons (car y)
			(recurse x (cdr y))))))))
%(merge)
(apply (merge) '((cons 1 nil) (cons 3 nil)))

