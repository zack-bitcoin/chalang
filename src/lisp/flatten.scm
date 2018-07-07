;macro to flatten recursive lists into one long list.
; (x (y ((z) a)) b c) -> (x y z a b c)

(macro flatten (L)
       (cond (((= L ()) ())
	      ((is_list (car L))
	       (++ (flatten (car L))
		   (flatten (cdr L))))
	      (true (cons (car L)
			  (flatten (cdr L)))))))

