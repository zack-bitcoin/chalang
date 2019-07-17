(import (basics.scm))

(define Double (x) (+ x x))

(=
 (Double 5)
 10)


(deflet foo (a);5
  ((c (+ a 3));8
   (d (+ c a));13
   (e (- (+ d c) 10)))
  (e))
;0
(= 11 (execute (@ foo)  (5)))
and

;4 variable definitions, 5 variables reads, 4 arithmetic operations, 1 function definition
;def dup r@ ! 3 + dup r@ 1 + ! r@ @ + r@ 1 + @ + 10 - ;

;23 opcodes. 


