(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm tree_lib.scm))

% currently there are no higher-order functions at compile-time


% first lets do a map completely at compile time.
(macro map_double (L)
       (cond (((= () L) ())
	      (true
	       (cons (* 2 (car L)) (map_double (cdr L)))))))

(macro == (A B) (= A B))
(macro test ()
       (== (map_double '(2 3 4 5))
	  '(4 6 8 10)))
(test)



% now a mix. We compute most of the mapping at compile time, and we do the comparison at run-time

(macro double_ct (x) (+ x x))

(macro map_helper (L)
       (cond (((= () L) nil)
	      (true
	       '(cons `(double_ct (car L))
		     `(map_helper (cdr L)))))))

(eqs
 (map_helper '(2 3 4 5))
 (tree '(4 6 8 10)))


%1
% next the map is happening completely at run-time
% we can use higher-order functions at run-time.

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

 and and

