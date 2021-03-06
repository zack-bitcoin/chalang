-module(chalang).
-export([run5/2, data_maker/9, data_maker/10, test/6, vm/6, replace/3, new_state/3, new_state/2, split/2, none_of/1, stack/1, time_gas/1]).
-record(d, {op_gas = 0, stack = [], alt = [],
	    ram_current = 0, ram_most = 0, ram_limit = 0, 
	    vars = {},  
	    funs = {}, many_funs = 0, fun_limit = 0,
	    state = [], hash_size = chalang_constants:hash_size(),
            version = 0,
            verbose = false
	   }).
-record(state, {
	  height, %how many blocks exist so far
	  slash = 0 %is this script being run as a solo_stop transaction, or a slash transaction?
	 }).
stack(D) -> D#d.stack.
time_gas(D) -> D#d.op_gas.
%space_gas(D) -> D#d.ram_current.
new_state(Height, Slash, _) ->
    new_state(Height, Slash).
new_state(Height, Slash) ->
    #state{height = Height, 
	   slash = Slash}.
-define(int, 0).
-define(binary, 2).
-define(int1, 3).
-define(int2, 4).
-define(print, 10).
-define(return, 11).
-define(nop, 12).
-define(fail, 13).
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
-define(eq2, 59).
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
-define(height, 94).
-define(gas, 96).
-define(ram, 97).
-define(many_vars, 100).
-define(many_funs, 101).
-define(define, 110).
-define(define2, 114).
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


-define(int_bits, 32). %this isn't an opcode, it is for writing this same page. chalang.erl

%op_gas limits our program in time.
%ram_gas limits our program in space.
make_tuple(X, Size) ->
    list_to_tuple(make_list(X, Size, [])).
make_list(_, 0, X) -> X;
make_list(X, Size, L) -> 
    make_list(X, Size - 1, [X|L]).
vm(Script, OpGas, RamGas, Funs, Vars, State) ->
    X = test(Script, OpGas, RamGas, Funs, Vars, State),
    case X of
	{error, R} -> io:fwrite("chalang error "),
		      io:fwrite(R),
		      io:fwrite("\n"),
		      [];
	_ ->
	    X#d.stack
    end.
test(Script, OpGas, RamGas, Funs, Vars, State) ->
    D = #d{op_gas = OpGas,
	   ram_limit = RamGas,
	   vars = make_tuple(e, Vars),
	   funs = #{},
	   fun_limit = Funs,
	   ram_current = size(Script), 
	   state = State,
           version = 2,
           verbose = false},
    %compiler_chalang:print_binary(Script),
    %io:fwrite("\nrunning a script =============\n"),
    %disassembler:doit(Script),
    run1([Script], D).
    %io:fwrite("\n"),

						%io:fwrite("oGas, stack, alt, ram_current, ram_most, ram_limit, vars, funs, many_funs, fun_limit\n"),
    %X#d.stack.

%run takes a list of bets and scriptpubkeys. Each bet is processed seperately by the RUN2, and the results of each bet is accumulated together to find the net result of all the bets.
data_maker(OpGas, RamGas, Vars, Funs, ScriptSig, SPK, State, HashSize, Version) ->
    data_maker(OpGas, RamGas, Vars, Funs, ScriptSig, SPK, State, HashSize, Version, false).
data_maker(OpGas, RamGas, Vars, Funs, ScriptSig, SPK, State, HashSize, Version, Verbose) ->
    #d{op_gas = OpGas, 
       ram_limit = RamGas, 
       vars = make_tuple(e, Vars),
       funs = #{},
       fun_limit = Funs,%how many functions can be defined.
       ram_current = size(ScriptSig) + size(SPK),
       state = State, 
       hash_size = HashSize,
       version = Version,
       verbose = Verbose}.
    
%run2 processes a single opcode of the script. in comparison to run3/2, run2 is able to edit more aspects of the RUN2's state. run2 is used to define functions and variables. run3/2 is for all the other opcodes. 
run5(A, D) ->
    true = balanced_f(A, 0),
    run1([A], D).
run1(_, {error, S}) ->
    io:fwrite("had an error\n"),
    io:fwrite(S),
    io:fwrite("\n"),
    {error, S};
