;examles of or 
;(or (clause clause ... ))
;examples of clause
;((unification unification ...)(outcome))
;examples of unification
;```(= z (+ x y))``` They check if two things can be set equal.
;outcome can be a variable ```x```, or it could be another `or` tree, or it could be an `end(a,b,c)` function.

;a clause has these steps:
;insert empty into each variable's value
;try to do all the unifications. If any fails, then fail. If they all pass, then do the outcome.

;in the define macro there was a variable called many so that we don't over-write variables. the clause macro needs space for more variables to do the unifications.


;a unification has these steps:
;calculate the value
;if the variable is empty, then store the value.
;if the variable already stores the value, then continue.
;if the variable already stores a non-matching value, then fail.

;an or has these steps:
;if there is nothing left to try, then fail.
;if the next thing to try doesn't fail, then return that.

(import (eqs_lib.scm let_lib.scm function_lib2.scm cond_lib.scm tree_lib.scm))

(macro empty () '(cons 4294967295 nil));biggest number we can store in 4 bytes.
(macro fail () '(cons 4294967294 nil));second biggest.
(macro success () '(cons 4294967293 nil));third biggest.
(macro logic_unification (Var Code)
       '(cond
	    (((= (@ Var) (empty))
	      ((! Code Var) (success)))
	     ((= (@ Var) Code) (success))
	     (true (fail)))))
;(! (empty) 1)
;(logic_unification 1 (+ 5 3))
;(and (= (fail) (logic_unification 1 (+ 5 2)))
;     (= 8 (@ 1)))

(macro empties (N)
       (cond (((= N 0) ())
	      (true '(nop (empty)
			  (empties (- N 1)))))))
(macro all_emp (U N)
       (nop (empties (prolog_length U 0))
	    (function_vars U N)))
(macro prolog_length (X N)
       (cond (((= X ()) N)
	      (true (prolog_length (cdr X) (+ N 1))))))

;(prolog_length ( a b c) 0)
;(prolog_length ( a b c) 0)
;(test (a b) 4)
;(nop (empties (prolog_length (a b) 0)) (function_vars (a b) 0))
;(all_emp (a) 0)
;(empty) (empty) (function_vars (a b) 0)

(macro is_in (I L)
       (cond (((= L ()) false)
	      ((= I (car L)) true)
	      (true (is_in I (cdr L))))))

;(is_in d (tree '(a b c)))

(macro no_repeats (L) (no_repeats2 L ()))
(macro no_repeats2 (A B)
       (cond (((= A ()) B)
	      ((is_in (car A) B) (no_repeats2 (cdr A) B))
	      (true (no_repeats2 (cdr A)
				 (cons (car A)
				       B))))))
(macro heads (p)
       (cond (((= p ()) ())
	      (true (cons (car (car p))
			  (heads (cdr p)))))))
(macro set_empties (L)
       (cond (((= L ()) ())
	      (true (cons '(! (empty) ,(car L))
			  (set_empties (cdr L)))))))
(macro clause_logic (pairs out)
       (cond (((= pairs ()) '(true out))
	      (true (cons '((= (logic_unification
				  ,(car (car pairs))
				  ,(car (cdr (car pairs))))
				 (fail))
			    (fail))
			  (clause_logic (cdr pairs) out))))))
(! (empty) 1)
(cond ((clause_logic ((z 5)) 3)))
(macro clause (pairs out)
       ((set_empties (no_repeats (heads pairs)))
       '(cond (clause_logic pairs out))))
;(clause 
; ((z 3)
;  (x (+ 10 z)))
; x)

;(! (empty) 1)(! (empty) 2)
;(cond
;    (((= (logic_unification 1 3) (fail)) (fail))
;     ((= (logic_unification 2 (+ 10 (@ 1))) (fail)) (fail))
;     (true (@ 2))))


;(reverse (tree (no_repeats '(a b c b a))))
;(tree (no_repeats '(a b c b a)))

;(cond (((= 1 1)(fail))
;       (true 0)))
;(prolog_or 5);(tree '()))
;(prolog_or (tree '(C1 C2)))

;(cond (((not (= C1 (fail))) C1)))

(macro prolog_or ()
       (lambda (L)
	 (cond (((= L nil) (fail))
		((not (= (car L) (fail))) (car L))
		(true (recurse (cdr L)))))))

;(execute (prolog_or) ((cons (fail) (tree '(5)))))
