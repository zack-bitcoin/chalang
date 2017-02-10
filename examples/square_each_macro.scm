(macro square (X) (* X X))
(macro = (A B)
       '(nop A B === swap drop swap drop))


(macro sqr (X)
       (cond (((= X ()) '(nil))
	      ((is_list X) '(cons (square `(car X))
				  (sqr `(cdr X))))
	      (true X))))
(macro tree (X)
       (cond (((= X ()) '(nil))
	      ((not (is_list X)) X)
	      ((is_list (car X)) '(cons `(tree (car X))
					`(tree (cdr X))))
	     (true '(cons `(car X)
			  `(tree (cdr X)))))))

(and
 (= (sqr (2 3))
    (cons 4 (cons 9 nil)))
 (= (tree (4 9))
    (cons 4 (cons 9 nil))))
