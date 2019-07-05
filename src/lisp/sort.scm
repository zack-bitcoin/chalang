(import (basics.scm))

; merge-sort

; first at compile-time

(macro ct_merge (a b)
       (cond (((= () a) b)
	      ((= () b) a)
	      ((> (car a) (car b))
	       (cons (car b)
		     (ct_merge a (cdr b))))
	      (true (cons (car a)
			  (ct_merge (cdr a) b))))))
;(ct_merge (1 3 5) (2 3 6)) -> (1 2 3 3 5 6)
(macro ct_setup (l)
       (cond (((= l ()) ())
	      (true (cons (cons (car l) ())
			  (ct_setup (cdr l)))))))
;(tree (ct_setup (5 5)))
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



;;;;;; next at run-time

(define rt_merge (a b)
  (cond (((= nil a) b)
	 ((= nil b) a)
	 ((> (car a) (car b))
	  (cons (car b)
		(recurse a (cdr b))))
	 (true (cons (car a)
		     (recurse (cdr a) b))))))

;(rt_merge (tree (2 4 6)) (tree (3 5 6)))

(define rt_sort2 (l)
  (cond (((= nil (cdr l)) (car l))
	 (true
	  (recurse
	   (reverse
	    (cons
	     (rt_merge (car l)
                       (car (cdr l)))
	     (reverse (cdr (cdr l))))))))))
;(execute (@ rt_sort2) ((tree ((5)(2)(6)(1)(3)))))

(define rt_setup (l)
  (cond (((= nil l) nil)
	 (true (cons (cons (car l) nil)
		     (recurse (cdr l)))))))
;(rt_setup ((tree (4 5 6))))

(macro sort (l)
       (rt_sort2 (rt_setup l)))
