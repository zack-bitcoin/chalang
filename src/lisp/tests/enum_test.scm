(import (enum.scm))

(macro test ()
       (= (enum 1 5)
	  (1 2 3 4 5)))
(test)
