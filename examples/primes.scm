%This calculates the biggest prime below the input.
%This calculation happens completely at compile-time.

(import (eqs_lib.scm))

(macro prime_p (N L)
       (cond (((= () L) true)
	      ((= 0 (rem N (car L))) false)
	      (true (prime_p N (cdr L))))))
       
(macro prime2 (Limit N L)
       (cond (((> N Limit) (car (reverse L)))
	      ((prime_p N L)
	       (prime2 Limit
		       (+ N 1)
		       (reverse (cons N (reverse L)))))
	      (true (prime2 Limit (+ N 1) L)))))

(macro prime (N)
       (prime2 N 3 (2)))

(eqs 97 (prime 100))
