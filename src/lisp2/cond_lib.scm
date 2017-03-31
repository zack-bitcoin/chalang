
(macro case (X)
       (cond (((= X ()) '(nop))
	      (true '(nop
		      `(car (car X))
		      if
		      `(car (cdr (car X)))
		      else
		      (case `(cdr X))
		      then)))))
