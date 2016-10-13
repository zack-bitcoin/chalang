
macro test
int 12 X !
int 11 Y !
X @ X @
int 10 X !
X @ Y @
int 11 == swap
int 10 == and swap
int 12 == and swap
int 12 == and %should return 1
;