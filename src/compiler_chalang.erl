-module(compiler_chalang).
-export([doit/1, print_binary/1]).

%-define(or_die, compile(<<" not if return else then ">>)).
%-define(plus_store, compile(<<" dup @ rot + swap ! ">>)).
-define(int_bits, 32).

doit(A) when is_list(A) ->
    doit(list_to_binary(A));
doit(A) ->
    %Test to make sure : and ; are alternating the whole way, or give an intelligent error.
    %Give error message if we define the same function twice.
    B = << <<" ">>/binary, A/binary, <<" \n">>/binary>>,
    C = remove_comments(B),
    D = add_spaces(C),
    E = parse_strings(D),
    Words = to_words(E, <<>>, []),
    Macros = get_macros(Words),
    YWords = remove_macros(Words),
    ZWords = apply_macros(Macros, YWords),
    {Functions, Variables} = get_functions(ZWords),
    %io:fwrite("FINISHED GETTING FUNCTIONS"),
    BWords = remove_functions(ZWords),
    %BWords = apply_functions(AWords, Functions),
    reuse_name_check(Macros, Functions),
    %io:fwrite(BWords),
    {X, _} = to_opcodes(BWords, Functions, [], Variables),
    %print_binary(X),
    X.
parse_strings(<<>>) -> <<>>;
parse_strings(<<".\" ", Rest/binary>>) -> 
    {S, B} = start_string(Rest, <<>>),
    B2 = parse_strings(B),
    <<S/binary, B2/binary>>;
parse_strings(<<C, Rest/binary>>) -> 
    B = parse_strings(Rest),
    <<C, B/binary>>.
start_string(<<"\"", Rest/binary>>, S) ->
    S2 = <<" binary ",(integer_to_binary(size(S)))/binary, " ", (base64:encode(S))/binary, " ">>,
    {S2, Rest};
start_string(<<C, Rest/binary>>, S) ->
    start_string(Rest, <<S/binary, C>>).
    
add_spaces(B) -> add_spaces(B, <<"">>).
add_spaces(<<"">>, B) -> B;
add_spaces(<<40:8, B/binary >>, Out) ->  % "("
    add_spaces(B, <<Out/binary, 32:8, 40:8, 32:8>>);
add_spaces(<<41:8, B/binary >>, Out) ->  % ")"
    add_spaces(B, <<Out/binary, 32:8, 41:8, 32:8>>);
add_spaces(<<91:8, B/binary >>, Out) ->  % "["
    add_spaces(B, <<Out/binary, 32:8, 91:8, 32:8>>);
add_spaces(<<93:8, B/binary >>, Out) ->  % "]"
    add_spaces(B, <<Out/binary, 32:8, 93:8, 32:8>>);
add_spaces(<<58:8, B/binary >>, Out) ->  % ":"
    add_spaces(B, <<Out/binary, 32:8, 58:8, 32:8>>);
add_spaces(<<59:8, B/binary >>, Out) ->  % ";"
    add_spaces(B, <<Out/binary, 32:8, 59:8, 32:8>>);
add_spaces(<<44:8, B/binary >>, Out) ->  % ","
    add_spaces(B, <<Out/binary, 32:8, 44:8, 32:8>>);
add_spaces(<<X:8, B/binary >>, Out) -> 
    add_spaces(B, <<Out/binary, X:8>>).
reuse_name_check(Macros, Functions) ->
    MacroKeys = dict:fetch_keys(Macros),
    FunctionKeys = dict:fetch_keys(Functions),
    L = repeats(MacroKeys ++ FunctionKeys),
    Bool = 0 == length(L),
    if
	Bool -> ok;
	true -> io:fwrite("error. you reused a name more than once."),
		io:fwrite(packer:pack(L)),
		Bool == true
    end.
repeats([]) -> [];
repeats([H|T]) -> 
    B = is_in(H, T),
    if
	B -> [H|repeats(T)];
	true -> repeats(T)
    end.
