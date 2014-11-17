#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Written by Zachary Murray (dremelofdeath) on 11/04/2013.
# Your right to steal this is reserved. <3

import sys


required_version = (2, 6)
if sys.version_info < required_version:
  print('Situate requires Python version 2.6+.')
  print('Your Python version was detected as %s.%s, which is too old.\n' %
      (sys.version_info[0], sys.version_info[1]))
  print('Install a newer version of Python and try again.\n')
  sys.exit(1)


import situate_core


if __name__ == '__main__':
  situate_core.main()

