;(import (eqs_lib.scm function_lib.scm cond_lib.scm
(import (map.scm basics.scm))

;[int ID, int Key, binary Size serialize(Oracle)]
;<<id:256, result:8, ...>

(define oracle_result (Proof)
  '(() 32 split drop 1 split swap drop --AAAA swap ++ ))
;true: 1, false: 2, bad_question: 3, unclosed: 0
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
(macro num_to_price (B)
       '(/ (* 10000 B) 256))

;(/ (* 10000 (binary_converter (tree (0 0 0 0 0 0 0 1))))   256)
(num_to_price (binary_converter (tree (0 0 0 0 0 0 0 1))))

(define oracle_results (X)
  (execute (@ map) ((@ oracle_result) X)))

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


