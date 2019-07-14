(import (basics.scm))

;This shows how to package a function so it can be imported and used in other pages of lisp.

;using a macro to hard-code a pointer to your function
;not recommended.
;(macro square () (lambda (x) (* x x)))
;(= 16
;   (execute (square) ((execute (square) ( 2)))))
;You might worry that this is re-defining the function every time you want to use it.
;that is not a problem. The compiler only defines it the first time it is used, and after that it replaces each function definition with the 32-byte binary id for that function.

;using an anonymous function.

;(=
; (execute (lambda (x y) (- (* x x) y)) (3 4))
; 5)
;and
;storing the pointer to your function in a variable
(define Fun_1 (x) (+ x (* x x)))
(=
 ;(execute (@ Fun_1) (5))
 (Fun_1 5)
 30)

;and

(define SS (x) (* x x))
(define FF (A B C) (+ A (+ C B)))
;(execute (@ FF) (4 5 6))
;(define map (F X)
;  (cond (((= nil X) 7);nil)
;	 (true (cons
;		6 ;(apply F ((car X)))
;		()))))) ;(recurse F (cdr X)))))))
;(execute (@ FF) (2 3 4))
;(macro fun ()
;       (lambda (x y z)
;	 (y x z z z)))
;(=
 ;(execute (@ fun) (5 4 3))
(macro fun () '(lambda (x) (* x x)))
(macro plus_n (n) '(lambda (x) (+ x n)));closure with lexical context
(macro plus_2 (x) ((plus_n 2) x))
;(macro plus_2b (x) (+ x 2))
                                        ; (4 5 3 3 3))
(macro test_macro ()
       '(()
         (= 25 ,((lambda (x) (* x x)) (5)))
         ;(= 25 ,(execute (fun) (5)))
         ;(= 25 ,(execute (fun) (5)))
         (= 25 ,((fun) 5))
         (= 7 ,((plus_n 2) 5))
         (= 7 ,(plus_2 5))
         and and and
       ))
(test_macro)
and
;(execute (plus_n 2) 5)
;(execute (plus_n 2) 5)
;(@ plus_s)
;(execute (@ plus_2) 5)
