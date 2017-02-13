I will show an example. I will show Satoshi Dice written in 3 different styles. The first is a forth compiler. It is very close to the VM. It is the most efficient of the 3, but hardest to read and write.

```
macro Amount int 1000 ;
macro Draw int 1 int 0 int 0 crash ;
: or_die not if Draw else then ;
macro reveal ( Reveal Commit -- bool )
  swap dup tuck hash == or_die call drop drop ;
macro Win1 int 0 Amount ; 
macro Win2 int 1 Amount ; 
macro player1revealed Commit1 reveal drop int 2 Win1 ;
macro player2revealed Commit2 reveal drop int 2 Win2 ;
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
```
Here are the 4 ways this program can be run:
```
     int 0 main ;
     (choose path 0, so neither player revealed. It is a tie. The nonce is 1.)

     int 1 int 1 main ;
     (choose path 1, meaning only player 1 revealed their secret. So player 1 wins. The secret happens to be 1. The nonce is 2.)

     int 2 int 2 main ;
     (choose path 2, meaning only player 1 revealed their secret. So player 2 wins. The secret happens to be 2. The nonce is 2)

     int 1 int 2 int 3 main;
     (choose path 3, so both revealed. the secrets are 1 and 2. The winner will be selected by XORing the secrets. The nonce is 3.)
```

Next I will show what this program looks like written in lisp. The lisp compiler is mostly functioning now.

```
(set amount 1000)
(macro Draw () (end 1 0 0))
(define or_die (B)
	(cond ((B ())
	       (true (Draw)))))
(macro reveal (Secret Commit)
	(or_die (= Commit (hash Secret))))
(macro (win Player Nonce) (end Nonce Player amount))
(macro (playerRevealed Player Secret)
       (do (reveal Secret (commit player))
           (win Player 2)))
(macro (bothRevealed Secret1 Secret2)
       (do (reveal Secret1 (commit 0))
       	   (reveal Secret2 (commit 1))
	   (win (rem (bxor Secret1 Secret2)
	   	     2)
		3)))
(define main (Secret1 Secret2 mode)
	(cond
		(((== mode 1) (playerRevealed 0 Secret1))
		 ((== mode 2) (playerRevealed 1 Secret2))
		 ((== mode 3) (bothRevealed Secret1 Secret2))
		 (true (Draw)))))
		 
```

Finally, I will show how this program will look in the final language I am aiming to create.

```
-define(amount, 1000).
one_reveal(Secret) ->
     N = or(0, 1),
     Commit(N) = hash(Secret),
     end(2, N, ?amount).
both_reveal(Secret1, Secret2) ->
     Commit(0) = hash(Secret1),
     Commit(1) = hash(Secret2),
     C = rem(bxor(Secret1, Secret2) 2),
     end(3, C, ?amount).
doit() ->
     or(both_reveal(),
        one_reveal(),
        end(1, 0, 0)).
```

This final one is a prolog-like language with backtracking.
the "or" function does the backtracking. If an "=" sign doesn't match equality, then it triggers a backtracking event.
This version will be about 3-5 times more expensive than the original.

Although it is more expensive, I feel like we should support this third version primarily.
It is much easier to tell what it does from looking at it in comparison to the other two.
Making the code easy to read is our main goal.

Eventually we should also make custom types, and add static type checking to all the functions. This would give us lots of nice error messages to make programming easier.