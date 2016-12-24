-module(test_chalang).
-export([test/0, test/1, run_script/3]).

-define(loc, "examples/").
run_script(X, Gas, Loc) ->
    {ok, A} = file:read_file(Loc ++ X ++ ".fs"),
    %io:fwrite("run script "),
    %io:fwrite(A),
    %io:fwrite("\n"),
    %io:fwrite("\n"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test \n">>/binary>>),
    {d,_,[<<1:32>>],_,_,_,_,_,_,_,_,_} = chalang:test(B, Gas, Gas, Gas, Gas).
run_scripts([], _, _) -> ok;
run_scripts([H|T], Gas, Loc) ->
    {d, NewGas, [<<1:32>>],_,_,_,_,_,_,_,_,_} = run_script(H, Gas, Loc),
    run_scripts(T, NewGas, Loc).
test() -> test(?loc).
test(Loc) ->
    Scripts = ["hashlock", "function", "variable",
	       "macro", "case", "recursion", "map"],
	       %"merge"],
    run_scripts(Scripts, 10000, Loc),
    success.
    
