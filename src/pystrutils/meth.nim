
import std/strutils except strip, split, rsplit, replace
from std/unicode import Rune
from std/sequtils import nil

import ./replaceWithCount as replaceLib
import ./errHandle
import ./finds

import pkg/unicode_case/utils
import pkg/unicode_space_decimal
export istitleImpl, allAlpha

template norm_idx(i, s): int =
  if i < 0: len(s) + i
  else: i

func count*[S](a: S, sub: S): int =
  if sub.len == 0: return a.len + 1
  count($a, $sub)

func count*[S](a: S, sub: S, start: int): int =
  let subA = substr($a, start.norm_idx(a))
  if sub.len == 0: return subA.len + 1
  count($a, $sub)

func count*[S](a: S, sub: S, start=0, `end`: int): int =
  count(substr($a, start.norm_idx(a), `end`.norm_idx(a) - 1), $sub)


template seWith(seWith, find, FindIdx){.dirty.} =
  template sewith*[S](a: S, suffix: char): bool =
    seWith($a, suffix)
  template sewith*[S](a: char, suffix: S): bool =
    suffix.len == 1 and a == suffix[0]
  func sewith*[S; Tup: tuple](a: S, suffix: Tup, start=0, `end`=a.len): bool =
    for _, suf in suffix.fieldPairs:
      if a.sewith(suf, start, `end`):
        return true
  func sewith*[S: not openArray; Suf: S](a: S, suffix: Suf,
      start=0, `end`=a.len): bool =
    substr($a, start.norm_idx(a), `end`.norm_idx(a) - 1).sewith(suffix)
  func sewith*[C](a, suffix: openArray[C],
      start=0, `end`=a.len): bool =
    let res = a.toOpenArray(start.norm_idx(a), `end`.norm_idx(a) - 1).find(suffix)
    if res < 0: return
    res == FindIdx

seWith startsWith, find, 0
seWith endsWith, rfind, `end`-start-suffix.len


func find1*[S; T](a: S, b: T, start = 0): int =
  ## `b` shall be one length long.
  var i = start.norm_idx(a)
  for s in a:
    if s == b: return i
    i.inc
  return -1

func find1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  ## `b` shall be one length long.
  var i = start.norm_idx(a)
  let last = `end`.norm_idx(a) - 1
  for s in a:
    if i == last: break
    if s == b: return i
    i.inc
  return -1

func rfind1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  for i in countdown(`end`.norm_idx(a) - 1, start.norm_idx(a)):
    if a[i] == b: return i
  return -1
func rfind1*[S; T](a: S, b: T, start = 0): int =
  rfind1(a, b, start, len(a))


template gen_find(find){.dirty.} =
  func find*[C](a, b: openArray[C], start: int): int =
    let i = start.norm_idx(a)
    finds.find(a, b, i)
  func find*[C](a, b: openArray[C], start = 0, `end`: int): int =
    let i = start.norm_idx(a)
    let last = `end`.norm_idx(a) - 1
    finds.find(a, b, i, last)

  func find*[T](a, b: T, start: int, `end`: int): int =
    let i = start.norm_idx(a)
    let last = `end`.norm_idx(a) - 1
    finds.find(a, b, i, last)

gen_find find
gen_find rfind

func rNoIdx{.inline.} =
  raise newException(ValueError, "substring not found")

func index1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.find1(b, start, `end`)
  if result == -1: rNoIdx()
func index1*[S; T](a: S, b: T, start = 0): int =
  index1 a, b, start, len(a)
func index*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.find(b, start, `end`)
  if result == -1: rNoIdx()
func index*[S; T](a: S, b: T, start = 0): int =
  index a, b, start, len(a)

func rindex1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.rfind1(b, start, `end`)
  if result == -1: rNoIdx()
func rindex1*[S; T](a: S, b: T, start = 0): int =
  rindex1 a, b, start, len(a)

func rindex*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.rfind(b, start, `end`)
  if result == -1: rNoIdx()
func rindex*[S; T](a: S, b: T, start = 0): int =
  rindex a, b, start, len(a)


const AsciiOrdRange = 0..0x7F

func isascii*(c: char|Rune): bool = ord(c) in AsciiOrdRange
func isascii*[C: char|Rune](s: openArray[C]): bool =
  result = true
  if s.len == 0: return
  for c in s:
    if not c.isascii(): return false

