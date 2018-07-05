; this is all happening at run-time.

(macro elclear () '(tuck drop drop))
(macro = (A B) '(nop A B === elclear))


