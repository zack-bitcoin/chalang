%if either user refuses to reveal, then they lose.

% SS1 [0]
%-both players refuse to reveal.
%-the money is returned to the original owners. nonce=1.

% SS2 [evidence, 1]
%-only player 1 revealed. so player 2 loses. nonce=2

% SS3 [evidence, 2]
%-only player 2 revealed, so player 1 loses. nonce=2

% SS4 [evidence, evidence2, 3]
%-both players revealed, we calculate the winner by xoring the data they revealed. nonce=3

macro Draw int 1 int 0 crash ;

: or_die not if Draw else then ;

macro reveal ( Reveal Commit -- bool )
  swap dup tuck hash = or_die call drop drop ;
  
%syntax for case statements.
macro -> == if drop drop ;
macro -- crash else then drop ;

macro Amount int 1000 ;
macro Secret1 int 1 hash ;
macro Secret2 int 2 hash ;

macro Win1 int 0 Amount ;
macro Win2 int 1 Amount ;

macro SS1 Secret1 reveal drop int 2 Win1 ;
macro SS2 Secret2 reveal drop int 2 Win2 ;
: SS3 Secret2 reveal swap
          Secret1 reveal bxor int 2 rem
	  int 3 swap
	  if Win1 else Win2 then ;

macro main
  int 1 -> SS1 -- 
  int 2 -> SS2 --
  int 3 -> print SS3 print call print --
  
  drop Draw ;


macro test1
     int 0 main ;

macro test2
     int 1 int 1 main ;

macro test3
     int 2 int 2 main ;

macro test4
     int 1 int 2 int 3 main; 