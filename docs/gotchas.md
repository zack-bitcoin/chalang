the name of a macro can be written as an atom, like this:
```
'double
```
you can use the is_atom function to see if it as atom
```
(is_atom 'double)
```
this returns true.

but watch out because this is also true:
```
(is_list 'double)
```