when isMainModule:
  assert "asd".isascii

template isspaceImpl(c: char): bool = c in Whitespace
template isdigitImpl(c: char): bool = strutils.isDigit(c) # just alias

template all(a: openArray, isX){.dirty.} =
  if a.len == 0: return
  result = true
  for c in a:
    if not isX(c):
      return false

template wrap2Aux(C, isX, wrap){.dirty.} =
  func isX*(c: C): bool = wrap(c)
  func isX*(s: openArray[C]): bool = all(s, wrap)

template wrap2(isX, wrap){.dirty.} = wrap2Aux(char, isX, wrap)
wrap2 isalpha, isAlphaAscii
wrap2 isspace, isspaceImpl
wrap2 isdigit, isdigitImpl
wrap2 isalnum, isAlphaNumeric


wrap2Aux Rune, isalpha, unicode.isAlpha
wrap2Aux Rune, isspace, unicode_space_decimal.isSpace

template `*`(c: char|string, i: int): string = strutils.repeat(c, i)
template `*`(c: Rune, i: int): seq[Rune] = sequtils.repeat(c, i)
proc `*`[C: char|Rune](c: seq[C], i: int): seq[C] =
  result = newSeqOfCap[C](c.len*i)
  for _ in 1..i:
    result.add c

template `+`[C](c: seq[C], i: C): seq[C] = @c & i
template `+`[C](c: openArray[C], i: openArray[C]): seq[C] = @c & @i

template centerImpl(a, width, fillchar; op: untyped = `+`) =
  let
    hWidth = (width-len(a)) div 2
    half = fillchar * hWidth
  result = half + a + half

func center*[S: not openArray](a: S, width: int, fillchar = ' '): S =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  retIfWider a
  centerImpl a, width, fillchar

func center*[C](a: openArray[C], width: int, fillchar: C): seq[C] =
  retIfWider(a, `@`)
  centerImpl a, width, fillchar

func center*[C](a: openArray[C], width: int, fillchar: openArray[C] = [C' ']): seq[C] =
  discard chkLen(a, `@`)
  centerImpl(a, width, fillchar[0])

func ljust*(a: string, width: int, fillchar = ' ' ): string =
  alignLeft $a, width, fillchar
func rjust*(a: string, width: int, fillchar = ' ' ): string =
  align $a, width, fillchar

func center*[S: not openArray](a: S, width: int, fillchar: S): S =
  discard chkLen a
  centerImpl(a, width, fillchar)

template ljustImpl(le) =
  let fills = fillchar * (width - le)
  result = a + fills
template rjustImpl(le) =
  let fills = fillchar * (width - le)
  result = fills + a

template gen_just(ljust){.dirty.} =
  func ljust*[S: not openArray](a: S, width: int, fillchar: S): S =
    let le = chkLen a
    `ljust Impl` a.len

  func ljust*[C](a: openArray[C], width: int, fillchar = C' '): seq[C] = `ljust Impl` a.len
  func ljust*[C](a: openArray[C], width: int, fillchar: openArray[C]): seq[C] =
    discard chkLen(a, `@`)
    let fillchar = fillchar[0]
    `ljust Impl` a.len

gen_just ljust
gen_just rjust

func zfill*(c: char, width: int): string =
  if 1 >= width:
    return $c
  # Now `width` is at least 2.
  let zeroes = '0'.repeat(width-1)
  if c == '+' or c == '-':
    return c & zeroes
  result = zeroes & c

template zfillImpl(CofS, S, res, `+`){.dirty.} =
  let le = len(a)
  if le >= width:
    return S res
  let fill = width - le
  let zeroes = (CofS'0') * fill
  if le == 0:
    return S zeroes

  let first = res[0]
  res = S(zeroes).`+` res
  if (first == CofS'+') or first == CofS'-':
    # move sign to beginning of string
    res[fill] = CofS'0'
    res[0] = first
  result = S res

func zfill*[S: not openArray](a: S, width: int): S =
  var res = $a
  zfillImpl char, S, res, `+`

func zfill*[C](a: openArray[C], width: int): seq[C] =
  var res = @a
  zfillImpl C, `@`, res, `&`

