(import (core/let_macro.scm
         flatten.scm))

;this is a library for making functions at run-time.

(macro lambda (Vars Code)
       ; define a new function
       '(nop
         def
         ,(let_stack Vars Code)
         end_fun))
;(ex (lambda (a b c) '(nop b))
(macro define (Name Vars Code)
      ;make a new function and give it a name.
       '(! ,(lambda Vars Code) Name))
(macro execute (F V)
       '(call ,(cons nop V) F))
(macro execute2 (Vars)
       '(execute (@ ,(car Vars)) ,(cdr Vars)))



(macro lexical_define (Name Vars Code)
       (lexical_define2 Name Vars Code (context Code)))
;(macro lexical_define2 (Name Vars Code Context)
;       '(,(context_switch Context)
;         ,(define Name (local_vars Vars Context)
;            (local_vars Code Context))))
(macro context2 (code)
      (cond (((= () code) ())
              ((is_number code) ())
              ((is_list code) ;())
               (cons '(context2 ,(car code))
                     (context2 (cdr code))))
              (true code))))
(macro context (X)
       (flatten (context2 X)))
;(context '(a 5 is (te beginning)))
;(write (abc def))
;(write (context '(abc '(1 def) abc)))
;0





;(define square (x)
;  (* x x))
;(ex (square 5))

;3 4 5 6 7
;(lambda (x y) (+ 1 (+ x y)))
;(lambda (x y z) (+ x (+ z y )))
;(_load_inputs (x y z) 0)
;(_length (x y z))
;(_variables (z y x) '(+ z (+ y x)) 0)
					;0
;1

;(1 2 3)
;(cons 1 (cons 2 (cons 3 ())))


;(_length (1 1 5 1 1 1 1))
;(_pointer 3) ; 4

;4 3 (_load_inputs (a b) 0)
;(_variable* a '(+ a 1) 0) ;900 @ 5 + @
;(_variable* a (_variable* b (a b) 0) 1)
;(_variables (a b) '(+ a (+ b 2)) 0)
;(_call_stack* 3 '(+ (+ a b) c))

;3 (_load_inputs (x) 0)

