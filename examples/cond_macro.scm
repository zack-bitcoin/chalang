(macro = (A B)
       '(nop A B === swap drop swap drop))
(macro cond (X)%this cond is a macro. it generates byte code.
       (cond (((= X ()) '(nop))%this cond is part of the pre-processor. It cannot generate byte code.
	      (true '(nop
		      `(car (car X))
		      if
		      `(car (cdr (car X)))
		      else
		      (cond `(cdr X))
		      then)))))
(cond (((= 4 5) 3)
       (false 2)
       (true 1)))
