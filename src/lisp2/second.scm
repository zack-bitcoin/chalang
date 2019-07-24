
                                        ;(tree ((1) 2))
;let is for lexically scoped variables. They are necessary for recursion if you don't write in the tail-call optimized style. They work best if you have many small functions with few inputs and outputs.
(= 6
   (let (((_ _ _ d) (1 2 3 4))
         ((a b c) (5 6 7)))
     (+ d 2)))

;var is for dynamically scoped global variables. They work well for configuration constants, and for non-recursive functions, or tail-call optimized recursive functions, who have many inputs.
(
 (var (Z 3))
 (define (f) (@ Z))
 (= 3 (f))
 )
;(f) ;<-- this returns an error because function f does not exist here. Z doesn't exist either.

(var (Z 4) A);initializing multiple variables

(define (f) (@ Z))
(= 4 (f))
(define (f2)
  ((var (C 7))));as a side effect, C is set to 7
(define (f3);f3 is identical to f2
  ((var C)
   (set! C 7)))
(define (f1)
  (
   (var (C 6));C starts as 6
   (f3);side effect changes C to 7
   (@ C)));returns 7
(= 7 (f1))


(forth and and and)

(define (f5 x)
  x)
(define (f4 y)
  (f5 4))
(f4 9)
