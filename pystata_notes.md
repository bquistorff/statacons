Oddities with pystata:
- `python script ...` does not define the `__file__` variable. Causes "NameError: name '__file__' is not defined"
- to leave interpreter you use `end` (not `exit()` like a real Python terminal)
- The signal handler issue (that we fix for Scons)
- stdout and stderr are redefined after python initializes
- PYTHONPATH Environment variable (sys.path): Prepends ['', BASE\py]. Postpends ['.', Stata executable dir, BASE, BASE/py, SITE, SITE/py, PLUS, PLUS/py, PERSONAL, PERSONAL/py, OLDSITE]
- PATH environment variable: On Windows prepends "python dir\Library/bin". On Unix post-pends "Stata dir/utilities/java/linux-x64/zulu-jre11.0.13/bin"
- When passing args to Python, Stata doesn't split them like a shell would (see runscons.py for example and work-around).
- It looks like python is running in the same executable (doesn't show up seprately in the task manager). sys.executable points to the Stata process path. Changing env vars in Python changes them in the "parent" Stata.
- `python set exec` is different than a virtual env activation so many dirs for the venv won't be added the PATH var. We manually add the python exe dir, but we'd be missing some (and it depends on your distribution).