is_in(_, []) -> false;
is_in(A, [A|_]) -> true;
is_in(A, [_|T]) -> is_in(A, T).
remove_comments(B) -> remove_comments(B, <<"">>).
remove_comments(<<"">>, Out) -> Out;
remove_comments(<<40:8, B/binary >>, Out) -> % [40] == "(".
    C = remove_till(41, B), % [41] == ")".
    remove_comments(C, Out);
remove_comments(<<37:8, B/binary >>, Out) -> % [37] == "%".
    C = remove_till(10, B), %10 is '\n'
    remove_comments(C, Out);
remove_comments(<<X:8, B/binary>>, Out) -> 
    remove_comments(B, <<Out/binary, X:8>>).
remove_till(N, <<N:8, B/binary>>) -> B;
remove_till(N, <<_:8, B/binary>>) -> 
    remove_till(N, B).
remove_macros(Words) -> remove_macros(Words, []).
remove_macros([], Out) -> Out;
remove_macros([<<"macro">>|Words], Out) ->
    {_, B} = split(<<";">>, Words),
    remove_macros(B, Out);
remove_macros([W|Words], Out) ->
    remove_macros(Words, Out ++ [W]).
apply_macros(Macros, Words) -> apply_macros(Macros, Words, []).
apply_macros(_, [], Out) -> Out;
apply_macros(Macros, [W|Words], Out) -> 
    NOut = case dict:find(W, Macros) of
	       error -> Out ++ [W];
	       {ok, Val} -> Out ++ Val
	   end,
    apply_macros(Macros, Words, NOut).

get_macros(Words) ->
    get_macros(Words, dict:new()).
get_macros([<<"macro">>|[Name|R]], Functions) ->
    case dict:find(Name, Functions) of
	error ->
	    {Code, T} = split(<<";">>, R),
	    Code2 = apply_macros(Functions, Code),
	    NewFunctions = dict:store(Name, Code2, Functions),
	    get_macros(T, NewFunctions);
	{X, _} ->
	    io:fwrite("can't name 2 macros the same. reused name: "),
	    io:fwrite(Name),
	    io:fwrite("\n"),
	    X = okay
    end;
get_macros([], Functions) -> Functions;
get_macros([_|T], Functions) -> get_macros(T, Functions).

get_functions(Words) -> get_functions(Words, dict:new(), {dict:new(), 1}). %this initializes variables on 1, because setelement starts at 1.

get_functions([Y|[Name|R]], Functions, Variables) when (Y == <<":">>)->
    %Make sure Name isn't on the restricted list.
    {Code, T} = split(<<";">>, R),
    {Opcodes, Variables2} = to_opcodes(Code, Functions, [], Variables),
    Signature = hash:doit(Opcodes, chalang_constants:hash_size()),
    case dict:find(Name, Functions) of
	error ->
	    NewFunctions = dict:store(Name, Signature, Functions),
	    get_functions(T, NewFunctions, Variables2);
	{X, _} ->
	    io:fwrite("can't name 2 functions the same. reused name: "),
	    io:fwrite(Name),
	    io:fwrite("\n"),
	    X = okay
    end;
get_functions([], Functions, Vars) -> {Functions, Vars};
get_functions([_|T], Functions, Vars) -> get_functions(T, Functions, Vars).
split(C, B) -> split(C, B, []).
split(C, [C|B], Out) -> {flip(Out), B};
split(C, [D|B], Out) ->
    split(C, B, [D|Out]).
remove_functions(Words) -> rad(Words, []).
rad([], Out) -> flip(Out);
rad([<<":">>|[_|T]], Out) -> rad(T, [<<":">>|Out]);
rad([<<"def">>|T], Out) -> rad(T, [<<"def">>|Out]);
rad([X|T], Out) -> rad(T, [X|Out]).
to_opcodes([<<"int">>|[B|T]], F, Out, V) ->
    Num = binary_to_integer(B),
    if
        Num < 0 ->
            io:fwrite("no negatives!"),
            1=2;
        Num < 36 ->
            Num2 = Num + 140,
            G = <<Num2:8>>,
            to_opcodes(T, F, [G|Out], V);
        Num < 256 ->
            G = <<Num:8>>,
            to_opcodes(T, F, [G|[3|Out]], V);
        Num < 65536 ->
            G = <<Num:16>>,
            to_opcodes(T, F, [G|[4|Out]], V);
        Num < 4294967296 ->
            G = <<Num:?int_bits>>,
            to_opcodes(T, F, [G|[0|Out]], V)
    end;
