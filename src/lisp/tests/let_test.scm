(import (core/let.scm))

; this is for loading variables off the stack into local namespace
; it is important for loading values from the script sig into the script pubkey.
; this tool is used in the definition of `define` and `let`.
(macro test3 ()
       (nop 3 5
            (let_stack (x y)
                       (* (+ x x) y))))
;(= (test3) 30)


; this is for defining local variables are compile-time. it is probably useless.
(macro test ()
    (let_macro ((x 5)
	  (y (- x 2)))
      '(+ x y)))
;(= 8 (test))
;and

;this version is for local variables at run-time. so you don't pollute the runtime global variable space.
(! 5 Z )
(macro test2 ()
       (let ((x 20)
             (y (@ Z))
             (z (* 1 (@ Z))))
         (+ y (- y (* y (* y 0))))))
(= 10 (test2))
;and
;(let ((x 3))
;  (+ x 5))

(macro test ()
       (let ((a 5))
         (let ((g a)
               (b (+ a 4))
               (c (- a 1)))
           (let ((d (+ b c))
                 (h g))
             (* d h)))))
(= (test) 65)
and
(macro test ()
       (let ((a 10)) (a)))
;(test)
(macro test ()
       (let* ((a 1)
              (b (+ a 2)) ;3
              (c (- b (* a 2))) ;1
              (d (- (+ c 2) a)));2
         (+ d (- b a))));4
(= (test) 4)
;compared to javascript, it is practically identical
; function test() {
;   var a = 1;
;   var b = a + 2;
;   var c = b - (2 * a);
;   var d = a - (c + 2);
;   return (d + (b - a));
; }

;let* expression compiles to this:
;  1 dup r@ ! 2 + dup r@ 1 + ! r@ @ 2 * - 2 + r@ @ - r@ 1 + @ r@ @ - +
;29 opcodes from 5 variable definitions, 7 variable reads, and 9 arithmetic operations. 5+7+9/29 is about 70% efficiency. Hand written code in assembly wouldn't be much shorter.

and
;0

