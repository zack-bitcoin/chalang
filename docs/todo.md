
in map2.scm the higher order macros are very fragile. It seems like if I change anything about that file it breaks.
We should make it work better, or at least give better error messages.

Lisp should have tests for:
append

We should add syntax for define and macro like this
(define (newFunc A B) (+ (* A A) B))

If we give the wrong number of inputs to a function, the compiler should tell us.
