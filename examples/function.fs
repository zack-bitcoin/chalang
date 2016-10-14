
: square dup * ; 
: quad square call square call ;

macro test
 int 2 quad call int 16 == swap drop swap drop
;

