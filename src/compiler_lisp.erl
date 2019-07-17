
%If the compiler is written in macros, it is easier to understand, and modify.

-module(compiler_lisp).
-export([doit/2, compile/2, test/0]).
%-define(int_bits, 32).
%-define(int, 0).
%-define(binary, 2).
%-define(define, 110).
%-define(define2, 114).
%-define(fun_end, 111).
test() ->
    Files = [ 
              "compiler",
              "objects",
	      "tests/first_macro", 
              "tests/square_each_macro", 
	      "tests/let_test",
	      "tests/primes", 
	      "tests/flatten_test",
	      "tests/case", 
              "lisp",
	      "tests/macro_basics",
	      "tests/fun_test",
	      "tests/fun_test4",
	      "tests/fun_test5",
              "tests/filter_test",
              "tests/fold_test",
	      "tests/enum_test",
	      "tests/append_test",
	      "tests/eqs_test",
              "tests/clojure",
	      "hashlock",
	      "tests/gcf",
	      "tests/map_test",
	      "tests/sort_test",
              "tests/rat_test",
              %"rationals",
              "sqrt",%slow to compile
              "example",
              "binary_convert"
	    ],
    test2(Files).
test2([]) -> success;
test2([H|T]) ->
    io:fwrite("test "),
    io:fwrite(H),
    io:fwrite("\n"),
    L = "src/lisp/",
    {ok, Text} = file:read_file(L ++ H ++ ".scm"),
    case doit(Text, L) of
	{_, [<<1:32>>]} ->
	    test2(T);
	X -> X
    end.
doit_1(A, Done, L) ->
    B = remove_comments(<<<<"nop ">>/binary, A/binary, <<"\n">>/binary>>),
    B2 = quote_unquote(B),
    C = add_spaces(B2),
    Words = to_words(C, <<>>, []),
    Tree = to_lists(Words),
    TempTree = integers(Tree),
    F = fun({F1, _}) -> F1 end,
    FNs = function_names(TempTree),
    MNs = macro_names(TempTree),
    %io:fwrite(stringify_lisp(TempTree)),
    Tree2 = export_funs(Tree, Tree, hd(Done), lists:map(F, MNs++FNs)),
    Tree3 = remove_export_tag(Tree2),
    imports(Tree3, Done, L).
%unique_file_name(File, [[<<"macro">>, Name, Vars, Code]|T]) ->
%    [[<<"macro">>, <<File/binary, <<".">>/binary, Name/binary>>, Vars, Code]|unique_file_name(File, T)]
remove_export_tag([]) ->
    [];
remove_export_tag([[<<"export">>,_]|T]) ->
    remove_export_tag(T);
remove_export_tag([H|T]) when is_list(H) ->
    [remove_export_tag(H)|
     remove_export_tag(T)];
remove_export_tag([H|T]) ->
    [H|remove_export_tag(T)].
export_funs([[<<"export">>, <<"global">>]|_], Tree, _, _) -> 
    Tree;
export_funs([[<<"export">>, Funs]|_], Tree, FileName, All) ->
    
    Exported = export_funs2(Funs, Tree, FileName, All),
    %io:fwrite("in export funs \n"),
    %io:fwrite(Exported),
    %io:fwrite("\n"),
    %io:fwrite(Exported),
    Exported;
export_funs([H|T], Tree, FileName, All) when is_list(H) ->
    export_funs((H++T), Tree, FileName, All);
%export_funs(T, Tree, FileName, All);
export_funs([_|T], Tree, FileName, All) ->
    export_funs(T, Tree, FileName, All);
export_funs([], Tree, _, _) -> 
    Tree;
export_funs(X, _, _, _) -> 
    io:fwrite("in export"),
    io:fwrite(X),
    io:fwrite("\n"),
    1=2,
    X.
export_funs2(_, [], _, _) -> [];
export_funs2(ExportFuns, [H|T], FileName, AllFuns) when is_list(H)->
    [export_funs2(ExportFuns, H, FileName, AllFuns)|
     export_funs2(ExportFuns, T, FileName, AllFuns)];
