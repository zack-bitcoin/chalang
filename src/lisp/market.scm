(import (basics.scm oracle.scm))
(macro mil () 1000000)

;<<height:32, price:16, portionMatched:16, market_id:256, signature/binary>>
(macro unpack (N B)
       ;'(nop B N split nil cons cons)
       '(cons (cons (split B N) nil)))
(macro extract (X)
       (split X 40))
(macro extract_old (X)
 ;( signed_price_declaration -- height price portion_matched )
       '(40 split dup tuck Pubkey @ verify_sig or_die
	     4 split 
	     swap  
	     2 split --AAA= swap ++ swap 
	     2 split --AAA= swap ++ swap
             MarketID @ == or_die drop drop 
             dup Height @ < not or_die 
	     ))

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
       
