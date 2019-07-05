
(import (core/map.scm))

; the first map is happening completely at run-time
;(macro double () (lambda (x) (* 2 x)))
;(=
;  (execute (@ map) ((double) (tree (2 3 4 5))))
;  (tree (4 6 8 10)))

; this second map is happening completely at compile time
(macro double2 (x) (* 2 x) )
(macro test3 ()
       (=
	(map_ct 'double2 (2 3 4 5))
	(4 6 8 10)))
(test3)

;and

; but this time we use `define` to make the function.
; so that means that the 32-byte function id is being stored in a variable.
;e can read the variable with `@`

(define double3 (x) (* 2 x) )
;(=
 ;(execute (@ map) ((@ double3) (tree (2 3 4))))
; (map '(@ 'double3) (tree (2 3 4)))
                                        ; (tree (4 6 8)))
(=
 (map (@ double3) (tree (2 3 4)))
 (tree (4 6 8)))
;(tree (2 3 4))

and
