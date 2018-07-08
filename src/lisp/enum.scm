; creates a list from integer A to integer B at compile-time
(macro enum (A B)
       (cond (((> A B) ())
	      (true
	       (cons A (enum (+ A 1) B))))))

