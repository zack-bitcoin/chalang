
%If the compiler is written in macros, it is easier to understand, and modify.

-module(compiler_lisp).
-export([doit/1, test/0]).
%-define(int_bits, 32).
%-define(int, 0).
%-define(binary, 2).
%-define(define, 110).
%-define(define2, 114).
%-define(fun_end, 111).
test() ->
    Files = [ 
              %"rationals",
              %"fun_test5",
	      "let",
              %"dice",
	      "fun_test4",
	      "fun_test",
	      "macro_basics",
	      "flatten_test",
	      "enum_test",
	      "append_test",
	      "eqs_test",
	      "case", 
	      "hashlock",
	      "first_macro", "square_each_macro", 
	      "primes", 
	      "gcf",
	      "map_test",
	      "sort_test",
              "rat_test",
              %"rationals",
              "sqrt",%slow to compile
              "binary_convert"
	    ],
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
    %io:fwrite(Tree1),
    %io:fwrite("\n"),
    %io:fwrite(packer:pack(Tree1)),
    %io:fwrite("\n"),
    %Tree1 = quote_list(Tree),
    io:fwrite("Macros\n"),
    Tree2_0 = integers(Tree1),
    Tree2_1 = macro_names(Tree2_0),
    %io:fwrite(Tree2_1),
    FNs = function_names(Tree2_1),
    Tree2 = apply_funs(FNs, Tree2_1),
    {Tree3, _} = macros(Tree2, dict:new()),
    io:fwrite("rpn\n"),
    %io:fwrite(Tree3),
    Tree35 = rpn(Tree3),%change to reverse polish notation.
    List = flatten(Tree35),
    List1 = just_in_time(List),
    List2 = variables(List1, {dict:new(), 1}),
    Funcs = dict:new(),
    List4 = to_ops(List2, Funcs),
    %{List5, _} = lambdas(List4, []),
    %io:fwrite("--------------------\n"),
    disassembler:doit(List4),
    io:fwrite("===========================\n"),
    Gas = 10000,
    VM = chalang:vm(List4, Gas*100, Gas*10, Gas, Gas, []),
    {{%Tree1, Tree3, Tree35, 
      List %List1, List4, List5
      }, VM}.
r_collapse([], _, _) ->
    false;
%%    io:fwrite("unbalanced >r and r>\n"),
%    ok;
r_collapse([<<">r">>|T], _, A) ->
    false;
r_collapse([I|T], N, A) when is_integer(I) ->
    r_collapse(T, N+1, A ++ [I]);
r_collapse([<<"r>">>|T], 0, A) ->
    A ++ T;%success
r_collapse([<<"r>">>|T], _, A) ->
    false;
r_collapse(_, N, _) when (N < 0) -> false;
r_collapse([Op|T], N, A) ->
    {B, _, Take, Give} = is_op(Op),
    if
	B -> r_collapse(T, N+Give-Take, A++[Op]);
	true -> false
    end.
just_in_time(X0) ->
    %io:fwrite(X0),
    %io:fwrite("\n"),
    %io:fwrite("\n"),
    X1 = just_in_time2(X0),
    X2 = func_input_simplify(X1),
    if 
	(X2 == X0) -> X2;
	true -> just_in_time(X2)
    end.
%for every >r we should look ahead in the code to see if we actually need to use the r stack. maybe we can leave this variable on the main stack until it is needed.
func_input_simplify([<<"r@">>,N,<<"+">>,<<"!">>,<<"r@">>,N,<<"+">>,<<"@">>|R]) when is_integer(N)->
    B = no_rff(N, R),
    X = if
        B -> [];
        true -> [<<"dup">>,<<"r@">>,N,<<"+">>,<<"!">>]
    end,
    X ++ func_input_simplify(R);
func_input_simplify([<<"r@">>,<<"!">>,<<"r@">>,<<"@">>|R]) ->
    %if there is only one `r@ @` until the function ends, then there must be a way to just leave it on the stack.
    B = no_rff0(R),
    %B = false,
    X = if
            B -> [];
            true -> [<<"dup">>,<<"r@">>,<<"!">>]
        end,
    X ++ func_input_simplify(R);
