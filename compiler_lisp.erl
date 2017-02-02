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
    Tree = hd(to_lists(Words)),
    %get macros
    %apply macros
    %rename vars in functions. That way we have dynamic scope. Replace every first var with V1, second with V2, etc.
    %get functions. load up a dictionary of the functions
    Functions = get_functions(Tree),
    %apply functions. replace the function's name with the hash of it's contents.
    var_number_check(Tree, Functions),%checks that every function has the right number of inputs.
    List = rpn(Tree),
    List2 = remove_functions(List),%functions are named by the hash of their contents. So remove the names from the code.
    Opcodes = to_opcodes(List2, Functions, Variables),
    {Words, Tree, Tree2, Opcodes}.
remove_functions(_) ->
     ok.
    
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
w2o(<<"+">>) ->
    {50, 2, 1};%{opcode, inputs, outputs}
w2o(<<"*">>) ->
    {52, 2, 1};
%w2o(<<"int">>) ->%its an integer
%    {0, 1, 1};
w2o(<<"define">>) ->
    {59, 3, 0};
w2o(X) -> 
    B = is_int(X),
    if
	B -> {int, X, 0, 1};
	true -> 
	    C = is_64(X),
	    if
		C -> {is_64, X, 0, 1};
		true ->
		    not_op
	    end
    end.
is_int(<<>>) -> true;
is_int(<<X:8, Y/binary>>) -> 
    ((X>47) and (X<57)) and is_int(Y).
-define(binary, <<45:8, 45:8>>).
is_64(<<?binary/binary, Y/binary>>) ->
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
    <<?binary/binary, Y/binary>>.
decode(X) ->
    <<?binary/binary, Y/binary>>,
    base64:decode(Y).
    
var_number_check([], F) -> 0;
var_number_check([H|T], F) -> 
    {In, Out} = 
	case get_dict(H, F) of
	    {error, undefined_function} ->
		{_Op, I, Ot} = w2o(H),
		{I, Ot};
	    Z ->
		{Z#func.in, Z#func.out}
	end,
    In = var_number_check2(T),
    Out.

var_number_check2([]) -> 0;
var_number_check2([H|T]) when is_list(H) ->
    var_number_check(H) + 
	var_number_check2(T);
var_number_check2([H|T]) ->
    1+var_number_check2(T).
rpn([]) ->  [];
rpn([H|T]) -> 
    rpn2(T) ++ [H].
rpn2([]) -> [];
rpn2([H|T]) when is_list(H) ->
    [rpn(H)|rpn2(T)];
rpn2([H|T]) ->
    [H|rpn2(T)].
to_opcodes(Tree, Funcs, Vars) -> 
    List = flatten(Tree),
    to_ops(List, Funcs, Vars).
flatten([]) -> [];
flatten([H|T]) -> 
    flatten(H) ++ flatten(T);
flatten(X) -> [X].
to_ops([], _, _) -> [];
to_ops([H|T], Funcs, Vars) -> 
    {X, V2} = case w2o(H) of
	    {Op, _, _} -> 
		{[Op], Vars};
	    {int, Op, _, _} ->
		{[0, Op], Vars};
	    {is_64, Op, _, _} ->
		S = size(decode(Op)),
		{[2, <<S:32>>, Op], Vars};
	    not_op ->
		case get_dict(X, Funcs) of
		    {error, undefined_function} ->
			%so it is a variable then.
			{Y, Vars2} = absorb_var(X, Vars),
			{[Y|Out], Vars2};
		    Z ->
			S = size(Z),
			%io:fwrite("hash of function is "),
			Y = <<2, S:32, Z/binary>>,
			{[Y|Out], Vars}
		end
	end,
    X ++ to_ops(T, Funcs, V2).
    
absorb_var(Variable, {D, Many}) ->
    <<X:8, _/binary>> = Variable,
    B = ((X > 64) and (X < 90))
	or ((X>96) and (X < 122)),
    if 
	B -> ok;
	true ->
	    io:fwrite("absorb var error "),
	    io:fwrite(Variable),
	    io:fwrite("  \n"),
	    X = 0
    end,
    %true = X > 64, %variables start with capitals
    %true = X < 90,
    case dict:find(Variable, D) of
	error ->
	    NewD = dict:store(Variable, Many, D),
	    {<<0, Many:32>>, {NewD, Many+1}};
	{ok, Var} ->
	    {<<0, Var:32>>, {D, Many}}
    end.
   
get_func(Key, Funcs) -> 
    dict:fetch(Key, Funcs).
get_functions(Tree) ->
    get_functions(Tree, dict:new(), {dict:new(), 1}).
get_functions([<<"define">>|[Name|[Vars|Code]]], Functions, Variables) ->
    Opcodes = compile_func(Name, Vars, Code, Functions, Variables),
    %Opcodes = to_opcodes(Code, Functions, Variables2),
    Signature = hash:doit(Opcodes),
    case dict:find(Name, Functions) of
	error ->
	    NewFunctions = dict:store(Name, Signature, Functions),
	    NewFunctions;
	{X, _} ->
	    io:fwrite("can't name 2 functions the same. reused name: "),
	    io:fwrite(Name),
	    io:fwrite("\n"),
	    X = okay
    end;
get_functions([H|T], Functions, Variables) ->
    F2 = get_functions(H, Functions, Variables),
    get_functions(T, F2, Variables);
get_functions(_, F, _) ->
    F.


define_vars([], Name, Variables, Out) -> {Out, Variables};
define_vars([V|T], Name, Variables, Out) -> 
    {Y, Variables2} = absorb_var(V++Name, Variables),
    define_vars(T, Name, Variables2, [Y|Out]).
    
compile_func(Name, Vars, Code, Functions, Variables) ->
    V2 = lists:reverse(Vars),
    {Out, Variables2} = define_vars(V2, Name, Variables, []),
    Code2 = replace_vars(Code, Vars, Name),
    {Out ++ Code2, Variables2}.
    











dictify([], _, D) -> D;
dictify([V|T], N, D) -> 
    NewD = dict:store(V, 274877906943 - N),
    dictify(T, N+1, NewD).
   
absorb_vars(Name, [V|T], Variables) -> 
    {Y, Variables2} = absorb_var(<<Name/binary, V/binary>>, Variables),
    {YL, Variables3} = absorb_vars(Name, T, Variables2),
    {[Y|YL], Variables3}. 
    
compile_func(FuncName, Vars, Code, Variables) ->
    V = absorb_vars(Name, Vars, Variables),
    Keys = dict:fetch_keys(V),
    load_vars(lists:reverse(lists:sort(Keys))) 
	++ compile_code(Code, Keys, V, Variables).
load_vars([]) -> [];
load_vars([H|T]) -> 
    [H|[33|load_vars(T)]].
compile_code(Code, Keys, V, Variables) ->
    Code2 = replace_vars(Code, V),
    to_opcodes(Code, Functions, Variables).
    
    %example
    % (x y) (* x y)
    % Y ! X ! X @ Y @ *
