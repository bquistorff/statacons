{smcl}


{p 4 4 2}
{it:version 1.1.0}


{title:statacons}

{p 4 4 2}
{bf:statacons} -- calls {bf:SCons} to build a project defined in an {bf:SConstruct}.

{p 4 4 2}
The syntax of  {bf:statacons} mimics that of {bf:scons}, with a few additions and customizations.

{p 4 4 2}
In this help file, we list only the most important options. We borrow heavily from the {bf:scons} help.

{p 4 4 2}
To see the full list of options, type  {bf:statacons --help} at the Stata prompt or {bf:scons -h} at the appropriate shell prompt. See the SCons User Manual and SCons Man Page for more details.


{title:Syntax}

{p 8 8 2} {bf:statacons} [option[=value]] [{it:targets}]

{p 4 4 2}
By default, {bf:statacons} will look in the current directory for an {bf:SConstruct} file, consider all targets described in that file, and then build or re-build targets if needed.

{p 4 4 2}{bf:Specifying targets}

{p 4 4 2}
By default, {bf:statacons} will build all targets described in the {bf:SConstruct}. The user can specify a target or a subset of targets using the {it:target} option on the command line:

{p 8 8 2} . statacons outputs/auto-modified.dta

{p 4 4 2}
Default targets can also be specified in the SConstruct with the {bf:Default()} function, although targets specified at the command line override defaults specified in the SConstruct.

{p 4 4 2}{bf:Standard SCons Options}

{col 5}Option{col 33}Description
{space 4}{hline}
{col 5}-c, --clean, --remove{col 33}Remove specified targets and dependencies.
{col 5}--debug=TYPE{col 33}Print various types of debugging information: count, duplicate, explain, findlibs, includes, memoizer, memory, objects, pdb, prepare, presub, stacktrace, time, action-timestamps.
{col 5}-f FILE, --file=FILE, --makefile=FILE, --sconstruct=FILE{col 33}Read FILE as the top-level SConstruct file.
{col 5}-h, --help{col 33}Print defined help message
{col 5}-k, --keep-going{col 33}Keep going when a target can{c 39}t be made.
{col 5}-n, --no-exec, --just-print, --dry-run, --recon{col 33}Don{c 39}t build; just print commands.
{col 5}-Q{col 33}Suppress "Reading/Building" progress messages.
{col 5}-s, --silent, --quiet{col 33}Don{c 39}t print commands.
{col 5}--tree=OPTIONS{col 33}Print a dependency tree in various formats: all, derived, prune, status, linedraw.
{col 5}-v, --version{col 33}Print the SCons version number and exit.
{space 4}{hline}

{p 4 4 2}{bf:Custom statacons options}

{col 5}Option{col 33}Description
{space 4}{hline}
{col 5}--config-user=CONFIG_USER{col 33}specify user configuration file
{col 5}--show-config{col 33}show configuration
{col 5}--assume-done="dofile.do"{col 33}instruct Stata builder to skip dofile.do but mark targets as built. Can be a colon-seprated list of file patterns.
{col 5}--assume-built="target"{col 33}if all targets for a task are listed then Stata builder will skip the task but mark all targets as build. Can be a colon-seprated list of file patterns.
{space 4}{hline}
{p 4 4 2}{bf:Return values}

{p 4 4 2}
{bf:statacons} will return the Python return code in {it:r(py_rc)}. If non-zero, {bf:statacons} will issue error 7103 "error occurs when running a Python script file or importing a Python module".



{title:SConstruct Syntax}
The {bf:pystatacons} Python package provides tools for {bf:scons} to run Stata code.

{p 4 4 2}{bf:Basic SConstruct Recipe}
    import pystatacons
    env = pystatacons.init_env()
    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/dofile.do'
    )
    Depends(task_name, ['path/to/dependency1.ext',
                        'path/to/dependency2.ext']
    )

{p 4 4 2}
This defines a {bf:task} {it:task_name} from the {it:StataBuild} method with {bf:targets} {it:path/to/target1.ext} and {it:path/to/target2.ext}, {bf:source}  {it:path/to/dofile.do} and {bf:dependencies} {it:path/to/dependency1.ext} and {it:path/to/dependency2.ext}.
{bf:statacons} will call Stata{c 39}s batch mode to {it:do path/to/dofile.do}.


