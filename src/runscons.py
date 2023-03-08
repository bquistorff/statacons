# Copyright 2022. This work is licensed under a CC BY 4.0 license.

# Meant to be executed from in Stata with: python script runScons.py, args(--warn=all)
# If you want to run this from within Stata's Python interpreter, you can actually copy and paste these lines.
# or can be from CLI (though no reason): python runScons.py --warn=all

import sys
import sfi
import sconstruct_fns
import platform


# Do better arg splitting (see note in statacons.ado).
if len(sys.argv) > 1:
    import shlex
    args = shlex.split(sys.argv[1])

    jobs_msg = "Parallel jobs not supported from inside Stata (can use scons from terminal). Setting --jobs=1."
    # Make sure we disable parallel builds in Stata until we solve that problem
    for i, arg in enumerate(args.copy()):
        if arg == "-j" and len(args) > i + 1:
            args[i + 1] = "1"
            print(jobs_msg)
            break
        elif arg.startswith("--jobs"):
            args[i] = "--jobs=1"
            print(jobs_msg)
            break

    sys.argv = [sys.argv[0]] + args

# Reload SCons. First clear Scons if already loaded:
# SCons has some package-level variables that need to be reset from main() to be able to be run multiple times
# Notes: https://stackoverflow.com/questions/437589/how-do-i-unload-reload-a-python-module/487718#487718
sconstruct_fns.rm_SCons_mods()
if 'SCons' in globals():
    del SCons
import SCons  # noqa: E402
import SCons.Script  # noqa: E402
from pkg_resources import packaging

# Add the python dir to path otherwise SCons can't call python commands
if platform.system() == "Windows":
    import os
    # Stata prepends "<python dir>\Library/bin" on Windows when loading Python.
    first_dir = os.environ['PATH'].split(os.pathsep)[0]
    if first_dir[-11:] == "Library/bin":
        python_exe_dir = first_dir[:-12]
        if python_exe_dir not in os.environ['PATH'].split(os.pathsep):
            os.environ['PATH'] = python_exe_dir + os.pathsep + os.environ['PATH']
            # If on Anaconda then also try to add the scripts path. Add more here for other distributions.
            relpath_subdirs = ["Scripts"]
            for relsubdir in relpath_subdirs:
                sub_dir = python_exe_dir + os.sep + relsubdir
                if os.path.isdir(sub_dir) and sub_dir not in os.environ['PATH'].split(os.pathsep):
                    os.environ['PATH'] = sub_dir + os.pathsep + os.environ['PATH']

# Patch things up for running in Stata (SCons doesn't handle these non-standard situations well)
# OK to do even if not in Stata
SCons.Script.Main.revert_io = sconstruct_fns.revert_io2
if packaging.version.parse(SCons.__version__) < packaging.version.parse("4.3.0"):
    SCons.Job.Jobs._reset_sig_handler = sconstruct_fns._reset_sig_handler2

# Actually execute:
# If we don't catch SystemExit then it'll always display a "SystemExit: 0" even if no error.
# SCons.Script.Main() catches all exceptions and then does sys.exit() which raises SystemExit
# Then use sfi's exit
exit_status = 0
try:
    SCons.Script.main()
except SystemExit as e:
    exit_status = e.code
sfi.SFIToolkit.exit(exit_status)
