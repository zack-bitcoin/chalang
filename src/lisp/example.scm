(import (basics.scm core/tree.scm core/fold.scm))

;the goal of this document is to show the different programming styles that are possible with chalang lisp.
; I wrote the same program 4 times to show 4 different programming styles that are possible.
; styles: forth, lisp, lisp with generics, python-like.

;the 4 programs all do this: given a list, find the average of the lowest and biggest elements. 

;this is the list we will use for all 4 example programming styles
(tree (0 1 2 3 4 2 10 2 1)) List !
;This list is being stored in the variable named "List"
;The ability to store values in variables and read them later is a bonus 5th style of programming.
; this symbol is used to store a value in a variable: `!`. this symbol is used to fetch a value from a variable: `@`.


;first in forth stack-based style

;( A B -- Min )
def 2dup < if drop else swap drop then end_fun
forth_min ! ;defined a function to calculate the min of 2 integers.

;( A B -- Max )
def 2dup > if drop else swap drop then end_fun
forth_max ! ;calculate the max of 2 integers

;( A L -- Min )
def nil === if drop drop else drop car@ tuck forth_min @ call swap recurse then end_fun
smallest_in_list1 ! ;a function to calculate the minimum of a list of integers

;( A L -- Max )
def nil === if drop drop else drop car@ tuck forth_max @ call swap recurse then end_fun
biggest_in_list1 ! ;a function to calculate the maximum of a list of integers

0 List @ dup tuck biggest_in_list1 @ call ;use the function to calculate the maximum of the list
swap 0 swap
smallest_in_list1 @ call ;use the other function to calcualte the minimum of the list
+ 2 / ;take the average
5 === tuck drop drop ;check that the average is 5.


;next using lisp

(define lispmax (a b);max of 2 integers
  (cond (((> a b) a)
         (true b))))
(define lispmin (a b);min of 2 integers
  (cond (((< a b) a)
         (true b))))
(define biggest_in_list2 (a L);max of a list
  (cond (((= L nil) a)
         (true (recurse;you can use keyword `recurse` for recursion.
                (lispmax a (car L))
                (cdr L))))))
(define smallest_in_list2 (a L);min of a list
  (cond (((= L nil) a)
         (true (smallest_in_list2;you can use the name of the function for recursion.
                (lispmin a (car L))
                (cdr L))))))
(define average (Q R)
       (/ (+ Q R) 2))

(define lisp_doit (L);putting it all together
  ((average
   (biggest_in_list2 0 L)
   (smallest_in_list2 0 L))))

(= 5 (lisp_doit (@ List))) ; testing that the average is 5


; now using lisp with generics

(define biggest_in_list3 (L)
  ((fold (@ forth_max) 0 L)))
   ;I used the function defined in forth syntax, to show how it is cross-compatible.
(define smallest_in_list3 (L)
  ((fold (@ lispmin) 0 L)));fold is a higher-order function that takes a pointer to another function as an input.
(define generic_doit (L);putting it all together
  ((average (biggest_in_list3 L)
           (smallest_in_list3 L))))

(= 5 (generic_doit (@ List))) ;check that the average is 5.


; now using something more similar to python syntax, where we allow for setting intermediate values Biggest and Smallest

(deflet pythonic_doit (L)
        ((Biggest (biggest_in_list3 L))
         (Smallest (smallest_in_list3 L)))
        (average Biggest Smallest))
;this is especially  useful if you are going to re-use the calculated intermediate value in multiple places. That way you don't have to re-calculate the value more than once.

(= 5 (pythonic_doit (@ List))) ;check that the average is 5


and and and ;combine the 4 test results into a single true/false result.
