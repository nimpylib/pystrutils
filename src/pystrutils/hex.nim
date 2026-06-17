
#from std/strutils import toHex
# NOTE: strutils.toHex uses upper ascii

when defined(nimPreviewSlimSystem):
  import std/assertions

const Py_hexdigits = "0123456789abcdef"
template splitToHex[I, C](c: I, lhs, rhs: var C) =
  lhs = Py_hexdigits[c shr 4]
  rhs = Py_hexdigits[c and 0x0f]

proc hex*[S](arg: S; sep_char: char, bytes_per_sep=1): S =
  var abs_bytes_per_group = abs bytes_per_sep
  let arglen = arg.len
  var resultlen = 0
  var bytes_per_sep_group = bytes_per_sep
  if bytes_per_sep_group != 0 and arglen > 0:
    resultlen = (arglen - 1) div abs_bytes_per_group

  if arglen >= (int.high div 2) - resultlen:
    raise new OutOfMemDefect
  resultlen += arglen * 2

  if abs_bytes_per_group >= arglen:
    bytes_per_sep_group = 0
    abs_bytes_per_group = 0

  result = S newStringUninit resultlen
  template stepHex2result(inc: untyped, reverse: static[bool]) =
    let jOld = j
    inc j
    when reverse:
      c.splitToHex result[j], result[jOld]
    else:
      c.splitToHex result[jOld], result[j]
    inc j

  if bytes_per_sep_group == 0:
    var j = 0
    for i in 0 ..< arglen:
      assert j+1 < resultlen
      let c = uint8 arg[i]
      stepHex2result inc, false
    return

  # The number of complete chunk+sep periods.

  let chunks = (arglen - 1) div abs_bytes_per_group

  template loop(inc, I, J, judgeLoopI, judgeJ: untyped, reverse: static[bool]) {.dirty.} =
    i = I
    j = J
    template loopBody {.dirty.} =
      let c = uint8 arg[i]
      inc i

      stepHex2result inc, reverse

    for chunk in 0 ..< chunks:
      for k in 0 ..< abs_bytes_per_group:
        loopBody
      result[j] = sep_char
      inc j

    while judgeLoopI:
      loopBody

    assert judgeJ

  var i, j: int
  if bytes_per_sep_group < 0:
    loop(inc, 0, 0, i < arglen, j == resultlen, false)
  else:
    loop(dec, arglen-1, resultlen-1, i >= 0, j == -1, true)


proc hex*[S](arg: S): S =
  hex arg, '\0', 0


proc hex*[S](arg: S; sep: S, bytes_per_sep=1): S =
  let seplen = sep.len

  if seplen != 1:
    raise newException(ValueError, "sep must be length 1")
  if ord(sep[0]) > 127:
    raise newException(ValueError, "sep must be ASCII")

  hex arg, sep[0], bytes_per_sep

