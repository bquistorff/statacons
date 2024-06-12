_version 3.0.2_

statacons
======

__statacons__ -- calls __SCons__ to build a project defined in an __SConstruct__.

The syntax of  __statacons__ follows that of __scons__, with a few additions and customizations. For the most commonly used options, we
have adapted SCons syntax into a style more familiar to Stata users.
These options are listed below. We also allow users to use the standard
SCons syntax, although not a mix of the two in the same command.

In this help file, we list only the most important options. We borrow heavily from the __scons__ help.

To see the full list of options, type  __statacons, help__ at the Stata prompt or __scons -h__ at the appropriate shell prompt. See the SCons User Manual and SCons Man Page for more details.

Syntax
------

The syntax of __statacons__ is:

> __statacons__ [ _targets_ ] [, option(value)]

The SCons equivalent is:

> __statacons__ [option[=value]] [ _targets_ ]

By default, __statacons__ will look in the current directory for an __SConstruct__ file, consider all targets described in that file, and then build or re-build targets if needed.

### Specifying targets

By default, __statacons__ will build all targets described in the __SConstruct__. The user can specify a target or a subset of targets using the _target_ option on the command line:

> . statacons outputs/auto-modified.dta

The SCons equivalent is identical.

Default targets can also be specified in the SConstruct with the Default() function, although targets specified at the command line override defaults specified in the SConstruct. Targets can be excluded from the default group with the Ignore() function.

### Standard SCons Options

We list the most common options, with Stata syntax on the first line and the SCons equivalent on the second line.

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| clean                      | Remove specified targets and dependencies. |
| -c, --clean                 |   |
| debug(TYPE)               | Print TYPE of debugging information, _explain_ is most useful |
| --debug=TYPE               |   |
| directory(DIRECTORY) | change directory to DIRECTORY before starting build |
| -C DIRECTORY   |    |
| dry_run | Don't build; just print commands. |
| -n,  --dry-run |    |
| file(FILE) | Read FILE as the top-level SConstruct file. |
| -f FILE, --file=FILE |  |
| help                 | Print SCons help message |
| -h, --help                 |  |
| q                         | Don't print SCons progress messages |
| -Q                         |   |
| silent       | Don't print SCons actions or progress messages |
| -s, --silent     |  |
| tree(OPTIONS)             | Print a dependency tree in various formats:  |
| --tree=OPTIONS             |  all, derived, prune, status, linedraw. |


### Custom statacons options

| Option                      | Description                                        |
|-----------------------------|----------------------------------------------------|
| assume_built("target") | instruct the Stata builder to skip a task if all of its targets are listed,  |
| --assume-built="target" |  then mark those targets as up-to-date  |
| assume_done("filename.do") | instruct the Stata builder to skip the given do-file in the current build,  |
| --assume-done="filename.do" |  then mark the associated target(s) as up-to-date  |
| assume_done(*) | instruct the Stata builder to skip all do-files in the current build,  |
| --assume-done=* |  then mark all their targets as up-to-date  |
| config_file(CONFIG_FILE) | specify configuration file(s) |
| --config-files=CONFIG_FILE |    |
| show_config               | show configuration |
| --show-config               |   |



### Return values

__statacons__ will return the Python return code in _r(py_rc)_. If non-zero, __statacons__ will issue error 7103 "error occurs when running a Python script file or importing a Python module".


SConstruct Syntax
-------


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

- file_cmd : the command SCons should pass to Stata's batch mode.

    The default is _do_ , but the user can specify anything that Stata can accept as a command,
                    e.g., _dyndoc_, _markdown_, _net_, etc.

- params : arguments or options that should follow the source in the call to Stata batch mode.

    For example, a task with _file_cmd_ of __dyndoc__ might specify

> params = ', saving(myfile.html) replace'

- depends : an alternative to using the __Depends()__ function

- full_cmd : Alternatively, one can specify the full command explicitly (including any file and parameters).
    This will ignore the _file_cmd_, _source_, and _params_.

As an example,

    helpFile = env.StataBuild(
            target = ['statacons.sthlp'],
            do_file = 'statacons.ado',
            file_cmd = "markdoc",
            params = ', export(statacons.sthlp) mini replace'
    )

defines a __task__ _helpFile_ from the _StataBuild_ method with __target__ _statacons.sthlp_, __source__  _statacons.ado_ and __params__ ', _export(statacons.sthlp) mini replace'_.
__statacons__ will call Stata in batch mode with command __markdoc statacons.ado, export(sthlp) replace mini__.



### SConstruct Functions

See the SCons User Manual and SCons Man Page for _functions_ available in SConstructs.


Configuration
----------

__statacons__ should run without configuration on most standard setups, assuming python and scons are installed properly.
See __utils/config_local_template.ini__ and __config_project.ini__ for configuration options.

Run __statacons, show_config__ to show current configuration.

Run __utils/debugging-checklist.do__ to obtain useful information for debugging.


Example(s)
----------

basic use

    . statacons

print debugging info and build tree

    . statacons,  debug(explain) tree(status,prune)

show current configuration

    . statacons, show_config

build target called 'dl_original_data'

    . statacons dl_original_data

mark all targets as built

    . statacons, assume_built(*)



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


