%Writing the first lisp, I realized that macros are very powerful, I can write most of the compiler in macros.
%If the compiler is in macros, it is easier to understand. 
%you can look at the source without having to learn erlang. you only have to understand lisp.
%dog-fooding the macro system results in a better macro system.
%I would like to use the macros to define a erlang-like language, and a python-like language, and a javascript-like language. So I want them to be good enough.


-module(compiler_lisp2).
-export([doit/1, test/0]).
-define(int_bits, 32).
test() ->
    Files = [
	     %"first_macro", "square_each_macro", 
	     %"cond_macro", "primes", 
	     %"lists"
	     "function"
	    ],
    test2(Files).
test2([]) -> success;
test2([H|T]) ->
    io:fwrite("test "),
    io:fwrite(H),
    io:fwrite("\n"),
    {ok, Text} = file:read_file("examples/" ++ H ++ ".scm"),
    case doit(Text) of
	{_, [<<1:32>>]} ->
	    test2(T);
	X -> X
    end.
    %{ok, Text} = file:read_file("examples/error.scm"),
doit_1(A, Done) ->
    B = remove_comments(<<A/binary, <<"\n">>/binary>>),
    B2 = quote_unquote(B),
    C = add_spaces(B2),
    Words = to_words(C, <<>>, []),
    Tree = to_lists(Words),
    imports(Tree, Done).
    
doit(A) when is_list(A) ->
    doit(list_to_binary(A));
doit(A) ->
    {Tree1, _} = doit_1(A, []),
    %Tree1 = quote_list(Tree),
    io:fwrite("Macros\n"),
    Tree2 = integers(Tree1),
    {Tree3, _} = macros(Tree2, dict:new()),
    io:fwrite("rpn\n"),
    Tree35 = rpn(Tree3),%change to reverse polish notation.
    List = flatten(Tree35),
    List2 = variables(List, {dict:new(), 1}),
    Funcs = dict:new(),
    List4 = to_ops(List2, Funcs),
    List5 = lambdas(List4),
    disassembler:doit(List5),
    io:fwrite("VM\n"),
    VM = chalang:vm(List5, 1000, 1000, 1000, 1000, []),
    %print_binary(List4),
    %Words, Tree, Tree2, Tree3, 
    %{Tree35, Tree4, List, List2, List3, 
    {{Tree35, List, List4
      }, VM}.%VM}. 
quote_list([<<"macro">>|T]) ->
    [<<"macro">>|T];
quote_list([<<"quote">>|T]) ->
    quote_list2(T);
quote_list([H|T]) ->
    [quote_list(H)|
     quote_list(T)];
quote_list(X) -> X.
quote_list2([A]) ->
    [<<"cons">>, quote_list2(A), <<"nil">>];
quote_list2([A|B]) ->
    [<<"cons">>, quote_list2(A), quote_list2(B)];
quote_list2(X) -> X.

imports([<<"import">>, []], Done) -> {[], Done};
imports([<<"import">>, [H|T]], Done) ->
    io:fwrite("importing "),
    io:fwrite(H),
    B = is_in(H, Done),
    {Tree, Done2} = 
	if
	    B -> {[], Done};
	    true ->		
		{ok, File} = file:read_file("examples/" ++ binary_to_list(H)),
		D2 = [H|Done],
		{Tr, D3} = doit_1(File, D2),
		{Tr, D3}
	end,
    {Tree2, Done3} = imports([<<"import">>, T], Done2),
    {[Tree|Tree2], Done3};
    
imports([H|T], Done) -> 
    {H2, Done2} = imports(H, Done),
    {T2, Done3} = imports(T, Done2),
    {[H2|T2], Done3};
imports(Tree, Done) -> {Tree, Done}.


integers([A|B]) ->
    [integers(A)|
     integers(B)];
integers(A) ->
    B = is_int(A),
    if
	B -> list_to_integer(binary_to_list(A));
	true -> A
    end.

macros([<<"macro">>, Name, Vars, Code], D) ->
    D2 = dict:store(Name, {Vars, Code}, D),
    {[], D2};
macros([<<"macro">>|[Name|_]], _) ->
    io:fwrite("error, macro named "),
    io:fwrite(Name),
    io:fwrite(" has the wrong number of inputs\n");
