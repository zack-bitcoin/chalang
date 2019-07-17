(import (basics.scm))
(export global)

; the map is happening completely at run-time

(define map (F X)
  (cond (((= nil X) nil)
	 (true (cons
		(execute F ((car X)))
		;,(F '(car X))
		(recurse F ((cdr X))))))))

; this map is happening completely at compile-time
(macro map_ct (f l)
;       (write f))
;(macro next ()
       (cond (((= () l) ())
	      (true
               (cons (f (car l))
                      (map_ct f (cdr l)))))))

                                        ;(map_ct (lambda (x) (+ 0 x)) (9))
(macro map_test_0 ()
       (map_ct '(lambda (x) (+ x 3))
               (1 2 3)))

;       ((lambda (x) (+ 5 x)) 4))
;(map_test_0)
;0
