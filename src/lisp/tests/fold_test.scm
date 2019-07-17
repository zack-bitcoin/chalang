(import (core/fold.scm core/tree.scm))

(define sum (a b) (+ a b))

(macro test ()
       (fold (@ sum)
             ;(lambda (a b) (+ a b))
             0
             (tree (1 2 3 4 5 6))))
(= (test) 21)
