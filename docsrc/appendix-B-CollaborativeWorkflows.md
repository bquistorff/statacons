# B. Collaborative Workflows

## The Problem

In this Appendix, we discuss a few models for collaborative workflows.
The main difficulty with collaboration is that, as we mention in the
Limitations section (6.3), SCons only understands builds it has done
itself. That is, SCons compares the current state of targets and
dependencies to their state as recorded in the `.sconsign.dblite`
database the last time SCons ran the build.

As an example, suppose that Users A and B are collaborating on the
Introductory Example of Section 2. User A is working primarily on the
dataprep task and User B is working primarily on analysis. Imagine for
the sake of this example that the dataprep task takes a very long time
to run. User A has made some edits to `dataprep.do` and updated
`auto-modified.dta`. User A shares these two files with User B.

The issue is that User B's SCons will look at `dataprep.do`, compare its
current status to its status the last time `auto-modified.dta` was built
*as recorded in User B's `.sconsign.dblite`*, see that `dataprep.do` is
different, and conclude that `auto-modified.dta` needs to be rebuilt.
User B could use the `assume_built()` or `assume_done()` options we have
added to SCons to tell SCons that in fact `auto-modified.dta` is up to
date, but in more complex projects this sort of mental
dependency-tracking is prone to failure.

The underlying problem is that there are three competing values: we want
builds to be complete (all targets up-to-date), we do not want to
duplicate work, and we want to automate the build and avoid manual
workarounds, which are error-prone. Our preferred approach is to use the
SCons *cache* to share built files. While this requires a small amount
of effort to set up and some care to maintain, it satisfies all three
values without introducing too much additional complexity. We will
describe this approach below, then mention a few alternatives and their
limitations.

Our project Wiki contains a simple worked example of a
collaborative project using the SCons cache along with GitHub: https://github.com/bquistorff/statacons/wiki/Collaboration-using-GitHub-and-the-SCons-cache

## SCons Cache

Our preferred approach is to use the SCons *cache* to share derived
files. See **Listing B1** for an example SConstruct.

**Listing B1: SConstruct for Introductory Example Using SCons Cache**
```
# **** Setup from pystatacons package *****
import pystatacons
env = pystatacons.init_env()
# use an sconsign database specific to this SConstruct
SConsignFile(".sconsignCache")
# set path to cache directory
# shared cache dir
# hard-coded -- if hard-coding path with spaces, *must* enclose in quotes
# dropbox example
#CacheDir('C:/Users/Username/Dropbox/SJ-BuildTools/simpleCacheShare')
# local folder example
#CacheDir('./scons_cache')
# from config_local.ini
-- in config, do *not* enclose path with spaces in quotes
CacheDir(env['CONFIG']['Project']['cache_dir'])
# **** Substance begins *****
# analysis
cmd_analysis = env.StataBuild(
    target = ['outputs/scatterplot.pdf', 'outputs/regressionTable.tex'],
    source = 'code/analysis.do' )
Depends(cmd_analysis, ['outputs/auto-modified.dta'])
# dataprep
cmd_dataprep = env.StataBuild(
    target = ['outputs/auto-modified.dta'],
    source = 'code/dataprep.do' )
Depends(cmd_dataprep,['inputs/auto-original.dta'])
```

In the SConstruct, we designate a shared folder to store the cache:

`CacheDir('path/to/cache')`

Rather than hard-code the path into the SConstruct, the path can be
coded into a configuration file (e.g., `config_project.ini`,
`config_local.ini`, or other specified through the `config_file()`
option), which the SConstruct can then read. Here, we use a local
`scons_cache` folder so that this can be a self-contained example, but
in practice this may be a shared drive or a folder on a file-sharing
service. See `config_local_template.ini` for several examples.

SCons will then store built files in the cache and, before building
targets, check to see whether an up-to-date version is available in the
cache. See the SCons User Guide for details on how this works.[^1]

