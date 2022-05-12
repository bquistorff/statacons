# Installation guide

Requirements: Stata 16+, Python 3.5+ (some advanced options require Python 3.8+) and the package [scons](https://scons.org/) 4.2+.

## Installing Python and SCons, and Linking Python with Stata

On the Stata Blog, Chuck Huber has a series of helpful posts for setting up Python with Stata and adding packages to Python: [part 1](https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/); [part 2](https://blog.stata.com/2020/08/25/stata-python-integration-part-2-three-ways-to-use-python-in-stata/); [part 3](https://blog.stata.com/2020/09/01/stata-python-integration-part-3-how-to-install-python-packages/).


## Installing statacons

## statacons Stata package
You can install the `statacons` Stata package by using the following in Stata:
```
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/)
```

## pystatacons Python package
You can install the `pystatacons` Python package using `pip` from your Python environment:
```
pip install pystatacons
```

## Project Files
See [here](https://github.com/bquistorff/statacons/blob/main/src/project_files.zip) for a zip of the project files: <https://github.com/bquistorff/statacons/blob/main/src/project_files.zip>. You can extract those into the root of a project that you're working on.

## Other installation notes

* If you have Stata installed in a non-default location, you'll then need to edit `config_local.ini` to provide the path to your Stata executable. Examples are provided in `config_local_template.ini`.
* If this project is git-versioned, then you'll want to add `config_local.ini` and a few other files (e.g., `.sconsign.dblite`) to your `.gitignore`.
* If you are updating the package, be sure to restart Stata. The Python environment caches imports, so updates will not take effect until Stata restarts.
* The included project file `debugging-checklist.do` will provide some useful information as you install `statacons` and set up your build files.


## Introductory examples

To try out statacons, download the code and data for our introductory example from <https://github.com/bquistorff/statacons/main/raw/examples/stataconsIntro.zip>, then follow Section 2 of the paper.
