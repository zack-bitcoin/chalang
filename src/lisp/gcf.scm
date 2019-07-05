(import (eqs_lib.scm function_lib3.scm cond_lib.scm let_lib.scm))
; gcf is the greatest common factg

; computing gcf at run-time
;(let ((gcf (lambda (a b)
;	     (cond (((= 0 b) a)
;		    (true (recurse b (rem a b))))))))
;  (= 12 (execute gcf '(24 36))))
(define gcf (a b)
  (cond (((= 0 b) a)
         (true (recurse b (rem a b))))))

;(= 12 (execute2 (gcf 24 36)))
;(= 12 (gcf 24 36))
;(gcf 24 36)
                                        ;0
(= 12 (gcf 24 36))


; computing gcf at compile-time
(macro ctgcf (a b)
       (cond (((= b 0) a)
	      (true (ctgcf b (rem a b))))))

(macro test ()
   (= 12 (ctgcf 24 36))
   )
(test)

and