to_opcodes([<<"int4">>|[B|T]], F, Out, V) ->
    Num = binary_to_integer(B),
    G = <<Num:?int_bits>>,
    to_opcodes(T, F, [G|[0|Out]], V);
to_opcodes([<<"int1">>|[B|T]], F, Out, V) ->
    Num = binary_to_integer(B),
    G = <<Num:8>>,
    to_opcodes(T, F, [G|[3|Out]], V);
to_opcodes([<<"int2">>|[B|T]], F, Out, V) ->
    Num = binary_to_integer(B),
    G = <<Num:16>>,
    to_opcodes(T, F, [G|[4|Out]], V);
to_opcodes([<<"int0">>|[B|T]], F, Out, V) ->
    Num0 = binary_to_integer(B),
    true = Num0 < 36,
    true = Num0 > -1,
    Num = Num0 + 140,
    G = <<Num:8>>,
    to_opcodes(T, F, [G|Out], V);
to_opcodes([<<"binary">>|[M|[B|T]]], F, Out, V) ->
    %io:fwrite("binary\n"),
    Bin = base64:decode(B),
    MM = binary_to_integer(M),
    if
        MM == size(Bin) -> ok;
        true ->
            io:fwrite("wrong size of binary \n"),
            io:fwrite(integer_to_list(MM)),
            io:fwrite("\n"),
            io:fwrite(integer_to_list(size(Bin))),
            io:fwrite("\n"),
            1=2
    end,
    to_opcodes(T, F, [Bin|[<<MM:32>>|[2|Out]]], V);
to_opcodes([Word|T], F, Out, Vars) ->
    case w2o(Word) of
	not_op ->
	    case get_func(Word, F) of
		{error, "undefined function"} ->
						%So it is a variable then.
		    {Y, Vars2} = absorb_var(Word, Vars),
		    to_opcodes(T, F, [Y|Out], Vars2);
		Z -> 
		    S = size(Z),
		    %io:fwrite("hash of function is "),
		    %print_binary(Z),
		    Y = <<2, S:32, Z/binary>>,
		    to_opcodes(T, F, [Y|Out], Vars)
	    end;
	
	Op ->
	    to_opcodes(T, F, [Op|Out], Vars)
    end;
to_opcodes([], _, Out, Vars) ->
    X = lists:reverse(Out),
    {make_binary(X), Vars}.
get_func(Name, F) -> %name should be like <<"square">>
    %io:fwrite("get func named "),
    %io:fwrite(Name),
    %io:fwrite("\n"),
    %io:fwrite(dict:fetch_keys(F)),
    case dict:find(Name, F) of
	error ->
	    %io:fwrite("error, that is not a defined function\n;"),
	    {error, "undefined function"};
	{ok, Val} ->
	    Val
    end.
make_binary(L) ->
    make_binary(L, <<>>).
make_binary([], X) -> X;
make_binary([H|T], B) when is_integer(H) ->
    make_binary(T, <<B/binary, H:8>>);
make_binary([H|T], B) ->
    make_binary(T, <<B/binary, H/binary>>).