when isMainModule:
  assert ['0', '0', 'c', 'z'] == ['c', 'z'].zfill 4
  assert "00cz" == "cz".zfill 4

func removeprefix*[S](a: S, suffix: S): S =
  var res = $a
  strutils.removePrefix(res, suffix)
  S res
func removesuffix*[S](a: S, suffix: S): S =
  var res = $a
  strutils.removeSuffix(res, suffix)
  S res

template replace*[S](a: S, sub, by: char): untyped =
  replaceLib.replace(a, sub, by)
template replace*[S](a: S, sub, by: S): untyped =
  replaceLib.replace(a, sub, by)

func replace*[S](a: S, sub, by: char, count: int): S =
  if count < 0: a.replace(sub, by)
  else: replaceLib.replace(a, sub, by, count)

func replace*[S](a: S, sub, by: S, count: int): S =
  if count < 0: a.replace(sub, by)
  else: replaceLib.replace(a, sub, by, count)

template expandtabsAux[S](a: S, tabsize#[: is a Positive]#;
  strByteLen: int;  iter; newStringOfCap
): untyped =
  # modified from CPython's Objects/unicodeobject.c unicode_expandtabs_impl
  # with some refinement:
  # 
  # 1. here `tabsize` is assumed to be Positive,
  #  get rid of making comparing within loop, that's what CPython does:
  #  two `if (tabsize > 0)` in two for loop.
  # 2. by using Nim's string, we use the strategy of
  #  dynamically memory allocation, so no need to
  #  firstly perform one loop to just count the length of the result.
  # 3. we use case-branch instead of if-branch within the loop.
  #
  # Also, we get some opt inspiration from std/strmisc's expandTabs
  # - with cap of `le + le shl 2`.
  # - add spaces via loop, which reduces space complexity.
  mixin add
  var column = 0
  var res = newStringOfCap(strByteLen + strByteLen shl 2)
  for c in a.iter:
    type C = typeof(c)
    template addChars(res;c: C; n) =
      for _ in 1..n:
        res.add c
    case c
    of C('\r'), C('\n'):
      res.add c
      column = 0
    of C('\t'):
      let incr = (tabsize - column mod tabsize)
      column.inc incr
      if incr > 0:
        res.addChars C(' '), incr
    else:
      res.add c
      column.inc
  res

template removeAll[S](a: S, toRM: char; strByteLen: int; iter; newStringOfCap): untyped =
  var result = newStringOfCap strByteLen
  for c in a.iter:
    if c != typeof(c)(toRM):
      result.add c
  result

template expandtabsImpl*[S](a: S, tabsize: int;
  strByteLen: int;  iter; newStringOfCap: typed = newStringOfCap
): untyped =
  if tabsize > 0: expandtabsAux(a, tabsize, strByteLen, iter, newStringOfCap)
  else: removeAll(a, '\t', strByteLen, iter, newStringOfCap)

proc expandtabs*(a: string, tabsize=8): string =
  expandtabsImpl(a, tabsize, a.len, items)

proc expandtabs*[C](a: openArray[C], tabsize=8): seq[C] =
  expandtabsImpl(a, tabsize, a.len, items, newSeqOfCap[C])

func join*[T](sep: char, a: openArray[T]): string =
  a.join(sep)

func join*[T, S](sep: S, a: openArray[T]): S =
  ## Mimics Python join() -> string
  S a.join($(sep))

template partitionImpl(find; resA; resSep: untyped = sep){.dirty.} =
  let idx = find
  if idx == -1:
    result.before = resA
    return
  result = (a[0..<idx], resSep, a[idx+len(sep) .. ^1] )

template len(c: char): int = 1
template len(c: Rune): int = 1
template partitionGen(name; find){.dirty.} =
  func name*[S](a: S, sep: S): tuple[before, sep, after: S] =
    noEmptySep(sep)
    partitionImpl(finds.find(a, sep, start=0), a)
  func name*[C](a: openArray[C], sep: C): tuple[before, sep, after: seq[C]] =
    partitionImpl a.find(sep), @a, @[sep]
  func name*(a: string, sep: char): tuple[before, sep, after: string] =
    partitionImpl strutils.find(a, sep), a, $sep

partitionGen partition, find
partitionGen rpartition, rfind
