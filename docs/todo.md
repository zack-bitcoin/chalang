compile-time and run-time syntax inconsistencies:
nil ()

there are problems with let_lib. we need to make it easy to control which parts happen at compile time.

We now have 2 ways of making functions, one is faster, and the other supports cond.
We should make a master macro that checks whether a function will need cond, and decides which type of function to make.

* better syntax for global variables. allocate memory locations in a sensible way.


If we give the wrong number of inputs to a function, the compiler should tell us.

