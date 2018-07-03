% This is map at compile-time. We are using higher-order macros. 

(macro map (f l)
       (cond (((= () l) ())
	      (true
	       (cons (execute f (cons (car l) ()))
		     (map f (cdr l)))))))
(macro fun (x) (* 2 x) )


(macro test ()
       (map 'fun (cons 3 (cons 4 (cons 5 ())))))
(macro test3 ()
       (=
	(test)
	(cons 6 (cons 8 (cons 10 ())))))
(test3)

(macro test5 (f)
       (map f (cons 3 (cons 4 (cons 5 ())))))
%(test5 'fun)

