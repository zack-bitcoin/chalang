% look at case.scm

(import (cond_lib.scm))
(import (eqs_lib.scm))

(cond (((= 4 5) 3)
       (false 2)
       (true 1)))