run1(_, D) when D#d.op_gas < 0 ->
    io:fwrite("out of time"),
    {error, "out of time"};
run1(_, D) when D#d.ram_current > D#d.ram_limit ->
    io:fwrite("Out of space. Limit was: "),
    io:fwrite(integer_to_list(D#d.ram_limit)),
    io:fwrite("\n"),
    {error, "out of space"};
run1(A, D) when D#d.ram_current > D#d.ram_most ->
    run1(A, D#d{ram_most = D#d.ram_current});
run1([<<>>|T], D) -> run1(T, D);
run1([], D) -> D;
run1(A, B) -> 
    if
        B#d.verbose ->
            [<<C:8, _/binary>>|_] = A,
            print_stack(5, B#d.stack),
            io:fwrite("opcode: "),
            io:fwrite(disassembler:doit2(C)),
            io:fwrite("\n"),
            ok;
        true -> ok
    end,
    run2(A, B).
run2([<<?binary:8, H:32, Script/binary>>|Tail], D) ->
    T = D#d.stack,
    X = H * 8,
    case Script of
	<<Y:X, Script2/binary>> ->
	    NewD = D#d{stack = [<<Y:X>>|T],
		       ram_current = D#d.ram_current + 1,%1 for the 1 list link added to ram.
		       op_gas = D#d.op_gas - H},
	    run1([Script2|Tail], NewD);
	true -> {error, "read binary underflow"}
    end;
run2([<<?int:8, V:?int_bits, Script/binary>>|T], D) ->
    NewD = D#d{stack = [<<V:?int_bits>>|D#d.stack],
	       ram_current = D#d.ram_current + 1,
	       op_gas = D#d.op_gas - 1},
    run1([Script|T], NewD);
run2([<<?int1:8, V:8, Script/binary>>|T], D) ->
    true = (D#d.version > 1),
    NewD = D#d{stack = [<<V:?int_bits>>|D#d.stack],
	       ram_current = D#d.ram_current + 1,
	       op_gas = D#d.op_gas - 1},
    run1([Script|T], NewD);
run2([<<?int2:8, V:16, Script/binary>>|T], D) ->
    true = (D#d.version > 1),
    NewD = D#d{stack = [<<V:?int_bits>>|D#d.stack],
	       ram_current = D#d.ram_current + 1,
	       op_gas = D#d.op_gas - 1},
    run1([Script|T], NewD);
run2([<<X:8, Script/binary>>|T], D) when ((X > 139) and (X < 176))->
    Y = X - 140,
    true = (D#d.version > 1),
    NewD = D#d{stack = [<<Y:?int_bits>>|D#d.stack],
	       ram_current = D#d.ram_current + 1,
	       op_gas = D#d.op_gas - 1},
    run1([Script|T], NewD);
run2([<<?caseif:8, Script/binary>>|Tail], D) ->
    [<<B:32>>|NewStack] = D#d.stack,
    case split_if(?else, Script) of
	{error, R1} -> {error, R1};
	{Case1, Rest, _} ->
	    case split_if(?then, Rest) of
		{error, R2} -> {error, R2};
		{Case2, Rest2, _} ->
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
		    run1([Case|[Rest2|Tail]], NewD)
	    end
    end;
run2([<<?call:8, ?fun_end:8, Script/binary>>|Tail], D) ->
    run1([<<?call:8, Script/binary>>|Tail], D); %tail call optimization
run2([<<?call:8>>|[<<?fun_end:8>>|Tail]], D) ->
    run1([<<?call>>|Tail], D); %tail call optimization
run2([<<?call:8, Script/binary>>|Tail], D) ->
    case D#d.stack of 
        [H|T] ->
            case maps:find(H, D#d.funs) of
                error -> 
		    {error, "called undefined function"};
                {ok, Definition} ->
                    S = size(Definition),
                    NewD = D#d{op_gas = D#d.op_gas - S - 10,
                               ram_current = D#d.ram_current + S + 2,%-1 for call, +1 for fun_end, +2 for 2 new list links.
                               stack = T},
                    run1([Definition|[<<?fun_end:8>>|[Script|Tail]]],NewD)
                end;
        _ -> {error, "stack underflow"}
    end;
run2([<<?define:8, Script/binary>>|T], D) ->
    %io:fwrite("run2 define\n"),
    case split(?fun_end, Script) of
	{error, R} -> {error, R};
	{Definition, Script2, _} ->
    %true = balanced_r(Definition, 0),
	    B = hash:doit(Definition, chalang_constants:hash_size()),
    %replace "recursion" in the definition with a pointer to this.
	    DSize = chalang_constants:hash_size(),
	    NewDefinition = replace(<<?recurse:8>>, <<2, DSize:32, B/binary>>, Definition),
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
                               %stack = [B|D#d.stack],
		       funs = M},
		    run1([Script2|T], NewD)
	    end
    end;
run2([<<?define2:8, Script/binary>>|T], D) ->
    %io:fwrite("run2 define\n"),
    true = (D#d.version > 0),
    case split(?fun_end, Script) of
	{error, R} -> {error, R};
	{Definition, Script2, _} ->
    %true = balanced_r(Definition, 0),
	    B = hash:doit(Definition, chalang_constants:hash_size()),
    %replace "recursion" in the definition with a pointer to this.
	    DSize = chalang_constants:hash_size(),
	    NewDefinition = replace(<<?recurse:8>>, <<2, DSize:32, B/binary>>, Definition),
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
                               stack = [B|D#d.stack],
		       funs = M},
		    run1([Script2|T], NewD)
	    end
    end;

run2([<<?return:8, _/binary>>|_], D) ->
    run1([<<>>], D);
run2([<<Command:8, Script/binary>>|T], D) 
  when ((Command == ?bool_and) or 
        (Command == ?bool_or) or 
        (Command == ?bool_xor)) ->
    %io:fwrite("run2 bool and/or/xor\n"),
    case D#d.stack of
        [<<A:32>>|[<<B:32>>|R]] ->
            %io:fwrite("bool combine\n"),
            C = bool2(Command, A, B),
            D2 = D#d{stack = [<<C:32>>|R],
                     op_gas = D#d.op_gas - 1,
                     ram_current = D#d.ram_current - 2},
            run1([Script|T], D2);
        [_|[_|_]] -> 
            io:fwrite("can only bool_and two 4 byte values\n"),
            {error, "can only bool_and two 4 byte values"};
        _ -> 
            io:fwrite("stack underflow\n"),
            {error, "stack underflow"}
    end;
    
run2([<<Command:8, Script/binary>>|T], D) ->
    case run4(Command, D) of
	{error, R} -> {error, R};
	NewD -> 
	    %io:fwrite("run word "),
	    %io:fwrite(integer_to_list(Command)),
	    %io:fwrite("\n"),
	    run1([Script|T], NewD)
    end.
bool2(?bool_and, _, 0) -> 0;
bool2(?bool_and, 0, _) -> 0;
bool2(?bool_and, _, _) -> 1;
bool2(?bool_or, 0, 0) -> 0;
bool2(?bool_or, _, _) -> 1;
bool2(?bool_xor, 0, 0) -> 0;
bool2(?bool_xor, 0, _) -> 1;
bool2(?bool_xor, _, 0) -> 1;
bool2(?bool_xor, _, _) -> 0.
    

run4(?print, D) ->
    print_stack(D#d.stack),
    D;
run4(?drop, D) ->
    case D#d.stack of 
	[H|T] ->
	    D#d{stack = T,
		ram_current = D#d.ram_current - memory(H) - 2,%drop leaves, and the list link is gone
		op_gas = D#d.op_gas - 1};
	_ -> {error, "drop stack underflow"}
    end;
run4(?dup, D) ->
    case D#d.stack of
        [H|T] ->
            D#d{stack = [H|[H|T]],
                ram_current = D#d.ram_current + memory(H),
                op_gas = D#d.op_gas - 1};
        _ -> {error, "dup stack underflow"}
    end;
run4(?swap, D) ->
    case D#d.stack of
        [A|[B|C]] ->
            Stack2 = [B|[A|C]],
            D#d{stack = Stack2,
                op_gas = D#d.op_gas - 1};
        _ -> {error, "swap stack underflow"}
    end;
run4(?tuck, D) ->
    case D#d.stack of
        [A|[B|[C|E]]] ->
            Stack2 = [B|[C|[A|E]]],
            D#d{stack = Stack2,
                op_gas = D#d.op_gas - 1};
        _ -> {error, "tuck stack underflow"}
    end;
run4(?rot, D) ->
    case D#d.stack of
        [A|[B|[C|E]]] ->
            Stack2 = [C|[A|[B|E]]],
            D#d{stack = Stack2,
                op_gas = D#d.op_gas - 1};
        _ -> {error, "rot stack underflow"}
    end;
run4(?ddup, D) ->
    case D#d.stack of 
        [A|[B|C]] ->
            Stack2 = [A|[B|[A|[B|C]]]],
            D#d{stack = Stack2,
                ram_current = D#d.ram_current +
                memory(A) + memory(B),
                op_gas = D#d.op_gas - 1};
        _ -> {error, "ddup stack underflow"}
    end;
run4(?tuckn, D) ->
    case D#d.stack of
        [<<N:(?int_bits)>>|[X|S]] ->
	    StackSize = length(S),
	    if
		N > StackSize -> {error, "tuckn stack underflow 2"};
		true ->
		    H = lists:sublist(S, 1, N),
		    T = lists:sublist(S, N+1, 100000000000000000),
		    Stack2 = H ++ [X|T],
		    D#d{stack = Stack2,
			op_gas = D#d.op_gas - 1}
	    end;
        _ -> {error, "tuckn stack underflow"}
    end;
run4(?pickn, D) ->
    case D#d.stack of
        [<<M:(?int_bits)>>|S] ->
            H = lists:sublist(S, 1, M),
            case lists:sublist(S, M + 1, 100000000000000000) of
                [X|T] ->
                    Stack2 = [X|(H ++ T)],
                    D#d{stack = Stack2,
                        op_gas = D#d.op_gas - 1};
                _ -> {error, "stack underflow"}
            end;
        _ -> {error, "pickn stack underflow"}
    end;
run4(?to_r, D) ->
    case D#d.stack of
        [H|T] ->
            D#d{stack = T,
                op_gas = D#d.op_gas - 1,
                alt = [H|D#d.alt]};
        _ -> {error, "to_r stack underflow"}
    end;
run4(?from_r, D) ->
    case D#d.alt of
        [H|T] ->
            D#d{stack = [H|D#d.stack],
                alt = T,
                op_gas = D#d.op_gas - 1};
        _ -> {error, "alt stack underflow"}
    end;
run4(?r_fetch, D) ->
    case D#d.alt of
        [H|T] ->
            D#d{stack = [H|D#d.stack],
                op_gas = D#d.op_gas - 1};
        _ -> {error, "alt stack underflow"}
    end;
run4(?hash, D) ->
    case D#d.stack of
        [H|T] ->
            D#d{stack = [hash:doit(H, D#d.hash_size)|T],
                op_gas = D#d.op_gas - 20};
        _ -> {error, "hash stack underflow"}
    end;
run4(?verify_sig, D) ->
    case D#d.stack of
        [Pub|[Data|[Sig|T]]] ->
            B = sign:verify_sig(Data, Sig, Pub),
            B2 = case B of
                     true -> <<1:(?int_bits)>>;
                     false -> (<<0:(?int_bits)>>)
		 end,
            D#d{stack = [B2|T],
                op_gas = D#d.op_gas - 20};
        _ -> {error, "verify_sig stack underflow"}
    end;
run4(X, D) when (X >= ?add) and (X < ?eq) ->
    case D#d.stack of
        [A|[B|C]] ->
	    AR = arithmetic_chalang:doit(X, A, B),
	    case AR of
		{error, _} -> AR;
		_ ->
		    D#d{stack = [AR|C],
			op_gas = D#d.op_gas - 1,
			ram_current = D#d.ram_current - 2}
	    end;
        _ -> {error, "arithmetic stack underflow"}
    end;
run4(?eq2, D) ->
    true = (D#d.version > 1),
    case D#d.stack of
        [A|[B|T]] ->
            C = if
                    A == B -> 1;
                    true -> 0
                end,
            S = [<<C:?int_bits>>|T],
            D#d{stack = S, 
                op_gas = D#d.op_gas - 1,
                ram_current = D#d.ram_current + 1};
        _ -> {error, "eq stack underflow"}
    end;
run4(?eq, D) ->
    case D#d.stack of
        [A|[B|_]] ->
            C = if
                    A == B -> 1;
                    true -> 0
                end,
            S = [<<C:?int_bits>>|D#d.stack],
            D#d{stack = S, 
                op_gas = D#d.op_gas - 1,
                ram_current = D#d.ram_current + 1};
        _ -> {error, "eq stack underflow"}
    end;
run4(?bool_flip, D) ->
    D2 = D#d{op_gas = D#d.op_gas - 1},
    case D#d.stack of
        [<<0:32>>|T] -> D2#d{stack = [<<1:32>>|T]};
        [<<_:32>>|T] -> D2#d{stack = [<<0:32>>|T]};
        [X|T] -> {error, "can only bool flip a 4 byte value"};
        _ -> {error, "bool_flip stack underflow"}
    end;
run4(X, D) when
  (((X == ?bin_and) or (X == ?bin_or)) or (X == ?bin_xor)) ->
    case D#d.stack of
        [G|[H|T]] ->
	    if
		(is_binary(G) and is_binary(H)) ->
		    B = 8 * size(G),
		    HS = 8 * size(H),
		    <<A:B>> = G,
		    <<C:HS>> = H,
		    E = max(B, HS),
		    F = case X of
			    ?bin_and -> (A band C);
			    ?bin_or -> (A bor C);
			    ?bin_xor -> (A bxor C)
			end,
		    D#d{op_gas = D#d.op_gas - E,
			stack = [<<F:E>>|T],
			ram_current = D#d.ram_current - min(B, D) - 1};
		true ->
		    {error, "can only bin_combine binaries"}
	    end;
        _ -> {error, "bin_combine stack underflow"}
    end;

run4(?stack_size, D) ->
    S = D#d.stack,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<(length(S)):?int_bits>>|S]};
run4(?height, D) ->
    S = D#d.stack,
    H = D#d.state#state.height,
    D#d{op_gas = D#d.op_gas - 1,
	ram_current = D#d.ram_current + 2,
	stack = [<<H:?int_bits>>|S]};
run4(?gas, D) ->
    G = D#d.op_gas,
    D#d{op_gas = G - 1,
	stack = [<<G:?int_bits>>|D#d.stack],
	ram_current = D#d.ram_current + 2};
run4(?many_vars, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<(size(D#d.vars)):?int_bits>>|D#d.stack],
	ram_current = D#d.ram_current + 2};
run4(?many_funs, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [<<(D#d.many_funs):?int_bits>>|D#d.stack],
	ram_current = D#d.ram_current + 2};
run4(?fun_end, D) ->
    D#d{op_gas = D#d.op_gas - 1};
run4(?set, D) ->
    case D#d.stack of
        [<<Key:32>>|[Value|T]] ->
            if 
                (Key > size(D#d.vars)) ->
                    {error, "ran out of space for variables"};
                true ->
                    Vars = setelement(Key, D#d.vars, Value),
                    D#d{op_gas = D#d.op_gas - 1,
                        stack = T,
                        vars = Vars}
            end;
        _ -> {error, "set stack underflow, or invalid key"}
    end;
run4(?fetch, D) ->
    case D#d.stack of
        [<<Key:32>>|T] ->
            if
                (Key > size(D#d.vars)) ->
                    {error, "cannot fetch variables from outside the allocated space"};
                true ->
                    Value = case element(Key, D#d.vars) of
                                e -> [];
                                V -> V
                            end,
                    D#d{op_gas = D#d.op_gas - 1,
                        stack = [Value|T],
                        ram_current = D#d.ram_current + memory(Value) + 1}
            end;
        _ -> {error, "fetch stack underflow"}
    end;
run4(?cons, D) -> % ( A [B] -- [A, B] )
    case D#d.stack of
        [A|[B|T]] ->
	    if
		is_list(A) ->
		    D#d{op_gas = D#d.op_gas - 1,
			stack = [[B|A]|T],
			ram_current = D#d.ram_current + 1};
		true -> {error, "can only cons onto a list"}
	    end;
        _ -> {error, "cons stack underflow"}
    end;
run4(?car, D) -> % ( [A, B] -- A [B] )
    case D#d.stack of
        [[B|A]|T] ->
            D#d{op_gas = D#d.op_gas - 1,
                stack = [A|[B|T]],
                ram_current = D#d.ram_current - 1};
        _ -> {error, "car stack underflow"}
    end;
run4(?nil, D) ->
    D#d{op_gas = D#d.op_gas - 1,
	stack = [[]|D#d.stack],
	ram_current = D#d.ram_current + 1};
run4(?append, D) ->
    case D#d.stack of
        [A|[B|T]] ->
            C = if
                    is_binary(A) and is_binary(B) ->
                        <<B/binary, A/binary>>;
                    is_list(A) and is_list(B) ->
                        B ++ A;
		    true ->
			error
                end,
	    case C of
		error -> {error, "can't append these things"};
		_ ->
		    D#d{op_gas = D#d.op_gas - 1,
			stack = [C|T],
			ram_current = D#d.ram_current + 1}
	    end;
        _ -> {error, "append stack underflow"}
    end;
run4(?split, D) ->
    case D#d.stack of
        [<<N:?int_bits>>|[L|T]] ->
            M = N * 8,
            if
                is_binary(L) ->
		    Bool = size(L),
		    if
			Bool >= N ->
			    <<A:M, B/binary>> = L,
			    D#d{op_gas = D#d.op_gas - 1,
				stack = [<<A:M>>|[B|T]],
				ram_current = D#d.ram_current - 1};
			true ->
			    {error, "not big enough to split there"}
		    end;
                true -> {error, "can only split binaries"}
            end;
        [_|[_|_]] -> {error, "need to use a 4-byte integer to say where to split the binary"};
        _ -> {error, "split stack underflow"}
    end;
run4(?reverse, D) ->
    case D#d.stack of
        [H|T] ->
            if
                is_list(H) ->
                    D#d{op_gas = D#d.op_gas - length(H),
                        stack = [lists:reverse(H)|T]};
                true -> {error, "can only reverse a list"}
            end;
        _ -> {error, "reverse stack underflow"}
    end;
run4(?is_list, D) ->
    case D#d.stack of
        [H|T] ->
            G = if
                    is_list(H) -> <<1:?int_bits>>;
                    true -> (<<0:?int_bits>>)
                end,
            D#d{op_gas = D#d.op_gas - 1,
                stack = [G|[H|T]],
                ram_current = D#d.ram_current - 1};
        _ -> {error, "is_list stack underflow"}
    end;
run4(?nop, D) -> D;
run4(?fail, D) -> 
    {error, "fail"};
run4(X, _) ->
    io:fwrite(integer_to_list(X)),
    {error, "operation not defined in chalang:run4."}.

memory(L) -> memory(L, 0).
memory([], X) -> X+1;
memory([H|T], X) -> memory(T, 1+memory(H, X));
memory(B, X) -> X+size(B).
balanced_f(<<>>, 0) -> true;
balanced_f(<<>>, 1) -> false;
balanced_f(<<?define:8, Script/binary>>, 0) ->
    balanced_f(Script, 1);
balanced_f(<<?define:8, _/binary>>, 1) -> false;
balanced_f(<<?define2:8, Script/binary>>, 0) ->
    balanced_f(Script, 1);
balanced_f(<<?define2:8, _/binary>>, 1) -> false;
balanced_f(<<?fun_end:8, Script/binary>>, 1) ->
    balanced_f(Script, 0);
balanced_f(<<?fun_end:8, _/binary>>, 0) -> false;
balanced_f(<<?int:8, _:?int_bits, Script/binary>>, X) ->
    balanced_f(Script, X);
balanced_f(<<?int1:8, _:8, Script/binary>>, X) ->
    balanced_f(Script, X);
balanced_f(<<?int2:8, _:16, Script/binary>>, X) ->
    balanced_f(Script, X);
balanced_f(<<?binary:8, H:32, Script/binary>>, D) ->
    X = H * 8,
    <<_:X, Script2/binary>> = Script,
    balanced_f(Script2, D);
balanced_f(<<_:8, Script/binary>>, X) ->
    balanced_f(Script, X).
none_of(X) -> none_of(X, ?return).
none_of(<<>>, _) -> true;
none_of(<<X:8, _/binary>>, X) -> false;
none_of(<<?int:8, _:?int_bits, Script/binary>>, X) -> 
    none_of(Script, X);
none_of(<<?int1:8, _:8, Script/binary>>, X) -> 
    none_of(Script, X);
none_of(<<?int2:8, _:16, Script/binary>>, X) -> 
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
	    R2 = replace(Old, New, R),
	    <<D:Pointer, New/binary, R2/binary>>;
	<<_:Pointer, ?int:8, _:?int_bits, _/binary>> ->
	    replace(Old, New, Binary, Pointer+8+?int_bits);
	<<_:Pointer, ?int1:8, _:8, _/binary>> ->
	    replace(Old, New, Binary, Pointer+8+8);
	<<_:Pointer, ?int2:8, _:16, _/binary>> ->
	    replace(Old, New, Binary, Pointer+8+16);
	<<_:Pointer, ?binary:8, H:32, _/binary>> ->
	    X = H * 8,
	    replace(Old, New, Binary, Pointer+8+32+X);
	_ -> replace(Old, New, Binary, Pointer+8)
    end.
	    
split(X, B) ->
    split(X, B, 0).
split(X, B, N) ->
    case B of
	<<_:N, ?binary:8, H:32, _/binary>> ->
	    split(X, B, N+40+(H*8));
	<<_:N, ?binary:8, _/binary>> ->
	    {error, "binary underflow in function definition"};
	<<_:N, ?int:8, _:(?int_bits), _/binary>> ->
	    split(X, B, N+8+?int_bits);
	<<_:N, ?int:8, _/binary>> ->
	    {error, "integer underflow in function definition"};
	<<_:N, ?int1:8, _:8, _/binary>> ->
	    split(X, B, N+8+8);
	<<_:N, ?int1:8, _/binary>> ->
	    {error, "integer underflow in function definition"};
	<<_:N, ?int2:8, _:16, _/binary>> ->
	    split(X, B, N+8+16);
	<<_:N, ?int2:8, _/binary>> ->
	    {error, "integer underflow in function definition"};
	<<A:N, X:8, T/binary>> ->
	    {<<A:N>>, T, N};
	<<_:N, _:8, _/binary>> ->
	    split(X, B, N+8);
	_ -> {error, "no closing operation on a function"}
    end.
split_if(X, B) ->
    split_if(X, B, 0).
split_if(X, B, N) ->
    case B of
	<<_:N, (?int):8, _:(?int_bits), _/binary>> ->
	    split_if(X, B, N+8+?int_bits);
	<<_:N, (?int):8, _/binary>> ->
	    {error, "integer underflow in case statment"};
	<<_:N, (?int1):8, _:8, _/binary>> ->
	    split_if(X, B, N+8+8);
	<<_:N, (?int1):8, _/binary>> ->
	    {error, "integer underflow in case statment"};
	<<_:N, (?int2):8, _:16, _/binary>> ->
	    split_if(X, B, N+8+16);
	<<_:N, (?int2):8, _/binary>> ->
	    {error, "integer underflow in case statment"};
	<<_:N, (?binary):8, H:32, _/binary>> ->
	    split_if(X, B, N+40+(H*8));
	<<_:N, (?binary):8, _/binary>> ->
	    {error, "binary underflow inside case statement"};
	<<_:N, (?caseif):8, C/binary>> ->
	    case split_if(?then, C) of
		{_, _Rest, M} ->
		    split_if(X, B, N+M+16);
		_ -> {error, "if-else-then has no 'then'"}
	    end;
	<<A:N, X:8, C/binary>> ->
	    {<<A:N>>, C, N};
	<<A:N, _:8, C/binary>> ->
	    split_if(X, B, N+8);
	_ -> {error, "broken if-else-then statement"}
    end.
print_stack(X) ->
    print_stack(12, X),
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
%print_stack(_, <<F:32, G:32>>) ->
%    io:fwrite(" " ++integer_to_list(F) ++"/"++
		  %integer_to_list(G) ++" ");
print_stack(_, B) -> io:fwrite(binary_to_list(base64:encode(B)) ++ "\n").
