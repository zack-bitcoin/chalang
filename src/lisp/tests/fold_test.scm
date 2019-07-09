(import (core/fold.scm core/tree.scm))

(macro test ()
       (fold (lambda (a b) (+ a b))
             0
             (tree (1 2 3 4 5 6))))
(= (test) 21)
