-module(chalang).
-export([run/6, test/5, replace/3]).
-record(d, {op_gas = 0, stack = [], alt = [],
	    ram_current = 0, ram_most = 0, ram_limit = 0, 
	    vars = {},  
	    funs = {}, many_funs = 0, fun_limit = 0
	   }).
-record(state, {total_coins, 
		height, %how many blocks exist so far
		slash = 0, %is this script being run as a solo_stop transaction, or a slash transaction?
		oracle, %this is the root of the merkle trie that says the results from all the oracles.
		accounts, 
		channels}). %data from the previous block that the contract may use.
-define(int, 0).
-define(binary, 2).
-define(print, 10).
-define(crash, 11).
-define(drop, 20).
-define(dup, 21).
-define(swap, 22).
-define(tuck, 23).
-define(rot, 24).
-define(ddup, 25).
-define(tuckn, 26).
-define(pickn, 27).
-define(to_r, 30).
-define(from_r, 31).
-define(r_fetch, 32).
-define(hash, 40).
-define(verify_sig, 41).
-define(add, 50).
-define(remainder, 57).
-define(eq, 58).
-define(caseif, 70).
-define(else, 71).
-define(then, 72).
-define(bool_flip, 80).
-define(bool_and, 81).
-define(bool_or, 82).
-define(bool_xor, 83).
-define(bin_and, 84).
-define(bin_or, 85).
-define(bin_xor, 86).
-define(stack_size, 90).
-define(pub2addr, 92).
-define(total_coins, 93).
-define(height, 94).
-define(slash, 95).
-define(gas, 96).
-define(ram, 97).
-define(id2pub, 98).
-define(oracle, 99).
-define(many_vars, 100).
-define(many_funs, 101).
-define(define, 110).
-define(fun_end, 111).
-define(recurse, 112).
-define(call, 113).
-define(set, 120).
-define(fetch, 121).
-define(cons, 130).
-define(car, 131).
-define(nil, 132).
-define(append, 134).
-define(split, 135).
-define(reverse, 136).
-define(int_bits, 32).

%op_gas limits our program in time.
%ram_gas limits our program in space.
make_tuple(X, Size) ->
    list_to_tuple(make_list(X, Size, [])).
make_list(_, 0, X) -> X;
make_list(X, Size, L) -> 
    make_list(X, Size - 1, [X|L]).
test(Script, OpGas, RamGas, Funs, Vars) ->
    D = #d{op_gas = OpGas,
	   ram_limit = RamGas,
	   vars = make_tuple(e, Vars),
	   funs = #{},
	   fun_limit = Funs,
	   ram_current = size(Script)},
    X = run2([Script], D),
    io:fwrite("\n"),
    io:fwrite("oGas, stack, alt, ram_current, ram_most, ram_limit, vars, funs, many_funs, fun_limit\n"),
    X.
run(ScriptSig, ScriptPubkey, OpGas, RamGas, Funs, Vars, State) ->
    true = balanced_f(ScriptSig, 0),
    true = balanced_f(ScriptPubkey, 0),
    true = none_of(ScriptSig, ?crash),
    Data = #d{op_gas = OpGas, 
	      ram_limit = RamGas, 
	      vars = make_tuple(e, Vars),
	      funs = #{},
	      fun_limit = Funs,%how many functions can be defined.
	      ram_current = size(ScriptSig) + size(ScriptPubkey) },
    io:fwrite("running script "),
    Data2 = run2([ScriptSig], Data, State),
    Data3 = run2([ScriptPubkey], Data2, State),
    [Amount|[Nonce|_]] = Data3#d.stack,
    ExtraGas = Data3#d.op_gas,
    ExtraRam = Data3#d.ram_limit - Data3#d.ram_most,
    io:fwrite("amount, nonce, spare_gas, spare_ram\n"),
    {Amount, Nonce, ExtraGas, ExtraRam}.
    
run2(_, D) when D#d.op_gas < 0 ->
    {error, "out of time"};
run2(_, D) when D#d.ram_current > D#d.ram_limit ->
    {error, "out of space"};
