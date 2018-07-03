(import (eqs_lib.scm cond_lib.scm))

% first show a case statement at compile time
(macro Z () 
       (cond (((= 0 1) 6)
	      (true 7)))
)
(Z)

% next show a case statment at run time 
(cond (((= 1 2) 6)
       (true 7 )))

and
