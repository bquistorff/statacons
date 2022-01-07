# statacons
`statacons` is a set of build tools (using [scons](https://scons.org/)) for Stata that doesn't require project changes, is [correct](https://doi.ieeecomputersociety.org/10.1109/MS.2018.111095025), and git-friendly. For more information, see our working paper:

Guiteras, Raymond, Ahnjeong Kim, Brian Quistorff and Clayson Shumway, "statacons: An SCons-based build tool for Stata," CEnREP Working Paper 22-001, January 2022, https://go.ncsu.edu/cenrep-wp-22-001. Under review at the Stata Journal.

[PDF](https://go.ncsu.edu/cenrep-wp-22-001.pdf)

## Installation
Requirements: Stata 16+, Python 3.5+ and the package [scons](https://scons.org/) 4.2+.  

Some advanced options require Python 3.8+.  

### Python and Stata

On the Stata Blog, Chuck Huber has a series of helpful posts for setting up Python with Stata and adding packages to Python: [part 1](https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/); [part 2](https://blog.stata.com/2020/08/25/stata-python-integration-part-2-three-ways-to-use-python-in-stata/); [part 3](https://blog.stata.com/2020/09/01/stata-python-integration-part-3-how-to-install-python-packages/).  

See Appendix A of our paper for a detailed installation guide.  



### Installing statacons  

`statacons` has two parts, the Stata package and then a set of files installed in each project.

#### Stata Package
You can install the package by using the following in Stata:
```
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/)
```


#### Project Files
To install the project template, in Stata:
```
// Change to project's root directory
cd path/to/your/project
// set other to the current directory, i.e. project's root directory
net set other .
// get project files
net get statacons, from(https://raw.github.com/bquistorff/statacons/main/)
unzipfile project_files
rm project_files.zip
```
If you have Stata in non-default location, you'll then need to edit `config_user.ini` to provide the path to your Stata executable. (Examples are provided in `config_user_template.ini`.) If this project is git-versioned, then you'll want to add `config_user.ini` and a few other files (e.g., `.sconsign.dblite`) to your `.gitignore`. If you are updating the package, be sure to restart Stata as the Python environment caches imports.


## Usage
Features:
1. With `statacons`, you can manage builds from within Stata, i.e., without a terminal or shell. 
  
   For those who are comfortable with the shell, scripts written for `statacons` are normal SCons scripts and will run from the shell with `scons` as expected.  
  
2. Our included `complete_datasignature` command creates file signatures for `.dta` files that do not depend on the embedded timestamp, but optionally can depend on variable and value labels or other metadata. 
  
   By default, `scons` would use an MD5 signature that, because timestamps are embedded in `.dta` files, would change every time a file is rebuilt, even if the contents had not changed. Stata's `datasignature` command produces a signature that does not depend on the timestamp but also ignores metadata such as variable values and labels.

