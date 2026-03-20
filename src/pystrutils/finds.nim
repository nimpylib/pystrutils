
when defined(linux):
  proc memmem(haystack: pointer, haystacklen: csize_t,
              needle: pointer, needlelen: csize_t): pointer {.importc, header: """#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <string.h>""".}
elif defined(bsd) or (defined(macosx) and not defined(ios)):
  proc memmem(haystack: pointer, haystacklen: csize_t,
              needle: pointer, needlelen: csize_t): pointer {.importc, header: "#include <string.h>".}

from std/algorithm import fill

type
  SkipTable[C: SomeOrdinal] = (
    when sizeof(C) == 1: array[C, int]
    else: seq[int]
  )

type Size1 = char|byte|int8
proc `[]`[C: not Size1](self: SkipTable[C], i: C): int = self[int(i)]
proc `[]=`[C: not Size1](self: var SkipTable[C], i: C, val: int) = self[int(i)] = val
proc `[]`[C: not Size1](self: var SkipTable[C], i: C): var int = self[int(i)]

proc newSkipTable[C]: SkipTable[C] =
  when sizeof(C) > 1:
    result = newSeq[int](ord high C)

func initSkipTable[C](a: var SkipTable[C], sub: openArray[C]) =
  # TODO: this should be the `default()` initializer for the type.
  let m = len(sub)
  a = newSkipTable[C]()
  fill(a, m)

  for i in 0 ..< m - 1:
    a[sub[i]] = m - 1 - i
func initSkipTable[C](sub: openArray[C]): SkipTable[C] =
  result.initSkipTable sub

func find[C](a: SkipTable[C], s, sub: openArray[C], start: Natural = 0, last = -1): int =
  ## Searches for `sub` in `s` inside range `start..last` using preprocessed
  ## table `a`. If `last` is unspecified, it defaults to `s.high` (the last
  ## element).
  let
    last = if last < 0: s.high else: last
    subLast = sub.len - 1

  if subLast == -1:
    # this was an empty needle string,
    # we count this as match in the first possible position:
    return start

  # This is an implementation of the Boyer-Moore Horspool algorithms
  # https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm
  result = -1
  var skip = start

  while last - skip >= subLast:
    var i = subLast
    while s[skip + i] == sub[i]:
      if i == 0:
        return skip
      dec i
    inc skip, a[s[skip + subLast]]


proc find*[C](s, sub: openArray[C], start: Natural = 0, last = -1): int =

  if sub.len > s.len - start: return -1
  if sub.len == 1:
    let i: Natural = if last < 0: s.len - 1 else: last
    result = system.find(s.toOpenArray(start, i), sub[0])
    if result < 0: return
    result.inc start
    return

  template useSkipTable =
    result = find(initSkipTable(sub), s, sub, start, last)

  when nimvm:
    useSkipTable()
  else:
    when declared(memmem):
      let subLen = sub.len
      if last < 0 and start < s.len and subLen != 0:
        let found = memmem(s[start].addr, csize_t((s.len - start)*sizeof(C)), addr(sub[0]), csize_t(subLen * sizeof(C)))
        result = if not found.isNil:
            (cast[int](found) -% cast[int](s[0].addr)) div sizeof(C)
          else:
            -1
      else:
        useSkipTable()
    else:
      useSkipTable()

func rfind*[C](s, sub: openArray[C], start: Natural = 0, last = -1): int =
  if sub.len == 0:
    let rightIndex: Natural = if last < 0: s.len else: last
    return max(start, rightIndex)
  if sub.len > s.len - start:
    return -1
  let last = if last == -1: s.high else: last
  result = 0
  for i in countdown(last - sub.len + 1, start):
    for j in 0..sub.len-1:
      result = i
      if sub[j] != s[i+j]:
        result = -1
        break
    if result != -1: return
  return -1

# system lacks such rfind
func rfind*[C](s: openArray[C], sub: C, start: Natural = 0, last = -1): int =
  let last: Natural = if last < 0: s.len-1 else: last
  for i in countdown(last, start):
    if s[i] == sub: return i
  return -1

