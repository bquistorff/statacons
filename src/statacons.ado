*! version 1.0.0  January 2022  statacons team
* Copyright 2022. This work is licensed under a CC BY 4.0 license. 

program statacons, rclass
	qui findfile runscons.py
	//Stata doesn't parse args through to the script the way a shell normally would
	// so --assume-built="code/analysis code.do" -> ['../pkg/runscons.py', '--assume-built=', 'code/analysis code.do'] which scons doesn't like
	// so actually pass it as a quote-string `"...."' and then parse in Python
	cap noi python script "`r(fn)'", args(`"`0'"')
	local py_rc = _rc
	return scalar py_rc = `py_rc'
	
    if "`py_rc'"!="0"{
		di as error "Error from Python: `py_rc'"
		error 7103
	}
    
end

// statacons.sthlp markdown code follows
// converted to .sthlp by markdoc
// markdoc statacons.ado, export(sthlp) replace mini
// see buildHelpFiles.do

/***


_version 1.0.0_

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

> By default, __statacons__ will build all targets described in the __SConstruct__. The user can specify a target or a subset of targets using the _target_ option on the command line:

> . statacons outputs/auto-modified.dta

Default targets can also be specified in the SConstruct with the Default() function, although targets specified at the command line override defaults specified in the SConstruct.

### Standard SCons Options

	-c, --clean, --remove       Remove specified targets and dependencies.
	--debug=TYPE                Print various types of debugging information:
	                              count, duplicate, explain, findlibs, includes,
	                              memoizer, memory, objects, pdb, prepare,
	                              presub, stacktrace, time, action-timestamps.
	-f FILE, --file=FILE, --makefile=FILE, --sconstruct=FILE
	                              Read FILE as the top-level SConstruct file.
	-h, --help                  Print defined help message
	-k, --keep-going            Keep going when a target can't be made.
	-n, --no-exec, --just-print, --dry-run, --recon
	                              Don't build; just print commands.
	-Q                          Suppress "Reading/Building" progress messages.
	-s, --silent, --quiet       Don't print commands.
	--tree=OPTIONS              Print a dependency tree in various formats: all,
	                              derived, prune, status, linedraw.
	-v, --version               Print the SCons version number and exit.


### Custom statacons options

  --config-user=CONFIG_USER   specify user configuration file
  --show-config               show configuration
  --assume-built="dofile.do"  instruct Stata builder to skip dofile.do but mark targets as built

### Return values

__statacons__ will return the Python return code in r(py_rc). If non-zero, __statacons__ will issue error 7103 "error occurs when running a Python script file or importing a Python module".


SConstruct Syntax
-------


### Basic SConstruct Recipe

    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/dofile.do'
    )
    Depends(task_name, ['path/to/dependency1.ext',
                        'path/to/dependency2.ext']
    )

This defines a __task__ _task_name_ for the _StataBuild_ __environment__ with __targets__ _path/to/target1.ext_ and _path/to/target2.ext_, __source__  _path/to/dofile.do_ and __dependencies__ _path/to/dependency1.ext_ and _path/to/dependency2.ext_. __statacons__ will call Stata's batch mode to _do path/to/dofile.do_.


### Additional Options for SConstruct Recipe

    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/source.ext',
          file_cmd = "command",
          params = 'arguments or options',
          depends = ['path/to/dependency1.ext', 'path/to/dependency2.ext']
    )

The additional options are

- file_cmd : the command SCons should pass to Stata's batch mode. The default is _do_, but the user can specify anything that Stata can accept as a command, e.g., _dyndoc_, _markdown_, _net_, etc.

- params : arguments or options that should follow the source in the call to Stata batch mode. For example, a task with file_cmd of  _markdown__ might specify

> params = ', saving\(myfile.html\) replace'

- depends : an alternative to using the Depends() function

- full_cmd : Alternatively, one can specify the full command explicitly (including any file and parameters). This will ignore the _file_cmd_ and _params_.

As an example,

    helpFile = env.StataBuild(
        target = ['statacons.sthlp'],
        do_file = 'statacons.ado',
        file_cmd = "markdoc",
        params = ', export\(statacons.sthlp\) mini replace'
    )

defines a __task__ _helpFile_ for the _StataBuild_ __environment__ with __target__ _statacons.sthlp_, __source__  _statacons.ado_ and __params__ _', export\(statacons.sthlp\) mini replace'_. __statacons__ will call Stata in batch mode with command __markdoc statacons.ado, export(sthlp) replace mini__.



### SConstruct Functions

See the SCons User Manual and SCons Man Page for _functions_ available in SConstructs.


Configuration
----------

__statacons__ should run without configuration on most standard setups, assuming python and scons are installed properly.
See __utils/config_user_template.ini__ and __config_project.ini__ for configuration options.

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
        . statacons --assume=built=*



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
