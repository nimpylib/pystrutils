

import std/unittest
import std/sugar

import pystrutils


template type2test(x): string =
  var res: string
  for i in x:
    res.add char i
  res

import pystrutils


suite "hex":
  test "no_extra_arg":
    check "".hex() == ""
    check "\x1a\x2b\x30".hex() == "1a2b30"

  test "separator_basics":
    let three_bytes = "\xb9\x01\xef"

    check three_bytes.hex() == "b901ef"

    expect ValueError: discard three_bytes.hex("")
    expect ValueError: discard three_bytes.hex("xx")
    expect ValueError: discard three_bytes.hex("\xff")
    expect ValueError: discard three_bytes.hex("\x80")
    #expect ValueError: discard three_bytes.hex(chr 0x100)


    check(three_bytes.hex(':', 0) == "b901ef")
    check(three_bytes.hex('\x00') == "b9\x0001\x00ef")
    check(three_bytes.hex('\x00') == "b9\x0001\x00ef")
    check(three_bytes.hex('\x7f') == "b9\x7f01\x7fef")
    check(three_bytes.hex('\x7f') == "b9\x7f01\x7fef")
    check(three_bytes.hex(':', 3) == "b901ef")
    check(three_bytes.hex(':', 4) == "b901ef")
    check(three_bytes.hex(':', -4)== "b901ef")
    check(three_bytes.hex(":")    == "b9:01:ef")
    check(three_bytes.hex("$")    == "b9$01$ef")
    check(three_bytes.hex(':', 1) == "b9:01:ef")
    check(three_bytes.hex(':', -1)== "b9:01:ef")
    check(three_bytes.hex(':', 2) == "b9:01ef")
    check(three_bytes.hex(':', 1) == "b9:01:ef")
    check(three_bytes.hex('*', -2)== "b901*ef")

    for bytes_per_sep in [3, -3, int32.high, -int32.high]:
      check(three_bytes.hex(':', bytes_per_sep) == "b901ef")


    #value = '{s\005\000\000\000worldi\002\000\000\000s\005\000\000\000helloi\001\000\000\0000"
    let value = "{s\x05\x00\x00\x00worldi\x02\x00\x00\x00s\x05\x00\x00\x00helloi\x01\x00\x00\x000"
    check(value.hex('.', 8) == "7b7305000000776f.726c646902000000.730500000068656c.6c6f690100000030")

  test "separator_basics2":
    let three_bytes = "\xb9\x01\xef"

  test "separator_five_bytes":
    let five_bytes = type2test(90..<95)
    check(five_bytes.hex() == "5a5b5c5d5e")

  test "separator_six_bytes":
    let six_bytes = type2test collect do:
      for x in 1..<7: x*3
    check(six_bytes.hex() == "0306090c0f12")
    check(six_bytes.hex('.', 1) == "03.06.09.0c.0f.12")
    check(six_bytes.hex(' ', 2) == "0306 090c 0f12")
    check(six_bytes.hex('-', 3) == "030609-0c0f12")
    check(six_bytes.hex(':', 4) == "0306:090c0f12")
    check(six_bytes.hex(':', 5) == "03:06090c0f12")
    check(six_bytes.hex(':', 6) == "0306090c0f12")
    check(six_bytes.hex(':', 95)=="0306090c0f12")
    check(six_bytes.hex('_', -3)=="030609_0c0f12")
    check(six_bytes.hex(':', -4)=="0306090c:0f12")
    check(six_bytes.hex('@', -5)=="0306090c0f@12")
    check(six_bytes.hex(':', -6)=="0306090c0f12")
    check(six_bytes.hex(' ', -95)=="0306090c0f12")

