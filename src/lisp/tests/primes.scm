;This calculates the biggest prime below the input.
;This calculation happens completely at compile-time.

(import (basics.scm))

(macro prime_p (N L)
       (cond (((= () L) true)
	      ((= 0 (rem N (car L))) false)
	      (true (prime_p N (cdr L))))))
(macro square (x) (* x x))       
(macro prime2 (Limit N L B)
       (cond (((> N (- (square Limit) 2)) B)
	      ((and (< N Limit)
		    (prime_p N L))
	       (prime2 Limit
		       (+ N 1)
		       (reverse (cons N (reverse L)))
		        N))
	      ((prime_p N L)
	       (prime2 Limit
		       (+ N 1)
		       L
		       N))
	      (true (prime2 Limit (+ N 1) L B)))))

(macro prime (N)
       (prime2 N 3 (2) 0))

(= (prime 10) 97)
