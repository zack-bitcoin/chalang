( mergesort )

( helper macros for making lists. )
macro [ nil ;
macro , swap cons ;
macro ] , reverse ;


% higher order function "map". applies a function to every element of a list. [A, B, B] -> [f(A), f(B), f(C)] 
def ( NewList OldList -- List2 )
  car swap r@ call rot cons swap
  nil ==
  if
    drop drop reverse
  else
    drop recurse call
  then ;
map2 !
macro map ( List Fun -- NewList )
  >r nil swap map2 @ call r> drop
;


( merge two sorted lists into one sorted list. )
def ( L1 L2 Accumulator -- L3 )
  >r
  nil == if ( if L1 is [] )
    drop drop r> reverse swap ++
  else
    drop swap nil ==
    if ( if L2 is [] )
      drop drop r> reverse swap ++
    else ( jumping from this else to wrong then )
      ( add bigger element to list in r stack )
      drop
      car swap rot car swap rot 2dup
      < if
        swap r> cons >r rot
      else
        r> cons >r swap
      then
      cons r> recurse call
    then
  then
;
merge2 !
macro merge ( L1 L2 -- L3 )
  nil merge2 @ call
;


( example: [A, B, C] -> [[A], [B], [C]]. )
def ( X -- [X] )
  nil cons ;
merge_setup2 !
macro merge_setup ( List -- ListOfLengthOneLists )
  merge_setup2 @ map
;


( sort a list )
def ( ListOfSortedLists -- SortedList )
  car nil == ( if there is only 1 sorted list left, return it. )
  if
    drop drop
  else
    ( sort the first 2 lists, and append the result to the listofsortedlists. )
    ( crashes in first merge )
    drop car tuck merge nil cons ++ recurse call
  then
;
sort2 !
macro sort ( UnsortedList -- SortedList )
  merge_setup sort2 @ call
;

macro test
  [ int 10, int 2, int 13, int 4, int 5 ] sort
  [ int 2, int 4, int 5, int 10, int 13 ]
  == tuck drop drop
  %int 0
;
