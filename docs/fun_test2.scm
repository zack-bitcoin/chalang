(import (eqs_lib.scm let_lib.scm function_lib2.scm tree_lib.scm))


% This is how you write the (32-byte binary pointer of the function definition) every time you want to call the function.
(macro square () (lambda (x) (* x x)))
(execute (square) (3))
(execute (square) (4))
(execute (square) (5))
(execute (square) (6))

% This is how you store the 32-byte binary pointer into a variable, that way you only need 5 bytes every time you want to reference the function
(define square2 (x) (* x x))
(execute (@ square2) (3))
(execute (@ square2) (4))
(execute (@ square2) (5))
(execute (@ square2) (6))
(execute (@ square2) (7))
