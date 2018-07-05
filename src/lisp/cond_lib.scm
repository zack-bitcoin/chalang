% run time
% case.scm tests this out.

(macro cond (X)
       (cond (((= X ()) '(nop))
	      (true '(nop
		      ,(car (car X))
		      if
		      ,(car (cdr (car X)))
		      else
		      (cond ,(cdr X))
		      then)))))