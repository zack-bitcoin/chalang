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
; anonymous functions at runtime can only be created at the top level. functions can't produce functions. But you can give anonymous functions as inputs to functions, and you can re-define variables to store different functions.
; the advantage of an anonymous function is that you don't waste time storing it's pointer in a variable, or recalling that variable to execute. you can leave the pointer on the stack, since it will immediately be consumed.
(= (execute (function (x y) (* x y)) (5 4))
   20)

;storing the pointer to your function in the variable "Fun_1", so it is easy to be executed whenever we need it.
(define Fun_1 (x) (+ x (* x x)))
;(=
; (Fun_1 5);executing the function
; 30)

;and

;unused function are automatically removed by the compiler
(define SS (x) (* x x))
(define FF (A B C) (+ A (+ C B)))


(macro fun () (lambda (x) (* x x)));a simple higher-order macro. the output is another macro.
(macro plus_n (n) (lambda (x) (+ x n)));closures use lexical context.
(macro plus_2 (x) ((plus_n 2) x));partial application
(macro test_macro ()
       '(()
         (= 25 ,((lambda (x) (* x x)) 5))
         (= 25 ,((fun) 5))
         (= 7 ,((plus_n 2) 5))
         (= 7 ,(plus_2 5))
         and and and
       ))
(test_macro)
and

