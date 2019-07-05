; in a macro, by default all computation happens at compile time.

(macro five () (+ 2 3))
(five)

; this macro "five" is identical to the chalang code: `int 5`

; you can use a single quote to mark any code to
; be run at run-time instead of compile time.

(macro six ()
       '(+ 2 4))
; this macro "six" is identical to the chalang code:
; `int 2 int 4 +`

; if there is some code inside of the quoted region
; which you want to run at compile time instead of
; run-time, then you mark it with a comma

(macro seven ()
       '(+ ,(+ 1 2) 4))
; this macro "seven" is identical to the chalang
; code: `int 3 int 4 +`

