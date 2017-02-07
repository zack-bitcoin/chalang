Before we compile any code, we should delete all the bytes it contains besides the characters we need for programming. This is to protect us from whitespace injection.

We should have 2 types of functions.
One for fast recursion, and the other for merkelizing the code.

Lisp should have tests for:
append
binaries

We should add syntax for define and macro like this
(define (newFunc A B) (+ (* A A) B))

If we give the wrong number of inputs to a function, the compiler should tell us.

We should change from static scope to lexical scope. We just rename variables with prefixes depending on their scopal location. Instead of using set!, we should use (let ((x 2)(y 3))). The compiler should enforce immutable variables.

maybe the order of inputs for cons should switch, since we always seem to be calling "swap cons".

There are lots more opcodes that need to be enabled for lisp.


Instead of defining so many things for the erlang compiler, we should get the macro system to work correctly.
Then we should use macros to define everything else, as much as possible.