func_input_simplify([X|T]) ->
    [X|func_input_simplify(T)];
func_input_simplify([]) -> [].
no_rff0([<<"end_fun">>|_]) -> true;
no_rff0([<<"r@">>,<<"@">>|_]) -> false;
no_rff0([X|T]) -> no_rff0(T).

no_rff(_, [<<"end_fun">>|_]) -> true;
no_rff(N, [<<"r@">>,N,<<"+">>,<<"@">>|_]) -> false;
no_rff(N, [X|T]) -> no_rff(N, T).
            
just_in_time2([<<"dup">>,<<">r">>,<<"dup">>,<<"r>">>|R]) -> 
    [<<"dup">>,<<"dup">>|just_in_time2(R)];
just_in_time2([<<"rot">>, <<"tuck">>|R]) -> 
    just_in_time2(R);
just_in_time2([<<"tuck">>, <<"rot">>|R]) -> 
    just_in_time2(R);
just_in_time2([<<"swap">>, <<"swap">>|R]) -> 
    just_in_time2(R);
just_in_time2([<<"dup">>, <<"drop">>|R]) -> 
    just_in_time2(R);
just_in_time2([<<">r">>, <<"r>">>|R]) -> 
    just_in_time2(R);
just_in_time2([<<"r>">>, <<">r">>|R]) -> 
    just_in_time2(R);

%we want to use the variables in last-in-first-out order if possible, since this often leads to more opportunities to optimize.
just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, N, <<"+">>, <<"@">>|R]) when is_integer(N)-> 
    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"r@">>, <<"@">>, <<"swap">>|R]);
just_in_time2([<<"r@">>, M, <<"+">>, <<"@">>, <<"r@">>, N, <<"+">>, <<"@">>|R]) when ((is_integer(N) and is_integer(M)) and (M < N))-> 
    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"r@">>, M, <<"+">>, <<"@">>, <<"swap">>|R]);

%using the first function var three in a row
just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, <<"@">>, <<"r@">>, <<"@">>|R]) -> 
    just_in_time2([<<"r@">>, <<"@">>, <<"dup">>, <<"dup">>|R]);
%using the first function var twice in a row
just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, <<"@">>|R]) -> 
    just_in_time2([<<"r@">>|[<<"@">>|[<<"dup">>|R]]]);


%using the Nth first function var twice in a row
just_in_time2([<<"r@">>|[N|[<<"+">>|[<<"@">>|[<<"r@">>|[N|[<<"+">>|[<<"@">>|R]]]]]]]]) when is_integer(N)-> 
    just_in_time2([<<"r@">>|[N|[<<"+">>|[<<"@">>|[<<"dup">>|R]]]]]);

%for the symmetric functions +, *, and =, we should try and push variables to the left and constants to the right so that we can simplify the function definitions.
%there are more symmetric functions we might want to do this with: and or xor band bor bxor
just_in_time2([N,<<"r@">>,M,<<"+">>,<<"@">>,<<"===">>|R]) when (((N== <<"nil">>) or (is_integer(N))) and is_integer(M))->
    just_in_time2([<<"r@">>,M,<<"+">>,<<"@">>,N,<<"===">>|R]);
just_in_time2([N,<<"r@">>,M,<<"+">>,<<"@">>,<<"*">>|R]) when (is_integer(N) and is_integer(M))->
    just_in_time2([<<"r@">>,M,<<"+">>,<<"@">>,N,<<"*">>|R]);
just_in_time2([N,<<"r@">>,M,<<"+">>,<<"@">>,<<"+">>|R]) when is_integer(N)->
    just_in_time2([<<"r@">>, M,<<"+">>, <<"@">>,N,<<"+">>|R]);
just_in_time2([N,<<"r@">>,<<"@">>,<<"===">>|R]) when ((N == <<"nil">>) or (is_integer(N)))->
    just_in_time2([<<"r@">>, <<"@">>,N,<<"===">>|R]);
just_in_time2([N,<<"r@">>,<<"@">>,<<"*">>|R]) when is_integer(N)->
    just_in_time2([<<"r@">>, <<"@">>,N,<<"*">>|R]);
