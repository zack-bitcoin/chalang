-module(test_chalang).
-export([test/0, test/1, run_script/3]).

-define(loc, "examples/").
run_script(X, Gas, Loc) ->
    {ok, A} = file:read_file(Loc ++ X ++ ".fs"),
    io:fwrite("run script "),
    io:fwrite(X),
    io:fwrite("\n"),
    io:fwrite("\n"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test \n">>/binary>>),
    chalang:test(B, Gas, Gas, Gas, Gas, []).
run_scripts([], _, _) -> ok;
run_scripts([H|T], Gas, Loc) ->
    X = run_script(H, Gas, Loc),
    {d, NewGas, [<<1:32>>],_,_,_,_,_,_,_,_,_} = X,
    run_scripts(T, NewGas, Loc).
test() -> test(?loc).
test(Loc) ->
    Scripts = ["function", "variable",
	       "macro", "case", "recursion", "map",
	       "math", "hashlock", "case2"],
	       %"merge"],
    Gas = 10000,
    run_scripts(Scripts, Gas, Loc),


    {ok, A} = file:read_file(Loc ++ "satoshi_dice.fs"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test1 \n">>/binary>>),
    {d, _, Stack, _,_,_,_,_,_,_,_,_} = chalang:test(B, Gas, Gas, Gas, Gas, []),
    [<<0:32>>,<<0:32>>,<<1:32>>] = Stack,
    C = compiler_chalang:doit(<<A/binary, <<"\n test2 \n">>/binary>>),
    {d, _, Stack2, _,_,_,_,_,_,_,_,_} = chalang:test(C, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<0:32>>,<<2:32>>] = Stack2,
    D = compiler_chalang:doit(<<A/binary, <<"\n test3 \n">>/binary>>),
    {d, _, Stack3, _,_,_,_,_,_,_,_,_} = chalang:test(D, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<1:32>>,<<2:32>>] = Stack3,
    E = compiler_chalang:doit(<<A/binary, <<"\n test4 \n">>/binary>>),
    {d, _, Stack4, _,_,_,_,_,_,_,_,_} = chalang:test(E, Gas, Gas, Gas, Gas, []),
    [<<1000:32>>,<<0:32>>,<<3:32>>] = Stack4,
    success.
