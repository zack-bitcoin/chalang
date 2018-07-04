
(import (map.scm tree_lib.scm))

% the first map is happening completely at run-time
(macro double () (lambda (x) (+ x x)))
(=
  (execute (map) ((double) (tree (2 3 4 5))))
  (tree (4 6 8 10)))

% this second map is happening completely at compile time
(macro double2 (x) (* 2 x) )
(macro test3 ()
       (=
	(map2 'double2 (2 3 4 5))
	(4 6 8 10)))
(test3)

and
