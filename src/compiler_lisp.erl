-module(compiler_lisp).
-export([doit/1, test/0]).
-define(int_bits, 32).
test() ->
    %{ok, Text} = file:read_file("examples/first.scm"),
    {ok, Text} = file:read_file("examples/lambda.scm"),
    doit(Text).

doit(A) ->
    B = remove_comments(A),
    C = add_spaces(B),
    Words = to_words(C, <<>>, []),
    Tree = to_lists(Words),
    {Tree2, _} = lambdas(Tree, 0),
    %get macros
    %apply macros
    %rename vars in functions. That way we have dynamic scope. Replace every first var with FuncNameV1, second with FuncNameV2, etc.

    {Tree3, FuncNames, _} = functions(Tree2, [], 0),%gets rid of "define", puts the bytes for : and ; to make a function. 


    %var_number_check(Tree, Functions),%checks that every function has the right number of inputs.
    Tree35 = rpn(Tree3),%change to reverse polish notation.
    Tree4 = compile_functions(Tree35),
    %List2 = remove_functions(List),%functions are named by the hash of their contents. So remove the names from the code.
    %get functions. load up a dictionary of the functions
    %Functions = get_functions(Tree),
    %apply functions. replace the function's name with the hash of it's contents.
    %Opcodes = to_opcodes(List2, Functions, Variables),
    List = flatten(Tree4),
    List2 = variables(List, {dict:new(), 1}, FuncNames),
    Funcs = hash_functions(List2, dict:new()),
    List3 = remove_funcnames(List2),
    List4 = to_ops(List3, Funcs),
    
    %chalang:vm(List4, 100000, 100000, 1000, 1000, []).
    %print_binary(List4),
    {Words, Tree, Tree2, Tree3, Tree35, Tree4, List, List2, List3, List4}.
    %List3.
lambdas([], N) -> {[], N};
lambdas([[[<<"lambda">>, Vars, Code]|T]|T2], N) -> 
    X = list_to_binary("lambda" ++ integer_to_list(N)),
    {[[<<"define">>, X, Vars, Code],[X, T]]++T2,
     N+1};
lambdas([H|T], N) -> 
    {A, N2} = lambdas(H, N),
    {B, N3} = lambdas(T, N2),
    {[A|B], N3};
lambdas(X, N) -> {X, N}.
print_binary({error, R}) ->
    io:fwrite("error! \n"),
    io:fwrite(R),
    io:fwrite("\n"); 
print_binary(<<A:8, B/binary>>) ->
    io:fwrite(integer_to_list(A)),
    io:fwrite("\n"),
    print_binary(B);
print_binary(<<>>) -> ok.
remove_funcnames([]) -> [];
remove_funcnames([<<":">>|[_|T]]) -> 
    [<<":">>|remove_funcnames(T)];
remove_funcnames([H|T]) -> 
    [H|remove_funcnames(T)].
hash_functions([], D) -> D;
hash_functions([<<":">>|[Name|T]], D1) -> 
    {Code1, T2} = split(<<";">>, T),
    Code2 = to_ops(Code1, D1),
    D2 = dict:store(Name, hash:doit(Code2), D1),
    hash_functions(T2, D2);
hash_functions([_|T], D) ->
    hash_functions(T, D).
split(C, B) -> split(C, B, []).
split(C, [C|B], Out) -> {lists:reverse(Out), B};
split(C, [D|B], Out) ->
    split(C, B, [D|Out]).
to_ops([], _) -> <<>>;
to_ops([H|T], F) -> 
    {B, C} = is_op(H),
    A = if
	    B -> <<C:8>>;
	    true ->
		case dict:find(H, F) of
		    error -> H;
		    {ok, Val} -> 
			S = size(Val),
			<<2, S:32, Val/binary, 113>>
		end
    end,
    Y = to_ops(T, F),
    <<A/binary, Y/binary>>;
to_ops(X, _) -> 
    io:fwrite(X),
    X = ok.
functions([<<"define">>|[Name|[Vars|T]]], N, L) -> 
    C = [Vars|T],
    {[<<";">>, <<":">>, Name] ++ C, [Name|N], L};
