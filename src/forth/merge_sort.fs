( mergesort )

( helper macros for making lists. )
macro [ nil ;
macro , swap cons ;
macro ] , reverse ;


% higher order function "map". applies a function to every element of a list. [A, B, B] -> [f(A), f(B), f(C)] 
: map2 ( OldList NewList -- List2 )
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


( merge two sorted lists into one sorted list. )
: merge2 ( L1 L2 Accumulator -- L3 )
  >r
  nil == if ( if L1 is [] )
    drop drop reverse r> ++ reverse
  else
    drop swap nil ==
    if ( if L2 is [] )
      drop drop reverse r> ++ reverse
    else
      ( add bigger element to list in r stack )
      drop
      car swap rot car swap rot 2dup
      < if
        swap r> cons >r rot cons r> recurse call
      else
        r> cons >r swap cons r> recurse call
      then
    then
  then
;
macro merge ( L1 L2 -- L3 )
  nil merge2 call
;


( example: [A, B, C] -> [[A], [B], [C]]. )
: merge_setup2 ( X -- [X] )
  nil cons ;
macro merge_setup ( List -- ListOfLengthOneLists )
  merge_setup2 map
;


( sort a list )
: sort2 ( ListOfSortedLists -- SortedList )
  car nil == ( if there is only 1 sorted list left, return it. )
  if
    drop cons
  else
    ( sort the first 2 lists, and append the result to the listofsortedlists. )
    drop car tuck merge nil cons ++ recurse call
  then
;
macro sort ( UnsortedList -- SortedList )
  merge_setup
  sort2 call
  car drop
;

macro test
  % [int 4, int 13] [int 2, int 5, int 10] merge 
   [ int 10, int 2, int 13, int 4, int 5 ] sort
  [ int 2, int 4, int 5, int 10, int 13 ]
  == tuck drop drop
  %int 0
;