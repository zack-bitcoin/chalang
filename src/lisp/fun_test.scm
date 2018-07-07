(import (eqs_lib.scm let_lib.scm function_lib.scm))
;(import (eqs_lib.scm let_lib.scm function_lib2.scm))

;This shows how to package a function so it can be imported and used in other pages of lisp.

;using a macro to hard-code a pointer to your function
(macro square () (lambda (x) (* x x)))
(= 16
   (execute (square) ((execute (square) ( 2)))))
;You might worry that this is re-defining the function every time you want to use it.
;that is not a problem. The compiler only defines it the first time it is used, and after that it replaces each function definition with the 32-byte binary id for that function.

;using an anonymous function.
(=
 (execute (lambda (x y) (- (* x x) y)) (3 4))
 5)
and

;storing the pointer to your function in a variable
(define Fun_1 (x) (+ x (* x x)))
(=
 (execute (@ Fun_1) (5))
 30)

and


