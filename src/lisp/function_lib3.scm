; this is a library for making functions at run-time.

; uses the r-stack to store the memory locations
; for the input of the functions we are currently
; processing. So the r-stack is used as a function
; call stack, one additional thing is added to r every
; time a function is called, and one thing is
					; removed from r every time a function returns.

(>r 500) ;start storing inputs to functions at 50, that way 1-49 are available for smart contract developers.
(macro _pointer (X)
       ; look up a pointer to the xth variable being stored for the current function being processed
       (cond (((= X 0) '(r@))
	      (true '(+ r@ X)))))
;(macro pointer_test ()
;       '(@ (_pointer 3)))
;(pointer_test)

(macro _load_inputs (V N)
       ; store the inputs of the function into variables,
       ; the top of the r stack points to these variables.
       (cond (((= V ()) ())
	      ((= 0 N) '(nop r@ !
			  ,(_load_inputs (cdr V) 1)))
	      (true '(nop ,(_pointer N) !
			  ,(_load_inputs (cdr V) (+ N 1)))))))
;1 2 3
;(_load_inputs (a) 0)
(macro _variable* (Var Code N)
       ;Replace each Var in Code with the input to the function
       (cond (((= Code ()) ())
	      (true
	       (cons
		(cond
		 (((is_list (car Code))
		   (_variable* Var (car Code) N))
		  ((= (car Code) Var)
		   '(@ ,(_pointer N)))
		  (true (car Code))))
		(_variable* Var (cdr Code) N))))))
;(_variable* zack '(nop 0 zack) 1)
(macro _variables (Vars Code N)
       ; repeatedly use _variable* to replace
       ; each Var in Code with the inputs to the function,
       ; which are stored in the vm as variables.
       (cond (((= Vars ()) Code)
	      (true (_variables
		     (cdr Vars)
		     (_variable* (car Vars) Code N)
		     (+ N 1))))))
;(_variables (reverse (a b c)) '(nop b) 0)
;(import (eqs_lib.scm))
;2 3
;(_load_inputs (a b) 0)
;(macro test ()
;       (=
;       '((+ 2 (@ r@)))
;       (_variable* a '(+ 2 a) 0))
;(test)
;(_variable* a (_variable* b '(a b) 0) 1)
;(_variables (b a) '(cons a b) 0)
;(_variable* a '(+ a 1) 0)
;0
(macro _call_stack* (Many Code)
       ; functions need to be able to call other functions.
       ; if function A calls function B, then when our
       ; program returns from function B, we need to
       ; remember the inputs for all the variables in
       ; function A, so we can process the rest of
       ; function A correctly.
       (cond
	(((= Many 0) Code)
	 ;if a function has no inputs, then the call
	 ; stack remains unchange.
	 ((= Code ()) ())
	 ((is_list (car Code))
	  (cons (_call_stack* Many (car Code))
		(_call_stack* Many (cdr Code))))
         ((= (car Code) call)
	   ;'(nop ,(cdr Code) (+ r@ Many) >r
	   ;'(nop ,(_call_stack* Many (cdr Code)) (+ r@ Many) >r
	   '(nop ,(_call_stack* Many (cdr Code)) ,(_pointer Many) >r
                 call
                 r> drop))
                 ;,(_call_stack* Many (cdr Code))))
         (true 
          (cons (car Code)
		 (_call_stack* Many (cdr Code)))))))
(macro _length (X)
       ;returns the length of list X at compile-time
       (cond (((= X ()) 0)
	      (true (+ (_length (cdr X)) 1)))))
(macro lambda (Vars Code)
       ; define a new function
       '(nop 
	     def
	     ,(_load_inputs Vars 0)
	     ,(_call_stack*
               (_length Vars)
               (_variables (reverse Vars)
			   '(Code)
			   0))
	     end_fun))
;(ex (lambda (a b c) '(nop b))
;define stores the 32-byte function id into a variable
;be careful with define, if a different function gets stored into the variable, then you could end up calling different code than you had expected. Make sure that it is impossible for an attacker to edit the variable after the function is defined.
(macro define (Name Vars Code)
       '(! ,(lambda Vars Code) Name))


(macro execute_old (Function Variables)
       (cons call
	     (reverse (cons Function
                            (reverse Variables)))))
(macro execute (F V)
       '(call ,(cons nop V) F))

(macro exec (Name Vars)
;       (cons call
;	     (reverse (cons Name
                                        ;			    (reverse Vars)))))
       '(execute (@ Name) Vars))
(macro ex (Vars)
       '(execute (@ ,(car Vars)) ,(cdr Vars)))

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

