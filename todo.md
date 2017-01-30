

compile from a high level language, and give useful error messages.

it would be nice if the compiler did static type analysis on the function inputs, and if we could define new types.

We should write macros for signed integer.

We should write macros for decimal numbers.

The functions are too expensive right now. They do two different tasks, and we should really have different flavors of functions for each task.
1) they merkelize the code, so you only publish on-chain the parts of the code that actually get executed.
2) it allows for looping to help do computation.