(import (basics.scm))

(macro oracle_result (Proof)
  '(() 32 split drop 1 split swap drop --AAAA swap ++ )
(macro oracle_result (ProofStructure); returns integer result of oracle.
       '(oracle_result (cdr (car (car (cdr ProofStructure))))))
(macro bet2 (R)
       '(cond (((= R 1);oracle returns True
	       ,(tree (0 3 (@ bet_amount ))))
	      ((= R 2);oracle returns False
	       ,(tree (0 3 (- 10000 (@ bet_amount)))))
	      ((= R 3);oracle returns Bad Question
	       ,(tree (0 3 (- 10000 (@ MaxPrice)))))
	      ((= R 0);oracle is not yet closed
	       ,(tree (1 1 (- 10000 (@ MaxPrice))))))))
(macro bet (ProofStructure); returns delay, nonce, amount
       (bet2 (oracle_result ProofStructure)))
