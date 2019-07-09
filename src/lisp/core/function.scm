(import (core/immutable_variables.scm))
(export (execute lambda define execute2 deflet))

;this is a library for making functions at run-time.

(macro lambda (Vars Code)
       ; define a new function
       '(nop
         def
         ;,(write (function lambda))
         ;(write Vars)
         ;(write Code)
         ,(let_stack Vars (Code))
         end_fun))
;(ex (lambda (a b c) '(nop b))
(macro define (Name Vars Code)
      ;make a new function and give it a name.
       '(! ,(lambda Vars Code) Name))
(macro execute (F V)
       '(call ,(cons nop V) F))
(macro execute2 (Vars)
       '(execute (@ ,(car Vars)) ,(cdr Vars)))

(macro deflet (name vars pairs code)
       ;store the function pointer in a variable
       '(! ,(deflet2 vars pairs code) name))
(macro deflet2 (vars pairs code) ;ths is the new version of lambda.
       ;wrap the function definition in `def` and `end_fun` to mark it as a function.
       '(nop
         def
         ,(deflet3 vars pairs code )
         end_fun))
(macro deflet3 (vars pairs code);we should use this to define let and define.
       (deflet4 vars pairs code (_length vars) (+ (_length vars) (_length pairs)) (reverse vars)))
(macro deflet4 (vars pairs code m n rv)
       '(nop
         ,(_load_inputs vars 0)
         ,(let*2 (_call_stack* n (_variables rv pairs 0))
                 ((_call_stack* n (_variables rv code 0)))
                 m)))
;(deflet3 () () () 0 ())
;(write (_variables (a) ((c a)) 0))
;0
;(let ((a 1)) (+ a 3))
                                        ;(write
;9
;(write (let*2 (_variables (a) ((c a)) 0)
;              (_variables (a) (c) 0)
;              2))
; )
;0
;(let ((c 5)) c)
;(write (let*2 ((a 5))
;              (+ a 4)
;              1))
(macro testf ()
       ,(write (deflet f (a) ((c 6)) (+ a c))))
;(testf)


;3 4 5 6 7
;(lambda (x y) (+ 1 (+ x y)))
;(lambda (x y z) (+ x (+ z y )))
;(_load_inputs (x y z) 0)
;(_length (x y z))
;(_variables (z y x) '(+ z (+ y x)) 0)

;(_length (1 1 5 1 1 1 1))
;(_pointer 3) ; 4

;4 3 (_load_inputs (a b) 0)
;(_variable* a '(+ a 1) 0) ;900 @ 5 + @
;(_variable* a (_variable* b (a b) 0) 1)
;(_variables (a b) '(+ a (+ b 2)) 0)
;(_call_stack* 3 '(+ (+ a b) c))

;3 (_load_inputs (x) 0)

