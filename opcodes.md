 data is lists of binaries.

opcode, symbol for compiled language, stack changes

# values opcodes

0 int % ( -- X ) % the next 32 bits = 4 bytes are put on the stack as a single binary.

1 fraction ( -- F ) The next 64 bits = 8 bytes are put onto the stack as a single binary.

2 binary % ( N -- L ) % the next N * 8 bits are put on the stack as a single binary.


# other opcodes

10 print % ( Y -- X )

11 crash %code stops execution here. Whatever is on top of the stack is the final state.


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

42 verify_account_sig ( Sig Data Pubs Address -- true/false ) an account is defined by a weighted list of pubkeys, and a minimum weight to make a signature. 


# arithmetic opcodes
To do arithmetic:
8-byte binaries are interpreted as fractions and return a 8-byte binaries.
4-byte binaries are interpreted as an integer, and results in a 4-byte binary.
Mixed input results in 8-byte fraction output.

50 + ( X Y -- Z )

51 - ( X Y -- Z )

52 * ( X Y -- Z )

53 / ( X Y -- Z ) %integers return integers. fractions return fractions. mixed returns fractions.

54 > ( X Y -- true/false )

55 < ( X Y -- true/false )

56 ^ ( X Y -- Z )

57 rem (A B -- C) only works for integers.

58 = ( X Y -- true/false )

59 f2i ( F -- I ) fraction to integer

60 i2f ( I -- F ) integer to fraction


# conditions opcodes

70 if  conditional statement

71 else  part of an switch conditional statement

72 then part of switch conditional statement.


# logic opcodes

80 bool_flip %( true/false -- false/true )

81 bool_and ( true/false true/false -- true/false ) %false is 0, true is any non-zero byte.

82 bool_or %( true/false true/false -- true/false )

83 bool_xor %( true/false true/false -- true/false )

84 band ( 4 12 -- 4 ) %if inputed binaries are different length, it returns a binary of the longer length

85 bor ( 4 8 -- 12 )

86 bxor ( 4 12 -- 8 ) 


# check state opcodes

90 stack_size ( -- Size )

91 id2balance % ( ID -- Balance )

92 pub2addr % ( Pub -- Addr )

93 total_coins %( -- TotalCoins )

94 height %( -- Height )

95 slash %( -- true/false) %if this is part of a solo_stop transaction, then return 0.
         %If it is part of a slash transaction, return 1

96 gas % ( -- X )

97 ram ( -- X ) tells how much space is left in ram.

98 id2addr % ( ID -- Addr )

99 oracle % ( ID -- Result ) % reads a result from one of the completed oracles

100 many_vars ( -- R )

101 many_funs ( -- F )


# function opcodes

110 : % this starts the function declaration.

111 ; % This symbol ends a function declaration. example : square dup * ;

112 recurse %crash. this word should only be used in the definition of a word.

113 call %Use the binary at the top of the stack to look in our hashtable of defined words. If it exists call the code, otherwise crash.


# variables opcodes

120 ! % ( X -- Y ) % only stores 32-bit integers

121 @ ( Y -- X )


# lists opcodes

130 cons % ( X Y -- [X|Y] )

131 car % ( [X|Y] -- X Y )

132 nil % ( -- [] ) this is the root of a list.

133 nil== % ( List -- List true/false ) %checks if the list is empty without duplicating the data in the list. Can be much faster than the equivalent ``` dup nil == ```

134 ++ % ( X Y -- Z ) appends 2 lists or 2 binaries. Cannot append a list to a binary.

135 split %( N Binary -- BinaryA BinaryB ) %Binary A has N*8 many bits. BinaryA appended to BinaryB makes Binary. 
         %( N List -- ListA ListB ) % ListA has N elements, listA appended to ListB makes List.

136 reverse % % ( F -- G ) %only works on lists


These are compiler macros to make it easier to program.

( a open parenthesis starts a multi-line comment block.

) a closed parenthesis ends the comment. Make sure to put spaces between the parenthesis and the other words. 

fraction ( X Y -- F ) makes a fraction from 2 integers. example: fraction 4 6

integer ( X -- Y ) loads an integer. example: "integer 27"

binary ( B -- A ) loads a binary encoded in base64

or_die ( B -- ) if B is true, then does nothing. if B is false, then it crashes.

+! ( Number Name -- ) increments the variable Name by Number

Lists are easy with these 3 words: "[", "," and, "]". You don't need spaces between them either. example: "[1,2,3,4]" 