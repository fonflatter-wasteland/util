#!/usr/bin/env python3

import fileinput
import html
import sys

with fileinput.input(files=sys.argv[1:], inplace=True) as f:
    for line in f:
        print(html.unescape(line), end='')

