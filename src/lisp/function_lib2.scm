(import (flatten.scm))
;this is a library for making functions at run-time.

;This library is very efficient, but functions made with this library cannot have a deep cond statment. variables are allowed in the first half of the first pair of inputs to the cond.

;functions made with this library can have any number of inputs
;this version is does not use variables. Function inputs are all stored in the stack and r-stack.
; so a function like `(define square_plus (x y) (+ (* y y) x)` gets expanded to `swap >r dup >r >r r> r> * r> +`

; our goal with function_lib2 is to store the inputs in the r stack. We want to store as many copies of the variable as we will need to read from the r-stack, in the order we need to read them.
; so the same function would get expanded to `swap >r dup >r >r r> r> * r> +`
; Then we want a just-in-time compiler to simplify it to `swap >r dup * r> +'

; ideally `dup * +`

;(>r 500) ;start storing inputs to functions at 500, that way 1-499 are available for smart contract developers.

(macro _length (X)
       ;returns the length of list X at compile-time
       (cond (((= X ()) 0)
	      (true (+ (_length (cdr X)) 1)))))
(macro _replace (Vars Op)
       (cond (((= Vars ()) ())
	      ((= Op (car Vars)) Op)
	      (true (_replace (cdr Vars) Op)))))
(macro _replace_test ()
       (= (_replace '(+ x 5) x) x))
(macro _order_needed2 (Vars Code)
       (cond (((= Code ()) ())
	      ((is_list (car Code))
		 (cons (_order_needed2 Vars (car Code))
		       (_order_needed2 Vars (cdr Code))))
	      ((= (_replace Vars (car Code)) ())
	       (_order_needed2 Vars (cdr Code)))
	      (true (cons (_replace Vars (car Code))
			  (_order_needed2 Vars (cdr Code)))))))
(macro _order_needed (Vars Code)
       ;what order should we put the Vars in the stack so that we can process Code
       (flatten (_order_needed2 Vars Code)))
(macro foo ()
       (= (a b c)
	  (_order_needed (c b a)
			  '(+ a (- b c)))))
;(foo)
(macro last_time2 (A)
       (cond (((= A ()) 1)
	      ;((= (cdr A) ()) 1)
	      (true 0))))
(macro last_time (X Code) ;check that X only appears once in Code.
       (last_time2 (_order_needed '(X) 'Code)))
(macro last_time3 (Code) ;check that X only appears once in Code.
       ;(last_time2 (_order_needed '(,(car Code)) (cdr Code))))
       (last_time2 (_order_needed '(,(car Code)) (cdr Code))))
(macro last_time3_test ()
       (= (= 1 1)
	  (last_time3 (x y))))
;(last_time3_test)
(macro last_time_test ()
       (= (and 1 1)
	  (and
	   (and
	    (not (last_time x '(x 1)))
	    (not (last_time x '(+ x (* (+ y x) x)))))
	   (and
	    (not (last_time y '(y x)))
	    (last_time y '(x))))))
;(last_time_test)
(macro last_time_test2 ()
       (cond (((last_time x '(x 1)) 5)
	      ((last_time y (y x)) 6)
	      (true 7))))
;(last_time_test2)
(macro last_time_test3 (X Code)
       (cond (((last_time X Code) 9)
	      (true 10))))
;(last_time_test3 y '(y x))

(macro depth (x l)
       (cond (((= x (car l)) (_length (cdr l)))
	      (true (depth x (cdr l))))))

(macro optimized_pick (N)
       (cond (((= N 0) ())
	      ((= N 1) 'swap)
	      ((= N 2) 'rot)
	      (true '(pickn N)))))
(macro pick_test ()
       '(() 1 2 3 4 5 6 7
	   ,(optimized_pick 4)))
;       '(pickn 4 3 2 1))
;(pick_test)
;(macro optimized_tuck (N)
;       (cond (((= N 0) ())
;	      ((= N 1) 'swap)
;	      ((= N 2) 'tuck)
;	      (true '(tuckn N)))))
;(macro tuck_test ()
;       '(nop 1 2 3 4 5 6 7 ,(optimized_tuck 3)))
	     ;(tuckn 4 3 2 1))
;(tuck_test)
(macro remove_nth (N L)
       (cond (((= (_length L) (+ 1 N)) (cdr L))
	      (true (cons (car L)
			  (remove_nth N (cdr L)))))))
(macro remove_nth_test ()
       (remove_nth 1 (1 2 3 4 5)))
;(remove_nth_test)
(macro move_to_bottom2 (N L A)
       (++ (remove_nth N L) (cons A ())))
(macro move_to_bottom_test (X)
       (= (move_to_bottom2 1 (x y) X)
	  (y x)))
;(move_to_bottom_test x)
(macro setup_inputs3 (Have Goal)
       '(()
	 ;,(optimized_tuck (_length Have))
	 ,(>r)
	 ,(setup_inputs Have Goal)
       ))
;look up location of (car Goal) in Have -> N
(macro setup_inputs2 (N Have X Goal)
       '(()
	 ,(optimized_pick N)
	 ,(cond (((last_time3 (cons X Goal))
		  (setup_inputs3 (remove_nth N Have) Goal))
		 (true '(()
			  dup
			  ,(setup_inputs3 (move_to_bottom2 N Have X) Goal))))))) ;move Nth to top of Have (bottom of the list)
(macro to_r_times (N)
       (cond (((= N 0) ())
	     (true '(()
		      >r
		      ,(to_r_times (- N 1)))))))
(macro setup_inputs (Have Goal)
       (cond (((= Have (reverse Goal)) (to_r_times (_length Goal)))
	      (true
	       (setup_inputs2 (depth (car Goal) Have)
			      Have (car Goal) (cdr Goal))))))

;check if this is the last instance of this variable in Goal
 ;if: NewHave = remove Nth from Have
 ;if not: dup, move Nth to top of Have (bottom of the list)
;tuck it to the bottom of the inputs
;(setup_inputs NewHave Goal)
(macro setup_test (Vars Code)
;(setup_inputs (x y) (x y y x)))
       (setup_inputs Vars (reverse (_order_needed Vars Code))))
       ;(setup_inputs Vars (_order_needed Vars Code)))
;8 7 6 5 4 3
;(setup_test (a b x) '(+ (a (+ b a)) (+ x x)))
;(setup_test (a b c) '(+ a (+ b c)))
;(setup_test (a b c) '(+ (- c b) a))
;(setup_inputs (a b) (b a))
;(setup_inputs (a b) (a b))
;(setup_inputs (a b) (a b))
;8 9 10
;(setup_inputs (a b) (b a))
;(setup_inputs2 1 (a b) a (b));good
;(setup_inputs2 0 (a b) b (a))
;8
;(depth a (a b c c))
;(depth a (b a c c))
(macro in_list (X L)
       (cond (((= L ()) 0)
	      ((= X (car L)) 1)
	      (true (in_list X (cdr L))))))
(macro from_r_var (V Code)
       (cond (((= Code ()) ())
	      ((is_list Code)
	       (cons (from_r_var V (car Code))
		     (from_r_var V (cdr Code))))
	      ((in_list Code V) r>)
	      (true Code))))
(macro from_r_var_test ()
	  (from_r_var (x y) '(+ y x)))
;4 >r 5 >r
;(from_r_var_test)
(macro lambda (Vars Code) ; define a new function
       '(()
	 start_fun
	 ,(setup_inputs Vars (reverse (_order_needed Vars 'Code)))
;	 ,(setup_inputs Vars (_order_needed Vars 'Code))
	 ,(from_r_var Vars 'Code);for every var in code, replace the var with r>
	 end_fun))

;(macro delist (L)
;       (cond (((= L ()) ())
;	      (true '(() ,(car L) ,(delist (cdr L)))))))
;(delist (1 2 3))

;define stores the 32-byte function id into a variable
;be careful with define, if a different function gets stored into the variable, then you could end up calling different code than you had expected. Make sure that it is impossible for an attacker to edit the variable after the function is defined.
(macro define (Name Vars Code)
       '(! ,(lambda Vars Code) Name))
(macro apply (Function Variables)
       (cons call
	     (reverse (cons Function
			    (reverse (cons () Variables))))))
(macro execute (Function Variables)
       (cons call
	     (reverse (cons Function
			    (reverse (cons () Variables))))))
(macro square () (lambda (x y) (- (+ y y) (+ x x))))
(macro lambda_test1 ()
       (apply (square) (3 4)))
;(lambda_test1)
;(define square2 (x) (* x x))
(macro lambda_test ()
       (apply (@ square2) (5)))
;(= 25 (lambda_test))



