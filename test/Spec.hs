module Main (main) where

import Example
import Test.Syd hiding (Spec)

main :: IO ()
main = sydTest $ do
  describe "add" $
    -- 2 + 2 = 4 and 2 * 2 = 4: equal inputs can't tell + from *, so the
    -- first attempt at this test (`add 2 2`) left that one mutant
    -- surviving. Unequal inputs can: 2 + 3 /= 2 - 3 /= 2 * 3.
    it "adds" $
      add 2 3 `shouldBe` 5

  describe "isAdult" $ do
    -- The boundary is back. Kills Cmp (`>=` to `>`: 18 > 18 is False, not
    -- True) and IntLit (`18` to `1`: 17 >= 1 is True, not False) -- both
    -- gaps this whole demo was built around, actually closed.
    it "is true above 18" $
      isAdult 25 `shouldBe` True
    it "is true at exactly 18" $
      isAdult 18 `shouldBe` True
    it "is false below 18" $
      isAdult 0 `shouldBe` False
    it "is false at exactly 17" $
      isAdult 17 `shouldBe` False
