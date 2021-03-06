(export (lisp))

(macro quote_internal (q env)
       (cond (((not (is_list q)) q)
              ((= q ()) ())
              ((= unquote (car q))
               (lisp2 (cdr q) env))
              (true q))))

(macro
    lisp2 (expr env)
    (cond
     (((is_number expr)
       expr)
      ((is_atom expr)
       (env expr))
      ((null? expr) ())
      ((is_number (car expr))
       expr)
      ((null? (car expr))
       (lisp2 (cdr expr) env))
      ((= (car expr) quote)
       ;(quote (cdr expr)))
       (quote_internal (cdr expr) env))
      ((= (car expr) write)
       (write (cdr expr)));
;       (write (lisp2 (cdr expr) env)))
      ((= (car expr) if)
       (cond (((lisp2 (car (cdr expr)) env)
               (lisp2 (car (cdr (cdr expr))) env))
              (true (lisp2 (car (cdr (cdr (cdr expr)))) env)))))
      ((= (car expr) <)
       (< (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) >)
       (> (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) =)
       (= (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) and)
       (and (lisp2 (car (cdr expr)) env)
            (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) or)
       (or (lisp2 (car (cdr expr)) env)
            (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) not)
       (not (lisp2 (car (cdr expr)) env)))
      ((= (car expr) reverse)
       (reverse (lisp2 (car (cdr expr)) env)))
      ((= (car expr) ++)
       (++ (lisp2 (car (cdr expr)) env)
             (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) cons)
       (cons (lisp2 (car (cdr expr)) env)
             (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) car)
       (car (lisp2 (car (cdr expr)) env)))
      ((= (car expr) cdr)
       (cdr (lisp2 (car (cdr expr)) env)))
      ((= (car expr) /)
       (/ (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) *)
       (* (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) rem)
       (rem (lisp2 (car (cdr expr)) env)
            (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) -)
       (- (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) +)
       (+ (lisp2 (car (cdr expr)) env)
          (lisp2 (car (cdr (cdr expr))) env)))
      ((= (car expr) lambda)
       (lambda (arg)
         '(lisp2 (car (cdr (cdr expr)))
                 (lambda (y)
                   (cond (((eqs y (car (cdr expr)))
                           (car arg))
                          (true (env y))))))))
      ((is_list (car expr))
       ((lisp2 (car expr) env)
        (lisp2 (cdr expr) env)))
      (true (()
             ,(write '(undefined syntax))
             ,(write (car expr))
             )))))
(macro lisp (expr)
       (lisp2
        expr
        (lambda (error_var);(123))))
           '(()
            ,(write '(undefined value))
            ,(write error_var)
            ;,(write expr)
            ))))
(macro test ()
       '(()
         ;print statements
         ,(lisp '(write hello world))

         ;math
         ,(= 5 (lisp 5))
         ,(= 10 (lisp '(+ 4 6)))

         ;lists
         ,(= 80 (lisp '(car (80 9))))
         ,(= 9 (lisp '(car (cdr (80 9)))))
         ,(= 8 (lisp '(car (cons 8 ()))))

         ;functions
         ,(= 14 (lisp '((lambda z (+ z z)) 7)))
         ,(= 6 (lisp '((lambda Y (+ Y (* Y Y))) 2)))

         ;lexical context
         ,(= 20 (lisp '(((lambda Y (lambda Z (* Y Z))) 4) 5)))
         ;conditionals
         ,(= 2 (lisp '(if (= 3 3) 2 3)))
         ,(= 5 (lisp '(if (> 3 3) 2 5)))

         ;function with multiple inputs
         ,(= 11 (lisp '((lambda X (+ (car X)
                                     (car (cdr X))))
                        (5 6))))

        ;producing code that runs at run-time using quote
         ,(! 5 Z)
         ,(lisp '('(+ (@ Z) 4)))
         9 === tuck drop drop;we have to check if this is = to 9 at run-time.

         ;running code at compile-time inside of a quoted expression, using unquote.
         ,(lisp '('(+ (@ Z) ,(+ 2 2))))
         9 === tuck drop drop
         ;combining all the passing tests into a single true value
         and and and and and and and and and and and and
        ))
(test)

        
