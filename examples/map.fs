macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;

: square dup * ;

: map2 car swap Func @ call rot cons swap
( print ) nil == if drop drop ( print ) reverse else drop recurse call then;
: map Func ! nil swap map2 call;

macro test
[int 5,int 6,int 7]
square map call
[int 25, int 36, int 49]
= >r drop drop r>
;