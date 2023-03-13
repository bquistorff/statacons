*! version 3.0.0  May 17 2022  statacons team
* Copyright 2022. This work is licensed under a CC BY 4.0 license.

* Anaconda env's script dir is added to path when you switch environments, but not added to PYTHONPATH/sys.path,
* so in Stata setting the env doesn't bring that path in.
* We could try to find the Scripts folder given the executable path, but this might differ across Python distributions,
* so instead just "vendor" sconsign-script.py (include it in our pkg), given it's so small and unlikely to change.

program stataconsign
	qui findfile sconsign-script.py
	python script "`r(fn)'", args(`0')
end

// stataconsign.sthlp markdown code follows
// converted to .sthlp by markdoc
// markdoc stataconsign.ado, export(sthlp) replace mini
// see buildHelpFiles.do

/***

_version 3.0.1_

stataconsign
======

__stataconsign__ -- calls the SCons function __sconsign__ to print the contents of the __sconsign__ database, typically __.sconsign.dblite__, to the Stata window.

The syntax of __stataconsign__ mimics that of __sconsign__. This help file reproduces the contents of the __sconsign__ help, which can be accessed from the appropriate shell prompt with __sconsign -h__, and adds a few comments.

Syntax
------

> __stataconsign__ [OPTIONS] [FILE ...]

By default, __stataconsign__ will look in the current directory for an file __sconsign.dblite__ and print the contents of that database to the Stata window.

### Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| -a, --act, --action        | Print build action information.                    |
| -c, --csig                 | Print content signature information.               |
| -d DIR, --dir=DIR          | Print only info about DIR.                         |
| -e ENTRY, --entry=ENTRY    | Print only info about ENTRY.                       |
| -f FORMAT, --format=FORMAT | FILE is in the specified FORMAT.                   |
| -h, --help                 | Print this message and exit.                       |
| -i, --implicit             | Print implicit dependency information.             |
| -r, --readable             | Print timestamps in human-readable form.           |
| --raw                      | Print raw Python object representations.           |
| -s, --size                 | Print file sizes.                                  |
| -t, --timestamp            | Print timestamp information.                       |
| -v, --verbose              | Verbose, describe each field.                      |

Remarks
-------

__stataconsign__ is useful for obtaining information on what SCons considers to be the most recent build, i.e., the last time the project was built _by SCons_.

Examples
----------

basic use

    . stataconsign

use human-readable timestamps

    . stataconsign -r

examine a database named .sconsignParallel.dblite in a sub-directory dbs

    . stataconsign dbs/.sconsignParallel.dblite


Advanced Use
----------------

Use the __SConsignFile()__ function in an SConstruct to specify a filename and directory for the sconsign database associated with that SConstruct. For example:

> SConsignFile("dbs/.sconsignParallel.dblite")

See the SCons User Manual and SCons Man Page for more details.

From a shell prompt, the screen output of __sconsign__ can be saved to a text file as follows:

> sconsign > sconsign.txt

Author
------

__statacons__ team
[https://github.com/bquistorff/statacons](https://github.com/bquistorff/statacons)

References
----------

SCons Development Team (2021a), [SCons 4.3.0 Man page, https://scons.org/doc/4.3.0/PDF/scons-man.pdf](https://scons.org/doc/4.3.0/PDF/scons-man.pdf)

SCons Development Team (2021b), [SCons 4.3.0 User Guide, https://scons.org/doc/4.3.0/PDF/scons-user.pdf](https://scons.org/doc/4.3.0/PDF/scons-user.pdf)


- - -

This help file was dynamically produced by
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/)

***/
