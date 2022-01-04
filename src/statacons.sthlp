{smcl}


{p 4 4 2}
{it:version 1.0.0}


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

{p 8 8 2} By default, {bf:statacons} will build all targets described in the {bf:SConstruct}. The user can specify a target or a subset of targets using the {it:target} option on the command line:

{p 8 8 2} . statacons outputs/auto-modified.dta

{p 4 4 2}
Default targets can also be specified in the SConstruct with the Default() function, although targets specified at the command line override defaults specified in the SConstruct.

{p 4 4 2}{bf:Standard SCons Options}

{break}    	-c, --clean, --remove       Remove specified targets and dependencies.
{break}    	--debug=TYPE                Print various types of debugging information:
	                              count, duplicate, explain, findlibs, includes,
	                              memoizer, memory, objects, pdb, prepare,
	                              presub, stacktrace, time, action-timestamps.
{break}    	-f FILE, --file=FILE, --makefile=FILE, --sconstruct=FILE
	                              Read FILE as the top-level SConstruct file.
{break}    	-h, --help                  Print defined help message
{break}    	-k, --keep-going            Keep going when a target can{c 39}t be made.
{break}    	-n, --no-exec, --just-print, --dry-run, --recon
	                              Don{c 39}t build; just print commands.
{break}    	-Q                          Suppress "Reading/Building" progress messages.
{break}    	-s, --silent, --quiet       Don{c 39}t print commands.
{break}    	--tree=OPTIONS              Print a dependency tree in various formats: all,
	                              derived, prune, status, linedraw.
{break}    	-v, --version               Print the SCons version number and exit.


{p 4 4 2}{bf:Custom statacons options}

{break}    {space 2}--config-user=CONFIG_USER   specify user configuration file
{break}    {space 2}--show-config               show configuration
{break}    {space 2}--assume-built="dofile.do"  instruct Stata builder to skip dofile.do but mark targets as built



{title:SConstruct Syntax}


{p 4 4 2}{bf:Basic SConstruct Recipe}

    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/dofile.do'
    )
    Depends(task_name, ['path/to/dependency1.ext',
                        'path/to/dependency2.ext']
    )

{p 4 4 2}
This defines a {bf:task} {it:task_name} for the {it:StataBuild} {bf:environment} with {bf:targets} {it:path/to/target1.ext} and {it:path/to/target2.ext}, {bf:source}  {it:path/to/dofile.do} and {bf:dependencies} {it:path/to/dependency1.ext} and {it:path/to/dependency2.ext}. {bf:statacons} will call Stata{c 39}s batch mode to {it:do path/to/dofile.do}.


{p 4 4 2}{bf:Additional Options for SConstruct Recipe}

    task_name = env.StataBuild(
          target = ['path/to/target1.ext', 'path/to/target2.ext'],
          source = 'path/to/source.ext',
          file_cmd = "command",
          params = 'arguments or options',
          depends = ['path/to/dependency1.ext', 'path/to/dependency2.ext']
    )

{p 4 4 2}
The additional options are

{break}    - file_cmd : the command SCons should pass to Stata{c 39}s batch mode. The default is {it:do}, but the user can specify anything that Stata can accept as a command, e.g., {it:dyndoc}, {it:markdown}, {it:net}, etc.

{break}    - params : arguments or options that should follow the source in the call to Stata batch mode. For example, a task with file_cmd of  {it:markdown} might specify

{p 8 8 2} params = {c 39}, saving\(myfile.html\) replace{c 39}

{break}    - depends : an alternative to using the Depends() function

{break}    - full_cmd : Alternatively, one can specify the full command explicitly (including any file and parameters). This will ignore the {it:file_cmd} and {it:params}.

{p 4 4 2}
As an example,

    helpFile = env.StataBuild(
        target = ['statacons.sthlp'],
        do_file = 'statacons.ado',
        file_cmd = "markdoc",
        params = ', export\(statacons.sthlp\) mini replace'
    )

{p 4 4 2}
defines a {bf:task} {it:helpFile} for the {it:StataBuild} {bf:environment} with {bf:target} {it:statacons.sthlp}, {bf:source}  {it:statacons.ado} and {bf:params} {it:{c 39}, export\(statacons.sthlp\) mini replace{c 39}}. {bf:statacons} will call Stata in batch mode with command {bf:markdoc statacons.ado, export(sthlp) replace mini}.



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




