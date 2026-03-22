
import std/unittest

import pystrutils
test "split":
  check "13\n2".rsplit == @["13", "2"]

test "partition":
  block:
    let t = "asd dsad d".partition(' ')
    check t[0] == "asd"
    check t[2] == "dsad d"
  block:
    let s = "asd dsad d"
    let t = (@s).partition(' ')
    check t[0] == @"asd"
    check t[2] == @"dsad d"

test "endswith":
  check "asdd".endswith("sdd")