export_funs2(ExportFuns, [H|T], FileName, AllFuns) ->
    B1 = is_in(H, AllFuns),
    B2 = is_in(H, ExportFuns),
    H2 = if
             (B1 and (not(B2))) -> 
                 X = <<FileName/binary, <<"_">>/binary, H/binary>>,
                 %io:fwrite(X),
                 %io:fwrite("\n"),
                 X;
             true -> H
         end,
    [H2|export_funs2(ExportFuns, T, FileName, AllFuns)].
            
doit(A, L) when is_list(A) ->
    doit(list_to_binary(A), L);
doit(A, L) ->

    List4 = compile(A, L),

    %io:fwrite("--------------------\n"),
    disassembler:doit(List4),
    io:fwrite("===========================\n"),
    Gas = 10000,
    VM = chalang:vm(List4, Gas*100, Gas*10, Gas, Gas, []),
    {%{%Tree1, Tree3, Tree35, 
     % List, List1%, List4%, List5
                     List4, VM}.


compile(A, L) ->

    {Tree1, _} = doit_1(A, [<<"">>], L),
    %io:fwrite("in doit\n"),
    %io:fwrite(Tree1),%bad
    %io:fwrite("\n"),
    %io:fwrite(packer:pack(Tree1)),
    %io:fwrite("\n"),
    %Tree1 = quote_list(Tree),
    %io:fwrite("Macros\n"),
    Tree2_0 = integers(Tree1),
    Tree2_1 = macro_var_names(Tree2_0),%adds the file name to every variable to make sure they are unique for the compiler.
    FNs = function_names(Tree2_1),
    UnusedFuns = unused_funs(FNs, Tree2_1),
    %io:fwrite(UnusedFuns),
    %io:fwrite("\n\n\n"),
    Tree2_2 = remove_unused_funs(UnusedFuns, Tree2_1),
%    Tree2_2 = Tree2_1,
    Tree2 = apply_funs(FNs, Tree2_2),
    check_recursion_variable_amounts(Tree2),
    {Tree3, _} = macros(Tree2, dict:new()),
    %io:fwrite("rpn\n"),
    %io:fwrite(stringify_lisp(Tree3)),
    Tree35 = rpn(Tree3),%change to reverse polish notation.
    List = flatten(Tree35),
    List1 = just_in_time(List),
    List2 = variables(List1, {dict:new(), 1}),
    Funcs = dict:new(),
    List4 = to_ops(List2, Funcs),
    List4.

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
no_rff0([]) -> true;
no_rff0([<<"r@">>,<<"@">>|_]) -> false;
no_rff0([X|T]) -> no_rff0(T).

no_rff(_, [<<"end_fun">>|_]) -> true;
no_rff(_, []) -> true;
no_rff(N, [<<"r@">>,N,<<"+">>,<<"@">>|_]) -> false;
no_rff(N, [X|T]) -> no_rff(N, T).
          
used_r([], _) -> false;
used_r([<<"end_fun">>|_], _) -> false;
used_r([<<"if">>|T], N) ->
    used_r(skip_next_else(T), N);
used_r([<<"else">>|T], N) ->
    used_r(skip_to_then(T), N);
used_r([<<"r@">>|_], 0) -> true;
used_r([<<"r>">>,<<"drop">>|_], 0) -> false;
used_r([<<"r>">>|_], 0) -> true;
used_r([<<"r>">>|T], N) -> used_r(T, N-1);
used_r([<<">r">>|T], N) -> used_r(T, N+1);
used_r([_|T], N) -> used_r(T, N).
skip_to_then([<<"then">>|T]) -> T;
skip_to_then([_|T]) -> skip_to_then(T);
skip_to_then([]) -> [].
skip_next_else([<<"else">>|T]) ->
    T;
skip_next_else([H|T]) ->
    [H|skip_next_else(T)].
skip_to_fromr_drop([<<"r>">>,<<"drop">>|T], T1, 0) ->
    {T1, T};
skip_to_fromr_drop(_, _, N) when (N < 0) -> 1=2;
skip_to_fromr_drop([<<"r>">>|T], T1, N) ->
    skip_to_fromr_drop(T, T1 ++ [<<"r>">>], N-1);
skip_to_fromr_drop([<<">r">>|T], T1, N) ->
    skip_to_fromr_drop(T, T1 ++ [<<">r">>], N+1);
skip_to_fromr_drop([A|B], T1, N) ->
    skip_to_fromr_drop(B, T1 ++ [A], N).

%if we are doing math with 2 constants, this is something that can be done at compile time.
just_in_time2([N, M, <<"+">>|R]) 
  when (is_integer(N) and is_integer(M)) ->
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


%r-stack optimizations
just_in_time2([<<">r">>, <<"r@">>|T]) ->
    [<<"dup">>, <<">r">>|just_in_time2(T)];
just_in_time2([<<"@r">>, N, <<"+">>, <<">r">>|T]) when is_integer(N) ->
    {T1, T2} = skip_to_fromr_drop(T,[],0),
    B = used_r(T2, 0),
    C = if
            B -> [N|just_in_time2([<<"+">>, <<">r">>|T])];
            true -> just_in_time2(T1 ++ T2)
        end;
    
%tail call optimizations
just_in_time2([F, <<"@">>, <<"r@">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>|T]) ->
    B = used_r(T, 0),
    C = if
        B -> [F, <<"@">>, <<"r@">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>];
        true -> [F, <<"@">>, <<"call">>]
        end,
    C ++ just_in_time2(T);
just_in_time2([F, <<"@">>, <<"r@">>, N, <<"+">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>|T]) ->
    B = used_r(T, 0),
    C = if
        B -> [F, <<"@">>, <<"r@">>, N, <<"+">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>];
        true -> [F, <<"@">>, <<"call">>]
        end,
    C ++ just_in_time2(T);

%if we repeatedly call functions, we don't have to restore variables for parent function in between. This is a kind of tail call optimization.
just_in_time2([<<"call">>,<<"r>">>,<<"drop">>,N,<<"@">>,<<"r@">>,M,<<"+">>,<<">r">>|R]) -> 
    [<<"call">>,N,<<"@">>|just_in_time2(R)];
just_in_time2([<<"call">>,<<"r>">>,<<"drop">>,N,<<"@">>,<<"r@">>,<<">r">>|R]) -> 
    [<<"call">>,N,<<"@">>|just_in_time2(R)];

%car/cdr repeat optimization
% first for the 0th input of the function
just_in_time2([<<"r@">>, <<"@">>, P, <<"r@">>, <<"@">>, P|R]) when ((P == <<"car">>) or (P == <<"cdr">>))->
    [<<"r@">>, <<"@">>, <<P>>, <<"dup">>|just_in_time2(R)];
just_in_time2([<<"r@">>, <<"@">>, <<"car">>, <<"r@">>, <<"@">>, <<"cdr">>|R]) ->
    [<<"r@">>, <<"@">>, <<"car@">>|just_in_time2(R)];
just_in_time2([<<"r@">>, <<"@">>, <<"cdr">>, <<"r@">>, <<"@">>, <<"car">>|R]) ->
    [<<"r@">>, <<"@">>, <<"car@">>, <<"swap">>|just_in_time2(R)];
% now the nth interval for n > 0.
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, P, <<"r@">>, N, <<"+">>, <<"@">>, P|R]) when ((P == <<"car">>) or (P == <<"cdr">>))->
    [<<"r@">>, N, <<"+">>, <<"@">>, <<P>>, <<"dup">>|just_in_time2(R)];
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"car">>, <<"r@">>, N, <<"+">>, <<"@">>, <<"cdr">>|R]) ->
    [<<"r@">>, N, <<"+">>, <<"@">>, <<"car@">>|just_in_time2(R)];
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"cdr">>, <<"r@">>, N, <<"+">>, <<"@">>, <<"car">>|R]) ->
    [<<"r@">>, N, <<"+">>, <<"@">>, <<"car@">>, <<"swap">>|just_in_time2(R)];



