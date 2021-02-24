-module(test_chalang).
-export([test/0, test/1, run_script/3, test_func/0]).

-define(loc, "src/forth/").
run_script(X, Gas, Loc) ->
    {ok, A} = file:read_file(Loc ++ X ++ ".fs"),
    io:fwrite(A),
    io:fwrite("\n"),
    B = compiler_chalang:doit(<<A/binary, <<"\n test \n">>/binary>>),
    io:fwrite("compiled script \n"),
    disassembler:doit(B),
    %rp(<<0,B/binary>>),
    io:fwrite("\n"),
    chalang:test(B, Gas, Gas, Gas, Gas, []).
run_scripts([], _, _) -> ok;
run_scripts([H|T], Gas, Loc) ->
    io:fwrite("run script "),
    io:fwrite(H),
    io:fwrite("\n"),
    X = run_script(H, Gas, Loc),
    %{d, NewGas, [<<1:32>>],_,_,_,_,_,_,_,_,_} = X,
    case X of
	{error, R} -> 
	    io:fwrite(R),
	    io:fwrite("\n"),
	    1=2;
	_ ->
	    [<<1:32>>] = chalang:stack(X),
	    NewGas = chalang:time_gas(X),
	    run_scripts(T, NewGas, Loc)
    end.
   
test_func() -> 
    %The purpose of this test is to show how much shorter the contract can be with our new tool for defining functions.

    %A0 = <<" int 3 : square dup * ; square X ! X @ call X @ call ">>,
    A0 = <<" int 3 : square dup * ; square call square call ">>,
    A = <<" int 3 def square dup * ; dup >r call r> call ">>,
    %A = <<" int 3 def square dup * ; X ! X @ call X @ call ">>,
    B0 = compiler_chalang:doit(<<A0/binary>>),
    B = compiler_chalang:doit(<<A/binary>>),
    io:fwrite("test chalang sizes \n"),
    io:fwrite(integer_to_list(size(B0))),
    io:fwrite("\n"),
    io:fwrite(integer_to_list(size(B))),
    io:fwrite("\n"),
    Gas = 10000,
    chalang:test(B, Gas, Gas, Gas, Gas, []).
    
test() -> test(?loc).
test(Loc) ->
    Scripts = [ "string"],
    Scripts_old = [
                "tuckn_test", "if_test", "pickn",
		"filter",
		"merge_sort",
		"function", "variable",
		"macro", "case", "recursion", "map",
		"math", "hashlock", "case2", 
		"case_binary", "binary_converter",
                "function2"
	      ],
    Gas = 100000,
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
    %S = compiler_lisp2:test(),
    success.
