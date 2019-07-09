(import (basics.scm core/tree.scm core/fold.scm))

;the goal of this document is to show the different programming styles that are possible with chalang lisp.
; I wrote the same program 4 times to show 4 different programming styles that are possible.
; styles: forth, lisp, lisp with generics, python-like.

;the 4 programs all do this: given a list, find the average of the lowest and biggest elements. 

;this is the list we will use for all 4 example programming styles
(tree (0 1 2 3 4 2 10 2 1)) List !


;first in forth stack-based style

;( A B -- M )
def 2dup < if drop else swap drop then end_fun
forth_min ! ;defined a function to calculate the min of 2 integers.

;( A B -- M )
def 2dup > if drop else swap drop then end_fun
forth_max ! ;calculate the max of 2 integers

;( A L -- M )
def nil === if drop drop else drop car@ tuck forth_min @ call swap recurse then end_fun
forth_list_min ! ;a function to calculate the minimum of a list of integers

;( A L -- M )
def nil === if drop drop else drop car@ tuck forth_max @ call swap recurse then end_fun
forth_list_max ! ;a function to calculate the maximum of a list of integers

0 List @ dup tuck forth_list_max @ call ;use the function to calculate the maximum of the list
swap 0 swap
forth_list_min @ call ;use the other function to calcualte the minimum of the list
+ 2 / ;take the average
5 === tuck drop drop ;check that the average is 5.


;next using lisp

(define lispmax (a b);max of 2 integers
  (cond (((> a b) a)
         (true b))))
(define lispmin (a b);min of 2 integers
  (cond (((< a b) a)
         (true b))))
(define lisp_max_list (a l);max of a list
  (cond (((= l nil) a)
         (true (lisp_max_list
                (lispmax a (car l))
                (cdr l))))))
(define lisp_min_list (a l);min of a list
  (cond (((= l nil) a)
         (true (lisp_min_list
                (lispmin a (car l))
                (cdr l))))))
(define lisp_average (a b);average of 2 integers
  (/ (+ a b) 2))

(define lisp_doit (l);putting it all together
  ((lisp_average
   (lisp_max_list 0 l)
   (lisp_min_list 0 l))))

(= 5 (lisp_doit (@ List))) ; checking that the average is 5


; now using lisp with generics

(define lispmax2 (a b);max of 2 integers
  (cond (((> a b) a)
         (true b))))
(define lispmin2 (a b);min of 2 integers
  (cond (((< a b) a)
         (true b))))
(define generic_doit (l);putting it all together
  (/ (+
      ((fold (@ lispmax2) 0 l))
      ((fold (@ lispmin2) 0 l)))
     2))

(= 5 (generic_doit (@ List))) ;check that the average is 5.


; now using something more similar to python syntax, where we allow for setting intermediate values A and B

(deflet pythonic_doit (l)
        ((A (fold (@ lispmax2) 0 l));store the biggest element in A
         (B (fold (@ lispmin2) 0 l)));store the smallest element in B
        ((/ (+ A B) 2)));take the average of A and B

(= 5 (execute (@ pythonic_doit) ((@ List)))) ;check that the average is 5


and and and ;combine the 4 test results into a single true/false result.
