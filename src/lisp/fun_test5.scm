
(import (eqs_lib.scm let_lib.scm function_lib3.scm))

(define Double (x) (+ x x))

(=
 (execute (@ Double) (5))
 10)
