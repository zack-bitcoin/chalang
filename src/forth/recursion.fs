% the main function recursively adds 0's to the stack. )
def _main ( print ) int 0 == not if drop int 1 - int 0 swap recurse call else drop drop then ;
main !


( the test macro adds 5 zeros, and checks to make sure that 5 zeros were added. )
macro test
int 5 main @ call
% print print print
int 0 == >r drop drop
int 0 == >r drop drop
int 0 == >r drop drop
int 0 == >r drop drop
int 0 == >r drop drop
r> r> r> r> r>
and and and and
;