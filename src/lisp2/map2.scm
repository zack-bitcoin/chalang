% This is map at compile-time. We are using higher-order macros. 
%(macro quote_test ()
%       '(+ `(- 2 1) 3))
%(quote_test)
(macro map (f l)
       (cond (((= () l) ())
	      (true
	       (cons (execute f (cons (car l) ()))
		     (map f (cdr l)))))))
(macro fun (x) (* 2 x) )


(macro test3 ()
       (=
	(map 'fun (cons 3 (cons 4 (cons 5 ()))))
	(cons 6 (cons 8 (cons 10 ())))))
(test3)


