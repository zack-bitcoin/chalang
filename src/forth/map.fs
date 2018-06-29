

macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;

%Lists are easy with these 3 words: "[", "," and, "]". You don't need spaces between them either. example: "[1,2,3,4]" 

: square dup * ;

: map2 ( NewList OldList -- List2 )
  car swap r@ call rot cons swap
  nil ==
  if
    drop drop reverse
  else
    drop recurse call
  then ;
macro map ( List Fun -- NewList )
  >r nil swap map2 call r> drop
;

macro test
[int 5,int 6,int 7]
square map
[int 25, int 36, int 49]
== >r drop drop r>
;