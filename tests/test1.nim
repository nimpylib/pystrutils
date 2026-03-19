
import std/unittest

import pystrutils
test "split":
  check "13\n2".rsplit == @["13", "2"]

