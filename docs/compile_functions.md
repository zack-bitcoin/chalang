getting variables to work correctly in functions can't be done completely at compile-time.
If a function calls itself recursively, and the function is not tail-call optimized, then we need to remember the values of the caller-function's variables, so that when the child returns, we know how to finish the parent's execution.
So, we need to keep track of a variable, at run-time, which increments every time we call a function, once for each of the function's inputs. The goal is to never re-use variables for functions that are being executed simultaniously.


f(x) ->
   cond
      (= x ()) ()
      true ((f (cdr (x)))
      	    drop
 %x needs to still exist at this point, with value 'x'
	    x)


Fdepth will keep track of how many variables have been defined. When returning from a function, fdepth needs to decrease by the number of variables to to the caller function.
When calling a function, Fdepth needs to increase by the number of variables to the caller function.
So variables in functions get compiled something like this:

(define func1 (x y) (+ x y))
(define func2 (x y) (+ (apply func1 (x y)) y))
(define func3 (x y) (apply func2 (x y)))

macro Fname 9999 ;
macro Fdepth Fname @ ;
macro A1 Fdepth 0 + ;
macro A2 Fdepth 1 + ;
: func1
  A1 ! A2 !
  A1 @ A2 @ + ;
: func2
  A1 ! A2 !
  A1 @ A2 @
  Fdepth 2 + Fname ! func1 call
  Fdepth 2 - Fname !
  A2 @ +;
: func3
  A1 ! A2 !
  A1 @ A2 @
  func2 call ;


: func1 + ;
: func2 dup tuck func1 call + ;
: func3 func2 call ;