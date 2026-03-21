## modified from std/strutils, adding `count` param
# and refine some style, add some opt, reduce code size by template.

import std/strutils
import ./finds

template add(res: var string, s: openArray[char]) =
  for i in s: res.add i
func replace[C](s: openArray[C], sub, by: C, count: Natural|bool, result: var auto) =
  var i = 0
  const hasCount = count is Natural
  when hasCount:
    var nDone = 0
  while i < s.len:
    when hasCount:
      if nDone == count:
        # copy the rest:
        result.setLen i  # as result was of `s.len`
        result.add s[i..s.high]
        break
    if s[i] == sub:
      result[i] = by
      when hasCount:
        nDone.inc
    else: result[i] = s[i]
    inc(i)

func replace*(s: string, sub, by: char, count: Natural): string =
  result = newString(s.len)
  replace(s, sub, by, count, result)
func replace*[C](s: openArray[C], sub, by: C, count: Natural): seq[C] =
  result = newSeqUninit[C](s.len)
  replace(s, sub, by, count, result)

func replace*(s: string, sub, by: char): string =
  result = newString(s.len)
  replace(s, sub, by, off, result)
func replace*[C](s: openArray[C], sub, by: C): seq[C] =
  result = newSeqUninit[C](s.len)
  replace(s, sub, by, off, result)

func replace*[C](s, sub, by: openArray[C], count: Natural|bool, result: var auto) =
  ## count must be Natural
  const hasCount = count is Natural
  let subLen = sub.len
  if subLen == 0:
    result.add s
    return

  template replaceImpl(findCb) =
    let last = s.high
    when hasCount:
      var nDone = 0
    var i = 0
    while (
      when hasCount: nDone != count
      else: true
    ):
      let j = findCb(i, last)
      if j < 0: break
      result.add s[i .. j - 1]
      result.add by
      when hasCount:
        nDone.inc
      i = j + subLen
    # copy the rest:
    result.add s[i..s.high]
  
  if subLen == 1:
    # when the pattern is a single char, we use a faster
    # char-based search that doesn't need a skip table:
    let c = sub[0]
    if by.len == 1:
      s.replace(c, by[0], count, result)
      return
    template findChar(first, last: int): int =
      s.find(c, first, last)
    replaceImpl(findChar)
  else:
    let a = initSkipTableT[C](sub)
    template findWithTable(first, last: int): int =
      find(a, s, sub, first, last)
    replaceImpl(findWithTable)

func replace*[C](s, sub, by: openArray[C], count: Natural): seq[C] =
  replace(s, sub, by, count, result)
func replace*(s: string, sub, by: string, count: Natural): string =
  replace(s, sub, by, count, result)

func replace*[C](s, sub, by: openArray[C]): seq[C] =
  replace(s, sub, by, off, result)
func replace*(s: string, sub, by: string): string =
  replace(s, sub, by, off, result)

