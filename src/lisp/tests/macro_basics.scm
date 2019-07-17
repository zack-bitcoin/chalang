(macro first (a y) a)
(macro second (a y) y)
(macro pass_var (x) (first x x))

(macro test (X)
       (= 'z (pass_var X)))
(test 'z)

;(macro maker_test ()
;       (macro inner (x) (+ x x)))
;(maker_test)
;(inner 2)

