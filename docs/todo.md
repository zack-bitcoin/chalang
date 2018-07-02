
we need higher-order functions in compile-time. for now we only have them in run-time.

Lisp should have tests for:
append

We should add syntax for define and macro like this
(define (newFunc A B) (+ (* A A) B))

If we give the wrong number of inputs to a function, the compiler should tell us.
