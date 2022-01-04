# Copyright 2022. This work is licensed under a CC BY 4.0 license. 
import re
import sys

from SCons.Utilities.sconsign import main

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(main())
