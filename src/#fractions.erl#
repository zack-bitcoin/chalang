-module(fractions).
-export([new/2,negate/1,add/2,sub/2,mul/2,divide/2,to_int/1,test/0, exponent/2, lt/2, gt/2, equal/2, is_fraction/1,sqrt/1]).
-record(f, {top = 0, bottom = 0}).
is_fraction(X) when not is_record(X, f) ->
    false;
is_fraction({f, _, Y}) when not is_integer(Y) -> false;
is_fraction({f, Y, _}) when not is_integer(Y) -> false;
is_fraction({f, _, Y}) when Y == 0 -> false;
is_fraction({f, _, _}) -> true;
is_fraction(_) -> false.
sqrt({f, A, B}) ->
    sqrt_helper({f, A, B}, {f, 1, 2}).
sqrt_helper(A, Guess) ->
    B = sub(A, mul(Guess, Guess)),
    Bool = (lt(B, {f, 1, 1000}) and (not lt(B, {f, -1, 1000}))), %correct to 8 decimal places.
    if
	Bool -> Guess;
	true -> 
	        Sum = add(Guess, divide(A, Guess)),
	        Improved = divide(Sum, {f, 2, 1}),
	        sqrt_helper(A, Improved)
    end.
to_frac(X) when is_integer(X) ->
    new(X, 1);
to_frac({f, X, Y}) -> {f, X, Y}.
equal(A, B) ->
    C = to_frac(A),
    D = to_frac(B),
    C#f.top * D#f.bottom == D#f.top * C#f.bottom.
gt(C, D) ->
    A = to_frac(D),
    B = to_frac(C),
    A#f.top * B#f.bottom < B#f.top * A#f.bottom.
lt(C, D) ->
    A = to_frac(C),
    B = to_frac(D),
    A#f.top * B#f.bottom < B#f.top * A#f.bottom.
new(T,B) -> #f{top = T, bottom = B}.
negate(B) -> 
    A = to_frac(B),
    #f{top = -A#f.top, bottom = A#f.bottom}.
sub(A, B) -> add(A, negate(B)).
add(C, D) -> 
    A = to_frac(C),
    B = to_frac(D),
    simplify(#f{top = (A#f.top * B#f.bottom) + (A#f.bottom * B#f.top) , bottom = A#f.bottom * B#f.bottom}).
mul(C, D) -> 
    A = to_frac(C),
    B = to_frac(D),
    simplify(#f{top = A#f.top * B#f.top, bottom = A#f.bottom * B#f.bottom}).
divide(C, D) -> 
    A = to_frac(C),
    B = to_frac(D),
    simplify(#f{top = A#f.top * B#f.bottom, bottom = A#f.bottom * B#f.top}).
to_int(A) -> A#f.top div A#f.bottom.

simplify(F) -> simplify_lcd(simplify_size(F)).
simplify_lcd(F) ->
    L = lcd(F#f.top, F#f.bottom),
    #f{top = F#f.top div L, bottom = F#f.bottom div L}.
simplify_size(F) ->
    IC = 4294967296,%this is higher than the highest value we can store in top or bottom.
    
    
    %IC = 281474976710656,
    %X = F#f.bottom div IC,
    %Y = F#f.top div IC,
    Z = if 
	    ((F#f.bottom > IC) and (F#f.top > IC)) -> IC; 
	    true -> 1 
    end,
    #f{top = F#f.top div Z, bottom = F#f.bottom div Z}.
exponent(F, N) -> 
    G = to_frac(F),
    exponent2(G, N).
exponent2(_, 0) -> #f{top = 1, bottom = 1};
exponent2(F, 1) -> F;
exponent2(F, N) when N rem 2 == 0 ->
    exponent2(mul(F, F), N div 2);
exponent2(F, N) -> mul(F, exponent2(F, N - 1)).
lcd(A, 0) -> A;
lcd(A, B) -> lcd(B, A rem B).
test() ->
    A = new(1, 3),
    B = new(2, 5),
    C = mul(A, B),
    C = new(2, 15),
    B = divide(C, A),
    9 = lcd(27, 9),
    5 = lcd(25, 15),
    success.
