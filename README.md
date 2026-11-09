# mutation-coverage-demo

A minimal, literal demonstration of one claim: **100% code coverage does not
mean your tests verify anything.**

## The setup

`src/Example.hs` has two functions:

- `add x y = x + y`
- `isAdult age = age >= 18`

`test/Spec.hs` has a test for each, and they're weak in two *different*
ways, deliberately:

- The `add` test calls `add 2 2`, forces the result with `evaluate`, and
  asserts nothing about it at all -- the obvious case.
- The `isAdult` tests have real, passing assertions (`isAdult 25` should be
  `True`, `isAdult 0` should be `False`) on correct code -- but neither
  input is the boundary. This one *looks* thorough on a skim. It isn't.

Both functions are fully covered -- every line in both runs during the test
suite -- and both tests pass, on correct code. Neither test would notice if
`isAdult`'s `>=` quietly became `>`, or if `add`'s `+` became `-`.

That's the point: "no assertion at all" and "assertions that pass but miss
the one input that mattered" are both invisible to coverage, in exactly the
same way. The second one is the more realistic failure mode -- it's the
kind of test that passes review.

Why `evaluate` and not a plain `let` in the `add` test: Haskell is lazy, so
`let _result = add 2 2` on its own builds a thunk that's never forced if
nothing looks at `_result` -- HPC then correctly reports `add` as *never
executed*, which is a true but different claim (dead code, not "untested
but covered" code). `evaluate` forces the thunk to WHNF (sufficient here,
since `Int`'s WHNF is fully evaluated) so `add` genuinely runs, without
ever comparing its result to anything. Worth having this ready if asked in
Q&A -- it's a real and relevant subtlety, not a tooling workaround.

## Demonstrating it live

```
nix develop
cabal test --enable-coverage
```

Open the generated HPC report (path printed at the end of the run, under
`dist-newstyle/.../hpc_index.html`) -- both `add` and `isAdult` show 100%
expression coverage (6/6).

Then, by hand, edit `src/Example.hs`:

```haskell
add x y = x - y        -- was: x + y
```

Run `cabal test` again. It still passes. Put the `+` back, and instead
change the boundary:

```haskell
isAdult age = age > 18  -- was: age >= 18
```

Run `cabal test` again. Also still passes -- `isAdult 25` and `isAdult 0`
don't care whether the comparison is `>` or `>=`. Put it back to `>=`.

Same 100% coverage number throughout, for both functions, the whole time.
Neither test suite was actually checking the thing that would have caught
its respective bug. That's the entire claim; there's no tool involved yet,
just two functions and two tests that each pass for the wrong reason.

## Where this is going

This project is the first stage of a larger example: later stages will wire
up [sydtest](https://github.com/NorfairKing/sydtest)'s mutation-testing GHC
plugin (the same tool used on `signs-alt`) so both of these survivors --
`add`'s unchecked result and `isAdult`'s missing boundary -- show up
automatically in a mutation report instead of needing a manual demonstration.
