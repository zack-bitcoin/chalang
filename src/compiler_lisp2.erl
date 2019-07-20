-module(compiler_lisp2).
-export([test/0, doit/2,compile/3]).


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
    io:fwrite(integer_to_list(length(Tree3))),
    io:fwrite("\n"),
    io:fwrite("\n"),
    Tree4 = just_in_time_main(Tree3),
    io:fwrite(integer_to_list(length(Tree4))),
    io:fwrite("\n"),
    io:fwrite("\n"),
    compile_utils:doit2([[], 500, <<">r">>] ++ Tree4).

just_in_time_main(X) ->     
    just_in_time2(just_in_time3(just_in_time_loop(just_in_time3(X)))).
    
   
    
fip([], _, Dict) -> Dict;
fip([A|T], D, Dict) ->
    fip(T, D+1, dict:store(A, [<<"r@">>,D, <<"+">>,<<"@">>], Dict)).
load_inputs(0, _) -> [];
load_inputs(Many, 0) -> [<<"r@">>, <<"!">>|load_inputs(Many-1, 1)];
load_inputs(Many, D) -> [<<"r@">>,D,<<"+">>,<<"!">>|load_inputs(Many-1, D+1)].
let_setup_inputs([], _, _, _) -> [];
let_setup_inputs([[A, V]|Pairs], Vars, Funs, N) ->
    functions(V, Vars, Funs, N+1) ++
        let_setup_inputs2(A, N).
let_setup_inputs2(0, N) -> [];
let_setup_inputs2(ManyIn, N) when is_integer(ManyIn)->
    [<<"r@">>, N, <<"+">>, <<"!">>] ++ let_setup_inputs2(ManyIn-1, N+1);
let_setup_inputs2(ManyIn, N) when is_list(ManyIn)->
    let_setup_inputs2(length(ManyIn), N);
let_setup_inputs2(_, N) ->
    let_setup_inputs2(1, N).

let_internal([], Code, Vars, Funs, N) ->
    functions(Code, Vars, Funs, N);
let_internal([[V, C]|Pairs], Code, Vars, Funs, N) when not(is_list(V))->
    Vars2 = dict:store(V, [<<"r@">>,N, <<"+">>,<<"@">>], Vars),
    functions(C, Vars, Funs, N+1) ++ [<<"r@">>,N,<<"+">>,<<"!">>]++let_internal(Pairs, Code, Vars2, Funs, N+1);
let_internal(Pairs, Code, Vars, Funs, N) ->
    let_setup_inputs( Pairs, Vars, Funs, N) ++
        let_setup_env(Pairs, Code, Vars, Funs, N).

let_setup_env2(Vars, _, []) -> Vars;
let_setup_env2(Vars, N, [H|L]) ->
    Vars2 = dict:store(H,[<<"r@">>, N, <<"+">>, <<"@">>],Vars),
    let_setup_env2(Vars2, N+1, L).
            
let_setup_env([[V,C]|Pairs], Code, Vars, Funs, N) ->
    Vars2 = let_setup_env2(Vars, N, lists:reverse(V)),
    let_internal(Pairs, Code, Vars2, Funs, N+length(V)).
            
functions([], _Vars, _, _Depth) -> [];
functions([[<<"define">>,[Name|V],Code]|T], Vars, Funs, N) ->
    Funs2 = dict:store(Name, true, Funs),
    LV = length(V),
    X2 = load_inputs(LV, 0) ++ functions(Code, fip(lists:reverse(V), N, Vars), Funs2, LV),
    [<<"def">>] ++ X2 ++ [<<"end_fun">>, Name, <<"!">>] ++ functions(T, Vars, Funs2, N);
%functions([<<"let">>, [[V,C]|Pairs]|Code], Vars, Funs, N) when not(is_list(V)) ->
%    let_internal([[V, C]|Pairs], Code, Vars, Funs, N);
functions([<<"let">>, Pairs|Code], Vars, Funs, N) ->
    let_internal(Pairs, Code, Vars, Funs, N);
