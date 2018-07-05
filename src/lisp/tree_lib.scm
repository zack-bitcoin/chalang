; T is a list computed at compile-time.
; T possibly contains other lists.
; tree converts T into a list available at run-time.

(macro tree (T)
       (cond (((= T ()) '(nil))
	      ((is_list (car T))
	       '(cons ,(tree (car T))
		      ,(tree (cdr T))))
	      (true '(cons ,(car T)
			   ,(tree (cdr T)))))))
