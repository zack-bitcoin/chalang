% This is map at compile-time. We are using higher-order macros. 

(macro map (f l)
       (cond (((= () l) ())
	      (true
	       (cons (execute f (car l)) (map f (cdr l)))))))
(macro fun (x) (* 2 x) )
(macro test ()
       (map '(fun) (cons (cons 3 ())
			 (cons (cons 4 ())
			       (cons (cons 5 ()) ())))))
(macro test3 ()
       (=
	(cons 6 (cons 8 (cons 10 ())))
	(test)))
(test3)


%(macro test_once ()
%       (execute '(fun) (cons 5 ())))
% (test_once)
