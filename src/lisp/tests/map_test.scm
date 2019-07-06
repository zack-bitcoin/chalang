(import (core/map.scm))

; map_ct is happening completely at compile time
(macro double2 (x) (* 2 x) )
(macro test3 ()
       (=
	(map_ct 'double2 (2 3 4 5))
	(4 6 8 10)))
(test3)

; but this time we use `define` to make the function.
; so that means that the 32-byte function id is being stored in a variable.
;e can read the variable with `@`

(define (double3 x) (* 2 x) )
(=
 (map (@ double3) (tree (2 3 4)))
 (tree (4 6 8)))
and

; this time we are mapping using an anonymous function

(=
 ;(map (@ double3) (tree (2 3 4)))
 (map (lambda (x) (* 2 x)) (tree (2 3 4)))
 (tree (4 6 8)))

and
