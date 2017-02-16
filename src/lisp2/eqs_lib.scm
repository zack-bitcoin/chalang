(macro eqs_lib_clear () '(nop swap drop swap drop))

(macro eqs (A B)
       '(nop A B === swap drop swap drop))
(macro gt (A B)
       '(nop A B > swap drop swap drop))
