# Requirements

The following are required :

-   Stata 16.0 or later

-   Python 3.6 or later (3.8 required for some advanced options)

-   SCons 4.3 or later (SCons 4.5 or later requires statacons 3.0.1 or later)

# Step 1: Python Setup

We provide the basic steps for installing Python and configuring Stata for use with Python. For more details, we recommend a series of posts by Chuck Huber on the [Stata
Blog](https://blog.stata.com/tag/python/). See especially  [post 1](https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/)  and [post 3](https://blog.stata.com/2020/09/01/stata-python-integration-part-3-how-to-install-python-packages/).

Python commands are issued at a command prompt in a terminal window.
Exactly which terminal will depend on your operating system and
implementation of Python. Some popular examples include

-   Windows

    -   Python: Windows Command Prompt ("`cmd.exe`") or Powershell

    -   Anaconda: Anaconda Powershell Prompt or Anaconda Prompt

-   macOS: Terminal

-   Unix-like (e.g., Linux): terminal

## Step 1.1: Install Python
Install Python 3.6 or later (3.8 or later recommended).

## Step 1.2: Configure Stata to work with Python

### Step 1.2.1: Locate Python executable

In Stata, enter

`python search`

to locate the Python executable. If your system has both Python 2 and
Python 3 installed, be sure to use the Python 3 executable.

### Step 1.2.2: Set path to Python executable in Stata

Stata will use the default Python, unless configured before first use.
To do so, in Stata, enter

`python set exec [pyexecutable], permanently`

where `[pyexecutable]` is a path found in Step 1.2.1.

If Stata is started in a specific Anaconda environment, we provide a
simple Stata command `set_python_exec_env` to query the environment and set the Python path
accordingly.

### Step 1.2.3: check setup

In Stata, check your setup by entering

`python query`

## Step 1.3: Install Python packages scons and pystatacons

`pip` is the standard way to install Python packages. In the terminal, enter

        pip install scons
        pip install pystatacons

To check that these are installed and recognized by Stata, open Stata
and enter

        python which SCons // case-sensitive
        python which pystatacons

# Step 2: statacons installation and setup

## Step 2.1: Install Stata package

First, check your `adopath`. By default `statacons` will be installed to your `PLUS` directory.
Users working in collaboration with others may wish to change the `PLUS` and `PERSONAL`
directories to be local to the project to ensure that all users are using the same version of `statacons` and other user-written commands. See `profile_template.do` included in our project files for what we recommend.

Second, `statacons` requires both the core program files and a key set of project
files. You may wish to install these separately. To install the main
program use:

    net install statacons, from(https://raw.github.com/bquistorff/statacons/main/)

The core program files are:

        complete_datasignature.ado
        statacons.ado
        stataconsign.ado
        runscons.py
        sconsign-script.py
        sconstruct_fns.py

To check that `statacons` is installed, enter `which statacons` in Stata.

## Step 2.2: Install project files

To install the project files, navigate to the root of your project
directory and then run

    // Change to project's root directory
    cd path/to/your/project
    // set other to the current directory, i.e. project's root directory
    net set other .
    // get project files
    net get statacons, from(https://raw.github.com/bquistorff/statacons/main/)
    unzipfile project_files
    rm project_files.zip

The project files packages in `project_files.zip` are

        SConstruct
        config_project.ini
        utils/config_local_template.ini
        utils/profile_template.do
        utils/debugging-checklist_template.do
        utils/.gitignore_template

The only project file required is `SConstruct`. You may also wish to use the template files; if so, copy them into the main project folder (removing
the `_template` suffix).

## Step 2.3: Configuration

`statacons` is intended to work without additional user configuration, for example by automatically detecting the location of the Stata executable.
However, some configuration may be required. For example, if you have more than one version of Stata installed, `statacons` may not find your preferred
version first.

Our default is to use two configuration files, `config_project.ini`, which sets parameters that are common to all users working on a given project, and `config_local.ini`, which sets parameters specific to the local user. The files `config_project.ini` and `config_local_template.ini` provided with
the Stata project files give several examples of how to set commonly-used parameters. See the paper for more information on these configuration files and how to read from them in SConstructs.

The default is that these configuration files, if used, will be stored in the same directory as the `SConstruct`. The command line option `config_file()`
can instruct SCons to use a custom location or filename instead.

To check the configuration of `statacons`, enter `statacons, show_config` in Stata. The do-file `debugging-checklist.do` included in the `utils` folder may also be useful in checking that components are in the right places.

## Step 2.4 (optional): Setup for Version Control

If you are using version control software such as git, here are a few recommendations:

-   set your ado-path so that `statacons` and other packages are installed in the project folder. This will ensure that all users have the same version of all ado-files. See `profile_template.do` in the `utils` folder

-   files to keep under version control: `SConstruct`, `config_project.ini`

-   files to *exclude* from version control: `config_local.ini`, all generated files, including SConsign files (e.g., `.sconsign.dblite`) and batch-generated `.log`-files. See `.gitignore_template` in the `utils` folder for what we recommend.

See the Online Appendix Section B for more details on working with version control.

# Step 3: Test run with Introductory Example

Replication code and data for our Introductory Example as well as the extensions to that example are provided in
<https://github.com/bquistorff/statacons/raw/main/examples/stataconsIntro.zip>,
posted to [our
repository](https://github.com/bquistorff/statacons). To run the example, unpack the zip archive and follow the steps in Section 2 of the paper.


# Updating statacons

To update the statacons Stata package to the latest version, enter the following in Stata:

~~~~
    net install statacons, from(https://raw.github.com/bquistorff/statacons/main/) force replace
~~~~

To update the pystatacons Python package to the latest version, enter the following at the appropriate Python prompt:

~~~~
    pip install --upgrade pystatacons
~~~~

