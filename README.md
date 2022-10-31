# statacons

`statacons` is a set of tools for the [SCons](https://scons.org/) build-system to allow running [Stata](https://stata.com) projects. It does not require changes to existing code, is [correct](https://doi.ieeecomputersociety.org/10.1109/MS.2018.111095025) (no unnecessary rebuilds), extensible via Python, and git-friendly.

With data analysis projects it can be difficult to know what needs to be rebuilt when code changes (either because the there are many dependencies to track or it involves multiple contributors) and some tasks take a long time, making full-rebuilds costly. "Build systems" solve this by allowing the user to define how task inputs generate ouputs (for SCons, using `SConstruct` files) and tracking file changes to know what must be rebuilt. Thinks of this as a more robust way to specify a project's "master" run script. The `SConstruct` provides an easy view for what happens in a projects.


## Resources:

The [Project Web Page](https://bquistorff.github.io/statacons/index.html) at <https://bquistorff.github.io/statacons/index.html> hosts or links to all `statacons` resources, including

 - The paper: Guiteras, Raymond, Ahnjeong Kim, Brian Quistorff and Clayson Shumway, "statacons: An SCons-based build tool for Stata," CEnREP Working Paper 22-001, May 2022, https://go.ncsu.edu/cenrep-wp-22-001. Accepted at the Stata Journal. [PDF](https://osf.io/preprints/metaarxiv/qesx6/download)
 - The [Installation Guide](https://bquistorff.github.io/statacons/installation.html): <https://bquistorff.github.io/statacons/installation.html>.
 - A [web tutorial](https://bquistorff.github.io/statacons/swc.html) based on Software Carpentry's `make` lesson: <https://bquistorff.github.io/statacons/swc.html>
 - The project [Wiki Page](https://github.com/bquistorff/statacons/wiki) with additional advanced features, a troubleshooting guide, ideas for future improvements, and fixes for common errors (user contributions welcome): https://github.com/bquistorff/statacons/wiki
 - Documentation for `statacons`, `stataconsign`, and `pystatacons`
 - The [MetaArXiV site](https://osf.io/preprints/metaarxiv/qesx6/) archiving all pre-publication drafts of the paper: <https://osf.io/preprints/metaarxiv/qesx6/>.
 - The [OSF site](https://osf.io/gbh4m/) archiving all versions of the software and replication code and data: <https://osf.io/gbh4m/>

## Installation:

See the [Installation Guide](https://bquistorff.github.io/statacons/installation.html): <https://bquistorff.github.io/statacons/installation.html>.

We have tested `statacons` with Stata versions 16 and 17, flavors / editions IC/BE, SE and MP, for Windows, Mac and Unix, with Python 3.6, 3.8 and 3.10 and SCons 4.3 and 4.4, although not all combinations of these parameters.

## Project components:

- A Stata `statacons` command to run `scons` (a Python package/script) from inside of Stata so that one does not have to use the system terminal. 
- A Python `pystatacons` package to aid in writing SCons build scripts, called `SConstruct` files. It provides (a) an SCons build environment that can automatically find most Stata installations, (b) a `StataBuilder()` method that takes care of running Stata in batch-mode, and checking the output for errors, (c) smart checking of Stata `.dta` files to know when their content atually changes (and not just their internal timestamp), and (d) a simple configuration system to over-ride package defaults
- Optional ancillary files: sample `SConstruct` file to get started, sample configuration files to override package defaults (a git-versionable `config_project.ini` and a not-to-version `config_local.ini`), and some worked-examples with more functionality. 



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

env.StataBuild(do_file="dataprep.do", target=["input-cleaned.dta"], depends=["input.dta"])
env.StataBuild(do_file="analysis.do", target=["results.dta"], depends=["input-cleaned.dta"])
```

You can build your project from the terminal using `scons` or from Stata using `statacons`. Output from the latter would be

```Stata
. statacons
scons: Reading SConscript files ...
Using 'Strict' custom_datasignature.
Calculates timestamp-independent checksum of dataset, including all metadata.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are DataOnly, VVLabelsOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
Computed dta-signature: <path>\input.dta
stata_run(["input-cleaned.dta"], ["dataprep.do"])
Running: StataMP-64.exe /e do "dataprep.do"
Computed dta-signature: <path>\input-cleaned.dta
stata_run(["results.dta"], ["analysis.do"])
Running: StataMP-64.exe /e do "analysis.do"
Computed dta-signature: <path>\results.dta
scons: done building targets.

```


If you modify `dataprep.do`, running `scons` will re-execute that file, then check if `input-cleaned.dta` actually changed to decide if `analysis.do` needs to be run also (see the section below for details). If a `git pull` updates lots of scripts, then a simple `scons` command will only rebuild what is necessary. If you execute scripts directly in Stata (i.e., not using `statacons`) then we provide helpful tools to ensure that running `scons` won't re-run scripts you've already ran (see our 'content-timestamp-newer' `Decider`).

For more details about general SCons usage and `SConstruct` files, see the [SCons help](https://scons.org/documentation.html). For more details about our specific additions to SCons, see [our WP](https://go.ncsu.edu/cenrep-wp-22-001).


### Content-aware signatures for Stata .dta files
Our included `complete_datasignature` Stata command creates file signatures for `.dta` files that do not depend on the embedded timestamp, but optionally can depend on variable and value labels or other metadata. 
  
The `scons` default is to use an MD5 signature. Because `.dta` files include an embedded timestamp, MD5 signatures will change every time a `.dta` file is rebuilt even if the data have not changed. Stata's `datasignature` command produces a signature that does not depend on the timestamp but also ignores metadata such as variable values and labels. `complete_datasignature` gives the user control over the inputs to the signature: data only (Stata's `datasignature`); data plus variable and value labels; data plus all metadata (variable and value labels, notes, characteristics); `scons` default MD5.

