
% case happens at run time. cond happens at compile time.
% case.scm tests this out.

(macro case (X)
       (cond (((= X ()) '(nop))
	      (true '(nop
		      ,(car (car X))
		      if
		      ,(car (cdr (car X)))
		      else
		      (case ,(cdr X))
		      then)))))