%common combinations of opcodes that cancel to nothing
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
just_in_time2([<<"dup">>,<<">r">>,<<"dup">>,<<"r>">>|R]) -> 
    [<<"dup">>,<<"dup">>|just_in_time2(R)];

%we want to use the variables in last-in-first-out order if possible, since this often leads to more opportunities to optimize.
%just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, N, <<"+">>, <<"@">>|R]) when is_integer(N)-> 
%    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"r@">>, <<"@">>, <<"swap">>|R]);
%just_in_time2([<<"r@">>, M, <<"+">>, <<"@">>, <<"r@">>, N, <<"+">>, <<"@">>|R]) when ((is_integer(N) and is_integer(M)) and (M < N))-> 
%    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"r@">>, M, <<"+">>, <<"@">>, <<"swap">>|R]);

%using the first function var three in a row
just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, <<"@">>, <<"r@">>, <<"@">>|R]) -> 
    just_in_time2([<<"r@">>, <<"@">>, <<"dup">>, <<"dup">>|R]);
%using the first function var twice in a row
just_in_time2([<<"r@">>, <<"@">>, <<"r@">>, <<"@">>|R]) -> 
    just_in_time2([<<"r@">>|[<<"@">>|[<<"dup">>|R]]]);


%using the Nth first function var multiple times
just_in_time2([<<"r@">>|[N|[<<"+">>|[<<"@">>|
              [<<"r@">>|[N|[<<"+">>|[<<"@">>|
              [<<"r@">>|[N|[<<"+">>|[<<"@">>|R]]]]]]]]]]]]) when is_integer(N)-> 
    just_in_time2([<<"r@">>|[N|[<<"+">>|[<<"@">>|[<<"dup">>|[<<"dup">>|R]]]]]]);