%    let_setup_inputs( Pairs, Vars, Funs, N) ++
%        let_setup_env(Pairs, Code, Vars, Funs, N);
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
functions([<<"tree">>, T], _, _, _) ->
    [[]] ++ tree_internal(T);
%functions([<<"+">>, A, B], Vars, Funs, N) ->
%    functions(A, Vars, Funs, N) ++ functions(B, Vars, Funs, N) ++ [<<"+">>];
functions([H|T], Vars, Funs, N) when is_integer(H)->
    [H|functions(T, Vars, Funs, N)];
functions([Rator|Rand], Vars, Funs, N) when (not(is_integer(Rator)) and( not(is_list(Rator)))) ->
    case dict:find(Rator, Vars) of
        {ok, Val} -> 
            Val ++ functions(Rand, Vars, Funs, N);
        error ->
            A = case dict:find(Rator, Funs) of
                    error -> 
                        lists:foldr( fun(Elem, Acc) ->
                                             Elem ++ Acc end, [], lists:map(fun(X) -> functions(X, Vars, Funs, N) end, Rand)) ++ [Rator];
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
            {ok, Val} -> Val
        end.
   
tree_internal([]) -> [<<"nil">>];
tree_internal([[H|T1]|T2]) -> 
        tree_internal([H|T1]) ++
        tree_internal(T2) ++ 
        [<<"cons">>];
tree_internal([[]|T]) ->
    [<<"nil">>]++tree_internal(T);
tree_internal([H|T]) ->
    [H] ++ tree_internal(T) ++ [<<"cons">>].
   
                      

just_in_time_loop(X0) ->
    %io:fwrite(X0),
    %io:fwrite("\n"),
    %io:fwrite("\n"),
    X1 = func_input_simplify(X0),
    X2 = just_in_time2(X1),
    if 
	(X2 == X0) -> X2;
	true -> just_in_time_loop(X2)
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
used_pth([<<"end_fun">>|_], _, _) -> false;
used_pth([<<"start_fun">>|T], P, N) -> %false;
    used_pth(skip_to_end_fun(T), P, N);
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
skip_to_end_fun([<<"end_fun">>|T]) -> T;
skip_to_end_fun([_|T]) -> skip_to_end_fun(T);
skip_to_end_fun([]) -> [].
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

-define(bin_sym(F), (
(F == <<"+">>) or
(F == <<"*">>) or
(F == <<"===">>) or
(F == <<"and">>) or
(F == <<"or">>) or
(F == <<"xor">>) or
(F == <<"band">>) or
(F == <<"bor">>) or
(F == <<"bxor">>)
)).
-define(op1_0(F), (
(F == <<">r">>)
)).
-define(op0_1(F), (
(is_integer(F)) or
(F == <<"true">>) or
(F == <<"false">>) or
(F == <<">r">>) or
(F == <<"r@">>) or
(F == <<"height">>) or
(F == <<"nil">>)
)).
-define(op1_1(F), (
(F == <<"hash">>) or
(F == <<"not">>) or
(F == <<"@">>) or
(F == <<"car">>) or
(F == <<"cdr">>) or
(F == <<"reverse">>)
)).
-define(op2_2(F), (
(F == <<"swap">>) or
(F == <<"car@">>) or
(F == <<"split">>)
)).
-define(op2_1(F), (
(?bin_sym(F)) or
(F == <<"-">>) or
(F == <<"/">>) or
(F == <<"<">>) or
(F == <<">">>) or
(F == <<"rem">>) or
(F == <<"cons">>) or
(F == <<"++">>)
)).
-define(sorted_op(F), (
                   (is_integer(F)) or
                   (?op1_0(F)) or
                   (?op0_1(F)) or
                   (?op1_1(F)) or
                   (?op2_2(F)) or
                   (?op2_1(F))
)).
r_combinator_helper(L, 0, 0) -> L;
r_combinator_helper(L, 1, N) -> 
    [<<"swap">>] ++ r_combinator_helper(L, 0, N);
r_combinator_helper(L, 2, N) ->
    [<<"tuck">>] ++ r_combinator_helper(L, 0, N);
