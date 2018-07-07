(import (flatten.scm))

(macro test ()
  (=
   (flatten (() ((2) 1)))
   (2 1)))

(test)