just_in_time2([<<"r@">>|[N|[<<"+">>|[<<"@">>|
              [<<"r@">>|[N|[<<"+">>|[<<"@">>|R]]]]]]]]) when is_integer(N)-> 
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


%just_in_time2([<<">r">>|R]) ->
%    R2 = r_collapse(R, 0, []),
%    io:fwrite(R2),
%    case R2 of
%	false -> [<<">r">>|just_in_time2(R)];
%	_ -> just_in_time2(R2)
%    end;
just_in_time2([A|B]) ->
    [A|just_in_time2(B)];
just_in_time2([]) -> [].

imports([<<"import">>, []], Done, _) -> {[], Done};
imports([<<"import">>, [H|T]], Done, L) ->
    %io:fwrite("importing "),
    %io:fwrite(H),
    B = is_in(H, Done),
    {Tree, Done2} = 
	if
	    B -> {[], Done};
	    true ->		
		{ok, File} = file:read_file(L ++ binary_to_list(H)),
		D2 = [H|Done],
		{Tr, D3} = doit_1(File, D2, L),
		{Tr, D3}
	end,
    {Tree2, Done3} = imports([<<"import">>, T], Done2, L),
    {[Tree|Tree2], Done3};
imports([H|T], Done, L) -> 
    {H2, Done2} = imports(H, Done, L),
    {T2, Done3} = imports(T, Done2, L),
    {[H2|T2], Done3};
imports(Tree, Done, _) -> {Tree, Done}.

integers([A|B]) ->
    [integers(A)|
     integers(B)];
integers(A) ->
    B = is_int(A),
    if
	B -> list_to_integer(binary_to_list(A));
	true -> A
    end.
remove_unused_funs([], Code) -> Code;
remove_unused_funs([F|T], Code) ->
    remove_unused_funs(T, remove_unused_fun(F, Code)).
remove_unused_fun(F, [<<"define">>, F, _, _]) -> [];
remove_unused_fun(F, [<<"define">>, [F|_], _]) -> [];
remove_unused_fun(F, [H|T]) when is_list(H) -> 
    [remove_unused_fun(F, H)|
     remove_unused_fun(F, T)];
remove_unused_fun(F, [H|T]) -> [H|remove_unused_fun(F, T)];
remove_unused_fun(_, []) -> [].
unused_funs([], _) -> [];
unused_funs([{H, _}|T], Code) ->
    B = used_fun(H, Code),
    X = if
            B -> [];
            true -> [H]
    end,
    X ++ unused_funs(T, Code).
used_fun(N, []) -> false;
used_fun(N, [[<<"define">>, Name, _, C]|T]) when not(is_list(Name))->
    used_fun(N, C) or used_fun(N, T);
used_fun(N, [[<<"define">>, _, C]|T]) ->
    used_fun(N, C) or used_fun(N, T);
used_fun(N, [N|_]) -> true;
used_fun(N, [H|T]) when is_list(H) ->
    used_fun(N, H) or used_fun(N, T);
