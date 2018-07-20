-module(arithmetic_chalang).
-export([doit/3, pow/2]).

-define(add, 50).
-define(subtract, 51).
-define(mul, 52).
-define(divide, 53).
-define(gt, 54).
-define(lt, 55).
-define(pow, 56).
-define(remainder, 57).
-define(eq, 58).
-define(int_bits, 32).
-define(fraction_bits, 64).

b2i(true) -> 1;
b2i(false) -> 0.
pow(B, 0) -> 0;
pow(B, 1) -> B;
pow(_, A) when (A > 31) -> {error, "exponent too big"};
pow(B, A) when ((A rem 2) == 0) ->
    pow(B*B, A div 2) rem 4294967296;
pow(B, A) ->
    (B * pow(B, A-1)) rem 4294967296.
int_arithmetic(?add, A, B) -> A+B;
int_arithmetic(?subtract, A, B) -> B-A;
int_arithmetic(?mul, A, B) -> A*B;
int_arithmetic(?divide, 0, _) -> {error, "div zero error"};
int_arithmetic(?divide, A, B) -> B div A;
int_arithmetic(?gt, A, B) -> b2i(A < B);
int_arithmetic(?lt, A, B) -> b2i(B < A);
int_arithmetic(?pow, A, B) -> pow(B, A); 
int_arithmetic(?remainder, A, B) -> 
    B rem A.
doit(?remainder, <<A:?int_bits>>, B) ->
    C = size(B)*8,
    <<D:C>> = B,
    E = D rem A,
    <<E:?int_bits>>;
doit(X, <<A:?int_bits>>, <<B:?int_bits>>) ->
    C = int_arithmetic(X, A, B),
    case C of
	{error, R} -> {error, R};
	_ -> (<<C:(?int_bits)>>)
    end;
doit(_, _, _) ->
    {error, "bad inputs to an arithmetic function"}.
%doit(X, <<A:?int_bits>>, <<B:?int_bits, C:?int_bits>>) ->
%    {f, E, D} = frac_arithmetic(X, {f, A, 1}, {f, B, C}),
%    <<E:?int_bits, D:?int_bits>>;
%doit(X, <<A:?int_bits, B:?int_bits>>, <<C:?int_bits>>) ->
%    {f, E, D} = frac_arithmetic(X, {f, A, B}, {f, C, 1}),
%    <<E:?int_bits, D:?int_bits>>;
%doit(X, <<A:?int_bits, B:?int_bits>>, <<C:?int_bits, D:?int_bits>>) ->
%    {f, E, F} = frac_arithmetic(X, {f, A, B}, {f, C, D}),
%    <<E:?int_bits, F:?int_bits>>.

%frac_arithmetic(?add, A, B) -> fractions:add(A, B, ?int_bits);
%frac_arithmetic(?subtract, A, B) -> fractions:sub(A, B, ?int_bits);
%frac_arithmetic(?mul, A, B) -> fractions:mul(A, B, ?int_bits);
%frac_arithmetic(?divide, A, B) -> fractions:divide(A, B, ?int_bits);
%frac_arithmetic(?gt, A, B) -> fractions:gt(A, B);
%frac_arithmetic(?lt, A, B) -> fractions:lt(A, B);
%%frac_arithmetic(?eq, A, B) -> fractions:eq(A, B);
%frac_arithmetic(?pow, A, B) -> fractions:pow(A, B, ?int_bits).

