(import (core/let.scm ));basics.scm))

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
;(= 10 (test2))
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
;(= (test) 65)
;and
(macro test ()
       (let ((a 10)) (a)))
;(test)
(macro test99 (A)
       (let* ((a A);10
              (b (+ a 2)) ;12
              (c (- b (* a 1))) ;2
              (d (+ (+ c 2) a)));14
         (+ d (- b a))));16
;(=
; (test99 10) 16)
;and
;(test)
(macro test98 (A)
       (let* ((a A)
             (b (+ a 1)))
         (a)))
;(test98 5)
(define (test100) ;(test98 8))
   (let ((a 8)(b 5))
     (+ 2 b)))
;(test100 0)
(define (test101) ;(test98 8))
   ;((! A Z))
;   (write
;    (let ((a (@ Z))) (a)))
;  (let* ((a 6)(b (+ a 1)))
;    b))
  (let*2 ((a 8)(b (+ a 10)))
         (+ 2 b)
         5))
;(test101)
;(test98 5)
;0
;[[] [>r [+ @r 30 ] ] [[] [@ Z ] ] [nop [nop r@ ! [] ] [[[@ [r@ ] ] ] ] ] [drop r> ] ]
;[[] [>r [+ @r 30 ] ] [[] [@ Z ] r@ 0 + ! [[[@ [r@ ] ] ] ] ] [drop r> ] ]
   ;(let* ((a (@ Z))) a)))
;(define (foo q g)
; (test q g))
;(foo 10 0)
;(= (test 10) 16)
;(=
; (test100 9)
                                        ; 1)
1
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

; I tried to write it by hand, and it ended up being 30 opcodes.
; 1 dup r@ ! 2 + dup r@ 1 + ! 2 r@ @ - 2 + r@ @ swap - r@ 1 + @ r@ @ - + ;

;and
;0
