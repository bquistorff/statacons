{smcl}

{p 4 4 2}
{it:version 2.0.0}


{title:stataconsign}

{p 4 4 2}
{bf:stataconsign} -- calls the SCons function {bf:sconsign} to print the contents of the {bf:sconsign} database, typically {bf:.sconsign.dblite}, to the Stata window.

{p 4 4 2}
The syntax of {bf:stataconsign} mimics that of {bf:sconsign}. This help file reproduces the contents of the {bf:sconsign} help, which can be accessed from the appropriate shell prompt with {bf:sconsign -h}, and adds a few comments.


{title:Syntax}

{p 8 8 2} {bf:stataconsign} [OPTIONS] [FILE ...]

{p 4 4 2}
By default, {bf:stataconsign} will look in the current directory for an file {bf:sconsign.dblite} and print the contents of that database to the Stata window.

{p 4 4 2}{bf:Options}

{col 5}Option{col 33}Description
{space 4}{hline}
{col 5}-a, --act, --action{col 33}Print build action information.
{col 5}-c, --csig{col 33}Print content signature information.
{col 5}-d DIR, --dir=DIR{col 33}Print only info about DIR.
{col 5}-e ENTRY, --entry=ENTRY{col 33}Print only info about ENTRY.
{col 5}-f FORMAT, --format=FORMAT{col 33}FILE is in the specified FORMAT.
{col 5}-h, --help{col 33}Print this message and exit.
{col 5}-i, --implicit{col 33}Print implicit dependency information.
{col 5}-r, --readable{col 33}Print timestamps in human-readable form.
{col 5}--raw{col 33}Print raw Python object representations.
{col 5}-s, --size{col 33}Print file sizes.
{col 5}-t, --timestamp{col 33}Print timestamp information.
{col 5}-v, --verbose{col 33}Verbose, describe each field.
{space 4}{hline}

{title:Remarks}

{p 4 4 2}
{bf:stataconsign} is useful for obtaining information on what SCons considers to be the most recent build, i.e., the last time the project was built {it:by SCons}.


{title:Examples}

{p 4 4 2}
basic use

    . stataconsign

{p 4 4 2}
use human-readable timestamps

    . stataconsign -r

{p 4 4 2}
examine a database named .sconsignParallel.dblite in a sub-directory dbs

    . stataconsign dbs/.sconsignParallel.dblite



{title:Advanced Use}

{p 4 4 2}
Use the {bf:SConsignFile()} function in an SConstruct to specify a filename and directory for the sconsign database associated with that SConstruct. For example:

{p 8 8 2} SConsignFile("dbs/.sconsignParallel.dblite")

{p 4 4 2}
See the SCons User Manual and SCons Man Page for more details.

{p 4 4 2}
From a shell prompt, the screen output of {bf:sconsign} can be saved to a text file as follows:

{p 8 8 2} sconsign > sconsign.txt


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



