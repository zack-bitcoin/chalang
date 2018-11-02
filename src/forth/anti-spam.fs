%Comments to remind how signatures work
% macro sig binary 96 TUVVQ0lIQ1Ixc3ZwN05uTmt6Um1qTFBUZnR3OTlRZXVmSlBRamRRVXRCTlZpYWlKQWlFQWhuakh6MzFERWtTYXI0UWVRc1NrOGlJRG4rMTh4azAwYUVoTENLMWtiSmc9 ;
%  macro pub binary 65 BLDdkEzI6L8qmIFcSdnH5pfNAjEU11S9pHXFzY4U0JMgfvIMnwMxDOA85t6DKArhzbPJ1QaNBFHO7nRguf3El3I= ;
% macro data binary 3 AQID ;
% macro test
% sig data pub print verify_sig ;






% need to define at compile time: ReceiverPubkey, MessageID, HeightLimit, Fee

macro timeout ( -- delay nonce amount)
 %% check that enough time has passed since the message was sent. return the money.
 HeightLimit height <
 if
    int 0 int 10000 Fee
 else
  fail
 then
;
macro ham ( Signature -- delay nonce amount)
 %% check that the receiver has signed the id of the message, appended with a byte storing 1.
 MessageID 1 ++ ReceiverPubkey verify_sig
 if
  int 0 int 10000 Fee
 else
  fail
 then
;
macro spam ( Signature -- delay nonce amount)
 %% check that the receiver has signed the id of the message, appended with a byte storing 0.
 MessageID 0 ++ ReceiverPubkey verify_sig
 if
  int 0 int 10000 int 10000
 else
  fail
 then
;


macro main
int 0 == if drop drop timeout else drop
int 1 == if drop drop ham else drop
int 2 == if drop drop spam else drop
then then then
return