(import (function_lib3.scm cond_lib.scm tree_lib.scm eqs_lib.scm))

(define binary_convert2 (L N)
  (cond (((= L nil) N)
         (true (binary_convert2
                (cdr L)
                (+ (car L) (* 2 N)))))))
(macro binary_convert (L)
  (binary_convert2 L 0))

(= 20
   (binary_convert (tree (1 0 1 0 0))))

