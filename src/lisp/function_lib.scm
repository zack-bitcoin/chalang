% this is a library for making functions at run-time.

% uses the r-stack to store the memory locations
% for the input of the functions we are currently
% processing. So the r-stack is used as a function
% call stack, one additional thing is pushed every
% time a function is called, and one thing is
% removed every time a function returns.

(>r 500) %start storing inputs to functions at 500, that way 1-499 are available for smart contract developers.

(macro _pointer (X)
       % look up a pointer to the xth variable being stored for the current function being processed
       (cond (((= X 0) '(r@))
	      (true '(+ r@ X)))))
(macro _load_inputs (V N)
       % store the inputs of the function into variables,
       % the top of the r stack points to these variables.
       (cond (((= V ()) ())
	      ((= 0 N) '(nop r@ !
			  ,(_load_inputs (cdr V) 1)))
	      (true '(nop ,(_pointer N) !
			  ,(_load_inputs (cdr V) (+ N 1)))))))
(macro _variable* (Var Code N)
       %Replace each Var in Code with the input to the function
       (cond (((= Code ()) ())
	      (true
	       (cons
		(cond
		 (((is_list (car Code))
		   (_variable* Var (car Code) N))
		  ((= (car Code) Var)
		   '(@ (_pointer N)))
		  (true (car Code))))
		(_variable* Var (cdr Code) N))))))
(macro _variables (Vars Code N)
       % repeatedly use _variable* to replace
       % each Var in Code with the inputs to the function,
       % which are stored in the vm as variables.
       (cond (((= Vars ()) Code)
	      (true (_variables
		     (cdr Vars)
		     (_variable* (car Vars) Code N)
		     ,(+ N 1))))))
(macro _call_stack* (Many Code)
       % functions need to be able to call other functions.
       % if function A calls function B, then when our
       % program returns from function B, we need to
       % remember the inputs for all the variables in
       % function A, so we can process the rest of
       % function A correctly.
       (cond
	(((= Many 0) Code)
	 %if a function has no inputs, then the call
	 % stack remains unchange.
	 ((= Code ()) ())
	 ((is_list (car Code))
	  (cons (_call_stack* Many (car Code))
		(_call_stack* Many (cdr Code))))
	  ((= (car Code) call)
	   '(nop ,(cdr Code) (+ r@ Many) >r
		 call
		 r> drop))
	  (true 
	   (cons (car Code)
		 (_call_stack* Many (cdr Code)))))))
(macro _length (X)
       %returns the length of list X at compile-time
       (cond (((= X ()) 0)
	      (true (+ (_length (cdr X)) 1)))))
(macro lambda (Vars Code)
       '(nop 
	     start_fun
	     ,(_load_inputs Vars 0)
	     (_call_stack* ,(_length Vars)
			  ,(_variables (reverse Vars)
					   (Code)
					   0))
	     end_fun))
%(_length (1 1 5 1 1 1 1))
%(_pointer 3) % 4

%4 3 (_load_inputs (a b) 0)
%(_variable* a '(+ a 1) 0) %900 @ 5 + @
%(_variable* a (_variable* b (a b) 0) 1)
%(_variables (a b) '(+ a (+ b 2)) 0)
%(_call_stack* 3 '(+ (+ a b) c))

%3 (_load_inputs (x) 0)

(macro execute (F V)
       (cons call (reverse (cons F (reverse V)))))


