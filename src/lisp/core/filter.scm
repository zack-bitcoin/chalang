(import (basics.scm))

(define (filter F X)
  (cond (((= nil X) nil)
         ((execute F ((car X)))
          (cons (car X)
                (recurse F (cdr X))))
         (true (recurse F (cdr X))))))


