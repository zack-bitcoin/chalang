
macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;


: bc2 % (Accumulator BinList -- Int)
  >r print
  nil == if drop drop r>
  else drop
    car swap r> int 2 print * + recurse call
  then
;

: binary_convert % (BinList -- Int)
  int 0 bc2 call
;


( Binary 1010 is decimal 8 )

macro test
[int 1, int 0, int 1, int 0]
binary_convert call print
int 10 == swap drop swap drop
;