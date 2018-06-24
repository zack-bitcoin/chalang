-module(test_chalang).
-export([test/0, test/1, run_script/3]).

-define(loc, "src/forth/").
run_script(X, Gas, Loc) ->
    {ok, A} = file:read_file(Loc ++ X ++ ".fs"),
    io:fwrite(A),
    io:fwrite("\n"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test \n">>/binary>>),
    chalang:test(B, Gas, Gas, Gas, Gas, []).
run_scripts([], _, _) -> ok;
run_scripts([H|T], Gas, Loc) ->
    io:fwrite("run script "),
    io:fwrite(H),
    io:fwrite("\n"),
    X = run_script(H, Gas, Loc),
    %{d, NewGas, [<<1:32>>],_,_,_,_,_,_,_,_,_} = X,
    NewGas = chalang:time_gas(X),
    [<<1:32>>] = chalang:stack(X),
    run_scripts(T, NewGas, Loc).
test() -> test(?loc).
test(Loc) ->
    Scripts = [
	       "function", "variable",
	       "macro", "case", "recursion", "map",
	       "math", "hashlock", "case2", 
	       "case_binary", "binary_converter"],
	       %"merge"],
    Gas = 10000,
    run_scripts(Scripts, Gas, Loc),


    {ok, A} = file:read_file(Loc ++ "satoshi_dice.fs"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test1 \n">>/binary>>),
    D1 = chalang:test(B, Gas, Gas, Gas, Gas, []),
    [<<0:32>>,<<0:32>>,<<1:32>>] = chalang:stack(D1),
    C = compiler_chalang:doit(<<A/binary, <<"\n test2 \n">>/binary>>),
    D2 = chalang:test(C, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<0:32>>,<<2:32>>] = chalang:stack(D2),
    D = compiler_chalang:doit(<<A/binary, <<"\n test3 \n">>/binary>>),
    D3 = chalang:test(D, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<1:32>>,<<2:32>>] = chalang:stack(D3),
    E = compiler_chalang:doit(<<A/binary, <<"\n test4 \n">>/binary>>),
    D4 = chalang:test(E, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<0:32>>,<<3:32>>] = chalang:stack(D4),
    S = success,
    S = compiler_lisp:test(),
    S = compiler_lisp2:test(),
    success.
