<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


Setup
====================


## Files

You need to download some files to follow this lesson:

1. Download `statacons-lesson.zip`

2. Move zip into a directory which you can access.

3. Unpack zip.


## Software

A brief installation guide follows. For additional detail, see the [statacons repository](https://github.com/bquistorff/statacons) or the Installation Guide appendix of our paper.

### Stata

Stata version 16 or higher is required to run `statacons`.

### Python

Python 3.5 is the minimum requirement. We recommend Python 3.8 or later.    [Anaconda](https://www.anaconda.com/products/individual) is a convenient wrapper for Python and contains many of the standard Python packages.

#### SCons

SCons 4.2 or later is required.

See the SCons User Guide for complete installation instructions.

Check if you already have SCons installed by typing `SCons -v` into a terminal (for example, Anaconda Powershell Prompt in Windows).

In Windows Python, install SCons from the terminal using `pip install SCons` or download from [Scons Download](https://sourceforge.net/projects/scons/).

In Anaconda, type `conda install -c conda-forge scons`

In Linux, install SCons from the terminal using `sudo apt-get install SCons` on Linux.

#### pystatacons

Install pystatacons in python: `pip install pystatacons`


### Statacons

Version 2.0.1 of Statacons is included in `statacons-lesson.zip`. Running the included `profile.do` will set your `adopath` locally to this project, so Stata will find this included version of Statacons.

To install the most recent version of Statacons, visit Statacons on [github](https://github.com/bquistorff/statacons) and follow the installation instructions.

### Verifying setup

To check that statacons, SCons, and pystatacons are installed, up-to-date, and accessible in Stata:

~~~~

. // run profile.do to point Stata to the local PLUS folder
. qui do profile.do

. // check that your ado-path, especially PLUS is set correctly
. adopath
  [1]  (BASE)      "C:\Program Files\Stata17\ado\base/"
  [2]  (SITE)      "C:\Program Files\Stata17\ado\site/"
  [3]              "."
  [4]  (PERSONAL)  "code/ado/personal/"
  [5]  (PLUS)      "code/ado/plus/"
  [6]  (OLDPLACE)  "code/ado/"
  [7]              "../pkg"

. 
. which statacons
../pkg\statacons.ado
*! version 2.0.2  May 04 2022  statacons team

. python
----------------------------------------------- python (type end to exit) -----
>>> import SCons
>>> print(SCons.__version__)
4.2.0
>>> import pystatacons
>>> print(pystatacons.__version__)
2.1.5
>>> end
-------------------------------------------------------------------------------


~~~~