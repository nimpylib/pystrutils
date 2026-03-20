
from std/strutils import Whitespace
from std/unicode import toRunes, Rune, `==`
from pkg/unicode_space_decimal/consts import spaces
import std/sets

template asSet[S: set[char]|HashSet[Rune]](s: S): S = s
func asSet(s: openArray[char]): set[char] =
  for i in s: result.incl i
func asSet(s: openArray[Rune]): HashSet[Rune] =
  for i in s: result.incl i
func asSet(s: openArray[int]): HashSet[Rune] =
  for i in s: result.incl Rune i

func subseq(s: openArray[char], start, stop: int): string =
  result = (when declared(newStringUninit): newStringUninit else: newString)(stop+1-start)
  for i, c in s: result[i] = c
func subseq(s: openArray[Rune], start, stop: int): seq[Rune] = s[start..stop]

template contains[T](a, b: T): bool = a == b

template gen_char(strip, Res){.dirty.} =
  func strip*[T](s: openArray[T], chars: T): Res = s.strip(chars=chars)

template gen_strip(T, Res, spaces, Set){.dirty.} =
  func stripImpl(s: openArray[T], leading: static[bool] = true, trailing: static[bool] = true,
              chars: Set[T]|T = spaces): Res =
    ## Strips leading or trailing `chars` (default: whitespace characters)
    ## from `s` and returns the resulting string.
    ##
    ## If `leading` is true (default), leading `chars` are stripped.
    ## If `trailing` is true (default), trailing `chars` are stripped.
    ## If both are false, the string is returned unchanged.

    var
      first = 0
      last = len(s)-1
    when leading:
      while first <= last and s[first] in chars: inc(first)
    when trailing:
      while last >= first and s[last] in chars: dec(last)
    result = subseq(s, first, last)

  func strip*(s, chars: openArray[T]): Res = s.stripImpl(true, true, chars=asSet chars)
  func strip*(s: openArray[T]): Res = s.stripImpl(chars=spaces)

  func lstrip*(self: openArray[T]): Res = self.stripImpl(trailing=false)
  func rstrip*(self: openArray[T]): Res = self.stripImpl(leading=false)

  func lstrip*(self, chars: openArray[T]): Res =
    self.stripImpl(trailing=false, chars=asSet chars)
  func rstrip*(self, chars: openArray[T]): Res =
    self.stripImpl(leading=false, chars=asSet chars)

  func strip* (s: openArray[T], chars: T): Res = s.stripImpl(chars=chars)
  func lstrip*(s: openArray[T], chars: T): Res = s.stripImpl(trailing=false, chars=chars)
  func rstrip*(s: openArray[T], chars: T): Res = s.stripImpl(leading=false, chars=chars)

const Spaces = spaces.asSet
gen_strip Rune, seq[Rune], Spaces, HashSet
gen_strip char, string, Whitespace, set

