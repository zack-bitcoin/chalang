Instead of the script being a big binary, it should be a list of binaries. That way we can quickly append and split.
So we don't need to use the return stack for functions, we can just append code together.

remove_till needs to be updated. it needs to ignore any ints, fractions, or binaries.
remove_first needs the same update.