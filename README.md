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

## Stage 2 (this branch): the real tool

`1baseline` is the stage-1 state above (plain hspec, manual demonstration).
This branch (`2mutations`) converts the test suite to
[sydtest](https://github.com/NorfairKing/sydtest) and wires up its
mutation-testing GHC plugin via `checks.mutation` in `flake.nix` -- the
same tool, same setup pattern, as `signs-alt`.

```
nix build '.#checks.x86_64-linux.mutation'
```

Last real run: **3 survived, 6 killed, 0 uncovered** -- the exact two
planted gaps, found automatically:

- `Cmp`: `isAdult`'s `>=` mutated to `>` -- survives
- `Arith`: `add`'s `+` mutated to `-` -- survives
- `IntLit`: `isAdult`'s `18` mutated to `1` -- also survives (a second way
  of hitting the same missing-boundary gap)

Getting a clean run took three real fixes, each worth knowing if this
demo is re-run or extended:

1. The package must be injected into `haskellPackages` via an overlay --
   `mutationCheck` looks packages up as `super.${pkg}` internally, so a
   plain local `callCabal2nix` binding isn't visible to it.
2. The test-suite needs `-rtsopts` in `ghc-options`. Without it, the
   driver's `--child-mem-limit` RTS flag is silently rejected rather than
   applied -- inconsistently enough to make a should-be-identical control
   mutation look different, which sydtest correctly flags as "mutation
   testing may be unsound."
3. `-with-rtsopts=-N` additionally needs `-threaded` -- GHC refuses `-N`
   (parallel GC) without it.

All three are exactly the kind of thing `signs-alt`'s own `.cabal` file
already has in its `common test-opts`/`common warnings` stanzas; this
project just hadn't copied them over yet.

## Stage 3 (`3genocide`): kill them all

Branch name is the field's own terminology taken literally, not a
euphemism I'm introducing -- see the talk's terminology slide. This
branch adds the tests the mutation report asked for, to see the other
end of the mutation-score scale.

```
nix build '.#checks.x86_64-linux.mutation'
```

**Survived: 0, Killed: 11, Uncovered: 0.** `add 2 3 \`shouldBe\` 5` kills
`Arith`, `isAdult 18`/`isAdult 17` close the boundary (kills `Cmp` and
`IntLit` both). One real wrinkle hit getting here: the first attempt used
`add 2 2 \`shouldBe\` 4`, which does *not* kill the `+` to `*` mutant --
2 + 2 and 2 * 2 are both 4. Equal inputs can't distinguish addition from
multiplication; `add 2 3` (5 vs. 6) can.
