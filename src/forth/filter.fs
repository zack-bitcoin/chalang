
macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;

: check ( Int -- Bool )
  int 27 >
;

: filter2 ( NewList OldList -- List2 )
  nil ==
  if
    drop drop reverse
  else
    drop car swap dup r@ call
    if
      rot cons swap
    else
      drop
    then
    recurse call
  then
;
macro filter ( List Fun -- NewList )
  >r nil swap filter2 call r> drop
;

macro test
  [int 20, int 30, int 40, int 10] check filter
  [int 30, int 40]
  == tuck drop drop
  %  int 0
;