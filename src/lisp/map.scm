(import (eqs_lib.scm function_lib3.scm cond_lib.scm))

; the map is happening completely at run-time

(define map (F X)
  (cond (((= nil X) nil)
	 (true (cons
		(execute F ((car X)))
		(recurse F (cdr X)))))))

; this map is happening completely at compile-time
(macro map2 (f l)
       (cond (((= () l) ())
	      (true
	       (cons (execute f ((car l)))
		     (map2 f (cdr l)))))))

			      