just_in_time2([N,<<"r@">>,<<"@">>,<<"+">>|R]) when is_integer(N)->
    just_in_time2([<<"r@">>, <<"@">>,N,<<"+">>|R]);

%try to keep constants to the right, and variables to the left
just_in_time2([N, <<"r@">>, <<"@">>|R]) when ((N == <<"nil">>) or (is_integer(N)))->
    just_in_time2([<<"r@">>, <<"@">>, N, <<"swap">>|R]);
just_in_time2([N, <<"r@">>, M, <<"+">>, <<"@">>|R]) when (((N == <<"nil">>) or (is_integer(N))) and (is_integer(M))) ->
    just_in_time2([<<"r@">>, M, <<"+">>, <<"@">>, N, <<"swap">>|R]);
%multiplying by 1 is the same as doing nothing
just_in_time2([1|[<<"*">>|R]]) -> 
    just_in_time2(R);
%adding 0 is the same as doing nothing
just_in_time2([0|[<<"+">>|R]]) -> 
    just_in_time2(R);
%the nop operation does nothing, so we can delete it.
just_in_time2([<<"nop">>|R]) -> 
    just_in_time2(R);

%if we are doing math with 2 constants, this is something that can be done at compile time.
just_in_time2([N, M, <<"+">>|R]) 
  when ((is_integer(N)) and (is_integer(M))) ->
    just_in_time2([(N + M)|R]);
just_in_time2([N|[M|[<<"-">>|R]]]) 
  when ((is_integer(N)) and (is_integer(M))) ->
    just_in_time2([(N - M)|R]);
just_in_time2([N|[M|[<<"*">>|R]]]) 
  when ((is_integer(N)) and (is_integer(M))) ->
    just_in_time2([(N * M)|R]);
just_in_time2([N|[M|[<<"/">>|R]]]) 
  when ((is_integer(N)) and (is_integer(M))) ->
    just_in_time2([(N div M)|R]);
%just_in_time2([<<">r">>|R]) ->
%    R2 = r_collapse(R, 0, []),
%    io:fwrite(R2),
%    case R2 of
%	false -> [<<">r">>|just_in_time2(R)];
%	_ -> just_in_time2(R2)
%    end;
just_in_time2([A|B]) ->
    [A|just_in_time2(B)];
just_in_time2(A) -> A.

imports([<<"import">>, []], Done) -> {[], Done};
imports([<<"import">>, [H|T]], Done) ->
    %io:fwrite("importing "),
    %io:fwrite(H),
    B = is_in(H, Done),
    {Tree, Done2} = 
	if
	    B -> {[], Done};
	    true ->		
		{ok, File} = file:read_file("src/lisp/" ++ binary_to_list(H)),
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
function_names([[<<"define">>, Name, _, _]|T]) when not(is_list(Name))->
    [Name] ++ function_names(T);
function_names([[<<"define">>, Name|_]|T]) ->
    [hd(Name)] ++ function_names(T);
function_names([H|T]) when is_list(H) ->
    function_names(H) ++ function_names(T);
function_names([H|T]) ->
    function_names(T);
function_names([]) -> [].
apply_funs([H|T], Code) ->
    apply_funs(T, apply_fun(H, Code));
apply_funs([], Code) -> Code.
apply_fun(_Name, []) -> [];
apply_fun(Name, [[<<"define">>, Name2, Vars, Code]|T]) ->
    [[<<"define">>, Name2, Vars, apply_fun(Name, [Code])]|apply_fun(Name, T)];
apply_fun(Name, [[<<"define">>, Vars, Code]|T]) ->
    [[<<"define">>, hd(Vars), tl(Vars), apply_fun(Name, [Code])]|apply_fun(Name, T)];
apply_fun(Name, [[Name|T1]|T2])->
    [[<<"execute2">>,[Name|apply_fun(Name, T1)]]|
     apply_fun(Name, T2)];
%apply_fun(Name, [Name|T]) ->
%    [<<"execute2">>, [Name|apply_fun(Name, T)]];
apply_fun(Name, [H|T]) when is_list(H) ->
    [apply_fun(Name, H)|
     apply_fun(Name, T)];
