-module(chalang).
-export([run/7, test/6, vm/6, replace/3, new_state/6, split/2]).
-record(d, {op_gas = 0, stack = [], alt = [],
	    ram_current = 0, ram_most = 0, ram_limit = 0, 
	    vars = {},  
	    funs = {}, many_funs = 0, fun_limit = 0,
	    state = []
	   }).
-record(state, {total_coins, 
		height, %how many blocks exist so far
		slash = 0, %is this script being run as a solo_stop transaction, or a slash transaction?
		oracle, %this is the root of the merkle trie that says the results from all the oracles.
		accounts, 
		channels}). %data from the previous block that the contract may use.
new_state(TotalCoins, Height, Slash, Oracle, Accounts, Channels) ->
    #state{total_coins = TotalCoins, height = Height,
	   slash = Slash, oracle = Oracle,
	   accounts = Accounts, channels = Channels}.
-define(int, 0).
-define(binary, 2).
-define(print, 10).
-define(crash, 11).
-define(nop, 12).
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
-define(is_list, 137).
-define(int_bits, 32).

%op_gas limits our program in time.
%ram_gas limits our program in space.
make_tuple(X, Size) ->
    list_to_tuple(make_list(X, Size, [])).
make_list(_, 0, X) -> X;
make_list(X, Size, L) -> 
    make_list(X, Size - 1, [X|L]).
vm(Script, OpGas, RamGas, Funs, Vars, State) ->
    X = test(Script, OpGas, RamGas, Funs, Vars, State),
    X#d.stack.
test(Script, OpGas, RamGas, Funs, Vars, State) ->
    D = #d{op_gas = OpGas,
	   ram_limit = RamGas,
	   vars = make_tuple(e, Vars),
	   funs = #{},
	   fun_limit = Funs,
	   ram_current = size(Script), 
	   state = State},
    %compiler_chalang:print_binary(Script),
    %io:fwrite("\nrunning a script =============\n"),
    %disassembler:doit(Script),
    X = run2([Script], D).
    %io:fwrite("\n"),

						%io:fwrite("oGas, stack, alt, ram_current, ram_most, ram_limit, vars, funs, many_funs, fun_limit\n"),
    %X#d.stack.

%run takes a list of bets and scriptpubkeys. Each bet is processed seperately by the RUN2, and the results of each bet is accumulated together to find the net result of all the bets.
run(ScriptSig, SPK, OpGas, RamGas, Funs, Vars, State) ->
    run(ScriptSig, SPK, OpGas, RamGas, Funs, Vars, State, 0, 0).
run([],[], OpGas, RamGas, _, _, _, Amount, Nonce) ->
    {Amount, Nonce, OpGas, RamGas};
run([SS|ScriptSig], [SPK|ScriptPubkey], OpGas, RamGas, Funs, Vars, State, Amount, Nonce) ->
    %io:fwrite("\nScriptSig =============\n"),
    %disassembler:doit(SS),
    %io:fwrite("\nSPK =============\n"),
    %disassembler:doit(SPK),
    {A2, N2, EOpGas, ERamGas} = run3(SS, SPK, OpGas, RamGas, Funs, Vars, State),
    run(ScriptSig, ScriptPubkey, EOpGas, ERamGas, Funs, Vars, State, A2+Amount, N2+Nonce).

%run3 takes a single bet and scriptpubkey, and calculates the result.
run3(ScriptSig, ScriptPubkey, OpGas, RamGas, Funs, Vars, State) ->
    %io:fwrite("script sig is "),
    %compiler_chalang:print_binary(ScriptSig),
    %io:fwrite("spk is "),
    %compiler_chalang:print_binary(ScriptPubkey),
    true = balanced_f(ScriptSig, 0),
    true = balanced_f(ScriptPubkey, 0),
    true = none_of(ScriptSig, ?crash),
    Data = #d{op_gas = OpGas, 
	      ram_limit = RamGas, 
	      vars = make_tuple(e, Vars),
	      funs = #{},
	      fun_limit = Funs,%how many functions can be defined.
	      ram_current = size(ScriptSig) + size(ScriptPubkey),
	      state = State},
    %io:fwrite("running script "),
    Data2 = run2([ScriptSig], Data),
    Data3 = run2([ScriptPubkey], Data2),
    [<<Amount:32>>|
     [<<Direction:32>>|
      [<<Nonce:32>>|_]]] = Data3#d.stack,
    ExtraGas = Data3#d.op_gas,
    ExtraRam = Data3#d.ram_limit - Data3#d.ram_most,
    %io:fwrite("amount, nonce, spare_gas, spare_ram\n"),
    D = case Direction of
	    0 -> 1;
	    _ -> -1
	end,
    {Amount * D, Nonce, ExtraGas, ExtraRam}.
   
%run2 processes a single opcode of the script. in comparison to run3/2, run2 is able to edit more aspects of the RUN2's state. run2 is used to define functions and variables. run3/2 is for all the other opcodes. 
run2(_, D) when D#d.op_gas < 0 ->
    io:fwrite("out of time"),
    D = ok,
    {error, "out of time"};
