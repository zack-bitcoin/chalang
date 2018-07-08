compile-time and run-time syntax inconsistencies:
nil ()

We now have 2 ways of making functions, one is faster, and the other supports cond.
We should make a master macro that checks whether a function will need cond, and decides which type of function to make.


convert map.scm and sort.scm to use the new functions.
find out how define has changed that is making it non-compatible.

maybe we should teach the lisp compiler to do some just in time optimizations of the bytecode.

If we give the wrong number of inputs to a function, the compiler should tell us.