used_fun(N, [_|T]) ->
    used_fun(N, T).
macro_names([<<"macro">>, Name, V, _]) ->
    [{Name, length(V)}];
macro_names([H|T]) ->
    macro_names(H) ++ macro_names(T);
macro_names(X) -> [].
function_names([[<<"define">>, Name, V, _Code]|T]) when not(is_list(Name))->
    L = length(V),
    [{Name, L}] ++ function_names(T);
function_names([[<<"define">>, Name, _Code]|T]) ->
    L = length(tl(Name)),
    [{hd(Name), L}] ++ function_names(T);
function_names([[<<"deflet">>, Name, Vars, _Pairs, _Code]|T]) ->
    L = length(Vars),
    [{Name, L}] ++ function_names(T);
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
    [[<<"define">>, Name2, Vars, apply_fun(Name, Code)]|apply_fun(Name, T)];
apply_fun(Name, [[<<"define">>, Vars, Code]|T]) ->
    [[<<"define">>, hd(Vars), tl(Vars), apply_fun(Name, Code)]|apply_fun(Name, T)];
apply_fun({Name, M}, [[Name|T1]|T2])->
    B = (M == length(T1)),
    if
        B ->
            [[<<"execute2">>,[Name|apply_fun({Name, M}, T1)]]|
             apply_fun({Name, M}, T2)];
        true -> io:fwrite("\n\n=======ERROR========\nwrong number of inputs to function " ++ binary_to_list(Name) ++ "\n\n\n"),
                error
    end;
%apply_fun(Name, [Name|T]) ->
%    [<<"execute2">>, [Name|apply_fun(Name, T)]];
apply_fun(Name, [H|T]) when is_list(H) ->
    [apply_fun(Name, H)|
     apply_fun(Name, T)];
apply_fun(Name, [H|T]) ->
    [H|apply_fun(Name, T)].
check_recursion_variable_amounts([]) -> ok;
check_recursion_variable_amounts([[<<"define">>, Name, V, Code]|T]) ->
    L = length(V),
    crva2(L, Code, Name),
    check_recursion_variable_amounts(T);
check_recursion_variable_amounts([[<<"define">>, V, Code]|T]) ->
    L = length(V) - 1, 
    crva2(L, Code, hd(V)),
    check_recursion_variable_amounts(T);
check_recursion_variable_amounts([H|T]) ->
    if
        is_list(H) ->
            check_recursion_variable_amounts(H);
        true -> ok
    end,
    check_recursion_variable_amounts(T),
    ok.
crva2(_, [], _) -> ok;
crva2(M, [<<"recurse">>|T], Name) ->
    L = length(T),
    if
        (L == M) -> ok;
        true -> 
            io:fwrite("ERROR: wrong number of inputs for recursion in function " ++ binary_to_list(Name) ++ "\n"),
            1=2
    end;
crva2(M, [H|T], Name) ->
    if
        is_list(H) -> crva2(M, H, Name);
        true -> ok
    end,
    crva2(M, T, Name).
    
macro_var_names([<<"macro">>, Name, Vars, Code]) ->
    Vars2 = macro_unique_vars(Name, Vars, Vars),
    Code2 = macro_unique_vars(Name, Vars, Code),
    [<<"macro">>, Name, Vars2, Code2];
macro_var_names([H|T]) when is_list(H) ->
    [macro_var_names(H)|macro_var_names(T)];
macro_var_names([H|T]) ->
    [H|macro_var_names(T)];
macro_var_names([]) -> [].
macro_unique_vars(Name, [], Code) -> Code;
macro_unique_vars(Name, [H|T], Code) ->
    macro_unique_vars(Name, T, macro_unique_vars2(Name, H, Code)).
macro_unique_vars2(Name, Var, []) -> [];
macro_unique_vars2(Name, Var, [H|T]) ->
    [macro_unique_vars2(Name, Var, H)|
     macro_unique_vars2(Name, Var, T)];
macro_unique_vars2(Name, Var, Var) ->
    <<Var/binary, <<".">>/binary, Name/binary>>;
macro_unique_vars2(Name, Var, H) ->
    H.
    