macros([H|T], D) when is_list(H) ->
    {T2, D2} = macros(H, D),
    {T3, D3} = macros(T, D2),
    {[T2|T3], D3};
macros([H|T], D) ->
    case dict:find(H, D) of
	error -> 
	    {T2, D2} = macros(T, D),
	    {[H|T2], D2};
	{ok, {Vars, Code}} ->
	    {T3, D2} = macros(T, D),
	    T2 = apply_macro(Code, Vars, T3, D2),
	    %io:fwrite("T2 macros "),
	    %io:fwrite({0, T2}),
	    macros(T2, D2)
	    %{apply_macro(Code, Vars, T, D), D}
    end;
macros(X, D) -> {X, D}.
   
apply_macro(Code, [], [], D) ->
    lisp(Code, D);
apply_macro(Code, [V|Vars], [H|T], D) ->%D is a dict of the defined macros.
    %V is the name given in the definition of the macro.
    %H is the name given when calling the macro in the code.
    Code2 = replace(Code, V, H),
    apply_macro(Code2, Vars, T, D);
apply_macro(C,_,_,_) ->
    io:fwrite("wrong number of inputs to function "),
    io:fwrite(C),
    io:fwrite("\n"),
    C = -1.
replace([], _, _) -> [];
replace([H|T], A, B) ->
    [replace(H, A, B)|
     replace(T, A, B)];
replace(A, A, B) -> B;
replace(X, _, _) -> X.
lisp_quote([[<<"unquote">>|T]|T2], D) -> 
    [lisp(T, D)|
     lisp_quote(T2, D)];
lisp_quote([H|T], D) -> 
    [lisp_quote(H, D)|
     lisp_quote(T, D)];
lisp_quote(X, _) -> X.
lisp([<<"print">>|T], D) -> 
    io:fwrite("print statment\n"),
    io:fwrite(T),
    io:fwrite("\n"),
    lisp(T, D);
lisp([<<"quote">>|T], D) -> lisp_quote(T, D);
lisp([<<"cond">>, T], D) -> lisp(lisp_cond(T, D), D);
lisp([<<"=">>, A, B], D) ->
    C = lisp(A, D),
    E = lisp(B, D),
    C == E;
