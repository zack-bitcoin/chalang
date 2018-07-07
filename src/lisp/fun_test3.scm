;(import (eqs_lib.scm let_lib.scm))
(import (function_lib2.scm eqs_lib.scm))

;This shows how to package a function so it can be imported and used in other pages of lisp.

;using a macro to hard-code a pointer to your function
;(macro square () (lambda (x) (* x x)))
;(= 16
;   (execute (square) ((execute (square) (2)))))
;You might worry that this is re-defining the function every time you want to use it.
;that is not a problem. The compiler only defines it the first time it is used, and after that it replaces each function definition with the 32-byte binary id for that function.

					;using an anonymous function.
;(apply (lambda (b c a) (+ a (- b c)))
;       (7 3 2))
;(apply (lambda (b c a) (+ a (- b c)))
;       (7 3 2))
;(apply (lambda (c b a) (+ a (- b c)))
;       (() 7 3 2))
(apply (lambda (c b a) (+ (+ 0 a) (- b c)))
       (0 3 2))

;(2 4 3
;(= 1 (apply (lambda (x y z) (- (+ y x) (- z x))) (0 4 3)))
;and
;(lambda (x) (* x x))
;(apply (lambda (x y z) (* (+ y x) (+ z x))) (() 0 4 3))
; compiled:
; 0 4 3 start_fun rot dup >r swap >r + r> r> + * end_fun call


;storing the pointer to your function in a variable
;(define Fun_1 (x) (+ x (* x x)))
;(=
; (execute (@ Fun_1) (5))
; 30)

;and
