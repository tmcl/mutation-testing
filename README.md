This is part of a repo of three steps demonstrating sydtest's mutation
testing.

You can run it this way:

```
nix develop
cabal test --enable-coverage
```

This version doesn't use sydtest - but the important point is that
every line of code is run but no lines are tested. Check the other
branches for examples of how to use sydtest-mutations.
