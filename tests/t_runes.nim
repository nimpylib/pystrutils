
import std/unittest

import pystrutils
import std/unicode


test "split runes":
  var s = [Rune'a', Rune' ', Rune'b']
  check s.split(Rune ' ') == @[
    @[Rune'a'],
    @[Rune'b'],
  ]

test "partition runes":
  template t(sep) =
    var s = @[Rune'a', Rune' ', Rune'b']
    check s.partition(sep) == (
      @[Rune'a'],
      @[Rune' '],
      @[Rune'b'],
    )
  t Rune ' '
  t @[Rune ' ']

