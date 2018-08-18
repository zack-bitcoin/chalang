(import (tree_lib.scm cond_lib.scm oracle.scm))
(macro mil () 1000000)

;<<height:32, price:16, portionMatched:16, market_id:256, signature/binary>>
(macro extract (X)
;verify the signature.
;check that the price declaration was made after the bet, or at the same height.       
;return declaration_height, price and portion_matched
       0)

(macro contradictory_prices (SPD1 SPD2) ;return delay, nonce, amount
	;extract both
	;confirm that heights are within half a period of each other
	;confirm that prices are unequal, or that the portion matched is unequal.
	;(tree (0 (* 2 (mil)) 0))
       0
       )
(macro no_publish ()
       (tree ((@ Period)
	      (/ height (* 2 (@ Period)))
	      0)))
(macro evidence (SPD) ;return delay, nonce, amount
       ;extract it
      ;require that SPD was made in the most recent period 
       (tree ((- (@ Expires) height)
	      (+ 1 (/ declaration_height (@ Period)))
	      (- 10000 (@ MaxPrice)))))

(macro match_order (SPD);return delay, nonce, amount
;extract it
       ;make sure it is better or equal to the agreed upon price.
       ;run the oracle program.
       ;if your bet was partly matched, then that needs to be handled differently.
)
(macro unmatched (OracleProof);return delay nonce amount
       ;extract it
       ;if the oracle is unresolved
       (tree ((+ 2000 (+ (@ Expires) (@ Period)))
	      0
	      (- 10000 (@ MaxPrice))))
;if the oracle is resolved
       (tree ((@ Period)
	      1
	      (- 10000 MaxPrice))))

(macro main (Type I1 I2)
       '(cond (((= Type 0) (no_publish))
	       ((= Type 1) (match_order I1))
	       ((= Type 2) (contradictory_prices I1 I2))
	       ((= Type 3) (evidence I1))
	       ((= Type 4) (unmatched I1)))))
       
