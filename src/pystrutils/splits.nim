
from std/unicode import Rune
from std/algorithm import reverse
import pkg/unicode_space_decimal/space
import ./split/[
  common, split_whitespace, rsplit_whitespace, gen
]

import ./meth

template ISSPACE*[S](s: S, i: int): bool =
  bind isspace
  isspace(s[i])

proc_gen_split split,  seq, add
proc_gen_split rsplit, seq, add
proc splitlines*[S](self: S, keepends = false): seq[S] =
  for i in splitlines[S](self, keepends): result.add(i)
