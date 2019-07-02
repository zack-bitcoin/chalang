(import (cond_lib.scm eqs_lib.scm function_lib3.scm))

;classic game of rock paper scissors.
;if there is a draw, then it starts a new round recursively, until someone wins.

;each commit needs to be signed, and reference the game id, and round number.


(macro check (commit rev) ;either returns 1 or 0.
       '(= (hash rev) commit))
(macro round1 (R time_limit Callback Nonce)
       (round3 (car R) (cdr R) time_limit Callback Nonce))
(macro round3 (H R time_limit Callback Nonce)
       (round4 (car H)
	       (car (cdr H))
	       (car (cdr (cdr H)))
	       (car (cdr (cdr (cdr H))))
	       R time_limit Callback Nonce))
(macro round4 (commit1 reveal1 commit2 reveal2 R time_limit Callback Nonce)
;       commit1)
       (check commit1 reveal1))
      ; 87)
(macro round5 (commit1 reveal1 commit2 reveal2 R time_limit Callback Nonce)
       '(cond (((and (check commit1 reveal1)
		     (check commit2 reveal2))
		(execute Callback ((rem (rem reveal1 4) 3)
				 (rem (rem reveal2 4) 3)
				 time_limit R Nonce)))
	       ((check commit1 reveal1)
		(() time_limit Nonce 0));money goes to account 1, nonce is low, time_limit is (time_limit)
	       ((check commit2 reveal2)
		(() time_limit  Nonce 10000))
	       (true 87))));money goes to account 2, nonce is low, time limit is (time_limit)

(define round2 (r1 r2 time_limit T Nonce)
  (cond
   (((= r1 r2)
     (round1 T time_limit recurse (+ Nonce 1)))
    ; {0:rock, 1:paper, 2:scissors, 3:rock}
    ((= (rem (+ 1 r1) 3) r2)
     (() 0 100000 10000);2 wins. time limit, nonce, amount
    ((= (rem (+ 2 r1) 3) r2)
     (() 0 100000 0));1 wins
    ))))


(macro main (R)
       (round1 R time_limit '(round2) 1))
;(main ((commit1 reveal1 commit2 reveal2)))
;(check (hash 1) 1)
;(main (((hash 1) 1 (hash 2) 2)))
					;(hash 1)
(macro drop_test (a b c d e) b)
(drop_test 3 4 5 6 7)
					; our goal is that the nonce should be higher if both reveal, and the nonce should be higher if they reveal more rounds.


1
		
