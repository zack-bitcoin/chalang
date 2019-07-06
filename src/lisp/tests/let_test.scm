(import (core/eqs.scm core/let_macro.scm core/let.scm))

; this is happening at compile time
; this is like a macro that is only defined for a small space.
(macro test ()
    (let_macro ((x 5)
	  (y (- x 2)))
      '(+ x y)))

(= 8 (test))
;0