run2(A, D) when D#d.ram_current > D#d.ram_most ->
    run2(A, D#d{ram_most = D#d.ram_current});
run2([<<>>|T], D) -> run2(T, D);
run2([], D) -> D;
run2([<<?binary:8, H:32, Script/binary>>|Tail], D) ->
    T = D#d.stack,
    X = H * 8,
    <<Y:X, Script2/binary>> = Script,
    NewD = D#d{stack = [<<Y:X>>|T],
	       ram_current = D#d.ram_current + 1,%1 for the 1 list link added to ram.
	       op_gas = D#d.op_gas - H},
    %<<Temp:8, _/binary>> = Script2,
    run2([Script2|Tail], NewD);
run2([<<?int:8, V:?int_bits, Script/binary>>|T], D) ->
    NewD = D#d{stack = [<<V:?int_bits>>|D#d.stack],
	       ram_current = D#d.ram_current + 1,
	       op_gas = D#d.op_gas - 1},
    run2([Script|T], NewD);
run2([<<?caseif:8, Script/binary>>|Tail], D) ->
    [<<B:32>>|NewStack] = D#d.stack,
    {Case1, Rest} = split(?else, Script),
    {Case2, Rest2} = split(?then, Rest),
    Steps = size(Case1) + size(Case2),
    {Case, SkippedSize} = 
	case B of
	    0 -> %false
		{Case2, size(Case1)};
	    _ ->
		{Case1, size(Case2)}
	end,
    NewD = D#d{ stack = NewStack,
		ram_current = D#d.ram_current - SkippedSize - 1, % +1 for new list link in Script. -2 for the else and then that are deleted.
	       op_gas = D#d.op_gas - Steps},
    run2([Case|[Rest2|Tail]], NewD);
run2([<<?call:8>>|[<<?fun_end:8>>|Tail]], D) ->
    %tail call optimization
    %should work if "call" is the last instruction of a function, 
    %it should also work when "call" is the last instruction of a conditional branch, and the conditional branch's "then" is the last instruction.
    [H|T] = D#d.stack,
    Definition = maps:get(H, D#d.funs),
    S = size(Definition),
    NewD = D#d{op_gas = D#d.op_gas - S - 10,
	       ram_current = D#d.ram_current + S - 1,%-1 is for the call that is removed
	       stack = T},
    run2([Definition|[<<?fun_end:8>>|Tail]], NewD);
run2([<<?call:8, Script/binary>>|Tail], D) ->
    [H|T] = D#d.stack,
    Definition = maps:get(H, D#d.funs),
    S = size(Definition),
    NewD = D#d{op_gas = D#d.op_gas - S - 10,
	       ram_current = D#d.ram_current + S + 2,%-1 for call, +1 for fun_end, +2 for 2 new list links.
	       stack = T},
    run2([Definition|[<<?fun_end:8>>|[Script|Tail]]],NewD);
run2([<<?define:8, Script/binary>>|T], D) ->
    io:fwrite("run2 define\n"),
    {Definition, Script2} = split(?fun_end, Script),
    %true = balanced_r(Definition, 0),
    B = hash:doit(Definition),
    %replace "recursion" in the definition with a pointer to this.
    NewDefinition = replace(<<?recurse:8>>, <<2, 12:32, B/binary>>, Definition),
    io:fwrite("chalang define function "),
    compiler_chalang:print_binary(NewDefinition),
    io:fwrite("\n"),
    M = maps:put(B, NewDefinition, D#d.funs),
    S = size(NewDefinition) + size(B),
    MF = D#d.many_funs + 1,
    if
	MF > D#d.fun_limit ->
	    {error, "too many functions"};
	true ->
	    NewD = D#d{op_gas = D#d.op_gas - S - 30,
		       ram_current = D#d.ram_current + (2 * S),
		       many_funs = MF,
		       funs = M},
	    run2([Script2|T], NewD)
    end;
run2([<<?crash:8, _/binary>>|_], D) ->
    run2(<<>>, D);
run2([<<Command:8, Script/binary>>|T], D) ->
    case run3(Command, D) of
	{error, R} -> {error, R};
	NewD -> 
	    io:fwrite("run word "),
	    io:fwrite(integer_to_list(Command)),
	    io:fwrite("\n"),
	    run2([Script|T], NewD)
    end.

run3(?print, D) ->
    print_stack(D#d.stack),
    D;
run3(?drop, D) ->
    case D#d.stack of 
	[H|T] ->
	    D#d{stack = T,
		ram_current = D#d.ram_current - memory(H) - 2,%drop leaves, and the list link is gone
		op_gas = D#d.op_gas - 1};
	_ -> {error, "stack underflow"}
    end;
run3(?dup, D) ->
    [H|T] = D#d.stack,
    D#d{stack = [H|[H|T]],
	ram_current = D#d.ram_current + memory(H),
	op_gas = D#d.op_gas - 1};
run3(?swap, D) ->
    [A|[B|C]] = D#d.stack,
    Stack2 = [B|[A|C]],
    D#d{stack = Stack2,
	op_gas = D#d.op_gas - 1};
run3(?tuck, D) ->
    [A|[B|[C|E]]] = D#d.stack,
    Stack2 = [B|[C|[A|E]]],
    D#d{stack = Stack2,
	op_gas = D#d.op_gas - 1};
run3(?rot, D) ->
    [A|[B|[C|E]]] = D#d.stack,
    Stack2 = [C|[A|[B|E]]],
    D#d{stack = Stack2,
	op_gas = D#d.op_gas - 1};
run3(?ddup, D) ->
    [A|[B|C]] = D#d.stack,
    Stack2 = [A|[B|[A|[B|C]]]],
    D#d{stack = Stack2,
	ram_current = D#d.ram_current +
	    memory(A) + memory(B),
	op_gas = D#d.op_gas - 1};
run3(?tuckn, D) ->
    [N|[X|S]] = D#d.stack,
    H = lists:sublist(S, 1, N),
    T = lists:sublist(S, N+1, 100000000000000000),
    Stack2 = H ++ [X|T],
    D#d{stack = Stack2,
	op_gas = D#d.op_gas - 1};
run3(?pickn, D) ->
    [N|S] = D#d.stack,
    H = lists:sublist(S, 1, N - 1),
    [X|T] = lists:sublist(S, N, 100000000000000000),
    Stack2 = [X|(H ++ T)],
    D#d{stack = Stack2,
	op_gas = D#d.op_gas - 1};
run3(?to_r, D) ->
    [H|T] = D#d.stack,
    D#d{stack = T,
	op_gas = D#d.op_gas - 1,
	alt = [H|D#d.alt]};
run3(?from_r, D) ->
    [H|T] = D#d.alt,
    D#d{stack = [H|D#d.stack],
	alt = T,
	op_gas = D#d.op_gas - 1};
run3(?r_fetch, D) ->
    [H|T] = D#d.stack,
    D#d{stack = [H|D#d.stack],
	alt = [H|T],
	op_gas = D#d.op_gas - 1};
run3(?hash, D) ->
    [H|T] = D#d.stack,
    D#d{stack = [trie_hash:doit(H)|T],
	op_gas = D#d.op_gas - 20};
run3(?verify_sig, D) ->
    [Pub|[Data|[Sig|T]]] = D#d.stack,
    B = sign:verify_sig(Data, Sig, Pub),
    D#d{stack = [B|T],
	op_gas = D#d.op_gas - 20};
run3(X, D) when (X >= ?add) and (X < ?eq) ->
    [A|[B|C]] = D#d.stack,
    D#d{stack = [arithmetic_chalang:doit(X, A, B)|C],
	op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current - 2};
run3(?eq, D) ->
    ST = D#d.stack,
    [A|[B|_]] = ST,
    C = if
	    A == B -> 1;
	    true -> 0
	end,
    S = [<<C:?int_bits>>|ST],
    D#d{stack = S, 
	op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 1};

run3(?bool_flip, D) ->
    [<<H:32>>|T] = D#d.stack,
    B = case H of
	    0 -> 1;
	    _ -> 0
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<B:32>>|T]};
run3(?bool_and, D) ->
    [<<A:32>>|[<<B:32>>|T]] = D#d.stack,
    C = case {A, B} of
	    {0, _} -> 0;
	    {_, 0} -> 0;
	    {_, _} -> 1
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<C:32>>|T],
	ram_current = D#d.ram_current - 2};
