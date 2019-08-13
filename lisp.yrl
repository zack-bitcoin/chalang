Nonterminals E F Args Arg.
Terminals '(' ')' integer atom.
Rootsymbol E.

E -> Arg : '$1'.
E -> '(' F ')' : ['$2'].
E -> '(' F Args ')' : '$3' ++ '$2'.

F -> atom : [value_of('$1')].

Args -> Arg : ['$1'].
Args -> Arg Args : ['$1' | '$2'].

Arg -> integer : value_of('$1').
Arg -> atom : value_of('$1').

Erlang code.
value_of(X) ->
  element(3, X).
line_of(X) ->
  element(2, X).