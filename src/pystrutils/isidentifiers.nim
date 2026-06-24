
import std/strutils
import std/unicode
import pkg/unicode_space_decimal

proc isidentifier*(x: char): bool = x in IdentStartChars
proc isidentifier*(x: Rune): bool = x.isAlpha

template gen(char, itIsContIdentifier) {.dirty.} =
  proc isidentifier*(x: openArray[char]): bool =
    if x.len == 0: return 
    if not x[0].isidentifier: return
    for i in 1..<x.len:
      let it = x[i]
      if not itIsContIdentifier:
        return
    return true

# like std/strutils.validIdentifier but also for openArray
gen char, it in IdentChars
proc isdecimalRune(c: Rune): bool = decimal(c, -1) >= 0
#TODO:isidentifier
#TODO:unicode:XID_Start
gen Rune, it.isAlpha or it.isDecimalRune

