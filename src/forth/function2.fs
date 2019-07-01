
def _square dup * ;
square ! % storing a function inside a variable
def _double dup + ;
>r % storing a pointer to a function on the r-stack

def _i_am_not_named int 5 ;
call % calling the anonymous function.
drop

macro test
  int 3 square @ call %calling the named function
  r@ call %calling the function being pointed to by the top of the r-stack
  int 18 == tuck drop drop
;