run3(?bool_or, D) ->
    [<<A:32>>|[<<B:32>>|T]] = D#d.stack,
    C = case {A, B} of
	    {0, 0} -> 0;
	    {_, _} -> 1
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<C:32>>|T],
	ram_current = D#d.ram_current - 2};
run3(?bool_xor, D) ->
    [G|[H|T]] = D#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    C = case {A, B} of
	    {0, 0} -> 0;
	    {0, _} -> 1;
	    {_, 0} -> 1;
	    _ -> 0
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<C:8>>|T],
	ram_current = D#d.ram_current - 2};
run3(?bin_and, D) ->
    [G|[H|T]] = D#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    E = max(B, D),
    F = A band C,
    D#d{op_gas = D#d.op_gas - E,
	stack = [<<F:E>>|T],
	ram_current = D#d.ram_current - min(B, D) - 1};
run3(?bin_and, D) ->
    [G|[H|T]] = D#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    E = max(B, D),
    F = A bor C,
    D#d{op_gas = D#d.op_gas - E,
	stack = [<<F:E>>|T],
	ram_current = D#d.ram_current - min(B, D) - 1};
run3(?bin_xor, D) ->
    [G|[H|T]] = D#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    E = max(B, D),
    F = A bxor C,
    D#d{op_gas = D#d.op_gas - E,
	stack = [<<F:E>>|T],
	ram_current = D#d.ram_current - min(B, D) - 1};
