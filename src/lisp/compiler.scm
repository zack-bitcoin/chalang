(import (core/immutable_variables.scm))
(export (compile))

(macro function_internal (Vars Code)
      ; define a new function
       (deflet2 Vars () (Code)))
(macro execute_internal (F V)
       '(call ,(cons nop V) F))
(macro define_internal (Name Vars Code)
      ;make a new function and give it a name.
       '(deflet Name Vars () Code))
(macro deflet (name vars pairs code)
       ;store the function pointer in a variable
       '(! ,(deflet2 vars pairs (code)) name))
(macro deflet2 (vars pairs code) ;ths is the new version of lambda.
       ;wrap the function definition in `def` and `end_fun` to mark it as a function.
       '(nop
         def
         ,(deflet3 vars pairs code )
         end_fun))
(macro let_set_internal (pairs env funs)
       (cond (((null? pairs) env)
              (true
               (
                (! (compile2 (car (cdr (car pairs))) env funs)
                   ;(car (car pairs)))
                   (compile2 (car (car pairs)) env funs))
                (let_set_internal
                 (cdr pairs)
;env
                 (lambda (arg2) ;0)
                   (cond (((= arg2 (car (car pairs)));(compile2 (car (car pairs)) env funs))
                           (@ arg2))
                          (true (env arg2)))))
                 funs))))))
(macro let_mac_internal (pairs env funs) ;env)
;(macro temp ()
       (cond (((null? pairs) env)
              (true 
               (let_mac_internal
                (cdr pairs)
                (lambda (arg)
                  (cond (((= arg (car (car pairs)))
                          (compile2 (car (cdr (car pairs))) env funs))
                         (true (env arg)))))
                funs)))))
       
(macro cond_internal (X env funs)
       (cond (((= X ()) '(()))
	      ((= (car (car X)) true)
	       (cdr (car X)))
	      (true '(nop
		      ,(compile2 (car (car X)) env funs)
		      if
		      ,(compile2 (car (cdr (car X))) env funs)
		      else
		      (cond_internal ,(cdr X) env funs)
		      then)))))
(macro =_i (A B) '(nop A B === tuck drop drop))
(macro tree_internal (T)
       (cond (((= T ()) '(nil))
	      ((is_list (car T))
	       '(cons ,(tree_internal (car T))
		      ,(tree_internal (cdr T))))
	      (true '(cons ,(car T)
			   ,(tree_internal (cdr T)))))))

(macro
    compile2 (expr env funs)
    (cond
     (((is_number expr) expr)
      ((is_atom expr) (env expr))
      ((null? expr) ())
      ((null? (car expr))
       (compile2 (cdr expr) env funs))
      ((= lambda (car expr))
       (function_internal
         (reverse (compile2 (car (cdr expr)) env funs))
         (compile2 (car (cdr (cdr expr))) env funs)))
      ((= let* (car expr)) 
       '((>r (+ @r 30))
         ,(let*2 (compile2 (car (cdr expr)) env funs)
                 (compile2 (cdr (cdr expr)) env funs)
                 0)
         (drop r>)))
      ((= let_set (car expr))
       (compile2 (car (cdr (cdr expr)))
                 (let_set_internal (car (cdr expr)) env funs)
                 funs))
      ((= (car expr) quote) (cdr expr))
      ((= let_mac (car expr))
       (compile2 (car (cdr (cdr expr)))
                 (let_mac_internal (car (cdr expr)) env funs)
                 funs))
      ((= cond (car expr))
       (cond_internal (car (cdr expr)) env funs))
      ((= = (car expr))
       (=_i (compile2 (car (cdr expr)) env funs)
            (compile2 (car (cdr (cdr expr))) env funs)))
      ((= tree (car expr))
       (tree_internal (car (cdr expr))))
      ((= execute (car expr))
       (execute_internal
        (compile2 (car (cdr expr)) env funs)
        (compile2 (cdr (cdr expr)) env funs)))
      ((funs (car expr))
       (execute_internal
        (@ (compile2 (car expr) env funs))
        (compile2 (cdr expr) env funs)))
      ((is_atom (car expr))
       (cons (env (car expr))
              (compile2 (cdr expr) env funs)))
      ((is_number (car expr))
       (cons (car expr)
             (compile2 (cdr expr) env funs)))
      ((= def (car (car expr)))
       (
         (! (function_internal
             (reverse (compile2 (car (cdr (cdr (car expr)))) env funs))
             (compile2 (car (cdr (cdr (cdr (car expr))))) env funs))
            (compile2 (car (cdr (car expr))) env funs))
         (compile2
          (cdr expr)
          ;store a pointer to the location where we store the hash of the new function
          (lambda (y) (cond (((= y (compile2 (car (cdr (car expr))) env funs))
                              (compile2 (car (cdr (car expr))) env funs))
                             (true (env y)))))
          ;update this boolean function to return 'true' if we lookup whether this variable is storing a function.
          (lambda (y) (cond (((= (compile2 y env funs)
                                 (compile2 (car (cdr (car expr))) env funs))
                              1)
                             (true (funs y))))))))
      ((is_list (car expr))
       (cons (compile2 (car expr) env funs)
             (compile2 (cdr expr) env funs)))
      (true (()
             ,(write '(undefined syntax))
             ,(write (car expr)))))))

(macro compile (expr)
       (compile2
        expr
        (lambda (x) x)
        (lambda (_) 0)))

(macro test ()
       '(()
       ,(! 5 N)
       (=_i 5 ,(compile '(@ N)))
       (=_i (cons 3 nil)
            ,(compile '(cons 3 nil)))
       (=_i 15 ,(compile '(+ (@ N) 10)))
       (=_i (+ 3 6)
            ,(compile '(+ 4 5)))
       (=_i 7 ,(compile '(execute (lambda (x) (+ x 2)) (5))))
       (=_i 5 ,(compile '(cond (((> 5 4) (@ N))
                                ((= 1 2) 6)
                                (true 3)))))
       (=_i (tree_internal (1 2 3 4))
            ,(compile '(tree (1 2 3 4))))
       (=_i 25 ,(compile '((! (lambda (x) (* x x)) square)
                           (execute (@ square) (5)))))
       (=_i 11,(compile '(let_mac ((a 5)
                                   (b (+ a 1)))
                                  (+ a b))))
       (=_i 15 ,(compile
                 '(let_mac ((f (lambda (x y) (* x (+ 1 y))));this only makes sense for very short functions, because the entire function gets written every time you call it.
                        (b (execute f (3 4)))
                        (c (execute f (0 4))))
                    (+ c b))))
       (=_i 9 ,(compile '(execute
                          (lambda (a b c)
                            (+ (+ a b) c))
                          (2 3 4))))
       ,(compile '((def f1 (x) (+ x 5));def is nice, because you don't need the (execute (@ when you call the function.
                   (= 10 (f1 5))
                   (= 11 (f1 6))
                   (= (f1 7) 12)
                   and and
                   ))
       ,(compile '(= 5 (let* ((a 5)) (+ a 0))));let* uses the r stack to store variables, so you can put it inside of recursive functions, and you don't have to waste global variable space.
       ,(compile '(let* ((f2 (lambda (A) (+ A 7)))
                         (b 9))
                    (= 16 (execute f2 (9)))))
       and and and and and and and and and and and and and

       ))
(test)