apply_fun(Name, [H|T]) ->
    [H|apply_fun(Name, T)].
    
macro_names([<<"macro">>, Name, Vars, Code]) ->
    Vars2 = macro_unique_vars(Name, Vars, Vars),
    Code2 = macro_unique_vars(Name, Vars, Code),
    [<<"macro">>, Name, Vars2, Code2];
macro_names([H|T]) when is_list(H) ->
    [macro_names(H)|macro_names(T)];
macro_names([H|T]) ->
    [H|macro_names(T)];
macro_names([]) -> [].
macro_unique_vars(Name, [], Code) -> Code;
macro_unique_vars(Name, [H|T], Code) ->
    macro_unique_vars(Name, T, macro_unique_vars2(Name, H, Code)).
macro_unique_vars2(Name, Var, []) -> [];
macro_unique_vars2(Name, Var, [H|T]) ->
    [macro_unique_vars2(Name, Var, H)|
     macro_unique_vars2(Name, Var, T)];
macro_unique_vars2(Name, Var, Var) ->
    <<Var/binary, Name/binary>>;
macro_unique_vars2(Name, Var, H) ->
    H.
    
macros([<<"macro">>, Name, Vars, Code], D) ->
    D2 = dict:store(Name, {Vars, Code}, D),
    {[], D2};
macros([<<"macro">>|[Name|_]], _) ->
    io:fwrite("\n\nerror, macro named "),
    io:fwrite(Name),
    io:fwrite(" has the wrong number of inputs\n\n");
macros([<<"quote">>|T], D) ->
    {[<<"quote">>|T], D};
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
	    T2 = apply_macro(H, Code, Vars, T3, D2),
	    %T2 = apply_macro(Code, Vars, T, D),
	    macros(T2, D2)
    end;
macros(X, D) -> {X, D}.
   
apply_macro(_, Code, [], [], D) ->
    lisp(Code, D);
apply_macro(Name, Code, [V|Vars], [H|T], D) ->%D is a dict of the defined macros.
    %V is the name given in the definition of the macro.
    %H is the name given when calling the macro in the code.
    Code2 = replace(Code, V, H),
    apply_macro(Name, Code2, Vars, T, D);
apply_macro(Name,_,_,_,_) ->
    io:fwrite("\nwrong number of inputs to macro "),
    io:fwrite(Name),
    io:fwrite("\n"),
    C = -1.
replace([], _, _) -> [];
replace([H|T], A, B) ->
    [replace(H, A, B)|
     replace(T, A, B)];
replace(A, A, B) -> B;
replace(X, _, _) -> X.
lisp_quote([[<<"unquote">>|T]|T2], D) -> 
    %{A, _} = macros(T, D),
    [lisp(T, D)|
     lisp_quote(T2, D)];
lisp_quote([H|T], D) -> 
    [lisp_quote(H, D)|
     lisp_quote(T, D)];
lisp_quote(X, _) -> X.
bool_atom_to_int(true) -> 1;
bool_atom_to_int(false) -> 0.
lisp([<<"quote">>|T], D) -> lisp_quote(T, D);
lisp([<<"cond">>, T], D) -> lisp(lisp_cond(T, D), D);
lisp([<<"execute">>,[<<"quote">>, F],A], D) ->
    case dict:find(F, D) of
	error ->
	    io:fwrite("no function named "),
	    io:fwrite(F),
	    io:fwrite("\n"),
	    1=2;
	{ok, {Vars, Code}} ->
	    {T3, D2} = macros(A, D),
	    T4 = lisp(T3, D2),
	    T2 = apply_macro(F, Code, Vars, T4, D2),
	    lisp(T2, D2)
    end;
lisp([<<"execute">>,F,A], D) ->
    io:fwrite("bad execute!!\n"),
    io:fwrite([F, A]),
    lisp([<<"execute">>,[<<"quote">>, F],A], D);
