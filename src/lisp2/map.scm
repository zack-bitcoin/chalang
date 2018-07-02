(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm tree_lib.scm))

% the map is happening at run-time

(macro double () (define (x) (+ x x)))

(macro map ()
       (define (F X)
	 (case (((eqs nil X) nil)
		 (true (cons
			 (apply F ((car X)))
			 (recurse F (cdr X))))))))

(eqs
 (apply (map) ((double) (tree '(2 3 4 5))))
 (tree '(4 6 8 10)))


