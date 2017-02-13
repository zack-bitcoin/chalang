(macro test1 (x y)
       (test2 (+ x x) y))
(macro test2 (a b)
       (+ b a))

%(= 7 (test1 2 3))


(macro test3 (X)
       (cond (((= X ()) ())
	      (true (cons (car X)
			  (test3 (cdr X)))))))
(test3 (test3 (1 2 3)))
