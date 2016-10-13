-module(test_chalang).
-export([test/0, run_script/2]).

-define(loc, "examples/").
run_script(X, Gas) ->
    {ok, A} = file:read_file(?loc ++ X ++ ".fs"),
    io:fwrite("run script "),
    io:fwrite(A),
    io:fwrite("\n"),
    io:fwrite("\n"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test \n">>/binary>>),
    %oGas, stack, alt, ram_current, ram_most, ram_limit, vars, funs, many_funs, fun_limit
    {d,_,[<<1:32>>],_,_,_,_,_,_,_,_} = chalang:test(B, Gas, Gas, Gas, Gas).
run_scripts([], _) -> ok;
run_scripts([H|T], Gas) ->
    io:fwrite("running script "),
    io:fwrite(H),
    io:fwrite("============================\n"),
    {d, NewGas, [<<1:32>>],_,_,_,_,_,_,_,_} = run_script(H, Gas),
    run_scripts(T, NewGas).

test() ->
    Scripts = ["hashlock", "function", "variable",
	       "macro", "case", "recursion", "map",
	       "merge"],
    run_scripts(Scripts, 10000).
    
