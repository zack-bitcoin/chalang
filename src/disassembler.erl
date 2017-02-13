-module(disassembler).
-export([doit/1,test/0]).

doit(<<0, I:32, T/binary>>) ->
    io:fwrite(" "++integer_to_list(I)),
    doit(T);
doit(<<2, N:32, T/binary>>) ->
    M = N*8,
    <<A:M, T2/binary>> = T,
    io:fwrite(" "++binary_to_list(base64:encode(<<A:M>>))),
    doit(T2);
doit(<<N, T/binary>>) ->
    io:fwrite(doit2(N)),
    doit(T);
doit(<<>>) ->
    io:fwrite("\n"),
    ok.

doit2(10) -> " print";
doit2(11) -> " crash";
doit2(12) -> " nop";
doit2(20) -> " drop";
doit2(21) -> " dup";
doit2(22) -> " swap";
doit2(23) -> " tuck";
doit2(24) -> " rot";
doit2(25) -> " 2dup";
doit2(26) -> " tuckn";
doit2(27) -> " pickn";
doit2(30) -> " >r";
doit2(31) -> " r>";
doit2(32) -> " r@";
doit2(40) -> " hash";
doit2(41) -> " verify_sig";
doit2(42) -> " pub2addr";
doit2(50) -> " +";
doit2(51) -> " -";
doit2(52) -> " *";
doit2(53) -> " /";
doit2(54) -> " >";
doit2(55) -> " <";
doit2(56) -> " ^";
doit2(57) -> " rem";
doit2(58) -> " =";
doit2(70) -> "\nif";
doit2(71) -> " else";
doit2(72) -> " then\n";
doit2(80) -> " not";
doit2(81) -> " and";
doit2(82) -> " or";
doit2(83) -> " xor";
doit2(84) -> " band";
doit2(85) -> " bor";
doit2(86) -> " bxor";
doit2(90) -> " stack_size";
doit2(91) -> " total_coins";
doit2(92) -> " height";
doit2(93) -> " slash";
doit2(94) -> " gas";
doit2(95) -> " ram";
doit2(96) -> " id2addr";
doit2(97) -> " many_vars";
doit2(98) -> " many_funs";
doit2(99) -> " oracle";
doit2(100) -> " id_of_caller";
doit2(101) -> " accounts";
doit2(102) -> " channels";
doit2(103) -> " verify_merkle";
doit2(110) -> "\n:";
doit2(111) -> " ;\n";
doit2(112) -> " recurse";
doit2(113) -> " call";
doit2(114) -> " store";
doit2(115) -> " fetch";
doit2(120) -> " !";
doit2(121) -> " @";
doit2(130) -> " cons";
doit2(131) -> " car";
doit2(132) -> " nil";
doit2(134) -> " ++";
doit2(135) -> " split";
doit2(136) -> " reverse";
doit2(X) -> 
    io:fwrite("\nthat is not a legal opcode: "),
    io:fwrite(integer_to_list(X)),
    io:fwrite("\n"),
    X=135.
test() ->
    {ok, A} = file:read_file("src/lisp/cond.scm"),
    {_, _, X} = compiler_lisp:doit(A),
    doit(X).
