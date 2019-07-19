-module(compiler_lisp2).
-export([test/0, doit/2]).


test() ->
    {ok, T} = file:read_file("src/lisp2/first.scm"),
    doit(T, "src/lisp2/").

doit(A, L) when is_list(A) ->
    doit(list_to_binary(A), L);
doit(Text, Location) ->
    List = compile(Text, Location, true),
    disassembler:doit(List),
    Gas = 10000,
    VM = chalang:vm(List, Gas*100, Gas*10, Gas, Gas, []),
    {List, VM}.
imports1(A, Done, L) ->
    Tree = compile_utils:doit(A),
    %TempTree = integers(Tree),
    %F = fun({F1, _}) -> F1 end,
%    FNs = function_names(TempTree),
%    MNs = macro_names(TempTree),
    %io:fwrite(stringify_lisp(TempTree)),
%    Tree2 = export_funs(Tree, Tree, hd(Done), lists:map(F, MNs++FNs)),
%    Tree3 = remove_export_tag(Tree2),
    imports1(Tree, Done, L).
    

compile(Text, Location, JustInTimeFlag) ->
    Tree = compile_utils:doit(Text),
    io:fwrite(compile_utils:stringify_lisp(Tree)),
    io:fwrite("\n"),
    Tree3 = functions(Tree, dict:new(), dict:new(), 0),
    io:fwrite("\n"),
    io:fwrite(compile_utils:stringify_lisp(Tree3)),
    io:fwrite("\n"),
    io:fwrite("\n"),
    F =fun(X) -> just_in_time3(just_in_time(X)) end,
    compile_utils:doit2(F, [[], 500, <<">r">>] ++ Tree3).
   
    
fip([], _, Dict) -> Dict;
fip([A|T], D, Dict) ->
    fip(T, D+1, dict:store(A, [<<"r@">>,D, <<"+">>,<<"@">>], Dict)).
load_inputs(0, _) -> [];
load_inputs(Many, 0) -> [<<"r@">>, <<"!">>|load_inputs(Many-1, 1)];
load_inputs(Many, D) -> [<<"r@">>,D,<<"+">>,<<"!">>|load_inputs(Many-1, D+1)].
            
functions([], _Vars, _, _Depth) -> [];
functions([[<<"define">>,[Name|V],Code]|T], Vars, Funs, N) ->
    Funs2 = dict:store(Name, true, Funs),
    LV = length(V),
    X2 = load_inputs(LV, 0) ++ functions(Code, fip(lists:reverse(V), N, Vars), Funs2, LV),
    [<<"def">>] ++ X2 ++ [<<"end_fun">>, Name, <<"!">>] ++ functions(T, Vars, Funs2, N);
functions([<<"let">>, []|Code], Vars, Funs, N) ->
    functions(Code, Vars, Funs, N);
functions([<<"let">>, [[V,C]|Pairs]|Code], Vars, Funs, N) when not(is_list(V)) ->
    Vars2 = dict:store(V, [<<"r@">>,N, <<"+">>,<<"@">>], Vars),
    [functions(C, Vars, Funs, N+1), <<"r@">>,N,<<"+">>,<<"!">>]++functions([<<"let">>, Pairs|Code], Vars2, Funs, N+1);
functions([<<"set!">>, Name, Code], Vars, Funs, N) ->
    functions(Code, Vars, Funs, N) ++ [Name, <<"!">>];
functions([<<"=">>, A, B], Vars, Funs, N) ->
    functions(A, Vars, Funs, N) ++
        functions(B, Vars, Funs, N) ++
        [<<"===">>, <<"tuck">>, <<"drop">>, <<"drop">>];
functions([<<"cond">>, []], _, _, _) -> [];
functions([<<"cond">>, [[<<"true">>, A]|T]], Vars, Funs, N) ->
    functions(A, Vars, Funs, N);
functions([<<"cond">>, [[Q, A]|T]], Vars, Funs, N) ->
    functions(Q, Vars, Funs, N) ++ [<<"if">>] ++
        functions(A, Vars, Funs, N) ++ [<<"else">>] ++
        functions([<<"cond">>, T], Vars, Funs, N) ++
        [<<"then">>];
functions([H|T], Vars, Funs, N) when is_integer(H)->
    [H|functions(T, Vars, Funs, N)];
