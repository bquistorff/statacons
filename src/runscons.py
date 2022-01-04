# Copyright 2022. This work is licensed under a CC BY 4.0 license. 

# Meant to be executed from in Stata with: python script runScons.py, args(--warn=all)
# If you want to run this from within Stata's Python interpreter, you can actually copy and paste these lines.
# or can be from CLI (though no reason): python runScons.py --warn=all

#import sys
#in_stata = 'sfi' in sys.modules #not currently needed

# Do better arg splitting (see note in statacons.ado).
import sys
import sfi

#print(sys.argv)
if len(sys.argv)>1:
    import shlex
    sys.argv = [sys.argv[0]] + shlex.split(sys.argv[1])
#print(sys.argv)

### Clear Scons if already loaded
# SCons has some package-level variables that need to be reset from main() to be able to be run multiple times
# Notes: https://stackoverflow.com/questions/437589/how-do-i-unload-reload-a-python-module/487718#487718
import sconstruct_fns
sconstruct_fns.rm_SCons_mods()
if 'SCons' in globals(): del SCons

#Add the python dir to path otherwise SCons can't call python commands
import platform
if platform.system()=="Windows":
    import os
    python_exe_dir = os.environ['PATH'].split(os.pathsep)[0][:-12] #Stata prepends "<python dir>\Library/bin"
    os.environ['PATH'] = python_exe_dir + os.pathsep + os.environ['PATH']

### Load SCons
import SCons
import SCons.Script

### Patch things up for running in Stata (SCons doesn't handle these non-standard situations well)
# OK to do even if not in Stata
SCons.Script.Main.revert_io = sconstruct_fns.revert_io2
SCons.Job.Jobs._reset_sig_handler = sconstruct_fns._reset_sig_handler2

### Actually execute
# If we don't catch SystemExit then it'll always display a "SystemExit: 0" even if no error.
# SCons.Script.Main() catches all exceptions and then does sys.exit() which raises SystemExit
# Then use sfi's exit
exit_status=0
try:
    SCons.Script.main()
except SystemExit as e:
    exit_status = e.code
sfi.SFIToolkit.exit(exit_status)
