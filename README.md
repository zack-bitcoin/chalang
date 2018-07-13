It is built for blockchain smart contracts.

This is a language make for state channels.

It is deterministic, so that every node of the blockchain gets the same result. the variable types of chalang are: integers, binary, lists. Uses functions instead of gotos. Functions are tail call optimized.

merkelized - functions are called by the hash of the contents of the function. Unused functions don't have to be included, which makes the transaction shorter.

Each operation of the virtual machine consumes a finite resource called gas. If the gas runs out, then the money in the bet is deleted. Has 2 types of gas, one for space, and one for time.

[You can read the documentation for the VM's opcodes here.](/docs/opcodes.md)


[You can see forth-like example code here](/src/forth), hashlock is especially well documented.

[You can see lisp-like example code here](/src/lisp)


to install:

sh install.sh


to start a node with these libraries loaded:

sh start.sh



to run tests on a node:

1> test_chalang:test().




