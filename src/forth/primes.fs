
macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;

: divisible ( x y -- x y b )
  rem not
;

: divisible_in_list ( x l -- b )
  nil == if
    drop drop drop int 0
  else
    drop
    car >r swap dup tuck divisible call print
    if
      r> drop swap drop drop int 1
    else
      r> recurse call
    then
  then
;

: append_if_not_divisible ( x l -- b )
  2dup divisible_in_list call
  if
    swap drop
  else
    cons
  then
;

( int 5 [ int 2 , int 3 ] divisible_in_list call )
 int 4 [ int 3 , int 2 ]
 append_if_not_divisible call 
( int 5 swap append_if_not_divisible call )
