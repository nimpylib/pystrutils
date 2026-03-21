
import std/unicode
export Rune

func substrEq[T](s: openArray[T], pos: int, substr: openArray[T]): bool =
  # Always returns false for empty `substr`
  var length = substr.len
  if length > 0:
    var i = 0
    while i < length and pos+i < s.len and s[pos+i] == substr[i]:
      inc i
    i == length
  else: false

template stringHasSep(s: openArray[char], index: int, seps: set[char]): bool =
  s[index] in seps

template stringHasSep[T](s: openArray[T], index: int, sep: T): bool =
  s[index] == sep

template stringHasSep[T](s: openArray[T], index: int, sep: openArray[T]): bool =
  s.substrEq(index, sep)

template subSeq(s: openArray[char|Rune], start, stop: int): untyped =
  @s[start..stop]

template splitCommon(s, sep, maxsplit, sepLen) =
  ## Common code for split procs
  var last = 0
  var splits = maxsplit

  while last <= len(s):
    var first = last
    while last < len(s) and not stringHasSep(s, last, sep):
      inc(last)
    if splits == 0: last = len(s)
    #TODO:NIM: std/strutils here uses `substr`, not necessarily
    yield subSeq(s, first, last-1)
    if splits == 0: break
    dec(splits)
    inc(last, sepLen)

template rsplitCommon(s, sep, maxsplit, sepLen) =
  ## Common code for rsplit functions
  var
    last = s.len - 1
    first = last
    splits = maxsplit
    startPos = 0
  # go to -1 in order to get separators at the beginning
  while first >= -1:
    while first >= 0 and not stringHasSep(s, first, sep):
      dec(first)
    if splits == 0:
      # No more splits means set first to the beginning
      first = -1
    if first == -1:
      startPos = 0
    else:
      startPos = first + sepLen
    #TODO:NIM: std/strutils here uses `substr`, not necessarily
    yield subSeq(s, startPos, last)
    if splits == 0: break
    dec(splits)
    dec(first)
    last = first

template gen_split(split){.dirty.} =
  iterator split*[C: char|Rune](s: openArray[C], sep: C, maxsplit: int = -1): seq[C] =
    splitCommon(s, sep, maxsplit, 1)

  iterator split*[C: char|Rune](s: openArray[C], sep: openArray[C], maxsplit: int = -1): seq[C] =
    let sepLen = if sep.len == 0: 1 # prevents infinite loop
      else: sep.len
    splitCommon(s, sep, maxsplit, sepLen)

gen_split split
gen_split rsplit

