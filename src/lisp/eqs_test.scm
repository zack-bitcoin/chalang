(import (eqs_lib.scm))

					; compile time
(macro A () (= 5 5))
(A)
(macro B () (= () ()))
(B)


; run time
(= 6 6)
(= nil nil)

and
and
and
%0
