

(logic_or '((both_reveal) (one_reveal) (end 1 0 0)))

(logic_define both_reveal (Secret1 Secret2)
  ((X (commit 0))
   (X (hash Secret1))
   (Y (commit 1))
   (Y (hash Secret2))
   (C (rem (bxor Secret1 Secret2) 2)))
  (end 3 C (amount)))

(logic_define one_reveal (Secret)
   ((N (logic_or (0 1)))
    (X (commit N))
    (X (hash Secret)))
   (end 2 N (amount)))


(macro (logic_or L)
       %each one needs to be a function, that way we can have continutations.
       (let ((Fs (to_funcs L
  (cond
    ((= (cdr L) ()) '(car L))
    (

(macro (logic_eqs Pointer Func Continuation)
  (let
    ((Var '(get Pointer)))
     '(case
       ((eqs Var (empty)) (store (Func) Pointer))
       ((eqs Var (Func)) ())
       (true (Continutation)))))

(macro both_reveal
  (define (Secret1 Secret2 Continuation VarCounter)
    (nop
     (store (empty) (+ 0 VarCounter))
     (store (empty) (+ 1 VarCounter))
     (store (empty) (+ 2 VarCounter))
     (logic_eqs (+ 0 VarCounter) (commit 0) Continutation)
     (logic_eqs (+ 0 VarCounter) Secret1 Continutation)
     (logic_eqs (+ 1 VarCounter) (commit 1) Continutation)
     (logic_eqs (+ 1 VarCounter) Secret2 Continutation)
     (logic_eqs (+ 2 VarCounter) (rem (bxor Secret1 Secret2) 2) Continutation)
     (end 3 C (amount)))))
  
          	   	    
