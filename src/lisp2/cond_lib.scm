
(macro cond (X)%this cond is a macro. it generates byte code.
       (cond (((= X ()) '(nop))%this cond is part of the pre-processor. It cannot generate byte code.
	      (true '(nop
		      `(car (car X))
		      if
		      `(car (cdr (car X)))
		      else
		      (cond `(cdr X))
		      then)))))
