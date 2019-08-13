Nonterminals E.
Terminals '+' '*' '(' ')' integer.
Rootsymbol E.
Left 100 '+'.
Left 200 '*'.
E -> E '*' E : {'$2', '$1', '$3'}.
E -> E '+' E : {'$2', '$1', '$3'}.
E -> '(' E ')' : '$2'.
E -> integer : '$1'. 
