(import (tree_lib.scm))

(macro test ()
       (= (++ (1 2 3) (4))
	  (1 2 3 4)))
(test)

%(macro test2 ()
%       (is_number 'five))
%       (is_list 1))
%       (is_atom 'true))
%(test2)



