;(import (eqs_lib.scm function_lib.scm cond_lib.scm
(import (map.scm tree_lib.scm))

(define oracle_result (Proof)
       '(() 32 split drop 1 split swap drop --AAAA swap ++ ))
(define binary_converter2 (L N)
  (cond (((= nil L) N)
	 (true (recurse
		(cdr L)
		(+ (car L)(* 2 N)))))))
;(execute (@ binary_converter2) ((tree (1 0 1 1)) 0))
(macro binary_converter (L)
       '(execute (@ binary_converter2) (L 0)))

(macro doit (L)
       '(binary_convert (execute (@ map) ((@ oracle_result) L))))
 

(/ (* 10000 (binary_converter (tree (0 0 0 0 0 0 0 1))))
   256)
   

;(macro bet2 (R)
;       '(cond (((= R 1);oracle returns True
;	       ,(tree (0 3 (@ bet_amount ))))
;	      ((= R 2);oracle returns False
;	       ,(tree (0 3 (- 10000 (@ bet_amount)))))
;	      ((= R 3);oracle returns Bad Question
;	       ,(tree (0 3 (- 10000 (@ MaxPrice)))))
;	      ((= R 0);oracle is not yet closed
;	       ,(tree (1 1 (- 10000 (@ MaxPrice))))))))
;(macro bet (ProofStructure); returns delay, nonce, amount
;      ((oracle_result ProofStructure))


