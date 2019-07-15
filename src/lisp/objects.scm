;(import (basics.scm))

(macro make (X) ;(+ X 1))
       
       (lambda (N)
          (cond (((= N 0) X)
                 ((= N 1) (* X 10))))))
;             '(lambda () (! X (+ X 1)))))

             
(macro test_object ()
       ((make 5) 1))
;(test_object)
;(Z)
;0
1
