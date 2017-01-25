%When I run tests, in test_chalang.erl, string "test" appended to the code. That way the test macro gets run.
%I don't want the test macro to run every time I load this library.
%"binary" is the command to load a binary onto the stack.
%The next number 32, tells binary how big the binary will be. Next is a base64 encoded binary.
%"hash" replaces the the binary on the top of the stack with the hash of that binary.
%Then we load a 12 byte binary.
%Then we check if they are equal with the "==" operation.
%Equals doesn't drop the 2 things it compares off the stack.
%Here is how forth operations are documented:
( A B -- A B C )
% This starts with 2 things on the stack, and adds a third on top.
%Next we do a swap, which trades the top 2 elements
( A B C -- A C B )
%Then we drop the top element
( A C B -- A C )
%Then we swap
( A C -- C A )
%Then we drop again
( C A -- C )
%And the only thing left on the stack is the result of the comparison. So if the hash of the 32 byte binary is equal to the 12 byte binary, then it returns [<<1:32>>], otherwise it returns [<<0:32>>]


macro test
binary 32 qfPbi+pbLu+SN+VICd2kPwwhj4DQ0yijP1tM//8zSOY= hash
binary 12 2J54tzk6WXTncb03 == swap drop swap drop
;