{p 4 4 2}{bf:Additional Options for SConstruct Recipe}

    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/source.ext',
          file_cmd = "command",
          params = 'arguments or options',
          depends = ['path/to/dependency1.ext', 'path/to/dependency2.ext']
    )

{p 4 4 2}
The additional options to {bf:StataBuild} are

{break}    - file_cmd : the command SCons should pass to Stata{c 39}s batch mode. The default is {it:do}, but the user can specify anything that Stata can accept as a command, e.g., {it:dyndoc}, {it:markdown}, {it:net}, etc.

{break}    - params : arguments or options that should follow the source in the call to Stata batch mode. For example, a task with {it:file_cmd} of {bf:markdown} might specify

{p 8 8 2} params = {c 39}, saving\(myfile.html\) replace{c 39}

{break}    - depends : an alternative to using the {bf:Depends()} function

{break}    - full_cmd : Alternatively, one can specify the full command explicitly (including any file and parameters). This will ignore the {it:file_cmd}, {it:source}, and {it:params}.

{p 4 4 2}
As an example,

    helpFile = env.StataBuild(
        target = ['statacons.sthlp'],
        do_file = 'statacons.ado',
        file_cmd = "markdoc",
        params = ', export\(statacons.sthlp\) mini replace'
    )

{p 4 4 2}
defines a {bf:task} {it:helpFile} from the {it:StataBuild} method with {bf:target} {it:statacons.sthlp}, {bf:source}  {it:statacons.ado} and {bf:params} {it:{c 39}, export\(statacons.sthlp\) mini replace{c 39}}.
{bf:statacons} will call Stata in batch mode with command {bf:markdoc statacons.ado, export(sthlp) replace mini}.

{p 4 4 2}
SCons uses {bf:Decider} functions to determine when to run a task. 
The default {bf:Decider} rebuilds a task if the content of any task{c 39}s dependencies has changed since the last time SCons was run. 
If your workflow involves running some Stata scripts outside of SCons, then SCons may not know what is actually up-to-date and unnecessarily rebuild some tasks.
The {bf:pystatacons} package, therefore defines a new {bf:Decider} called {c 39}content-timestamp-newer{c 39}, which only rebuilds a task if 
"a task{c 39}s dependency has changed content since the last time SCons was run" AND "a task{c 39}s dependency has been modified after all of the task{c 39}s targets".
To use this new {bf:Decider},  include this line later in the {bf:SConstruct} file.

    Decider(pystatacons.decider_str_lookup['content-timestamp-newer'])

{p 4 4 2}{bf:SConstruct Functions}

{p 4 4 2}
See the SCons User Manual and SCons Man Page for {it:functions} available in SConstructs.



{title:Configuration}

{p 4 4 2}
{bf:statacons} should run without configuration on most standard setups, assuming python and scons are installed properly.
See {bf:utils/config_user_template.ini} and {bf:config_project.ini} for configuration options.

{p 4 4 2}
Run {bf:statacons --show-config} to show current configuration.

{p 4 4 2}
Run {bf:utils/debugging-checklist.do} to obtain useful information for debugging.



{title:Example(s)}

{p 4 4 2}
basic use

    . statacons

{p 4 4 2}
print debugging info and build tree

    . statacons --debug=explain --tree=status,prune

{p 4 4 2}
show current configuration

    . statacons --show-config

{p 4 4 2}
build target called {c 39}dl_original_data{c 39}

    . statacons dl_original_data

{p 4 4 2}
mark all targets as built

    . statacons --assume-built=*




{title:Author}

{p 4 4 2}
{bf:statacons} team
{browse "https://github.com/bquistorff/statacons":https://github.com/bquistorff/statacons}


{title:References}

{p 4 4 2}
SCons Development Team (2021a),  {browse "https://scons.org/doc/4.3.0/PDF/scons-man.pdf":SCons 4.3.0 Man page, https://scons.org/doc/4.3.0/PDF/scons-man.pdf}

{p 4 4 2}
SCons Development Team (2021b),  {browse "https://scons.org/doc/4.3.0/PDF/scons-user.pdf":SCons 4.3.0 User Guide, https://scons.org/doc/4.3.0/PDF/scons-user.pdf}


{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package}