macros([<<"macro">>, Name, Vars, Code], D) ->
    %{Code2, D3} = macros(Code, D),
    %io:fwrite(Code2),
    %{Code2, _} = macros(Code, D),
    D2 = dict:store(Name, {Vars, Code}, D),
    {[], D2};
macros([<<"macro">>|[Name|_]], _) ->
    io:fwrite("\n\nerror, macro named "),
    io:fwrite(Name),
    io:fwrite(" has the wrong number of inputs in it's definition\n\n");
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
	    %{T3, D2} = macros(lisp(T, D), D),
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
    {H2, _} = macros(H, D),
    %Code2 = replace(Code, V, H2),
    Code2 = replace(Code, V, H2),
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
lisp([<<"cond">>, T], D) -> 
    lisp(lisp_cond(T, D), D);
    %lisp_cond(T,D);
lisp([[<<"lambda">>, Vars, Code]|A], D) ->
    {T3, D2} = macros(A, D),
    T4 = lisp(T3, D2),
    T2 = apply_macro(<<"lambda">>, Code, Vars, T4, D2),
    lisp(T2, D2);
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
lisp([<<"is_atom">>, X], F) ->
    {A2,_} = macros(X, F),
    A3 = lisp(A2, F),
    bool_atom_to_int(is_binary(A3));
%lisp([<<"is_atom">>, X], F) when is_binary(X) ->
%    bool_atom_to_int(true);
%lisp([<<"is_atom">>, [<<"quote">>, X]], F) when is_binary(X) ->
%    bool_atom_to_int(true);
%lisp([<<"is_atom">>, A], F) ->
%    {A2,_} = macros(A, F),
%    A3 = lisp(A2, F),
%    io:fwrite("compiler lisp is atom false "),
%    io:fwrite(A3),
%    io:fwrite("\n"),
%    bool_atom_to_int(false);
lisp([<<"null?">>, X], F) ->
    {X2, _} = macros(X, F),
    X3 = lisp(X2, F),
    B = X3 == [],
    bool_atom_to_int(B);
lisp([<<"is_number">>, X], F) ->
    {X2, _} = macros(X, F),
    X3 = lisp(X2, F),
    bool_atom_to_int(is_integer(X3));
lisp([<<"eqs">>, A, B], D) ->
    {A3, _} = macros(A, D),
    A2 = lisp(A3, D),
    {B3, _} = macros(B, D),
    B2 = lisp(B3, D),
    bool_atom_to_int(A2 == B2);
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
    %io:fwrite([C, D]),
    %io:fwrite(packer:pack([C, D])),
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
%lisp([[<<"write">>|M],R], F) ->
%    io:fwrite(packer:pack(M)),
%    lisp(R, F);
lisp([<<"write">>, R], F) ->
    {A, _} = macros(R, F),
    A2 = lisp(A, F),
    io:fwrite(stringify_lisp(A2)),
%    lisp_write_helper(A2),
    io:fwrite("\n"),
    lisp([], F);
%lisp([<<"nil">>], F) ->
%    [];
lisp([[]|T], F) ->
    [[]|lisp(T, F)];
lisp([H|T], F) when is_list(H)-> 
    {H2, D1} = macros(H, F),
    {T3, D2} = macros(T, D1),
    T4 = lisp(T3, D2),
    H3 = case H2 of
             [<<"lambda">>, Vars, Code] ->
                 apply_macro(<<"lambda">>, Code, Vars, T4, D2);
             _ -> 
%                 [lisp(H2, D1)|T4]
                 [H2|T4]
         end;
lisp(X, _) -> X.
lisp_write_helper(R) ->
    if 
        is_integer(R) ->
            io:fwrite(integer_to_list(R));
        is_list(R) ->
            io:fwrite("["),
            lists:map(fun(X) -> lisp_write_helper(X), io:fwrite(" ") end, R),
            io:fwrite("]");
        %io:fwrite(packer:pack(R));
        is_binary(R) ->
            io:fwrite(R);
        true -> 
            io:fwrite(R),
            1=2
    end.
    
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
is_op(<<"return">>) -> {true, <<11>>, 0, 0};
is_op(<<"fail">>) -> {true, <<13>>, 0, 0};
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
    
    