run3(?stack_size, D) ->
    S = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [length(S)|S]};
run3(?total_coins, D, State) ->
    S = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<State#state.total_coins:?int_bits>>|S]};
run3(?height, D, State) ->
    S = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<State#state.height:?int_bits>>|S]};
run3(?gas, D) ->
    G = D#d.op_gas,
    D#d{op_gas = G - 1,
	stack = [G|D#d.stack],
	ram_current = D#d.ram_current + 2};
run3(?many_vars, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [size(D#d.vars)|D#d.stack],
	ram_current = D#d.ram_current + 2};
run3(?many_funs, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [D#d.many_funs|D#d.stack],
	ram_current = D#d.ram_current + 2};
run3(?fun_end, D) ->
    D#d{op_gas = D#d.op_gas - 1};
run3(?set, D) ->
    [<<Key:32>>|[Value|T]] = D#d.stack,
    Vars = setelement(Key, D#d.vars, Value),
    D#d{op_gas = D#d.op_gas - 1,
	stack = T,
	vars = Vars};
run3(?fetch, D) ->
    [<<Key:32>>|T] = D#d.stack,
    Value = element(Key, D#d.vars),
    D#d{op_gas = D#d.op_gas - 1,
	stack = [Value|T],
	ram_current = D#d.ram_current + memory(Value) + 1};
run3(?cons, D) -> % ( A [B] -- [A, B] )
    [A|[B|T]] = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [[B|A]|T],
	ram_current = D#d.ram_current + 1};
run3(?car, D) -> % ( [A, B] -- A [B] )
    [[B|A]|T] = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [A|[B|T]],
	ram_current = D#d.ram_current - 1};
run3(?nil, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [[]|D#d.stack],
	ram_current = D#d.ram_current + 1};
run3(?append, D) ->
    [A|[B|T]] = D#d.stack,
    C = if
	    is_binary(A) and is_binary(B) ->
		<<B/binary, A/binary>>;
	    is_list(A) and is_list(B) ->
		B ++ A
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [C|T],
	ram_current = D#d.ram_current + 1};
run3(?split, D) ->
    [N|[L|T]] = D#d.stack,
    M = N * 8,
    {G, H} = if
	    is_binary(L) -> 
		<<A:M, B/binary>> = L,
		{<<A:M>>, B};
	    is_list(L) ->
		split_list(N, L)
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [G|[H|T]],
	ram_current = D#d.ram_current - 1};
run3(?reverse, D) ->
    [H|T] = D#d.stack,
    D#d{op_gas = D#d.op_gas - length(H),
	stack = [lists:reverse(H)|T]}.


memory(L) -> memory(L, 0).
memory([], X) -> X+1;
memory([H|T], X) -> memory(T, 1+memory(H, X));
memory(B, X) -> X+size(B).
balanced_r(<<>>, 0) -> true;
balanced_r(<<>>, 1) -> false;
balanced_r(_, X) when X < 0 -> false;
balanced_r(<<?int:8, _:?int_bits, Script/binary>>, X) ->
    balanced_r(Script, X);
balanced_r(<<?binary:8, H:32, Script/binary>>, D) ->
    X = H * 8,
    <<_:X, Script2/binary>> = Script,
    balanced_r(Script2, D);
balanced_r(<<?to_r:8, Script/binary>>, X) ->
    balanced_r(Script, X+1);
balanced_r(<<?from_r:8, Script/binary>>, X) ->
    balanced_r(Script, X-1);
balanced_r(<<_:8, Script/binary>>, X) ->
    balanced_r(Script, X).
%balanced_f makes sure that every function we start finishes, and that there aren't functions inside of each other.
balanced_f(<<>>, 0) -> true;
balanced_f(<<>>, 1) -> false;
balanced_f(<<?define:8, Script/binary>>, 0) ->
    balanced_f(Script, 1);
balanced_f(<<?define:8, _/binary>>, 1) -> false;
balanced_f(<<?fun_end:8, Script/binary>>, 1) ->
    balanced_f(Script, 0);
balanced_f(<<?fun_end:8, _/binary>>, 0) -> false;
balanced_f(<<?int:8, _:?int_bits, Script/binary>>, X) ->
    balanced_f(Script, X);
balanced_f(<<?binary:8, H:8, Script/binary>>, D) ->
    X = H * 8,
    <<_:X, Script2/binary>> = Script,
    balanced_f(Script2, D);
balanced_f(<<_:8, Script/binary>>, X) ->
    balanced_f(Script, X).
none_of(<<>>, _) -> true;
none_of(<<X:8, _/binary>>, X) -> false;
none_of(<<?int:8, _:?int_bits, Script/binary>>, X) -> 
    none_of(Script, X);
none_of(<<?binary:8, H:8, Script/binary>>, D) -> 
    X = H * 8,
    <<_:X, Script2/binary>> = Script,
    none_of(Script2, D);
none_of(<<_:8, Script/binary>>, X) -> 
    none_of(Script, X).
replace(Old, New, Binary) ->
    replace(Old, New, Binary, 0).
replace(_, _, B, P) when (P div 8) > size(B) ->
    B;
replace(Old, New, Binary, Pointer) ->
    %io:fwrite("replace\n"),
    N = 8 * size(Old),
    <<AB:N>> = Old,
    case Binary of
	<<D:Pointer, AB:N, R/binary>> ->
	    <<D:Pointer, New/binary, R/binary>>;
	<<_:Pointer, ?int:8, _:?int_bits, _/binary>> ->
	    replace(Old, New, Binary, Pointer+8+?int_bits);
	<<_:Pointer, ?binary:8, H:32, _/binary>> ->
	    X = H * 8,
	    replace(Old, New, Binary, Pointer+8+32+X);
	_ -> replace(Old, New, Binary, Pointer+8)
    end.
	    
split(X, B) ->
    split(X, B, 0).
split(X, B, N) ->
    <<_:N, Y:8, _/binary>> = B,
    case Y of
	?int -> split(X, B, N+8+?int_bits);
	?binary ->
	    <<_:N, Y:8, H:8, _/binary>> = B,
	    %J = H*8,
	    %<<_:N, Y:8, H:8, _:H, _/binary>> = B,
	    split(X, B, N+16+(H*8));
	X ->
	    <<A:N, Y:8, T/binary>> = B,
	    {<<A:N>>, T};
	_ -> split(X, B, N+8)
    end.
split_list(N, L) ->
    split_list(N, L, []).
split_list(0, A, B) ->
    {lists:reverse(B), A};
split_list(N, [H|T], B) ->
    split_list(N-1, T, [H|B]).
print_stack(X) ->
    print_stack(7, X),
    io:fwrite("\n").
print_stack(_, []) -> io:fwrite("[]");
print_stack(0, _) -> io:fwrite("\n");
print_stack(N, [H]) ->
    io:fwrite("["),
    print_stack(N-1, H),
    io:fwrite("]");
print_stack(N, [H|T]) ->
    io:fwrite("["),
    print_stack(N-1, H),
    io:fwrite("|"),
    print_stack(N - 1, T),
    io:fwrite("]");
print_stack(_, <<X:8>>) ->
    io:fwrite("c"++integer_to_list(X) ++" ");
print_stack(_, <<N:32>>) ->
    io:fwrite("i"++integer_to_list(N) ++" ");
print_stack(_, <<F:32, G:32>>) ->
    io:fwrite(" " ++integer_to_list(F) ++"/"++
		  integer_to_list(G) ++" ");
print_stack(_, B) -> io:fwrite(binary_to_list(base64:encode(B)) ++ "\n").