We have found that this approach handles the three competing goals of a
build tool (complete builds; reduce unnecessary builds; automaticity
instead of manual intervention) well, with a few caveats.

The main caveat is that by default SCons will update the cache whenever
a target is newly built, which is not desirable while writing and
testing code since it will lead to filling the cache with unnecessary
files, and other users will be repeatedly downloading these unnecessary
files. It is good practice to update the cache only when you are sure
the work is complete. There are two ways to do this.

The first way is to use the command-line option `cache_readonly` to tell
SCons to check and read from the cache but not update the cache with any
built files, or `cache_disable` to tell SCons to ignore the cache
entirely. Once you have successfully completed your build, use the
option `cache_force` to force SCons to update the cache. This will also
make it less likely that two users will attempt to update the same
cached file at the same time.

The second way is to edit the SConstruct so that the default is to have
the cache disabled, and a command-line option is required to read to or
write to the cache. We provide an example on our project Wiki: https://github.com/bquistorff/statacons/wiki/Cache-with-cache-disabled-as-default.

A few additional caveats. First, the cache can get large and
periodically need to be cleaned and rebuilt.[^2] Second, when using the
cache, SCons calculates build signatures regardless of the Decider
method chosen, so there are no time savings from using, for example,
`content-timestamp`. Of course, this does not affect those using the
default `content`. Finally, in its own storage, the cache uses file
signatures as filenames, instead of the cached file's own name, which is
slightly inconvenient if you need to find and examine the cached version
of a particular file. The `cache_debug` option will provide information
on the files being used, and note that the file will be stored in a
subfolder corresponding to the first two characters of the cached
filename. For example, a cached file `d7581eba1ac59ad5f92b2fceba04477f`
will be in subfolder `D7`.

We list some useful command-line options for the cache below. Using
these options together with `dry_run` can be instructive to get a
preview of how SCons will interact with the cache.

We list the Stata-style syntax first, then the standard SCons syntax.
Recall that either syntax is allowed but the two cannot be mixed in a
single command.

>`cache_debug(-)` prints information on the cache files being used to the
screen
>
>SCons equivalent: `–cache-debug=-`
>
>`cache_debug(file)` saves information on the cache files being used to
the file `file`
>
>SCons equivalent: `–cache-debug=file`
>
>`cache_disable` do not use files from the cache, do not write files to
the cache
>
>SCons equivalent: `–cache-disable`, `–no-cache`
>
>`cache_force` write all derived files to the cache, whether they are
built in this call to SCons or have previously been built. This
overrides the default, which is to write only files that are built or
rebuilt files in the current call to SCons.
>
>SCons equivalent: `–cache-force`, `–cache-populate`
>
>`cache_readonly` use files from the cache but do not write files to the
cache
>
>SCons equivalent: `–cache-readonly`
>
>`cache_show` by default, SCons will print "`retrieved file from cache`"
to the screen when it pulls a file from the cache rather than building
it. With the `cache_show` option, SCons will instead print what it
*would have done* to build the file if it had not used the cache.

>SCons equivalent: `–cache-show`

## Other Options

Here are a few alternatives, along with what we see as their main
drawbacks.

### Shared `.sconsign.dblite` database

Since SCons uses the `.sconsign.dblite` database to decide which targets
need to be rebuilt, it is tempting to use a shared database, whether
through a file-synchronization service like Dropbox or version-control
system like Git or GitHub. However, this is unlikely to work well. Since
the `.sconsign.dblite` is a single, binary file, version conflicts or
file corruption can arise even if users are working on different aspects
of a project. Furthermore, unless all users have all their code, targets
and dependencies synchronized at all times, a shared `.sconsign.dblite`
database will cause SCons to get very confused, since it will see
discrepancies between files and database entries every time any user
updates any file. This might be approximately workable if all users are
synced to the same shared folder, e.g., a shared Dropbox folder, but
this is not possible if one is using more full-featured source code and
collaboration management solutions such as git.

### Marking files as built

