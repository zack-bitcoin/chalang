;(import (eqs_lib.scm function_lib2.scm cond_lib.scm let_lib.scm tree_lib.scm))
(import (sort.scm))


; merge-sort

; first at compile-time

(macro test_ct_sort ()
       (=
	(ct_sort (3 1 5 3 9 20 4 8))
	(1 3 3 4 5 8 9 20)))
(test_ct_sort)

;;;;;; next at run-time

(= (rt_sort (tree (3 1 5 3 9 20 4 8)))
   (tree (1 3 3 4 5 8 9 20)))

and
;(rt_sort (tree (3 5 7 2 45 2 5 3)))