functions([Rator|Rand], Vars, Funs, N) when (not(is_integer(Rator)) and( not(is_list(Rator)))) ->
    case dict:find(Rator, Vars) of
        {ok, Val} -> 
            Val ++ functions(Rand, Vars, Funs, N);
        error ->
            A = case dict:find(Rator, Funs) of
                    error -> [Rator|functions(Rand, Vars, Funs, N)];
                    {ok, true} -> 
                        M = if
                                N > 0 -> [<<"r@">>, N, <<"+">>, <<">r">>, Rator, <<"@">>,<<"call">>,<<"r>">>,<<"drop">>];
                                true -> [Rator,<<"@">>,<<"call">>]
                            end,
                        functions(Rand, Vars, Funs, N) ++ M
                end,
            A
        end;
functions([H|T], Vars, Funs, N) when is_list(H) ->
    functions(H, Vars, Funs, N) ++
        functions(T, Vars, Funs, N);
functions(I, _, _, _) when is_integer(I) -> [I];
functions(I, Vars, _, _) ->
    A = case dict:find(I, Vars) of
            error -> [I];
            {ok, Val} -> [Val]
        end.
    
    
   
                      

just_in_time(X0) ->
    %io:fwrite(X0),
    %io:fwrite("\n"),
    %io:fwrite("\n"),
    X1 = func_input_simplify(X0),
    X2 = just_in_time2(X1),
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
     
%used_pth(_,_,_) -> true; 
used_pth([], P, N) -> false;
used_pth([<<"end_fun">>|_], _, _) -> true;
used_pth([<<"r@">>, P, <<"+">>, <<"!">>|T], P, 0) -> false;
used_pth([<<"r@">>, P, <<"+">>, <<"@">>|T], P, 0) -> true;
used_pth([P, <<"r@">>, <<"+">>, <<"!">>|T], P, 0) -> false;
used_pth([P, <<"r@">>, <<"+">>, <<"@">>|T], P, 0) -> true;
used_pth([<<"r@">>, <<"!">>|T], 0, 0) -> false;
used_pth([<<"r@">>, <<"@">>|T], 0, 0) -> true;
used_pth([<<"if">>|T], P, N) ->
    used_pth(skip_next_else(T), P, N);
used_pth([<<"else">>|T], P, N) ->
    used_pth(skip_to_then(T), P, N);
used_pth([<<"r>">>,<<"drop">>|T], _, 0) -> false;
used_pth([<<"r>">>|T], _, 0) -> true;
used_pth([<<"r>">>|T], P, N) -> 
    used_pth(T, P, N-1);
used_pth([<<">r">>|T], P, N) -> 
    used_pth(T, P, N+1);
used_pth([H|T], P, N) -> used_pth(T, P, N).
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
    {C, D} = if
        B -> {[F], [<<"@">>, <<"r@">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>]};
        true -> {[], [F, <<"@">>, <<"call">>]}
        end,
    C ++ just_in_time2(D++T);
just_in_time2([F, <<"@">>, <<"r@">>, N, <<"+">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>|T]) ->
    B = used_r(T, 0),
    {C, D} = if
        B -> {[F, <<"@">>], [<<"r@">>, N, <<"+">>, <<">r">>, <<"call">>, <<"r>">>, <<"drop">>]};
        true -> {[], [F, <<"@">>, <<"call">>]}
        end,
    C ++ just_in_time2(D++T);

%r-stack optimizations related to tail call 
just_in_time2([<<"r@">>, 0, <<"+">>|T]) ->
    just_in_time2([<<"r@">>|T]);
just_in_time2([<<"r@">>, P, <<"+">>, <<"!">>,<<"drop">>|T]) ->
    just_in_time2([<<"swap">>,<<"drop">>,<<"r@">>,P,<<"+">>,<<"!">>|T]);
just_in_time2([<<"block this">>, <<"r@">>, P, <<"+">>, <<"!">>|T]) ->
    B = used_pth(T, P, 0),
    C = if
            B -> [<<"r@">>, P, <<"+">>, <<"!">>|just_in_time2(T)];
            true -> [<<"drop">>|just_in_time2(T)]
        end;

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
    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<P>>, <<"dup">>|R]);
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"car">>, <<"r@">>, N, <<"+">>, <<"@">>, <<"cdr">>|R]) ->
    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"car@">>|R]);
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"cdr">>, <<"r@">>, N, <<"+">>, <<"@">>, <<"car">>|R]) ->
    just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"car@">>, <<"swap">>|R]);



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
just_in_time2([0, <<"+">>|R]) -> 
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



just_in_time3([<<"r@">>, P, <<"+">>, <<"!">>|T]) ->
    B = used_pth(T, P, 0),
    C = if
            B -> [<<"r@">>, P, <<"+">>, <<"!">>|just_in_time3(T)];
            true -> [<<"drop">>|just_in_time3(T)]
        end;
just_in_time3([A|B]) ->
    [A|just_in_time3(B)];
just_in_time3([]) -> [].


