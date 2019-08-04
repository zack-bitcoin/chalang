-module(compile_utils).
-export([quote_unquote/1,remove_comments/1,add_spaces/1,to_words/3,to_lists/1,integers/1,rpn/1,flatten/1,variables/1,variables/2,to_ops/1,stringify_lisp/1,doit/1,doit2/1,is_64/1,is_op/1,stringify_lisp/1]).


doit(X) ->
    B = compile_utils:remove_comments(<<X/binary, <<"\n">>/binary>>),
    B2 = quote_unquote(B),
    C = add_spaces(B2),
    Words = to_words(C, <<>>, []),
    integers(to_lists(Words)).
doit2(Tree) ->
    Optimized = flatten(Tree),
    V = variables(Optimized),
    to_ops(V).
    
integers([A|B]) ->
    [integers(A)|
     integers(B)];
integers(A) ->
    B = is_int(A),
    if
	B -> list_to_integer(binary_to_list(A));
	true -> A
    end.
to_ops([]) -> <<>>;
to_ops([H|T]) -> 
    {B, C, _, _} = is_op(H),%is it a built-in word?
    A = if
	    B -> C;%return it's compiled format.
	    true -> H %if it isn't built in
    end,
    Y = to_ops(T),
    <<A/binary, Y/binary>>;
to_ops(X) -> 
    io:fwrite(X),
    X = ok.
variables(X) ->
    variables(X, {dict:new(), 1}).
variables([], {_Dict, _Many}) -> [];
variables([<<":">>|[N|T]], {Dict, Many}) -> 
    [<<":">>|[N|variables(T, {Dict, Many})]];
