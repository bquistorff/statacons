_version 2.0.0_

statacons
======

__statacons__ -- calls __SCons__ to build a project defined in an __SConstruct__.

The syntax of  __statacons__ mimics that of __scons__, with a few additions and customizations.

In this help file, we list only the most important options. We borrow heavily from the __scons__ help.

To see the full list of options, type  __statacons --help__ at the Stata prompt or __scons -h__ at the appropriate shell prompt. See the SCons User Manual and SCons Man Page for more details.

Syntax
------

> __statacons__ [option[=value]] [_targets_]

By default, __statacons__ will look in the current directory for an __SConstruct__ file, consider all targets described in that file, and then build or re-build targets if needed.

### Specifying targets

By default, __statacons__ will build all targets described in the __SConstruct__. The user can specify a target or a subset of targets using the _target_ option on the command line:

> . statacons outputs/auto-modified.dta

Default targets can also be specified in the SConstruct with the __Default()__ function, although targets specified at the command line override defaults specified in the SConstruct.

### Standard SCons Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| -c, --clean, --remove      | Remove specified targets and dependencies. |
| --debug=TYPE               | Print various types of debugging information: count, duplicate, explain, findlibs, includes, memoizer, memory, objects, pdb, prepare, presub, stacktrace, time, action-timestamps. |
| -f FILE, --file=FILE, --makefile=FILE, --sconstruct=FILE | Read FILE as the top-level SConstruct file. |
| -h, --help                 | Print defined help message |
| -k, --keep-going           | Keep going when a target can't be made. |
| -n, --no-exec, --just-print, --dry-run, --recon | Don't build; just print commands. |
| -Q                         | Suppress "Reading/Building" progress messages. |
| -s, --silent, --quiet      | Don't print commands. |
| --tree=OPTIONS             | Print a dependency tree in various formats: all, derived, prune, status, linedraw. |
| -v, --version              | Print the SCons version number and exit. |


### Custom statacons options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| --config-files=CONFIG_FILES  | specify user configuration files |
| --show-config              | show configuration |
| --assume-done="dofile.do"  | instruct Stata builder to skip dofile.do but mark targets as built. Can be a colon-seprated list of file patterns.|
| --assume-built="target" | if all targets for a task are listed then Stata builder will skip the task but mark all targets as build. Can be a colon-seprated list of file patterns. |

### Return values

__statacons__ will return the Python return code in _r(py_rc)_. If non-zero, __statacons__ will issue error 7103 "error occurs when running a Python script file or importing a Python module".


SConstruct Syntax
-------
The __pystatacons__ Python package provides tools for __scons__ to run Stata code.

### Basic SConstruct Recipe
    import pystatacons
    env = pystatacons.init_env()
    task_name = env.StataBuild(
              target = ['path/to/target1.ext', 'path/to/target2.ext'],
              source = 'path/to/dofile.do'
    )
    Depends(task_name, ['path/to/dependency1.ext',
                            'path/to/dependency2.ext']
    )

This defines a __task__ _task_name_ from the _StataBuild_ method with __targets__ _path/to/target1.ext_ and _path/to/target2.ext_, __source__  _path/to/dofile.do_ and __dependencies__ _path/to/dependency1.ext_ and _path/to/dependency2.ext_.
__statacons__ will call Stata's batch mode to _do path/to/dofile.do_.


### Additional Options for SConstruct Recipe

    task_name = env.StataBuild(
              target = ['path/to/target1.ext', 'path/to/target2.ext'],
              source = 'path/to/source.ext',
              file_cmd = "command",
              params = 'arguments or options',
              depends = ['path/to/dependency1.ext', 'path/to/dependency2.ext']
    )

The additional options to __StataBuild__ are

- file_cmd : the command SCons should pass to Stata's batch mode. The default is _do_, but the user can specify anything that Stata can accept as a command, e.g., _dyndoc_, _markdown_, _net_, etc.

- params : arguments or options that should follow the source in the call to Stata batch mode. For example, a task with _file_cmd_ of __markdown__ might specify

> params = ', saving\(myfile.html\) replace'

- depends : an alternative to using the __Depends()__ function

- full_cmd : Alternatively, one can specify the full command explicitly (including any file and parameters). This will ignore the _file_cmd_, _source_, and _params_.

As an example,

    helpFile = env.StataBuild(
            target = ['statacons.sthlp'],
            do_file = 'statacons.ado',
            file_cmd = "markdoc",
            params = ', export\(statacons.sthlp\) mini replace'
    )

defines a __task__ _helpFile_ from the _StataBuild_ method with __target__ _statacons.sthlp_, __source__  _statacons.ado_ and __params__ _', export\(statacons.sthlp\) mini replace'_.
__statacons__ will call Stata in batch mode with command __markdoc statacons.ado, export(sthlp) replace mini__.

SCons uses __Decider__ functions to determine when to run a task. 
The default __Decider__ rebuilds a task if the content of any task's dependencies has changed since the last time SCons was run. 
If your workflow involves running some Stata scripts outside of SCons, then SCons may not know what is actually up-to-date and unnecessarily rebuild some tasks.
The __pystatacons__ package, therefore defines a new __Decider__ called 'content-timestamp-newer', which only rebuilds a task if 
"a task's dependency has changed content since the last time SCons was run" AND "a task's dependency has been modified after all of the task's targets".
To use this new __Decider__,  include this line later in the __SConstruct__ file.

    Decider(pystatacons.decider_str_lookup['content-timestamp-newer'])

### SConstruct Functions

See the SCons User Manual and SCons Man Page for _functions_ available in SConstructs.


Configuration
----------

__statacons__ should run without configuration on most standard setups, assuming python and scons are installed properly.
See __utils/config_local_template.ini__ and __config_project.ini__ for configuration options.

Run __statacons --show-config__ to show current configuration.

Run __utils/debugging-checklist.do__ to obtain useful information for debugging.


Example(s)
----------

basic use

    . statacons

print debugging info and build tree

    . statacons --debug=explain --tree=status,prune

show current configuration

    . statacons --show-config

build target called 'dl_original_data'

    . statacons dl_original_data

mark all targets as built

    . statacons --assume-built=*



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


