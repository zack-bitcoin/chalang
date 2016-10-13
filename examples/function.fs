
: square dup * ; 
: quad square call square call ;

macro test
 int 2 quad call int 16 ==
;


% 110 21 52 111
% 110 0 0 0 0 1 113
%     0 0 0 0 1 113 111
% 0 0 0 0 2 0 0 0 0 2 113
% 0 0 0 0 16 58