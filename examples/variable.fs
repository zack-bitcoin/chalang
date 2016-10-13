
macro test
int 12 x !
int 11 y !
x @ x @
int 10 x !
x @ y @
int 11 == swap
int 10 == and swap
int 12 == and swap
int 12 == and %should return 1
;