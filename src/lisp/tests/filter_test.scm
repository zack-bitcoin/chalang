(import (core/filter.scm core/tree.scm))


(macro test ()
       (filter
        (lambda (x) (= 0 (rem x 2)))
        (tree (2 3 4 5))))
(= (test) (tree (2 4)))


