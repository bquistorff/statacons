# statacons
`statacons` is a set of build tools (using [scons](https://scons.org/)) for Stata that doesn't require project changes, is correct, and git-friendly. For more information, see our working paper: [statacons: An SCons-based build tool for Stata](https://cenrep.ncsu.edu/cenrep/wp-content/uploads/2022/01/statacons-An-SCons-based-Build-Tool-for-Stata.pdf).

## Installation
Requirements: Python 3.5+ and the package [scons](https://scons.org/). Stata 16+.

`statacons` has two parts, the Stata package and then a set of files installed in each project.
### Stata Package
You can install the package by using the following in Stata:
```
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/)
```


### Project Files
To install the project template, in Stata:
```
// Change to project root
net set other .
net get statacons, from(https://raw.github.com/bquistorff/statacons/main/)
unzipfile project_files
rm project_files.zip
```
If you have Stata in non-default location, you'll then need to edit `config_user.ini`paths. If this project is git-versions, then you'll want to add `config_user.ini` as a line in your `.gitignore`. After that you can add you depedencies to `SConstruct`. If you are updating the package, make sure to restart Stata as the Python environment caches imports.


## Usage
Features:
1. If you have a python environment with the [scons](https://scons.org) python package, and you select that python environment in Stata 16+ (`python setexec <path to environment's python.exe`), you can, from the normal Stata command line, use our Stata program `statacons` to call the Python `scons` with the same options.
2. Python `scons` (either called from Stata or Python command line) can use a custom file-signature function for `dta` files to ensure that rebuilds only happen when actual content in the `dta` file changes (the default signature will think the file changed whenever it was rebuilt, even if the content is the same, because the file embeds timestamps and has areas that are filled with randomness). To use these, you need to specify in the `SConstruct` where to find our new methods (we define these in `config_user.ini` and then read that in `SConstruct`) and then use these instead of the default Python `scons` functions (also in `SConstruct`).
