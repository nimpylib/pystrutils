
import ./[common, reimporter]
import std/strutils
import ./split_runes

template postdo*(split_name) =
  const name = astToStr(split_name)
  when name[0] == 'r':  # rsplit[_whitespace]
    result.reverse()

template strutils_split(s, sep, maxsplit): untyped =
  bind split
  split(s, sep, maxsplit)

template strutils_rsplit(s, sep, maxsplit): untyped =
  bind rsplit
  rsplit(s, sep, maxsplit)


template byteLen*(s: string): int = s.len
template byteLen*(s: openArray[char|Rune]): int = s.len
template byteLen*(c: char|Rune): int = 1

template proc_gen_split*(split; PyList; append){.dirty.} =
  bind postdo, noEmptySep
  bind norm_maxsplit, PREPARE_CAP
  bind strutils_split
  bind strutils_rsplit
  bind Rune
  proc `split whitespace`*[S](pystr: S, maxsplit = -1): PyList[S] =
    let
      str_len = len(pystr)
      maxcount = norm_maxsplit(maxsplit, str_len)
    result = `new PyList OfCap`[S](PREPARE_CAP(maxcount))
    for i in pystr.`split whitespace impl`(str_len=str_len, maxsplit=maxcount):
      result.append i
    postdo split
  

  iterator `split NoCheck`(s: string, sep: char|string, maxsplit = -1): string{.inline.} =
    for i in `strutils split`(s, sep, maxsplit): yield i
  iterator `split NoCheck`[C: char|Rune](s: openArray[C], sep: openArray[C]|C, maxsplit = -1): seq[C]{.inline.} =
    for i in `strutils split`(s, sep, maxsplit): yield i

  iterator split*[S: not openArray[Rune|char]](a: S,
      sep: S|string|char, maxsplit = -1): S{.inline.} =
    noEmptySep sep
    for i in `split NoCheck`($a, sep, maxsplit): yield S i

  iterator split*[C: char|Rune](a: openArray[C],
      sep: openArray[C], maxsplit = -1): seq[C]{.inline.} =
    noEmptySep sep
    for i in `split NoCheck`(a, sep, maxsplit): yield i
  iterator split*[C: char|Rune](a: openArray[C],
      sep: C, maxsplit = -1): seq[C]{.inline.} =
    noEmptySep sep
    for i in `split NoCheck`(a, sep, maxsplit): yield i

  proc split*[S](a: S, maxsplit = -1): PyList[S] =
    a.`split whitespace`(maxsplit)

  # strutils.split func does not use any predicted capacity.

  template split_proc_impl[S](a2splitNoCheck) =
    template initRes[PyStr](maxcount) = 
      result = `new PyList OfCap`[PyStr](PREPARE_CAP maxcount)
    noEmptySep sep
    # CPython uses unicode len, here using byte-len shall be fine.
    let
      str_len = a.byteLen
      sep_len = sep.byteLen
    initRes[S](norm_maxsplit(maxsplit, str_len=str_len, sep_len=sep_len))
    for i in `split NoCheck`(a2splitNoCheck, sep, maxsplit): result.append i
    postdo split
  proc split*[C: char|Rune](a: openArray[C], sep: openArray[C], maxsplit = -1): PyList[seq[C]] =
    split_proc_impl[seq[C]](a)
  proc split*[C: char|Rune](a: openArray[C], sep: C, maxsplit = -1): PyList[seq[C]] =
    split_proc_impl[seq[C]](a)
  proc split*[S: not seq](a: S, sep: S|string|char, maxsplit = -1): PyList[S] =
    split_proc_impl[S]($a)

