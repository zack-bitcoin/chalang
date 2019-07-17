(import (basics.scm))

; first show a case statement at compile time
(macro Z () 
       (cond (((= 0 1) 0)
	      (true
	       (cond
		((false 0)
		 (true 1)))))))
 (Z)

; next show a case statment at run time

(cond (((= 1 2) 0)
       (false 0)
       (true 1 )))

and
