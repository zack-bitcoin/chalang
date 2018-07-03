(import (eqs_lib.scm function_lib.scm cond_lib.scm let_lib.scm))

% computing gcf at run-time
(let ((gcf (define (a b)
	     (cond (((= 0 b) a)
		    (true (recurse b (rem a b))))))))
  (= 12 (execute gcf '(24 36))))


% computing gcf at compile-time
(macro ctgcf (a b)
       (cond (((= b 0) a)
	      (true (ctgcf b (rem a b))))))

(macro test ()
   (= 12 (ctgcf 24 36))
   )
(test)
and
%0