functions([H|T], N, L) -> 
    {C1, N1, L2} = functions(H, [], L),
    {C2, N2, L3} = functions(T, [], L2),
    {[C1|C2], N++N1++N2, L3};
functions(X, N, L) -> 
    {X, N, L}.
compile_functions([]) -> [];
compile_functions([<<":">>, Name, Vars, Code, <<";">>]) -> 
    Vars2 = compile_vars(Vars),
    Code2 = compile_code(Code, Vars),
    [<<":">>, Name] ++ Vars2 ++ Code2 ++ [<<";">>];
compile_functions([H|T]) ->
    [compile_functions(H)|compile_functions(T)];
compile_functions(X) -> X.
compile_vars([]) -> [];
compile_vars([H|T]) -> [H, <<"!">>] ++ compile_vars(T).
compile_code([], _) -> [];
compile_code([H|T], Vars) -> 
    B = is_in(H, Vars),
    A = if
	    B -> [H, <<"@">>];
	    true -> [H]
	end,
    A ++ compile_code(T, Vars).
is_in(H, [H|_]) -> true;
is_in(_, []) ->  false;
is_in(X, [_|T]) -> is_in(X, T).
variables([], {_Dict, _Many}, _) -> [];
variables([<<":">>|[N|T]], {Dict, Many}, Funcs) -> 
    [<<":">>|[N|variables(T, {Dict, Many}, Funcs)]];
variables([H|T], {Dict, Many}, FuncNames) ->
    B = is_in(H, FuncNames),
    C = is_int(H),
    D = is_64(H),
    {E, _} = is_op(H),
    {A, D2} = 
	if
	    B -> {[H], {Dict, Many}};
	    C -> 
		Int = list_to_integer(binary_to_list(H)),
		{[<<"int">>, <<Int:32>>], {Dict, Many}};
	    D -> 
		Bin = decode(H),
		S = size(Bin),
		{[<<"binary">>, <<S:32>>, Bin], {Dict, Many}};
	    E -> {[H], {Dict, Many}};
	    true -> %must be a variable then
		case dict:find(H, Dict) of
		    error ->
			NewDict = dict:store(H, Many, Dict),
			{[<<"int">>, <<Many:32>>], {NewDict, Many+1}};
		    {ok, Val} ->
			{[<<"int">>, <<Val:32>>], {Dict, Many}}
		end
	end,
    A ++ variables(T, D2, FuncNames).
is_op(<<"*">>) -> {true, 52};
is_op(<<"+">>) -> {true, 50};
is_op(<<":">>) -> {true, 110};
is_op(<<";">>) -> {true, 111};
is_op(<<"@">>) -> {true, 121};
is_op(<<"!">>) -> {true, 120};
is_op(<<"int">>) -> {true, 0};
is_op(<<"binary">>) -> {true, 2};
is_op(_) -> {false, not_an_op}.

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
is_int(<<>>) -> true;
is_int(<<X:8, Y/binary>>) -> 
    ((X>47) and (X<58)) and is_int(Y).
-define(Binary, <<45:8, 45:8>>).
is_64(<<45,45, Y/binary>>) ->
    is_64_2(Y);
is_64(_) -> false.
is_64_2(<<>>) -> true;
is_64_2(<<X:8, Y/binary>>) -> 
    (is_int(<<X:8>>) 
     or ((X>64) and (X<90)) 
     or ((X>96) and (X<122)) 
     or (X == hd("/")) 
     or (X == hd("+")))
	and is_64_2(Y).
encode(X) -> 
    Y = base64:encode(X),
    <<45,45, Y/binary>>.
decode(X) ->
    <<45,45, Y/binary>> = X,
    base64:decode(Y).
    
rpn([]) ->  [];
rpn([[H|S]|T]) -> 
    [rpn([H|S])|rpn(T)];
rpn([H|T]) -> 
    rpn2(T) ++ [H].
rpn2([]) -> [];
rpn2([H|T]) when is_list(H) ->
    [rpn(H)|rpn2(T)];
rpn2([H|T]) ->
    [H|rpn2(T)].
flatten([]) -> [];
flatten([H|T]) -> 
    flatten(H) ++ flatten(T);
flatten(X) -> [X].
    
