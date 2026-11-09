module Main (main) where

import Control.Exception (evaluate)
import Example
import Test.Hspec

main :: IO ()
main = hspec $ do
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
    it "is true at and above 18" $ do
      isAdult 18 `shouldBe` True
      isAdult 25 `shouldBe` True
    it "is false below 18" $ do
      isAdult 17 `shouldBe` False
      isAdult 0 `shouldBe` False
