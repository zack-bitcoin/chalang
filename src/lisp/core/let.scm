; let is a common tool for lisp.
(import (basics.scm core/let_macro.scm))

;let is how lisp offers local variables. That way you don't pollute the global namespace

;this let library provides the most standard syntax of let for lisp. example
;(let ((x 2)(y 3)(z 5)) (+ (- z y) x)) -> 2

;you can use expressions as inputs to the let expression:
;(let ((x (@ Height))(y 3)) (+ x y)) -> (+ (@ Height) 3)

(macro seconds (ps)
  (cond (((= () ps) ())
         (true 
          (cons (car (cdr (car ps)))
                (seconds (cdr ps)))))))
(macro firsts (ps)
  (cond (((= () ps) ())
         (true 
          (cons (car (car ps))
                (firsts (cdr ps)))))))
;(firsts '((1 2)(3 4)))
;(seconds '((x 2)(3 y)))

(macro let (pairs code)
       (nop (>r (+ @r 30));hopefully the parent functions has less than 30 input variables. there is probably a better way to do this.
             (seconds pairs)
             (let_stack (flip (firsts pairs) ())
                        code)
             (drop r>)))

(macro flip (a b)
       (cond (((= a ()) b)
              (true (flip (cdr a)
                          (cons (car a)
                                b))))))
;'(1 2 3)
;(flip '(1 2 3) ())

;20 10 (let_stack (x y) (+ x (- 1 y)))
;(seconds '((x 20)(y 10)))
;(flip (seconds '((x 20)(y 10))) ())
;(let_stack (firsts '((x 20)(y 10)))
;           (+ x (- 1 y)))
;(let_stack (firsts (tree ((x 2) (y 3))))
                                        ;           '(+ (- y 1)))
(! 5 Z )
;(@ Z)
;(seconds '((x 10) (y (@ Z))))
(let ((x 20)
      (y (@ Z))
      (z (* 1 (@ Z))))
  (+ y (- x (* z 1))))
