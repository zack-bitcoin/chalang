 data is lists of binaries.

opcode, symbol for compiled language, stack changes

# values opcodes

0 int % ( -- X ) % the next 32 bits = 4 bytes are put on the stack as a single binary.

2 binary % ( N -- L ) % the next N * 8 bits are put on the stack as a single binary.

3 int1  % ( -- X ) % the next 8 bits = 1 byte are put on the stack as a 4-byte binary, which is our representation of integers

4 int2  % ( -- X ) % the next 16 bits = 2 byte are put on the stack as 4-byte binary.


# other opcodes

10 print % ( Y -- X )

11 return %code stops execution here. Whatever is on top of the stack is the final state.

12 nop % ( -- ) does nothing

13 fail % this smart contract fails.


# stack opcodes

20 drop ( X -- )

21 dup ( X -- X X )

22 swap ( A B -- B A)

23 tuck ( a b c -- c a b ) 

24 rot ( a b c -- b c a )

25 2dup ( a b -- a b a b )

26 tuckn ( X N -- ) inserts X N-deeper into the stack.

27 pickn ( N -- X ) grabs X from N-deep into the stack.


# r-stack opcodes

30 >r %( V -- )

31 r> %( -- V ) % moves from return to stack

32 r@ %( -- V ) % copies from return to stack


# crypto opcodes

40 hash ( X -- <<Bytes:256>> ) 

41 verify_sig ( Sig Data Pub -- true/false )

42 pub2addr % ( Pub -- Addr ) This is difficult because we can't represent tuples. Maybe pinkcrypto:address needs to use lists instead


# arithmetic opcodes
To do arithmetic:
only works with 4-byte integers. Results are 4-byte integers. 32-bits. The integers are encoded so that FFFFFFFF is the highest integer and 00000000 is the lowest.

50 + ( X Y -- Z )

51 - ( X Y -- Z )

52 * ( X Y -- Z )

53 / ( X Y -- Z )

54 > ( X Y -- true/false X Y )

55 < ( X Y -- true/false X Y )

56 ^ ( X Y -- Z )

57 rem (A B -- C) only works for integers.

58 == ( X Y -- true/false X Y )

59 ==2 ( X Y -- true/false )


# conditions opcodes

70 if  conditional statement

71 else  part of an switch conditional statement

72 then part of switch conditional statement.


# logic opcodes

80 not %( true/false -- false/true )

81 and ( true/false true/false -- true/false ) %false is 0, true is any non-zero byte.

82 or %( true/false true/false -- true/false )

83 xor %( true/false true/false -- true/false )

84 band ( 4 12 -- 4 ) %if inputed binaries are different length, it returns a binary of the longer length

85 bor ( 4 8 -- 12 )

86 bxor ( 4 12 -- 8 ) 


# check state opcodes

90 stack_size ( -- Size )

91 total_coins %( -- TotalCoins )

92 height %( -- Height )

93 slash %( -- true/false) %if this is part of a solo_stop transaction, then return 0.
         %If it is part of a slash transaction, return 1

94 gas % ( -- X )

95 ram ( -- X ) tells how much space is left in ram.

96 id2addr % ( ID -- Addr )

97 many_vars ( -- R ) how many more variables are defined

98 many_funs ( -- F ) how many functions are there defined

99 oracle ( -- R ) the root of the oracle trie from the previous block.

100 id_of_caller ( -- ID ) the ID of the person who published the code on-chain

%%%%100 questions ( -- H ) the root of the questions trie from the previous block. Used for crowdfunding the asking of questions. %%%% We don't need this because the oracle trie can be used to crowdfund the asking of questions.

101 accounts ( -- A ) the root of the accounts trie from the previous block.

102 channels ( -- C ) the root of the channels trie from the previous block.

103 verify_merkle ( Root Proof Value -- Value true/false )


# function opcodes

110 : % this starts the function declaration.

111 ; % This symbol ends a function declaration. example : square dup * ;

112 recurse %crash. this word should only be used in the definition of a word.

113 call %Use the binary at the top of the stack to look in our hashtable of defined words. If it exists call the code, otherwise crash.

114 def % this is the same as `:`. it is used to start a function declaration. The only difference is that it leaves the hash of the function on the top of the stack. This is the pointer that is used for calling the function later.


# variables opcodes

120 ! % ( X Y -- )

121 @ ( Y -- X )


# lists opcodes

130 cons % ( X Y -- [X|Y] )

131 car % ( [X|Y] -- X Y )

132 nil % ( -- [] ) this is the root of a list.
134 ++ % ( X Y -- Z ) appends 2 lists or 2 binaries. Cannot append a list to a binary.

135 split %( N Binary -- BinaryA BinaryB ) %Binary A has N*8 many bits. BinaryA appended to BinaryB makes Binary. 
         %( N List -- ListA ListB ) % ListA has N elements, listA appended to ListB makes List.

136 reverse % % ( F -- G ) %only works on lists

140 - 175 : load the integer (op# - 140). so we can load integers 0-35 in 1 byte.


These are compiler macros to make it easier to program.

( a open parenthesis starts a multi-line comment block.

) a closed parenthesis ends the comment. Make sure to put spaces between the parenthesis and the other words. 

or_die ( B -- ) if B is true, then does nothing. if B is false, then it crashes.

+! ( Number Name -- ) increments the variable Name by Number