r_combinator_helper(L, M, 1) ->
    r_combinator_helper(L, M, 0) ++ [<<"swap">>];
r_combinator_helper(L, M, 2) ->
    r_combinator_helper(L, M, 0) ++ [<<"rot">>];
r_combinator_helper(_, _, _) -> error.



op_to_ints(F) ->
    if
        ?op1_0(F) -> {1, 0};
        ?op0_1(F) -> {0, 1};
        ?op1_1(F) -> {1, 1};
        ?op2_1(F) -> {2, 1};
        ?op2_2(F) -> {2, 2}
    end.
ops_to_ints(X) -> ops_to_ints(X, 0, 0).
ops_to_ints([], A, B) -> {A, B};
ops_to_ints([F|T], A, B) ->
    {A1, B1} = op_to_ints(F),
    C = B - A1,
    if
        (C > -1) -> ops_to_ints(T, A, C+B1);
        true -> ops_to_ints(T, A-C, B1)
    end.
r_combinator(L) when is_list(L)->%protects the top thing on the stack from a variety of kinds of pairs of functions, so we don't have to use the r-stack so much.
    {A, B} = ops_to_ints(L),
    r_combinator_helper(L, A, B).
%r_combinator(F) ->%protects the top thing on the stack from a variety of kinds of functions, so we don't have to use the r-stack so much.
%    {A, B} = op_to_ints(F),
%    r_combinator_helper([F], A, B).

jitrc(S, NoChange, N, T) ->
    B = if
            (N==0) -> no_rff0(T);
            true -> no_rff(N, T)
        end,
    {Q, R} = if
                 B -> 
                     {Take, Give} = ops_to_ints(S),
                     if
                         ((Take < 3) and (Give < 3)) -> {[], r_combinator(S)};
                         true -> NoChange
                     end;
                 true -> NoChange
             end,
    Q ++ just_in_time2(R ++ T).
    
                      
                

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



just_in_time2([<<"swap">>, F|T]) when ?bin_sym(F) ->
    just_in_time2([F|T]);
just_in_time2([<<"tuck">>, F, F|T]) when ?bin_sym(F) ->
    just_in_time2([F, F|T]);
just_in_time2([<<"rot">>, F, F|T]) when ?bin_sym(F) ->
    just_in_time2([F, F|T]);


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
    %move variable load right, to increase the odds tha we can combine it with the read
    just_in_time2([<<"swap">>,<<"drop">>,<<"r@">>,P,<<"+">>,<<"!">>|T]);

%if we save something, and load it right away, and we only load it that one time, then sometimes we can optimize this.
just_in_time2([<<"r@">>,<<"!">>,F,<<"r@">>,<<"@">>|T]) when ?sorted_op(F) ->
    NoChange = {[<<"r@">>], [<<"!">>,F,<<"r@">>,<<"@">>]},
    S = [F],
    jitrc(S, NoChange, 0, T);
just_in_time2([<<"r@">>,N,<<"+">>,<<"!">>,F,<<"r@">>,N, <<"+">>, <<"@">>|T]) when (is_integer(N) and ?sorted_op(F)) ->
    NoChange =  {[<<"r@">>], [N, <<"+">>,<<"!">>,F,<<"r@">>,N,<<"+">>,<<"@">>]},
    S = [F],
    jitrc(S, NoChange, N, T);
just_in_time2([<<"r@">>,<<"!">>,F,G,<<"r@">>,<<"@">>|T]) when (?sorted_op(F) and ?sorted_op(G)) ->
    NoChange = {[<<"r@">>], [<<"!">>,F,G,<<"r@">>,<<"@">>]},
    S = [F, G],
    jitrc(S, NoChange, 0, T);
just_in_time2([<<"r@">>,N,<<"+">>,<<"!">>,F,G,<<"r@">>,N, <<"+">>, <<"@">>|T]) when (is_integer(N) and ?sorted_op(F) and ?sorted_op(G)) ->
    NoChange =  {[<<"r@">>], [N, <<"+">>,<<"!">>,F,G,<<"r@">>,N,<<"+">>,<<"@">>]},
    S = [F,G],
    jitrc(S, NoChange, N, T);