variables([H|T], {Dict, Many}) ->
    B = is_integer(H),
    D = is_64(H),
    {E, _, _, _} = is_op(H),
    {A, D2} = 
	if
	    B -> {[<<"int">>, <<H:32>>], {Dict, Many}};
	    D -> 
		%io:fwrite("variables case D \n"),
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
is_op(<<"return">>) -> {true, <<11>>, 3, 0};
is_op(<<"fail">>) -> {true, <<13>>, 0, 0};
is_op(<<"list">>) -> {true, <<>>, any, 1};
is_op(<<"drop">>) -> {true, <<20>>, 1, 0};
is_op(<<"dup">>) -> {true, <<21>>, 1, 2};
is_op(<<"swap">>) -> {true, <<22>>, 2, 2};
is_op(<<"tuck">>) -> {true, <<23>>, 3, 3};
is_op(<<"rot">>) -> {true, <<24>>, 3, 3};
is_op(<<"2dup">>) -> {true, <<25>>, 2, 4};
is_op(<<"tuckn">>) -> {true, <<26>>, 1, 1};
is_op(<<"pickn">>) -> {true, <<27>>, 1, 1};
is_op(<<">r">>) -> {true, <<30>>, 1, 0};
is_op(<<"r>">>) -> {true, <<31>>, 0, 1};
is_op(<<"r@">>) -> {true, <<32>>, 0, 1};
is_op(<<"hash">>) -> {true, <<40>>, 1, 1};
is_op(<<"verify_sig">>) -> {true, <<41>>, 3, 1};
%is_op(<<"pub2addr">>) -> {true, <<42>>, 1, 1};
is_op(<<"+">>) -> {true, <<50>>, 2, 1};
is_op(<<"-">>) -> {true, <<51>>, 2, 1};
is_op(<<"*">>) -> {true, <<52>>, 2, 1};
is_op(<<"/">>) -> {true, <<53>>, 2, 1};
is_op(<<">">>) -> {true, <<54>>, 2, 1};
is_op(<<"<">>) -> {true, <<55>>, 2, 1};
is_op(<<"rem">>) -> {true, <<57>>, 2, 1};
is_op(<<"===">>) -> {true, <<58>>, 2, 3};
is_op(<<"if">>) -> {true, <<70>>, 1, 0};
is_op(<<"else">>) -> {true, <<71>>, 0, 0};
is_op(<<"then">>) -> {true, <<72>>, 0, 0};
is_op(<<"not">>) -> {true, <<80>>, 1, 1};
is_op(<<"and">>) -> {true, <<81>>, 2, 1};
is_op(<<"or">>) -> {true, <<82>>, 2, 1};
is_op(<<"xor">>) -> {true, <<83>>, 2, 1};
is_op(<<"band">>) -> {true, <<84>>, 2, 1};
is_op(<<"bor">>) -> {true, <<85>>, 2, 1};
is_op(<<"bxor">>) -> {true, <<86>>, 2, 1};
is_op(<<"stack_size">>) -> {true, <<90>>, 0, 1};
%is_op(<<"total_coins">>) -> {true, <<91>>, 0, 1};
is_op(<<"height">>) -> {true, <<94>>, 0, 1};
%is_op(<<"slash">>) -> {true, <<93>>, 0, 1};
is_op(<<"gas">>) -> {true, <<96>>, 0, 1};
is_op(<<"ram">>) -> {true, <<97>>, 0, 1};
is_op(<<"many_vars">>) -> {true, <<100>>, 0, 1};
is_op(<<"many_funs">>) -> {true, <<101>>, 0, 1};
%is_op(<<"oracle">>) -> {true, <<99>>, 0, 1};
%is_op(<<"id_of_caller">>) -> {true, <<100>>, 0, 1};
%is_op(<<"accounts">>) -> {true, <<101>>, 0, 1};
%is_op(<<"channels">>) -> {true, <<102>>, 0, 1};
%is_op(<<"verify_merkle">>) -> {true, <<103>>, 3, 2};
is_op(<<"start_fun">>) -> {true, <<110>>, 3, 0};
is_op(<<"def">>) -> {true, <<114>>, 3, 0};
is_op(<<"end_fun">>) -> {true, <<111>>, 0, 0};
is_op(<<"recurse">>) -> {true, <<112, 113>>, any, 1};
is_op(<<"call">>) -> {true, <<113>>, 1, 1};
is_op(<<"@">>) -> {true, <<121>>, 1, 1};
%is_op(<<"get">>) -> {true, <<121>>, 1, 1};
is_op(<<"!">>) -> {true, <<120>>, 2, 0};
is_op(<<"set!">>) -> {true, <<22, 120>>, 2, 0};
is_op(<<"cons">>) -> {true, <<130>>, 2, 1};
is_op(<<"car@">>) -> {true, <<131>>, 1, 2};
is_op(<<"car">>) -> {true, <<131, 20>>, 1, 1};
is_op(<<"cdr">>) -> {true, <<131, 22, 20>>, 1, 1};
is_op(<<"nil">>) -> {true, <<132>>, 0, 1};
is_op(<<"++">>) -> {true, <<134>>, 2, 1};
is_op(<<"split">>) -> {true, <<135>>, 2, 2};
is_op(<<"reverse">>) -> {true, <<136>>, 1, 1};
is_op(<<"is_list">>) -> {true, <<137, 22, 20>>, 1, 2};
is_op(_) -> {false, not_an_op, 0, 0}.

stringify_lisp(X) ->
    << <<"(">>/binary, (stringify_lisp2(X))/binary>>.
stringify_lisp2([]) -> <<")">>;
stringify_lisp2([H]) when is_list(H) -> << (stringify_lisp(H))/binary, <<")">>/binary >>;
stringify_lisp2([H]) -> << (stringify_lisp2(H))/binary, <<")">>/binary >>;
stringify_lisp2([[<<"macro">>|T1]|T]) ->
    << <<"\n(macro ">>/binary, (stringify_lisp2(T1))/binary, (stringify_lisp2(T))/binary>>;
stringify_lisp2([[<<"define">>|T1]|T]) ->
    << <<"\n(define ">>/binary, (stringify_lisp2(T1))/binary, (stringify_lisp2(T))/binary>>;
