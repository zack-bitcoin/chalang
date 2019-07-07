; let is a common tool for lisp.
(import (basics.scm))

;let is how lisp offers local variables. That way you don't pollute the global namespace

;this let library provides the most standard syntax of let for lisp. example
;(let ((x 2)(y 3)(z 5)) (+ (- z y) x)) -> 2

;you can use expressions as inputs to the let expression:
;(let ((x (@ Height))(y 3)) (+ (- x x) y)) -> (- y (* 2 (@ height)))

; the (@ Height) computation executes only once, the result is stored in a variable, and read from that variable for every time you use x.

(macro seconds (ps)
  (cond (((= () ps) ())
         (true
          (cons ()
                (cons (car (cdr (car ps)))
                      (seconds (cdr ps))))))))
(macro firsts (ps)
  (cond (((= () ps) ())
         (true 
          (cons (car (car ps))
                (firsts (cdr ps)))))))
;(firsts '((1 2)(3 4)))
;(seconds '((x 2)(3 y)))
                                        ;1
;(macro mcons (x y) (cons x y));for some reason I had to do this to get the compiler-time version of cons to run.
(macro let (pairs code)
       '(() (>r (+ @r 30));hopefully the parent functions has less than 30 input variables. there is probably a better way to do this.
         (seconds pairs)
         (let_stack ;(firsts pairs)
          (reverse (firsts pairs))
          code)
         (drop r>)))
(macro let* (pairs code)
       (cond (((= pairs ()) code)
              (true (let* (cdr pairs)
                      (let ((car pairs)) code))))))


(macro let*_bad (pairs code)
       (nop (>r (+ @r 30))
            pairs
            (_call_stack*
             (_length pairs)
             (_variables (reverse (firsts pairs))
                         '(code)
                         0))))

;(let ((a 0)(x 2)(y 5)(z 7)) (+ x y))
;(let ((a 5)) (+ a b))

;0

;2 5 7 (let_stack (x y z) (+ x y))
;(seconds '((x 20)(y 10)))
;(let_stack (reverse (firsts '((x 20)(y 10))))
;           (+ x (- 1 y)))

;(! 5 Z )
;(let ((x 20)
;      (y (@ Z))
;      (z (* 1 (@ Z))))
;  (+ y (- y (* y (* y 0)))))
;drop
