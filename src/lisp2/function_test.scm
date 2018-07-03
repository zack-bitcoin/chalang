(import (function_lib.scm))

(macro test ()
       (define (x) (+ x x)))

(execute (test) (5))
(execute (test) (5))
(execute (test) (5))
(execute (test) (5))