The `assume_built`/`assume_done` options we have added for `statacons`
can help in one-off cases. See Section 3.2 of the main paper for their
description. In the example above, User B could update to User A's
latest `dataprep.do` and `auto-modified.dta`, then run

`statacons , assume_built(’outputs/auto-modified.dta’)`

SCons will then skip rebuilding `auto-modified.dta`, record the current
file signature as in `.sconsign.dblite`, and move on to rebuilding the
final outputs.

While this approach can be useful, it relies on users accurately keeping
track of what is up to date and what is not, and making manual choices
in builds, both of which build tools are intended to make unnecessary.
For example, we have found `assume_built(*)` to be useful if a minor
change to the builder has caused SCons to think all files need to be
re-built when in fact none of them do. Again, though, we have to be sure
that the change to the builder will not result in any substantive
change.

## Additional Comments on Collaborative Workflows

### Version Control

If you are using a version control system like Git or SVN, we recommend
that you do *not* keep `config_local.ini` or `.sconsign.dblite` under
version control. In the case of `config_local.ini`, this is simply
because the purpose of this file is to account for things that will vary
across users. In the case of `.sconsign.dblite`, see our discussion
under "Shared .sconsign.dblite database" above. There are a few additional Python-generated files (e.g.,
`__pycache__`) that should not be kept under version control. In Git,
this is handled with a `.gitignore` file. In the replication archive we
provide for our Introductory Example, we have included an example
`.gitignore` that excludes the files above. In addition, we recommend
excluding all generated files. That is, as a rule, we keep only code (in
the broad sense of things a human has typed, as opposed to things
generated by the computer) under version control. This is generally
considered good practice but is essential when using the SCons cache,
since the cache is already essentially handling version control for
generated files, and having both SCons and the version control software
attempting the same task will lead to conflicts.

We do recommend keeping user-written programs under version control to
ensure that all users have the same version of these programs. In our
Introductory Example, we have kept user-written `estout` (Jann, Stata
Journal, 2007) in the folder `code/ado/plus`. Our `profile.do` sets
Stata's `adopath` to instruct Stata to look in this folder (and
subfolders). Similarly, we keep `config_project.ini`, the `SConstruct`,
`statacons.ado` and the other associated files under version control,
again so that the build will be consistent across users. The downside of
this practice is that you will need to maintain separate copies of the
same programs for each project.

### Shared SCons cache

If you are using Dropbox or a similar service to share your SCons cache,
make sure that you have offline access to the folder containing the
cache.[^3] Using the "Smart Sync" or "Streaming Access" options that
store files online and then fetch them when requested is likely to cause
several problems. First, Python may not find folders that are only
available in the cloud. Second, this will slow down the process of
retrieving cached files. Third, you may not be able to access certain
recently cached files when working offline.

Finally, as of April 2022 we do not recommend Google Drive for sharing
caches. Google Drive will sometimes be able to discern the type of
cached files and will add a file extension to the filename in the cache.
This happens especially frequently with `.pdf`s. This will confuse SCons
and prevent it from successfully retrieving that file from the cache. We
have not found this to occur with Dropbox.



[^1]: As of SCons 4.3.0 (December 2021), this is Section 22, "Caching
    Built Files." See especially the first footnote in that section,
    which describes the information SCons stores and uses to determine
    whether a target is up to date.

[^2]: Rebuilding the cache does not require rebuilding the project, just
    erasing the cache and then calling SCons with the option
    `cache_force`.

[^3]: As of April 2022: in Dropbox, either turn off "Smart Sync" to make
    all of your Dropbox content available offline, or use "Selective
    Sync" to keep your cache folders available offline. While we
    currently do not recommend Google Drive for shared caches (see the
    next paragraph), if you do use Google Drive, choose either "Mirror
    files" to make *all* of your Google Drive content available offline,
    or follow the instructions under "Stream files -- Choose specific
    files and folders to make available offline" to keep your cache
    folders available offline.
