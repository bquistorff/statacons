*! version 2.0.2  May 04 2022  statacons team
* Copyright 2022. This work is licensed under a CC BY 4.0 license.

program statacons, rclass
	* Try to capture some simple mistakes in STata-syntax
	loc comma_pos = strpos(`"`0'"',",")
	loc cap = cond(`comma_pos'==0 | `comma_pos'>=4, "cap", "")

	`cap' syntax [anything(name=targets everything equalok)] [, clean debug(string) file(string asis) help dry_run ///
        silent tree(string) show_config assume_built(string asis) assume_done(string asis) config_files(string asis) ///
        q sconstruct(string asis) cache_debug(string asis) cache_disable cache_force cache_readonly cache_show ///
        directory(string asis)]
	if "`cap'"=="" | _rc==0 {
		if "`anything'"=="" | substr(`"`anything'"',1,1)!="-" {
			_assert `"`file'"'=="" | `"`sconstruct'"'=="", msg("Can not specify both file() and sconstruct().")
		    * Parse separately the options that might have quotes in them
			loc file_opt = cond(`"`file'`sconstruct'"'!="",`" --file=`file'`sconstruct'"',"")
			loc assume_built_opt = cond(`"`assume_built'"'!="",`" --assume-built=`assume_built'"',"")
			loc assume_done_opt = cond(`"`assume_done'"'!="",`" --assume-done=`assume_done'"',"")
			loc config_files_opt = cond(`"`config_files'"'!="",`" --config-files=`config_files'"',"")
            loc cache_debug_opt = cond(`"`cache_debug'"'!="",`" --cache-debug=`cache_debug'"',"")
            loc directory_opt = cond(`"`directory'"'!="",`" --directory=`directory'"',"")

			loc 0 `"`=cond("`clean'"!="", " --clean", "")'`=cond("`debug'"!="", " --debug=`debug'", "")'"'
            loc 0 `"`0'`file_opt'`=cond("`help'"!="", " --help", "")'`=cond("`dry_run'"!="", " --dry-run", "")'"'
            loc 0 `"`0'`=cond("`q'"!="", " -Q", "")'`=cond("`silent'"!="", " --silent", "")'`=cond("`tree'"!="", " --tree=`tree'", "")'"'
            loc 0 `"`0'`=cond("`show_config'"!="", " --show-config", "")'`assume_built_opt'`assume_done_opt'`config_files_opt'"'
            loc 0 `"`0'`cache_debug_opt'`=cond("`cache_disable'"!="", " --cache-disable", "")'`=cond("`cache_force'"!="", " --cache-force", "")'"'
            loc 0 `"`0'`=cond("`cache_readonly'"!="", " --cache-readonly", "")'`=cond("`cache_show'"!="", " --cache-show", "")'`directory_opt' `targets'"'
			loc 0 = strtrim(`"`0'"')
			*di `"[`0']"'
		}
	}
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


_version 2.0.1_

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

Default targets can also be specified in the SConstruct with the __Default()__ function, although targets specified at the command line override defaults specified in the SConstruct. Targets can be excluded from the default group with the __Ignore()__ function.

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

    The default is _do_, but the user can specify anything that Stata can accept as a command,
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

Run __statacons --show-config__ to show current configuration.

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

    . statacons assume_built(*)



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
