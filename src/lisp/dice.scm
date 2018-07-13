(import (cond_lib.scm eqs_lib.scm))


; here we store the evidence into variables.
(macro close_type () 678);global variable

2 (close_type) !
2 (! reveal1)
3 (! reveal2)
;(@ reveal2)

;these details are customized with every contract.
(macro commit1 () (hash 2))
(macro commit2 () (hash 3))
(macro time_limit () 5)


; everything below this line always stay the same

;given the 2 reveals, who won?
(macro outcome (rev1 rev2) ;either returns a 1 or 0.
       '(rem (bxor rev1
		   rev2)
	     2))
;(outcome 4 6)

;check if this reveal is valid for what was committed to.
(macro check (commit rev) ;either returns 1 or 0.
       '(= (hash rev) commit))
;(check (commit1) 2)
;(check (commit2) 3)

(macro main () ;delay nonce amount
       '(cond (((and (check (commit1) (@ reveal1))
		     (check (commit2) (@ reveal2)))
		(() 0 2 (* 10000 (outcome (@ reveal1)
					  (@ reveal2)))));nonce should be high, time limit should be 0. the money is determined by outcome/2
	       ((check (commit1) (@ reveal1))
		(() ,(time_limit) 1 0));money goes to account 1, nonce is low, time_limit is (time_limit)
	       ((check (commit2) (@ reveal2))
		(() ,(time_limit)  1 10000)))));money goes to account 2, nonce is low, time limit is (time_limit)
;(main)
;possible states.
; only 1 party reveals.
; both parties reveal

; our goal is that the nonce should be higher if both reveal.

1



