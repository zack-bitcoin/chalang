%Both participants make and reveal secrets, the winner is selected randomly by XORing the secrets.
%if either user refuses to reveal, then they lose.

macro Amount int 1000 ;

macro Draw int 1 int 0 int 0 crash ;

: or_die not if Draw else then ;

macro reveal ( Reveal Commit -- bool )
  swap dup tuck hash == or_die call drop drop ;
% If a secret is improperly revealed, the contract defaults to case 0. a draw.
  

macro Secret1 int 1 hash ;
macro Secret2 int 2 hash ;

macro Win1 int 0 Amount ; 
macro Win2 int 1 Amount ; 

macro player1revealed Secret1 reveal drop int 2 Win1 ;
macro player2revealed Secret2 reveal drop int 2 Win2 ;
macro bothRevealed Secret2 reveal swap
          Secret1 reveal bxor int 2 rem
	  int 3 swap
	  if Win1 else Win2 then ;

%syntax for case statements.
macro -> == if drop drop ;
macro -- crash else then drop ;

macro main
  int 1 -> player1revealed -- 
  int 2 -> player2revealed --
  int 3 -> bothRevealed --
  drop Draw ;

macro test1
     int 0 main ;
     (choose path 0, so neither player revealed. It is a tie. The nonce is 1.)

macro test2
     int 1 int 1 main ;
     (choose path 1, meaning only player 1 revealed their secret. So player 1 wins. The secret happens to be 1. The nonce is 2.)

macro test3
     int 2 int 2 main ;
     (choose path 2, meaning only player 1 revealed their secret. So player 2 wins. The secret happens to be 2. The nonce is 2)

macro test4
     int 1 int 2 int 3 main;
     (choose path 3, so both revealed. the secrets are 1 and 2. The winner will be selected by XORing the secrets. The nonce is 3.)