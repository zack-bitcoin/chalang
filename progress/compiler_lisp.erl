-module(compiler_lisp).
-export([doit/1, test/0]).
-define(int_bits, 32).

test() ->
    {ok, Text} = file:read_file("examples/first.scm"),
    doit(Text).

doit(A) ->
    B = remove_comments(A),
    C = add_spaces(B),
    Words = to_words(C, <<>>, []),
    Tree = to_lists(Words),
    %get macros
    %apply macros
    %check that each operator has the correct number of variables.
    true = var_number_check(Tree),
    Tree2 = rpn(Tree),
    Opcodes = to_opcodes(Tree2),
    %switch to reverse polish notation.
    %remove the parenthasis, and replace symbols with opcodes.
    Opcodes.
w2o(<<"+">>) ->
    {50, 2, 1};%{opcode, inputs, outputs}
w2o(<<"*">>) ->
    {52, 2, 1}.
to_lists(Words) ->
    case to_lists(Words, [], 0) of	
	{ok, X} -> X;
	{_, _} -> io:fwrite("too many close parenthasis ) \n")
    end.

to_lists([<<")">>|T], X, _)->
    {lists:reverse(X), T};
to_lists([<<"(">>|T], X, N) ->
    {H, T2} = to_lists(T, [], N+1),
    to_lists(T2, [H|X], N);
to_lists([A|T], X, N) ->
    to_lists(T, [A|X], N);
to_lists([], X, 0) ->
    {ok, lists:reverse(X)};
to_lists(_, _, N) when N > 0->
    io:fwrite("not enough close parenthasis )").

to_words(<<>>, <<>>, Out) -> lists:reverse(Out);
to_words(<<>>, N, Out) -> lists:reverse([N|Out]);
to_words(<<"\t", B/binary>>, X, Out) ->
    to_words(<<" ", B/binary>>, X, Out);
to_words(<<"\n", B/binary>>, X, Out) ->
    to_words(<<" ", B/binary>>, X, Out);
to_words(<<" ", B/binary>>, <<"">>, Out) ->
    to_words(B, <<>>, Out);
to_words(<<" ", B/binary>>, N, Out) ->
    to_words(B, <<>>, [N|Out]);
to_words(<<C:8, B/binary>>, N, Out) ->
    to_words(B, <<N/binary, C:8>>, Out).

remove_till(N, <<N:8, B/binary>>) -> B;
remove_till(N, <<_:8, B/binary>>) -> 
    remove_till(N, B).
remove_comments(B) -> remove_comments(B, <<"">>).
remove_comments(<<"">>, Out) -> Out;
remove_comments(<<37:8, B/binary >>, Out) -> % [37] == "%".
    C = remove_till(10, B), %10 is '\n'
    remove_comments(C, Out);
remove_comments(<<X:8, B/binary>>, Out) -> 
    remove_comments(B, <<Out/binary, X:8>>).
add_spaces(B) -> add_spaces(B, <<"">>).
add_spaces(<<"">>, B) -> B;
add_spaces(<<40:8, B/binary>>, Out) -> % (
    add_spaces(B, <<Out/binary, 32:8, 40:8, 32:8>>);
add_spaces(<<41:8, B/binary>>, Out) -> % )
    add_spaces(B, <<Out/binary, 32:8, 41:8, 32:8>>);
add_spaces(<<X:8, B/binary >>, Out) -> 
    add_spaces(B, <<Out/binary, X:8>>).
var_number_check([]) -> true;
var_number_check([H|T]) -> 
    {Op, In, Out} = w2o(H),
    
