%Sort lists at run-time.

(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm tree_lib.scm))


(macro merge ()
       (define (x y)
	 (cond (((= nil x) y)
		 ((= nil y) x)
		 ((> (car x) (car y))
		  (cons (car x)
			(recurse (cdr x) y)))
		 (true
		  (cons (car y)
			(recurse x (cdr y))))))))
(drop (merge))
%(merge (merge) ((tree '(9 7 5 3 2)) (tree '(8 6 4 2 0))))

(macro merge_to_lists ()
       (define (L)
	 (cond (((= nil L) nil)
		 (true (cons (cons (car L) nil)
			     (recurse (cdr L))))))))
(drop (merge_to_lists))
%(merge (merge_to_lists) ((tree '(2 5 67 23 4 4 6))))

(macro merge_sort_helper2 ()
       (define (L)
	 (cond (((= nil L) nil)
		((= nil (cdr L)) L)
		(true (cons (merge (merge)
				   ((car L)
				    (car (cdr L))))
			    (recurse
			     (cdr (cdr L)))))))))
(drop (merge_sort_helper2))
%(merge (merge_sort_helper2)
%       ((tree '(1 2))(tree '(2 3))))
(macro merge_sort_helper ()
       (define (L)
	 (cond (((= nil (cdr L)) (car L))
		 (true (recurse
			(merge (merge_sort_helper2)
			       (L))))))))
(drop (merge_sort_helper))
%(merge (merge_sort_helper2)
%       ((merge (merge_to_lists)
%	      ((tree '(3 4 2 5))))))

(macro merge_sort (L)
       (merge (merge_sort_helper)
	      ((merge (merge_to_lists) '(L)))))
(=
 (merge_sort (tree '(2 5 67 23 6)))
 (tree '(67 23 6 5 2)))

%(merge_sort (tree '(3 5 7 3 24 546 6 5 4 3 7 8 6 4 3 4 6 8 9 9 7 6 4 4 6 7 8 6 4 3)))
