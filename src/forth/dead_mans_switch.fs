%% define: SwitchID SenderPubkey TimeoutHeight

macro reset ( Signature -- delay nonce amount )
 SwitchID SenderPubkey verify_sig
 if
  int 0 int 10000 int 0
 else
  fail
 then
;

macro timeout ( -- delay nonce amount )
 TimeoutHeight height <
 if
  int 0 int 10000 int 10000
 else
  fail
 then
;

macro main
int 0 == if drop drop reset else drop
int 1 == if drop drop timeout else drop
then then
return
;