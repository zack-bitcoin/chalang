(import (core/eqs.scm core/let_macro.scm core/let.scm))

; this is for defining local variables are compile-time. it is probably useless.
(macro test ()
    (let_macro ((x 5)
	  (y (- x 2)))
      '(+ x y)))
(= 8 (test))

;this version is for local variables at run-time. so you don't pollute the runtime global variable space.
(! 5 Z )
(macro test2 ()
       (let ((x 20)
             (y (@ Z))
             (z (* 1 (@ Z))))
         (+ y (- y (* y (* y 0))))))
(= 6 (test2))
and