w2o(<<"int">>) -> 0;
w2o(<<"binary">>) -> 2;
w2o(<<"int1">>) -> 3;
w2o(<<"int2">>) -> 4;
w2o(<<"int0">>) -> w2o(<<"nop">>);
w2o(<<"print">>) -> 10;
w2o(<<"return">>) -> 11;
w2o(<<"nop">>) -> 12;
w2o(<<"fail">>) -> 13;
w2o(<<"drop">>) -> 20;
w2o(<<"dup">>) -> 21;
w2o(<<"swap">>) -> 22;
w2o(<<"tuck">>) -> 23;
w2o(<<"rot">>) -> 24;
w2o(<<"2dup">>) -> 25;
w2o(<<"ddup">>) -> 25;
w2o(<<"tuckn">>) -> 26;
w2o(<<"pickn">>) -> 27;
w2o(<<">r">>) -> 30;
w2o(<<"r>">>) -> 31;
w2o(<<"r@">>) -> 32;
w2o(<<"hash">>) -> 40;
w2o(<<"verify_sig">>) -> 41;
w2o(<<"verify_account_sig">>) -> 42;
w2o(<<"+">>) -> 50;
w2o(<<"-">>) -> 51;
w2o(<<"*">>) -> 52;
w2o(<<"/">>) -> 53;
w2o(<<">">>) -> 54;
w2o(<<"<">>) -> 55;
w2o(<<"^">>) -> 56;
w2o(<<"rem">>) -> 57;
w2o(<<"==">>) -> 58;
w2o(<<"=2">>) -> 59;
w2o(<<"if">>) -> 70;
w2o(<<"else">>) -> 71;
w2o(<<"then">>) -> 72;
w2o(<<"not">>) -> 80;
w2o(<<"and">>) -> 81;
w2o(<<"or">>) -> 82;
w2o(<<"xor">>) -> 83;
w2o(<<"band">>) -> 84;
w2o(<<"bor">>) -> 85;
w2o(<<"bxor">>) -> 86;
w2o(<<"stack_size">>) -> 90;
w2o(<<"id2balance">>) -> 91;
w2o(<<"pub2addr">>) -> 92;
w2o(<<"total_coins">>) -> 93;
w2o(<<"height">>) -> 94;
w2o(<<"slash">>) -> 95;
w2o(<<"gas">>) -> 96;
w2o(<<"ram">>) -> 97;
w2o(<<"id2pub">>) -> 98;
w2o(<<"id2addr">>) -> 98;
w2o(<<"oracle">>) -> 99;
w2o(<<"many_vars">>) -> 100;
w2o(<<"many_funs">>) -> 101;
w2o(<<":">>) -> 110;
w2o(<<"def">>) -> 114;
w2o(<<";">>) -> 111;
w2o(<<"recurse">>) -> 112;
w2o(<<"call">>) -> 113;
w2o(<<"!">>) -> 120;
w2o(<<"@">>) -> 121;
w2o(<<"cons">>) -> 130;
w2o(<<"car">>) -> 131;
w2o(<<"nil">>) -> 132;
w2o(<<"++">>) -> 134;
w2o(<<"split">>) -> 135;
w2o(<<"reverse">>) -> 136;
w2o(<<"is_list">>) -> 137;
w2o(_) -> not_op.
%to_opcodes([<<"or_die">>|R], F, Out) ->
    %( bool -- )
    %if bool is true, ignore. if bool is false, then return.
%    to_opcodes(R, F, flip(?or_die) ++ Out);
%to_opcodes([<<"+!">>|R], F, Out) ->
    %( 5 N -- ) in this exampe N increments by 5.
%    to_opcodes(R, F, flip(?plus_store) ++ Out);
%to_opcodes([], _, Out) -> flip(Out);
to_words(<<>>, <<>>, Out) -> flip(Out);
to_words(<<>>, N, Out) -> flip([N|Out]);
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
flip(X) -> flip(X, []).
flip([], Out) -> Out;
flip([H|T], Out) -> flip(T, [H|Out]).
print_binary({error, R}) ->
    io:fwrite("error! \n"),
    io:fwrite(R),
    io:fwrite("\n"); 
print_binary(<<A:8, B/binary>>) ->
    io:fwrite(integer_to_list(A)),
    io:fwrite("\n"),
    print_binary(B);
print_binary(<<>>) -> ok.
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
            if
                (Many < 36) ->
                    {<<(140 + Many):8>>, {NewD, Many+1}};
                (Many < 256) ->
                    {<<3, Many:8>>, {NewD, Many+1}};
                true ->
                    {<<0, Many:32>>, {NewD, Many+1}}
            end;
        {ok, Var} when (Var < 36) ->
            {<<(140+Var):8>>, {D, Many}};
	{ok, Var} when (Var < 256) ->
	    {<<3, Var:8>>, {D, Many}};
	{ok, Var} ->
	    {<<0, Var:32>>, {D, Many}}
    end.
    
				
