(import (eqs_lib.scm function_lib3.scm cond_lib.scm let_lib.scm tree_lib.scm))

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

;(execute (@ rt_merge) ((tree (2 4 6)) (tree (3 5 6))))

(define rt_sort2 (l)
  (cond (((= nil (cdr l)) (car l))
	 (true
	  (recurse
	   (reverse
	    (cons
	     (execute (@ rt_merge) ((car l)
				    (car (cdr l))))
	     (reverse (cdr (cdr l))))))))))
;(execute (@ rt_sort2) ((tree ((5)(2)(6)(1)(3)))))

(define rt_setup (l)
  (cond (((= nil l) nil)
	 (true (cons (cons (car l) nil)
		     (recurse (cdr l)))))))
;(execute (@ rt_setup) ((tree (4 5 6))))

(macro rt_sort (l)
       '(execute (@ rt_sort2)
		 ((execute (@ rt_setup) (l)))))


; this is the chalang code that gets generated from the run-time lisp functions above.

; 50 >r % this is from function_lib3.scm

; def r@ ! r@ 1 + ! nil r@ 1 + @ = tuck drop drop
;   if r@ @
;   else nil r@ @ = tuck drop drop
;     if r@ 1 + @
;     else r@ 1 + @ car drop r@ @ car drop >
;       if r@ @ car drop r@ 1 + @ r@ @ car swap drop recurse call cons
;       else r@ 1 + @ car drop r@ 1 + @ car swap drop r@ @ recurse call cons then
;     then
;   then
; 1 !

; def r@ ! nil r@ @ car swap drop = tuck drop drop
;   if r@ @ car drop
;   else r@ @ car drop r@ @ car swap drop car drop 1 @ r@ 1 + >r call r> drop r@ @ car swap drop car swap drop reverse cons reverse recurse call then
; 2 !

; def r@ ! nil r@ @ = tuck drop drop
;   if nil
;   else r@ @ car drop nil cons r@ @ car swap drop recurse call cons then
; 3 !

;1 3 1 5 3 9 20 4 8 nil cons cons cons cons cons cons cons cons 3 @ call 2 @ call 1 3 3 4 5 8 9 20 nil cons cons cons cons cons cons cons cons = tuck drop drop and
