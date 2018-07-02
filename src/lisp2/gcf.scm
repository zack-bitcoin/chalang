(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm))

%(let '((gcf (define (a b)
%	      (case (((eqs 0 b) a)
%		      (true (recurse b (rem a b))))))))
%       (eqs 12 (apply gcf '(24 36))))

(let ((gcf (define (a b)
	     (case (((eqs 0 b) a)
		    (true (recurse b (rem a b))))))))
       (eqs 12 (apply gcf '(24 36))))
