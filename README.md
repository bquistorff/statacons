# statacons
`statacons` is a set of tools for the [SCons](https://scons.org/) build-system to allow running [Stata](https://stata.com) projects. It does not require changes to existing code, is [correct](https://doi.ieeecomputersociety.org/10.1109/MS.2018.111095025) (no unnecessary rebuilds), extensible via Python, and git-friendly.

With data analysis projects it can be difficult to know what needs to be rebuilt when code changes (either because the there are many dependencies to track or it involves multiple contributors) and some tasks take a long time, making full-rebuilds costly. "Build-systems" solve this by allowing the user to define how task inputs generate ouputs (for SCons, using `SConstruct` files) and tracking file changes to know what must be rebuilt. Thinks of this as a more robust way to specify a project's "master" run script. The `SConstruct` provides an easy view for what happens in a projects.

Project components:
- A Stata `statacons` command to run `scons` (a Python package/script) from inside of Stata so that one does not have to use the system terminal. 
- A Python `pystatacons` package to aid in writing SCons build scripts, called `SConstruct` files. It provides (a) an SCons build environment that can automatically find most Stata installations, (b) a `StataBuilder()` method that takes care of running Stata in batch-mode, and checking the output for errors, (c) smart checking of Stata `.dta` files to know when their content atually changes (and not just their internal timestamp), and (d) a simple configuration system to over-ride package defaults
- Optional ancillary files: sample `SConstruct` file to get started, sample configuration files to override package defaults (a git-versionable `config_project.ini` and a not-to-version `config_user.ini`), and some worked-examples with more functionality. 

For more information, see our working paper:

Guiteras, Raymond, Ahnjeong Kim, Brian Quistorff and Clayson Shumway, "statacons: An SCons-based build tool for Stata," CEnREP Working Paper 22-001, January 2022, https://go.ncsu.edu/cenrep-wp-22-001. Under review at the Stata Journal. [PDF](https://go.ncsu.edu/cenrep-wp-22-001.pdf)

## Installation
Requirements: Stata 16+, Python 3.5+ (some advanced options require Python 3.8+) and the package [scons](https://scons.org/) 4.2+.

### Installing Python and SCons, and Linking Python with Stata

On the Stata Blog, Chuck Huber has a series of helpful posts for setting up Python with Stata and adding packages to Python: [part 1](https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/); [part 2](https://blog.stata.com/2020/08/25/stata-python-integration-part-2-three-ways-to-use-python-in-stata/); [part 3](https://blog.stata.com/2020/09/01/stata-python-integration-part-3-how-to-install-python-packages/).  

See Appendix A of our paper for a detailed installation guide.  

### Installing statacons  

#### statacons Stata package
You can install the `statacons` Stata package by using the following in Stata:
```
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/)
```

#### pystatacons Python package
You can install the `pystatacons` Python package using `pip` from your Python environment:
```
pip install pystatacons
```

#### Project Files
See here for a zip of the project files: [src/project_files.zip](src/project_files.zip). You can extract those into the root of a project that you're working on.

### Other installation notes  

* If you have Stata installed in a non-default location, you'll then need to edit `config_user.ini` to provide the path to your Stata executable. Examples are provided in `config_user_template.ini`.  
* If this project is git-versioned, then you'll want to add `config_user.ini` and a few other files (e.g., `.sconsign.dblite`) to your `.gitignore`. 
* If you are updating the package, be sure to restart Stata. The Python environment caches imports, so updates will not take effect until Stata restarts.
* The included project file `debugging-checklist.do` will provide some useful information as you install `statacons` and set up your build files.


## Usage
Suppose your project has a "`master.do`" file to run scripts:
```C
do dataprep.do   /* uses input.dta to generate input-cleaned.dta */
do analysis.do   /* uses input-cleaned.dta to generate results.dta */
```

You can re-write this as an `SConstruct` file:
```Python
import pystatacons
env = pystatacons.init_env()

StataBuild(do_file="dataprep.do", target=["input-cleaned.dta"], depends="input.dta")
StataBuild(do_file="analysis.do", target=["results.dta"], depends="input-cleaned.dta")
```

You can build your project from the terminal using `scons` or from Stata using `statacons`. If you modify `dataprep.do`, running `scons` will re-execute that file, then check if `input-cleaned.dta` actually changed to decide if `analysis.do` needs to be run also (see the section below for details). If a `git pull` updates lots of scripts, then a simple `scons` command will only rebuild what is necessary. If you execute scripts directly in Stata (i.e., not using `statacons`) then we provide helpful tools to ensure that running `scons` won't re-run scripts you've already ran (see our 'content-timestamp-newer' `Decider`).

For more details about general SCons usage and `SConstruct` files, see the [SCons help](https://scons.org/documentation.html). For more details about our specific additions to SCons, see [our WP](https://go.ncsu.edu/cenrep-wp-22-001).


### Content-aware signatures for Stata .dta files
Our included `complete_datasignature` Stata command creates file signatures for `.dta` files that do not depend on the embedded timestamp, but optionally can depend on variable and value labels or other metadata. 
  
The `scons` default is to use an MD5 signature. Because `.dta` files include an embedded timestamp, MD5 signatures will change every time a `.dta` file is rebuilt even if the data have not changed. Stata's `datasignature` command produces a signature that does not depend on the timestamp but also ignores metadata such as variable values and labels. `complete_datasignature` gives the user control over the inputs to the signature: data only (Stata's `datasignature`); data plus variable and value labels; data plus all metadata (variable and value labels, notes, characteristics); `scons` default MD5.

