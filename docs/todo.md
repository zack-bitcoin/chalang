We should have 2 types of functions.
One for fast recursion, and the other for merkelizing the code.

right now we allow for re-assignment of variables. So assignment has 2 inputs.
Instead, we should have immutable variables. Assignment should have 1 input and 1 output.
This will be useful for functions that call themselves recursively, and read their variables after the recursion.