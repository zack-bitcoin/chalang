(import (core/sort.scm))
; merge-sort

; first at compile-time
;(macro test_ct_sort ()
;       (=
;	(ct_sort (3 1 5 3 9 20 4 8))
;	(1 3 3 4 5 8 9 20)))
;(test_ct_sort)

;;;;;; next at run-time
(define lt (a b) (< a b))

(=
 (sort (tree (3 1 5 3 9 20 4 8)) (@ lt))
   (tree (1 3 3 4 5 8 9 20)))
;0
;and
