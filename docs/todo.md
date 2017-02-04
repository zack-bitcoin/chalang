Before we compile any code, we should delete all the bytes it contains besides the characters we need for programming. This is to protect us from whitespace injection.


We should have 2 types of functions.
One for fast recursion, and the other for merkelizing the code.

Lisp should have:
append
defmacro

We should add syntax for define like this
(define (newFunc A B) (+ (* A A) B))

If we give the wrong number of inputs to a function, the compiler should tell us.

We should change from static scope to lexical scope. We just rename variables with prefixes depending on their scopal location.

