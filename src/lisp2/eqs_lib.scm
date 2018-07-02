% this is all happening at run-time.

(macro elclear () '(tuck drop drop))

(macro eqs (A B) '(nop A B === elclear))
(macro gt (A B)  '(nop A B > elclear))
