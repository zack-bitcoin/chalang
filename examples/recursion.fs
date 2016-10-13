% the main function recursively adds 0's to the stack. )
: main dup int 0 = not if int 1 - int 0 swap recurse call else drop then ;


( the test macro adds 5 zeros, and checks to make sure that 5 zeros were added. )
macro test
int 5 main call
int 0 == swap 
int 0 == and swap 
int 0 == and swap 
int 0 == and swap
int 0 == and 
;