lisp([<<">">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    bool_atom_to_int(C > D);
lisp([<<"<">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    bool_atom_to_int(C < D);
lisp([<<"is_list">>, A], F) ->
    {A2, _} = macros(A, F),
    B = lisp(A2, F),
    bool_atom_to_int(is_list(B));
lisp([<<"is_atom">>, [<<"quote">>, X]], F) when is_binary(X) ->
    bool_atom_to_int(true);
lisp([<<"is_atom">>, _], F) ->
    bool_atom_to_int(false);
lisp([<<"is_number">>, X], F) ->
    bool_atom_to_int(is_integer(X));
lisp([<<"=">>, A, B], D) ->
    {A3, _} = macros(A, D),
    A2 = lisp(A3, D),
    {B3, _} = macros(B, D),
    B2 = lisp(B3, D),
    bool_atom_to_int(A2 == B2);
lisp([<<"+">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    C + D;
lisp([<<"-">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    C - D;
lisp([<<"/">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    C div D;
lisp([<<"*">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    C * D;
lisp([<<"rem">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A2, F),
    D = lisp(B2, F),
    C rem D;
lisp([<<"reverse">>, A], F) ->
    lists:reverse(lisp(A, F));
lisp([<<"++">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    A3 = lisp(A2, F),
    B3 = lisp(B2, F),
    A3 ++ B3;
lisp([<<"cons">>, A, B], F) ->
    %{A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    C = lisp(A, F),
    D = lisp(B2, F),
    [C|D];
lisp([<<"hd">>, A], F) ->
    {A2, _} = macros(A, F),
    C = lisp(A2, F),
    hd(C);
lisp([<<"car">>, A], F) ->
    {A2, _} = macros(A, F),
    C = lisp(A2, F),
    hd(C);
lisp([<<"cdr">>, A], F) ->
    {A2, _} = macros(A, F),
    C = lisp(A2, F),
    tl(C);
lisp([<<"or">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    bih(A2, F) or bih(B2, F);
lisp([<<"and">>, A, B], F) ->
    {A2, _} = macros(A, F),
    {B2, _} = macros(B, F),
    bih(A2, F) and bih(B2, F);
lisp([<<"not">>, A], F) ->
    {A2, _} = macros(A, F),
    not(bih(A2, F));
lisp([<<"print">>|R], F) ->
    io:fwrite(packer:pack(R)),
    lisp(R, F);
%lisp([<<"nil">>], F) ->
%    [];
lisp(X, _) -> X.
bih(A, F) -> bool_interpret(lisp(A, F)).
bool_interpret(<<"false">>) -> false;
bool_interpret([<<"false">>]) -> false;
bool_interpret(false) -> false;
bool_interpret(0) -> false;
bool_interpret(<<0:32>>) -> false;
bool_interpret(<<"true">>) -> true;
bool_interpret([<<"true">>]) -> true;
bool_interpret(true) -> true;
bool_interpret(1) -> true;
bool_interpret(<<1:32>>) -> true;
bool_interpret(X) -> 
    io:fwrite("bad bool \n"),
    io:fwrite(X),
    io:fwrite("\n"),
    io:fwrite(packer:pack(X)),
    io:fwrite("\n"),
    {error, bad_bool, X}.
    
lisp_cond([], _) ->
    {error, no_true_cond};
lisp_cond([[Bool, Code]|T], D) ->
    B = lisp(Bool, D),
    {B2, _} = macros(B, D),
    B3 = lisp(B2, D),
    A = bool_interpret(B3),
    case A of
	true -> Code;
	false -> lisp_cond(T, D);
	X -> X
    end.

%print_binary({error, R}) ->
%    io:fwrite("error! \n"),
%    io:fwrite(R),
%    io:fwrite("\n"); 
%print_binary(<<A:8, B/binary>>) ->
%    io:fwrite(integer_to_list(A)),
%    io:fwrite("\n"),
%    print_binary(B);
%print_binary(<<>>) -> ok.
%split_def(B) ->
%    split_def(B, 0).
%split_def(B, N) ->
%    <<Prev:N, Y:8, C/binary>> = B,
%    case Y of
%	?int -> split_def(B, N+8+?int_bits);
%	?binary ->
%	    <<_:N, Y:8, H:32, _/binary>> = B,
%	    split_def(B, N+40+(H*8));
%	?define ->
%	    <<_:N, _D/binary>> = C,
%	    {Func, T} = split_def(C),
%	    Hash = hash:doit(Func, chalang_constants:hash_size()),
%	    DSize = chalang_constants:hash_size(),
%	    B2 = <<Prev:N, 2, DSize:32, Hash/binary, T/binary>>,
%	    split_def(B2, N+40+(DSize*8));
%	?fun_end ->
%	    <<A:N, Y:8, T/binary>> = B,
%	    {<<A:N>>, T};
%	_ -> split_def(B, N+8)
%    end.
%after the first function definition, replace any repeated definition with the hash of the definition.
%lambdas(<<0, N:32, T/binary>>, Done) -> 
%    {T2, Done2} = lambdas(T, Done),
%    {<<0, N:32, T2/binary>>, Done2};
%lambdas(<<2, N:32, T/binary>>, Done) ->
%    M = N * 8,
%    <<X:M, T2/binary>> = T,
%    {T3, Done2} = lambdas(T2, Done),
%    {<<2, N:32, X:M, T3/binary>>, Done2};
    
%lambdas(<<110, T/binary>>, Done) ->
%    {Func, T2} = split_def(T),
%    Hash = hash:doit(Func, chalang_constants:hash_size()),
%    Bool = is_in(Hash, Done),
%    {Bin, Done2} = 
%	if 
%	    Bool -> 
%		{<<>>, Done};
%	    true -> 
%		{<<110, Func/binary, 111>>, [Hash|Done]}
%	end,
%    {T3, Done3} = lambdas(T2, Done2),
%    DSize = chalang_constants:hash_size(),
    %{<<Bin/binary, 2, DSize:32, Hash/binary, T3/binary>>, Done3};
%    {<<Bin/binary, 2, DSize:32, Hash/binary, T3/binary>>, Done3};
%lambdas(<<X, T/binary>>, Done) -> 
%    {T2, Done2} = lambdas(T, Done),
%    {<<X, T2/binary>>, Done2};
%lambdas(<<>>, D) -> {<<>>, D}.
    
to_ops([], _) -> <<>>;
to_ops([H|T], F) -> 
    {B, C, _, _} = is_op(H),%is it a built-in word?
    A = if
	    B -> C;%return it's compiled format.
	    true -> H %if it isn't built in
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
    B = is_integer(H),
    D = is_64(H),
    {E, _, _, _} = is_op(H),
    {A, D2} = 
	if
	    B -> {[<<"int">>, <<H:32>>], {Dict, Many}};
	    D -> 
		io:fwrite("variables case D \n"),
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
is_op(<<">r">>) -> {true, <<30>>, 1, 0};
is_op(<<"r>">>) -> {true, <<31>>, 0, 1};
is_op(<<"r@">>) -> {true, <<32>>, 0, 1};
is_op(<<"hash">>) -> {true, <<40>>, 1, 1};
is_op(<<"verify_sig">>) -> {true, <<41>>, 3, 1};
is_op(<<"pub2addr">>) -> {true, <<42>>, 1, 1};
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
is_op(<<"total_coins">>) -> {true, <<91>>, 0, 1};
is_op(<<"height">>) -> {true, <<92>>, 0, 1};
is_op(<<"slash">>) -> {true, <<93>>, 0, 1};
is_op(<<"gas">>) -> {true, <<94>>, 0, 1};
is_op(<<"ram">>) -> {true, <<95>>, 0, 1};
is_op(<<"many_vars">>) -> {true, <<97>>, 0, 1};
is_op(<<"many_funs">>) -> {true, <<98>>, 0, 1};
is_op(<<"oracle">>) -> {true, <<99>>, 0, 1};
is_op(<<"id_of_caller">>) -> {true, <<100>>, 0, 1};
is_op(<<"accounts">>) -> {true, <<101>>, 0, 1};
is_op(<<"channels">>) -> {true, <<102>>, 0, 1};
is_op(<<"verify_merkle">>) -> {true, <<103>>, 3, 2};
is_op(<<"start_fun">>) -> {true, <<110>>, 3, 0};
is_op(<<"def">>) -> {true, <<114>>, 3, 0};
is_op(<<"end_fun">>) -> {true, <<111>>, 0, 0};
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
-define(Binary, <<45:8, 45:8>>).
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
    