lisp([<<">">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C > D;
lisp([<<"<">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C < D;
lisp([<<"is_list">>, A], F) ->
    B = lisp(A, F),
    is_list(B);
lisp([<<"+">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C + D;
lisp([<<"-">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C - D;
lisp([<<"/">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C div D;
lisp([<<"*">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C * D;
lisp([<<"rem">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    C rem D;
lisp([<<"reverse">>, A], F) ->
    lists:reverse(lisp(A, F));
lisp([<<"cons">>, A, B], F) ->
    C = lisp(A, F),
    D = lisp(B, F),
    [C|D];
lisp([<<"car">>, A], F) ->
    C = lisp(A, F),
    hd(C);
lisp([<<"cdr">>, A], F) ->
    C = lisp(A, F),
    tl(C);
lisp([<<"or">>, A, B], F) ->
    lisp(A, F) or lisp(B, F);
lisp([<<"and">>, A, B], F) ->
    lisp(A, F) and lisp(B, F);
lisp([<<"not">>, A], F) ->
    not(lisp(A, F));
lisp(X, _) -> X.
    
lisp_cond([], _) ->
    {error, no_true_cond};
lisp_cond([[Bool, Code]|T], D) ->
    %B = lisp(Bool),
    {B2, _} = macros(Bool, D),
    B3 = lisp(B2, D),
    case B3 of
	false -> lisp_cond(T, D);
	<<"false">> -> lisp_cond(T, D);
	[<<"false">>] -> lisp_cond(T, D);
	<<"true">> -> Code;
	[<<"true">>] -> Code;
	true -> Code;
	X -> 
	    {error, bad_bool, X}
    end. 


print_binary({error, R}) ->
    io:fwrite("error! \n"),
    io:fwrite(R),
    io:fwrite("\n"); 
print_binary(<<A:8, B/binary>>) ->
    io:fwrite(integer_to_list(A)),
    io:fwrite("\n"),
    print_binary(B);
print_binary(<<>>) -> ok.
split(C, B) -> split(C, B, []).
split(C, [C|B], Out) -> {lists:reverse(Out), B};
split(C, [D|B], Out) ->
    split(C, B, [D|Out]).
lambdas(<<0, N:32, T/binary>>) -> 
    T2 = lambdas(T),
    <<0, N:32, T2/binary>>;
lambdas(<<2, N:32, T/binary>>) ->
    M = N * 8,
    <<X:M, T2/binary>> = T,
    T3 = lambdas(T2),
    <<2, N:32, X:M, T3/binary>>;
lambdas(<<110, T/binary>>) ->
    {Func, T2, _} = chalang:split(111, T),
    Hash = hash:doit(Func),
    T3 = lambdas(T2),
    <<110, Func/binary, 111, 2, 12:32, Hash/binary, T3/binary>>;
lambdas(<<X, T/binary>>) -> 
    T2 = lambdas(T),
    <<X, T2/binary>>;
lambdas(<<>>) -> <<>>.
    
to_ops([], _) -> <<>>;
to_ops([H|T], F) -> 
    {B, C, _, _} = is_op(H),%is it a built-in word?
    A = if
	    B -> C;%return it's compiled format.
	    true ->%if it isn't built in
		H 
		%case dict:find(H, F) of %check if it is a function.
		%    error -> H; %if it isn't a function, then it is probably compiled already.
		%    {ok, Val} -> %It is a function.
		%	S = size(Val),
		%	<<2, S:32, Val/binary>>
		%end
    end,
    Y = to_ops(T, F),
    <<A/binary, Y/binary>>;
to_ops(X, _) -> 
    io:fwrite(X),
    X = ok.
is_in(H, [H|_]) -> true;
is_in(_, []) ->  false;
is_in(X, [_|T]) -> is_in(X, T).
variables([], {_Dict, _Many}) -> [];
variables([<<":">>|[N|T]], {Dict, Many}) -> 
    [<<":">>|[N|variables(T, {Dict, Many})]];
variables([H|T], {Dict, Many}) ->
    %B = is_in(H, FuncNames),
    B = is_integer(H),
    %C = is_int(H),
    D = is_64(H),
    {E, _, _, _} = is_op(H),
    {A, D2} = 
	if
	    B -> {[<<"int">>, <<H:32>>], {Dict, Many}};
	    %C -> 
		%Int = list_to_integer(binary_to_list(H)),
		%{[<<"int">>, <<Int:32>>], {Dict, Many}};
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
    A ++ variables(T, D2).
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
is_op(<<">">>) -> {true, <<54>>, 2, 1};
is_op(<<"<">>) -> {true, <<55>>, 2, 1};
is_op(<<"rem">>) -> {true, <<57>>, 2, 1};
is_op(<<"===">>) -> {true, <<58>>, 2, 3};
is_op(<<"not">>) -> {true, <<80>>, 1, 1};
is_op(<<"and">>) -> {true, <<81>>, 2, 1};
is_op(<<"or">>) -> {true, <<82>>, 2, 1};
is_op(<<"xor">>) -> {true, <<83>>, 2, 1};
is_op(<<"band">>) -> {true, <<84>>, 2, 1};
is_op(<<"bor">>) -> {true, <<85>>, 2, 1};
is_op(<<"bxor">>) -> {true, <<86>>, 2, 1};
is_op(<<"=">>) -> {true, <<10,10,10>>, 2, 1};
is_op(<<"lambda">>) -> {true, <<110>>, 3, 0};
is_op(<<"end_lambda">>) -> {true, <<111>>, 0, 0};
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
is_op(<<"reverse">>) -> {true, <<136>>, 1, 1};
is_op(<<"is_list">>) -> {true, <<137, 22, 20>>, 1, 2};
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
    
quote_unquote(<<"'(", T/binary>>) ->
    T2 = quote_unquote(T),
    <<"( quote ", T2/binary>>;
quote_unquote(<<"`(", T/binary>>) ->
    T2 = quote_unquote(T),
    <<"( unquote ", T2/binary>>;
quote_unquote(<<X, T/binary>>) ->
    T2 = quote_unquote(T),
    <<X, T2/binary>>;
quote_unquote(X) -> X.

