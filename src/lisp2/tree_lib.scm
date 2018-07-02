%T which was computed at compile time gets written directly into the byte-code which will be read at run-time.

(macro tree (T)
       (cond (((= T ()) '(nil))
	      ((is_list (car T))
	       '(cons `(tree (car T))
		      `(tree (cdr T))))
	      (true '(cons `(car T)
			   `(tree (cdr T)))))))
