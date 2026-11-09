# mutation-coverage-demo

A minimal, literal demonstration of one claim: **100% code coverage does not
mean your tests verify anything.**

## The setup

`src/Example.hs` has two functions:

- `add x y = x + y`
- `isAdult age = age >= 18`

`test/Spec.hs` has a test for each:

- The `add` test calls `add 2 2`, forces the result with `evaluate`, and
  asserts nothing about it.
- The `isAdult` tests check the boundary properly (`17`, `18`, `25`, `0`).

Both functions are fully covered -- every line in both runs during the test
suite. Only one of them is actually verified.

Why `evaluate` and not a plain `let`: Haskell is lazy, so `let _result =
add 2 2` on its own builds a thunk that's never forced if nothing looks at
`_result` -- HPC then correctly reports `add` as *never executed*, which is
a true but different claim (dead code, not "untested but covered" code).
`evaluate` forces the thunk to WHNF (sufficient here, since `Int`'s WHNF is
fully evaluated) so `add` genuinely runs, without ever comparing its result
to anything. Worth having this ready if asked in Q&A -- it's a real and
relevant subtlety, not a tooling workaround.

## Demonstrating it live

```
nix develop
cabal test --enable-coverage
```

Open the generated HPC report (path printed at the end of the run, under
`dist-newstyle/.../hpc_index.html`) -- both `add` and `isAdult` show 100%
expression coverage.

Then, by hand, edit `src/Example.hs`:

```haskell
add x y = x - y        -- was: x + y
```

Run `cabal test` again. It still passes. Nothing noticed. Put the `+` back,
and instead change `isAdult`:

```haskell
isAdult age = age > 18  -- was: age >= 18
```

Run `cabal test` again. It fails -- the `isAdult 18` assertion breaks.

Same coverage number for both functions, the whole time. Only one test
suite was actually checking anything. That's the entire claim; there's no
tool involved yet, just two functions, a broken test, and a working one.

## Where this is going

This project is the first stage of a larger example: later stages will wire
up [sydtest](https://github.com/NorfairKing/sydtest)'s mutation-testing GHC
plugin (the same tool used on `signs-alt`) so this same contrast -- `add`'s
untested body vs. `isAdult`'s boundary-tested body -- shows up automatically
as a mutation-testing report instead of a manual demonstration.
