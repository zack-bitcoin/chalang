(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm tree_lib.scm))

% merge-sort

% first at compile-time

(macro ct_merge (a b)
       (cond (((= () a) b)
	      ((= () b) a)
	      ((> (car a) (car b))
	       (cons (car b)
		     (ct_merge a (cdr b))))
	      (true (cons (car a)
			  (ct_merge (cdr a) b))))))
%(tree (ct_merge (1 3 5) (2 3 6)))
(macro ct_setup (l)
       (cond (((= l ()) ())
	      (true (cons (cons (car l) ())
			  (ct_setup (cdr l)))))))
%(tree (ct_setup (5 5)))
(macro ct_sort2 (l)
       (cond (((= (cdr l) ()) (car l))
	      (true
	       (ct_sort2
		(reverse
		 (cons (ct_merge (car l)
				 (car (cdr l)))
		       (reverse (cdr (cdr l))))))))))
(macro ct_sort (l)
       (ct_sort2
	(ct_setup l)))



%%%%%% next at run-time

(macro rt_merge ()
       (lambda (a b)
	 (cond (((= nil a) b)
		((= nil b) a)
		((> (car a) (car b))
		 (cons (car b)
		       (recurse a (cdr b))))
		(true (cons (car a)
			    (recurse (cdr a) b)))))))

% rt_merge needs to be instantiated before the definition of rt_sort2.
% because the hash of rt_merge needs to be embedded in rt_sort2's definition.
(drop (rt_merge))

%(execute (rt_merge) ((tree (2 4 6)) (tree (3 5 6))))

(macro rt_sort2 ()
       (lambda (l)
	 (cond (((= nil (cdr l)) (car l))
		(true
		 (recurse
		  (reverse
		    (cons
		     (execute (rt_merge) ((car l)
					  (car (cdr l))))
		     (reverse (cdr (cdr l)))))))))))
%(execute (rt_sort2) ((tree ((5)(2)(6)(1)(3)))))

(macro rt_setup ()
       (lambda (l)
	 (cond (((= nil l) nil)
		(true (cons (cons (car l) nil)
			    (recurse (cdr l))))))))
%(execute (rt_setup) ((tree (4 5 6))))

(macro rt_sort (l)
       '(execute ,(rt_sort2)
		 ((execute ,(rt_setup) (l)))))

