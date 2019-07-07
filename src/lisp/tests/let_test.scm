(import (core/let.scm))

; this is for loading variables off the stack into local namespace
; it is important for loading values from the script sig into the script pubkey.
; this tool is used in the definition of `define` and `let`.
(macro test3 ()
       (nop 3 5
            (let_stack (x y)
                       (* (+ x x) y))))
;(= (test3) 30)


; this is for defining local variables are compile-time. it is probably useless.
(macro test ()
    (let_macro ((x 5)
	  (y (- x 2)))
      '(+ x y)))
;(= 8 (test))
;and

;this version is for local variables at run-time. so you don't pollute the runtime global variable space.
(! 5 Z )
(macro test2 ()
       (let ((x 20)
             (y (@ Z))
             (z (* 1 (@ Z))))
         (+ y (- y (* y (* y 0))))))
(= 10 (test2))
;and
;(let ((x 3))
;  (+ x 5))

(macro test ()
       (let ((a 5))
         (let ((g a)
               (b (+ a 4))
               (c (- a 1)))
           (let ((d (+ b c))
                 (h g))
             (* d h)))))
(= (test) 65)
and
(macro test ()
       (let ((a 10)) (a)))
;(test)
;0
