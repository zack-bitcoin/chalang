-module(compiler_lisp3).
-export([test1/0, test2/1]).

test1() ->
    F = "lisp.yrl",
    yecc:file(F).
test2(S) ->
    %c("language.erl"),
    {ok, P, N} = erl_scan:string(S),
    lisp:parse(P).
