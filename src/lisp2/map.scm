(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm tree_lib.scm))


% the map is happening completely at run-time

(macro double () (define (x) (+ x x)))
(macro map ()
       (define (F X)
	 (cond (((= nil X) nil)
		 (true (cons
			 (execute F ((car X)))
			 (recurse F (cdr X))))))))

(=
  (execute (map) ((double) (tree (2 3 4 5))))
  (tree (4 6 8 10)))


% this map is happening completely at compile-time
(macro double2 (x) (* 2 x) )
(macro map2 (f l)
       (cond (((= () l) ())
	      (true
	       (cons (execute f ((car l)))
		     (map2 f (cdr l)))))))
(macro test3 ()
       (=
	(map2 'double2 (2 3 4 5))
	(4 6 8 10)))
(test3)

and

