
import std/unittest

import pystrutils
import std/unicode


test "split runes":
  var s = [Rune'a', Rune' ', Rune'b']
  check s.split(Rune ' ') == @[
    @[Rune'a'],
    @[Rune'b'],
  ]

