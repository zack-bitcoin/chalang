-module(compiler_lisp).
-export([doit/1, test/0]).
-define(int_bits, 32).
test() ->
    Files = ["first", "eqs", "cons", 
	     "car", "set", "lambda", "gcf",
	     "cond", "error", 
	     "macro"],
    test2(Files).
test2([]) -> success;
test2([H|T]) ->
    io:fwrite("test "),
    io:fwrite(H),
    io:fwrite("\n"),
    {ok, Text} = file:read_file("src/lisp/" ++ H ++ ".scm"),
    case doit(Text) of
	{_, [<<1:32>>]} ->
	    test2(T);
	X -> X
    end.
doit(A) when is_list(A) ->
    doit(list_to_binary(A));
doit(A) ->
    B = remove_comments(A),
    C = add_spaces(B),
    Words = to_words(C, <<>>, []),
    Tree = to_lists(Words),
    %true = ins_outs(Tree),
    {Tree1, _} = macros(Tree, dict:new()),
    {Tree2, _} = lambdas(Tree1, 0),
    %rename vars in functions. That way we have dynamic scope. Replace every first var with FuncNameV1, second with FuncNameV2, etc.

    {Tree3, FuncNames, _} = functions(Tree2, [], 0),%gets rid of "define", puts the bytes for : and ; to make a function. 

    %var_number_check(Tree, Functions),%checks that every function has the right number of inputs.
    Tree33 = conds(Tree3),
    Tree335 = lists(Tree33),
    Tree34 = eqs(Tree335),
    Tree345 = variable_gets(Tree34, FuncNames),
    Tree35 = rpn(Tree345),%change to reverse polish notation.
    Tree37 = add_calls(Tree35, FuncNames),
    Tree4 = compile_functions(Tree37),
    List = flatten(Tree4),
    List2 = variables(List, {dict:new(), 1}, FuncNames),
    Funcs = hash_functions(List2, dict:new()),
    List3 = remove_funcnames(List2),
    List4 = to_ops(List3, Funcs),
    
    VM = chalang:vm(List4, 1000, 1000, 1000, 1000, []),
    %print_binary(List4),
    %Words, Tree, Tree2, Tree3, 
    %{Tree35, Tree4, List, List2, List3, 
     {{FuncNames, Tree, Tree2, Tree34, Tree345, Tree37, List, List2, List4
      }, VM}. 
macros([<<"define-syntax">>|[Name|[Vars|[Code]]]], D) ->
    io:fwrite("macro name "),
    io:fwrite(Name),
    io:fwrite("\n"),
    C = compile_vars(Vars) ++ [Code],
    D2 = dict:store(Name, C, D),
    {[], D2};
macros([H|T], D) -> %when is_list(H) ->
    case dict:find(H, D) of
	error -> 
	    {H2, D2} = macros(H, D),
	    {T2, D3} = macros(T, D2),
	    {[H2|T2], D3};
	{ok, Val} -> 
	    {T2, D2} = macros(T, D),
	    {[<<"nop">>] ++ T2 ++ Val, D2}
    end;
macros(X, D) -> {X, D}.
    
variable_gets([<<"set!">>|[Name|[Definition]]], F) ->
    [<<"set!">>, Name] ++ [variable_gets(Definition, F)];
variable_gets([<<":">>|[Name|[Vars|[Code]]]], F) ->
    [<<":">>, Name, Vars] ++ [variable_gets(Code, F)];
variable_gets([H|[<<"!">>|T]], F) ->
    [H|[<<"!">>|variable_gets(T, F)]];
variable_gets([H|T], F) ->
    [variable_gets(H, F)|
     variable_gets(T, F)];
variable_gets(X, FuncNames) -> 
    B = is_variable(X, FuncNames),
    if
	B -> [<<"get">>, X];
	%B -> 
	true -> X
    end.
is_variable(X, FuncNames) ->
    B = is_in(X, FuncNames),
    C = is_int(X),
    D = is_64(X),
    {E, _, _, _} = is_op(X),
    (not B)
	and is_binary(X)
	and (not C)
	and (not D)
	and (not E).
lists([<<"list">>|T]) ->
    B = lists2(T),
    [<<"nop">>, <<"nil">>] ++ B;
lists([H|T]) ->
    [lists(H)|lists(T)];
lists(X) -> X.
lists2([<<"list">>|_]) -> io:fwrite("error, 'list' can only be the first element of a list");
lists2([H|T]) when is_list(H) ->
    [lists(H)] ++ [<<"swap">>, <<"cons">>] ++ lists2(T);
lists2([H|T]) ->
    [H] ++ [<<"swap">>, <<"cons">>] ++ lists2(T);
lists2(X) -> X.
add_calls([H], F) when is_list(H) ->
    [add_calls(H, F)];
add_calls([H], FuncNames) -> 
    B = is_in(H, FuncNames),
    if
	B -> [H, <<"call">>];
	true ->[H]
    end;
add_calls([H|T], F) -> 
    [add_calls(H, F)|
     add_calls(T, F)];
add_calls(X, _F) -> X.
	    
eqs([<<"=">>|T]) ->
    [<<"nop">>] ++ eqs(T) ++ [<<"===">>,<<"swap">>, <<"drop">>,<<"swap">>, <<"drop">>];
eqs([H|T]) -> [eqs(H)|eqs(T)];
eqs(X) -> X.
conds([<<"cond">>, T]) -> conds2(T);
conds([H|T]) -> [conds(H)|conds(T)];
conds(X) -> X.
conds2([[A,B]|T]) -> %It is a list of pairs. The first part of each pair should leave exactly 1 thing on the stack.
    [<<"nop">>] ++ [A]++[<<"if">>] ++[B] ++ [<<"else">>] ++ conds2(T) ++ [<<"then">>];

conds2([]) -> [].
    
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
    {B, C, _, _} = is_op(H),%is it a built-in word?
    A = if
	    B -> C;%return it's compiled format.
	    true ->%if it isn't built in
		case dict:find(H, F) of %check if it is a function.
		    error -> H; %if it isn't a function, then it is probably compiled already.
		    {ok, Val} -> %It is a function.
			S = size(Val),
			<<2, S:32, Val/binary>>
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
    [<<":">>, Name] ++ Vars2 ++ Code ++ [<<";">>];
compile_functions([H|T]) ->
    [compile_functions(H)|compile_functions(T)];
compile_functions(X) -> X.
compile_vars([]) -> [];
compile_vars([H|T]) -> [H, <<"!">>] ++ compile_vars(T).
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
    {E, _, _, _} = is_op(H),
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
%{true, compiles, inputs, outputs}
is_op(<<"true">>) -> {true, <<0,1:32>>, 0, 1};
is_op(<<"false">>) -> {true, <<0,0:32>>, 0, 1};
is_op(<<"int">>) -> {true, <<0>>, 0, 0};
is_op(<<"binary">>) -> {true, <<2>>, 0, 0};
is_op(<<"print">>) -> {true, <<10>>, 0, 0};
is_op(<<"nop">>) -> {true, <<>>, 0, 0};
is_op(<<"list">>) -> {true, <<>>, any, 1};
is_op(<<"drop">>) -> {true, <<20>>, 1, 0};
is_op(<<"dup">>) -> {true, <<21>>, 1, 2};
is_op(<<"swap">>) -> {true, <<22>>, 2, 2};
is_op(<<"tuck">>) -> {true, <<23>>, 3, 3};
is_op(<<"rot">>) -> {true, <<24>>, 3, 3};
is_op(<<"2dup">>) -> {true, <<25>>, 4, 4};
is_op(<<"tuckn">>) -> {true, <<26>>, 1, 1};
is_op(<<"pickn">>) -> {true, <<27>>, 1, 1};
is_op(<<"+">>) -> {true, <<50>>, 2, 1};
is_op(<<"-">>) -> {true, <<51>>, 2, 1};
is_op(<<"*">>) -> {true, <<52>>, 2, 1};
is_op(<<"/">>) -> {true, <<53>>, 2, 1};
is_op(<<"rem">>) -> {true, <<57>>, 2, 1};
is_op(<<"===">>) -> {true, <<58>>, 2, 3};
is_op(<<"=">>) -> {true, <<10,10,10>>, 2, 1};
is_op(<<":">>) -> {true, <<110>>, 3, 0};
is_op(<<";">>) -> {true, <<111>>, 0, 0};
is_op(<<"recurse">>) -> {true, <<112, 113>>, 0, 1};
is_op(<<"call">>) -> {true, <<113>>, 1, 1};
is_op(<<"@">>) -> {true, <<121>>, 1, 1};
is_op(<<"get">>) -> {true, <<121>>, 1, 1};
is_op(<<"!">>) -> {true, <<120>>, 2, 0};
is_op(<<"set!">>) -> {true, <<22, 120>>, 2, 0};
is_op(<<"cons">>) -> {true, <<130>>, 2, 1};
is_op(<<"car@">>) -> {true, <<131>>, 2, 2};
is_op(<<"car">>) -> {true, <<131, 20>>, 1, 1};
is_op(<<"cdr">>) -> {true, <<131, 22, 20>>, 1, 1};
is_op(<<"nil">>) -> {true, <<132>>, 0, 1};
is_op(<<"++">>) -> {true, <<134>>, 2, 1};
is_op(<<"split">>) -> {true, <<135>>, 2, 2};
is_op(<<"if">>) -> {true, <<70>>, 1, 0};
is_op(<<"else">>) -> {true, <<71>>, 0, 0};
is_op(<<"then">>) -> {true, <<72>>, 0, 0};
is_op(_) -> {false, not_an_op, 0, 0}.

to_lists(Words) ->
    {ok, X} = to_lists(Words, [], 0),
    X.
to_lists([<<")">>|T], X, N) when N > 0->
    {lists:reverse(X), T};
to_lists([<<")">>|_], _, _)->
    io:fwrite("too many close parenthesis )\n"),
    error;
to_lists([<<"(">>|T], X, N) ->
    {H, T2} = to_lists(T, [], N+1),
    to_lists(T2, [H|X], N);
to_lists([A|T], X, N) ->
    to_lists(T, [A|X], N);
to_lists([], X, 0) ->
    {ok, lists:reverse(X)};
to_lists(_, _, N) when N > 0->
    io:fwrite("not enough close parenthasis )"),
    error.
       

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
    ((X>47) and (X<58)) and is_int(Y);
is_int(_) -> false.
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
    