stringify_lisp2([[<<"deflet">>|T1]|T]) ->
    << <<"\n(deflet ">>/binary, (stringify_lisp2(T1))/binary, (stringify_lisp2(T))/binary>>;
stringify_lisp2([H|T]) when is_list(H)->
    << (stringify_lisp(H))/binary, <<" ">>/binary, (stringify_lisp2(T))/binary>>;
stringify_lisp2([H|T]) ->
    << (stringify_lisp2(H))/binary, <<" ">>/binary, (stringify_lisp2(T))/binary>>;
stringify_lisp2(H) when is_integer(H) ->
    << (list_to_binary(integer_to_list(H)))/binary>>;
stringify_lisp2(H) -> H.
to_lists(Words) ->
    {ok, X} = to_lists(Words, [], 0),
    X.
to_lists([<<")">>|T], X, N) when N > 0->
    {lists:reverse(X), T};
to_lists([<<")">>|_], X, _)->
    io:fwrite("too many close parenthesis )\n"),
    io:fwrite(stringify_lisp(lists:reverse(X))),
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
      
grab_string(<<"\"", R/binary>>, S) -> {S, R};
grab_string(<<C:8, R/binary>>, S) -> 
    grab_string(R, <<S/binary, C:8>>);
grab_string(<<>>, _) -> 
    io:fwrite("error, unmatched string quotes \"\"\n"),
    error.
to_words(<<>>, <<>>, Out) -> lists:reverse(Out);
to_words(<<>>, N, Out) -> lists:reverse([N|Out]);
to_words(<<"\"", B/binary>>, <<>>, Out) ->
    {S, R} = grab_string(B, <<>>),
    S2 = base64:encode(S),
    N = << <<"--">>/binary, S2/binary>>,
    to_words(R, <<>>, [N|Out]);
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
remove_comments(<<59:8, B/binary >>, Out) -> % [37] == "%".
    C = remove_till(10, B), %10 is '\n'
    remove_comments(C, Out);
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
%-define(Binary, <<45:8, 45:8>>).
is_64(<<45,45, Y/binary>>) ->
    is_64_2(Y);
is_64(_) -> false.
is_64_2(<<>>) -> true;
is_64_2(<<X:8, Y/binary>>) -> 
    (is_int(<<X:8>>) 
     or ((X>64) and (X<91)) 
     or ((X>96) and (X<123)) 
     or (X == hd("=")) 
     or (X == hd("/")) 
     or (X == hd("+")))
	and is_64_2(Y).
decode(X) ->
    <<45,45, Y/binary>> = X,
    base64:decode(Y).
    
rpn([]) ->  [];
rpn([[H|S]|T]) -> 
    [rpn([H|S])|rpn(T)];
rpn([H|T]) -> 
    rpn2(T) ++ [H].
rpn2([]) -> [];
rpn2(<<"nil">>) -> [];
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
quote_unquote(<<",(", T/binary>>) ->
    T2 = quote_unquote(T),
    <<"( unquote ", T2/binary>>;
quote_unquote(<<"'", T/binary>>) ->
    {Atom, T2} = quote_unquote_atom(T),
    T3 = quote_unquote(T2),
    <<"( quote ", Atom/binary, " ) ",T3/binary>>;
quote_unquote(<<",", T/binary>>) ->
    {Atom, T2} = quote_unquote_atom(T),
    T3 = quote_unquote(T2),
    <<"( unquote ", Atom/binary, " ) ",T3/binary>>;
quote_unquote(<<X, T/binary>>) ->
    T2 = quote_unquote(T),
    <<X, T2/binary>>;
quote_unquote(X) -> X.

quote_unquote_atom(B) ->
    qua2(B, <<>>).
qua2(<<32, T2/binary>>, X) -> {X, T2};%space
qua2(<<10, T2/binary>>, X) -> {X, T2};%newline
qua2(<<L, R/binary>>, X) ->
    qua2(R, <<X/binary, L>>).
    
    
