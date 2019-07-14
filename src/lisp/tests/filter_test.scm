(import (core/filter.scm core/tree.scm))

(define even (X) (= 0 (rem X 2)))
(macro test ()
       (filter
        (@ even)
        (tree (2 3 4 5))))
(= (test) (tree (2 4)))


