module Main (main) where

import Control.Exception (evaluate)
import Example
import Test.Syd hiding (Spec)

main :: IO ()
main = sydTest $ do
  describe "add" $
    -- This test runs `add`, so it counts towards coverage -- but it never
    -- looks at the result. Any change to `add`'s body passes this test.
    -- `evaluate` forces the result (otherwise, being unused, it would never
    -- even run -- laziness means an uninspected result isn't "coverage" at
    -- all, it's just dead code).
    it "runs without crashing" $ do
      _result <- evaluate (add 2 2)
      pure ()

  describe "isAdult" $ do
    -- Deliberately missing the boundary (age 18 and age 17): this test has
    -- real, passing assertions, on correct code, with 100% coverage --
    -- HPC's tick fires on "this expression ran", not on which inputs it
    -- ran with, so dropping these two cases doesn't move the coverage
    -- number at all. It still can't tell `>=` from `>`.
    it "is true above 18" $
      isAdult 25 `shouldBe` True
    it "is false below 18" $
      isAdult 0 `shouldBe` False