just_in_time2([<<"r@">>,<<"!">>,F,G,H,<<"r@">>,<<"@">>|T]) when (?sorted_op(F) and ?sorted_op(G) and ?sorted_op(H)) ->
    NoChange = {[<<"r@">>], [<<"!">>,F,G,H,<<"r@">>,<<"@">>]},
    S = [F, G, H],
    jitrc(S, NoChange, 0, T);
just_in_time2([<<"r@">>,N,<<"+">>,<<"!">>,F,G,H,<<"r@">>,N, <<"+">>, <<"@">>|T]) when (is_integer(N) and ?sorted_op(F) and ?sorted_op(G) and ?sorted_op(H)) ->
    NoChange =  {[<<"r@">>], [N, <<"+">>,<<"!">>,F,G,H,<<"r@">>,N,<<"+">>,<<"@">>]},
    S = [F,G,H],
    jitrc(S, NoChange, N, T);

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

% integer and local variable

just_in_time2([N,<<"r@">>,<<"@">>,F|R]) when (((N == <<"nil">>) or (is_integer(N))) and ?bin_sym(F)) ->
    just_in_time2([<<"r@">>, <<"@">>,N,F|R]);
just_in_time2([N,<<"r@">>,M,<<"+">>,<<"@">>,F|R]) when (((N== <<"nil">>) or (is_integer(N))) and ?bin_sym(F)) ->
    just_in_time2([<<"r@">>,M,<<"+">>,<<"@">>,N,F|R]);
%two local variables
just_in_time2([<<"r@">>,<<"@">>,<<"r@">>,M,<<"+">>,<<"@">>,F|R]) when ((is_integer(M)) and ?bin_sym(F)) ->
    just_in_time2([<<"r@">>,M,<<"+">>,<<"@">>,<<"r@">>,<<"@">>,F|R]);
just_in_time2([<<"r@">>,N,<<"+">>,<<"@">>,<<"r@">>,M,<<"+">>,<<"@">>,F|R]) when ((((is_integer(N))) and is_integer(M)) and ((M > N) and ?bin_sym(F))) ->
    just_in_time2([<<"r@">>,M,<<"+">>,<<"@">>,<<"r@">>,N,<<"+">>,<<"@">>,F|R]);



%try to keep constants to the right, and variables to the left
just_in_time2([N, <<"r@">>, <<"@">>|R]) when ((N == <<"nil">>) or (is_integer(N)))->
    just_in_time2([<<"r@">>, <<"@">>, N, <<"swap">>|R]);
just_in_time2([N, <<"r@">>, M, <<"+">>, <<"@">>|R]) when (((N == <<"nil">>) or (is_integer(N))) and (is_integer(M))) ->
    just_in_time2([<<"r@">>, M, <<"+">>, <<"@">>, N, <<"swap">>|R]);
just_in_time2([<<"r@">>, N, <<"+">>, <<"@">>, <<"r@">>, M, <<"+">>, <<"@">>|R]) when ((((N == <<"nil">>) or (is_integer(N))) and (is_integer(M))) and (M > N)) ->
    just_in_time2([<<"r@">>, M, <<"+">>, <<"@">>, <<"r@">>, N, <<"+">>, <<"@">>, <<"swap">>|R]);

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



just_in_time3([<<"r@">>, <<"!">>|T]) ->
    B = used_pth(T, 0, 0),
    C = if
            B -> [<<"r@">>, <<"!">>|just_in_time3(T)];
            true -> [<<"drop">>|just_in_time3(T)]
        end;
just_in_time3([<<"r@">>, P, <<"+">>, <<"!">>|T]) ->
    B = used_pth(T, P, 0),
    C = if
            B -> [<<"r@">>, P, <<"+">>, <<"!">>|just_in_time3(T)];
            true -> [<<"drop">>|just_in_time3(T)]
        end;
just_in_time3([A|B]) ->
    [A|just_in_time3(B)];
just_in_time3([]) -> [].


