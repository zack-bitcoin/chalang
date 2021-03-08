
macro test
int 12 X !
int 11 Y !
X @ X @
int 10 X !
X @ Y @
int 11 == >r drop drop
int 10 == >r drop drop
int 12 == >r drop drop
int 12 == >r drop drop
r> r> r> r> and and and
%should return 1
;