run2(_, D) when D#d.ram_current > D#d.ram_limit ->
    io:fwrite("Out of space. Limit was: "),
    io:fwrite(integer_to_list(D#d.ram_limit)),
    io:fwrite("\n"),
    D = ok,
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
    {Case1, Rest, _} = split_if(?else, Script),
    {Case2, Rest2, _} = split_if(?then, Rest),
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
    %it should also work when "call" is the last instruction of a conditional branch, and the conditional branch's "then" is the last instruction of the function.
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
    %io:fwrite("run2 define\n"),
    {Definition, Script2, _} = split(?fun_end, Script),
    %true = balanced_r(Definition, 0),
    B = hash:doit(Definition),
    %replace "recursion" in the definition with a pointer to this.
    NewDefinition = replace(<<?recurse:8>>, <<2, 12:32, B/binary>>, Definition),
    %io:fwrite("chalang define function "),
    %compiler_chalang:print_binary(NewDefinition),
    %io:fwrite("\n"),
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
    run2([<<>>], D);
run2([<<Command:8, Script/binary>>|T], D) ->
    case run3(Command, D) of
	{error, R} -> {error, R};
	NewD -> 
	    %io:fwrite("run word "),
	    %io:fwrite(integer_to_list(Command)),
	    %io:fwrite("\n"),
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
    D#d{stack = [hash:doit(H)|T],
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
run3(?bool_xor, Data) ->
    [G|[H|T]] = Data#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    J = case {A, C} of
	    {0, 0} -> 0;
	    {0, _} -> 1;
	    {_, 0} -> 1;
	    _ -> 0
	end,
    Data#d{op_gas = Data#d.op_gas - 1,
	stack = [<<J:32>>|T],
	ram_current = Data#d.ram_current - 2};
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
run3(?bin_or, D) ->
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
run3(?bin_xor, Data) ->
    [G|[H|T]] = Data#d.stack,
    B = 8 * size(G),
    D = 8 * size(H),
    <<A:B>> = G,
    <<C:D>> = H,
    E = max(B, D),
    F = A bxor C,
    Data#d{op_gas = Data#d.op_gas - E,
	stack = [<<F:E>>|T],
	ram_current = Data#d.ram_current - min(B, D) - 1};
run3(?stack_size, D) ->
    S = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [length(S)|S]};
run3(?total_coins, D) ->
    S = D#d.stack,
    TC = D#d.state#state.total_coins,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<TC:?int_bits>>|S]};
run3(?height, D) ->
    S = D#d.stack,
    H = D#d.state#state.height,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<H:?int_bits>>|S]};
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
    false = (Value == e),
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
	stack = [lists:reverse(H)|T]};
run3(?is_list, D) ->
    [H|T] = D#d.stack,
    G = if
	    is_list(H) -> <<1:?int_bits>>;
	    true -> <<0:?int_bits>>
	end,
    D#d{op_gas = D#d.op_gas - 1,
	stack = [G|[H|T]],
	ram_current = D#d.ram_current - 1};
run3(?nop, D) -> D.


    


memory(L) -> memory(L, 0).
memory([], X) -> X+1;
memory([H|T], X) -> memory(T, 1+memory(H, X));
memory(B, X) -> X+size(B).
%balanced_r(<<>>, 0) -> true;
%balanced_r(<<>>, 1) -> false;
%balanced_r(_, X) when X < 0 -> false;
%balanced_r(<<?int:8, _:?int_bits, Script/binary>>, X) ->
%    balanced_r(Script, X);
%balanced_r(<<?binary:8, H:32, Script/binary>>, D) ->
%    X = H * 8,
%    <<_:X, Script2/binary>> = Script,
%    balanced_r(Script2, D);
%balanced_r(<<?to_r:8, Script/binary>>, X) ->
%    balanced_r(Script, X+1);
%balanced_r(<<?from_r:8, Script/binary>>, X) ->
%    balanced_r(Script, X-1);
%balanced_r(<<_:8, Script/binary>>, X) ->
%    balanced_r(Script, X).
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
balanced_f(<<?binary:8, H:32, Script/binary>>, D) ->
    X = H * 8,
    <<_:X, Script2/binary>> = Script,
    balanced_f(Script2, D);
balanced_f(<<_:8, Script/binary>>, X) ->
    balanced_f(Script, X).
none_of(<<>>, _) -> true;
none_of(<<X:8, _/binary>>, X) -> false;
none_of(<<?int:8, _:?int_bits, Script/binary>>, X) -> 
    none_of(Script, X);
none_of(<<?binary:8, H:32, Script/binary>>, D) -> 
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
    <<_:N, Y:8, C/binary>> = B,
    case Y of
	?int -> split(X, B, N+8+?int_bits);
	?binary ->
	    <<_:N, Y:8, H:32, _/binary>> = B,
	    %J = H*8,
	    %<<_:N, Y:8, H:8, _:H, _/binary>> = B,
	    split(X, B, N+16+(H*8));
	X ->
	    <<A:N, Y:8, T/binary>> = B,
	    {<<A:N>>, T, N};
	_ -> split(X, B, N+8)
    end.
split_if(X, B) ->
    split_if(X, B, 0).
split_if(X, B, N) ->
    <<_:N, Y:8, C/binary>> = B,
    case Y of
	?int -> split_if(X, B, N+8+?int_bits);
	?binary ->
	    <<_:N, Y:8, H:32, _/binary>> = B,
	    %J = H*8,
	    %<<_:N, Y:8, H:8, _:H, _/binary>> = B,
	    split_if(X, B, N+40+(H*8));
	?caseif ->
	    {_, Rest, M} = split_if(?then, C),
	    split_if(X, B, N+M+16);
	X ->
	    <<A:N, Y:8, T/binary>> = B,
	    {<<A:N>>, T, N};
	_ -> split_if(X, B, N+8)
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
