(macro = (A B)
       (quote nop A B === swap drop swap drop))
(macro twos (X)
       (cond (((= X 0) '(nil))
       	      (true '(cons 2 (twos (- X 1)))))))
(macro things (X Y)
       (cond (((= X 0) '(nil))
       	      (true '(cons Y (things (- X 1) Y))))))


(= (things 3 5) (cons 5 (cons 5 (cons 5 nil))))
