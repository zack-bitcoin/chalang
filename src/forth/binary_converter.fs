% For converting a list of bits into an integer.


% Some macros to make lists easier.
macro [ nil ;
macro , swap cons ;
macro ] swap cons reverse ;


% Binary conversion function
: bc2 (Accumulator BinList -- Int)
  >r
  nil == if drop drop r>
  else drop
    car swap r> int 2 * + recurse call
  then
;
macro binary_convert (BinList -- Int)
  int 0 bc2 call
;


% the test. returns [true] if it succeeds.
% Binary 1100 is decimal 12
macro test
[int 1, int 1, int 0, int 0]
binary_convert
int 12 == swap drop swap drop
;