
macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;

: divisible ( x y -- x y b )
  remainder not
;

: divisible_in_list ( x l -- b )
  nil == if
    drop drop drop int 0
  else
    drop
    car >r swap dup tuck swap rem not 
    if
      r> drop drop int 1
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

: get_primes ( list start end -- list2 )
  == if
    drop drop
  else
    >r dup >r swap append_if_not_divisible call
    r> int 1 + r> recurse call
  then
;

( int 4 [ int 2 , int 3 ] divisible_in_list call )
( int 4 [ int 3 , int 2 ]
 append_if_not_divisible call
 int 5 swap
 append_if_not_divisible call
 int 6 swap
 append_if_not_divisible call
 int 7 swap
 append_if_not_divisible call )

 [ int 2 ]
 
 int 3 int 5000 get_primes call 

 print
( int 5 swap append_if_not_divisible call )
