(import (eqs_lib.scm))

% compile time
(macro A () (= 5 5))
(A)


% run time
(= 6 6)

 and
%0
