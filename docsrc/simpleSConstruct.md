<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


A Simple SConstruct file
========================

We concluded the previous module with

> What we really want is an executable description of our pipeline that allows software to do the tricky part for us: figuring out what steps need to be rerun.

This is where SCons comes in -- we write an `SConstruct` file that codifies our workflow: what are the outputs, what are the inputs (including data and code), and what must be done to create the outputs from the inputs. Furthermore, SCons can tell which steps need to be re-run as the inputs change.

## A first example

In your text editor, open the file called `SConstruct` (no extension).

Skip the section at the top marked
```
# **** Setup from pystatacons package ***
```
and start reading at the section marked
```
# **** Substance begins        *****
```

You will see the following:
```
cmd_isles_data = env.StataBuild(
    target = 'outputs/data/dta/isles.dta',
    source = 'code/count_isles.do'
)
Depends(cmd_isles_data,
    ['inputs/txt/isles.txt',
    'code/ado/plus/w/wordcloud.ado',
    'code/ado/personal/countWords.ado']
```

Let's walk through this one piece at a time.

- `cmd_isles_data` is the name we are giving to this task. It will allow us to refer to this task elsewhere in the SConstruct if we need to.

- `env.StataBuild` tells SCons that this task will be performed according to `StataBuild`. Essentially, `StataBuild` tells Stata "Do the do-file `source` in batch mode."

- The `target` is the file to be created or built, so this task will be building `outputs/data/isles.dta`.

- `source` is the do-file we will use to build our target. In general, source can include other dependencies. However, we have set up `StataBuild` to `do` the first thing it finds in `source`, so we list only the do-file we want to run.

- in `Depends`, we list the remaining inputs (or "dependencies") for our task `cmd_isles_data`. In this case, we have three additional dependencies. It is clear why the input file `inputs/txt/isles.txt` is a dependency -- if the input data change, the output may change, so we will need to re-run our analysis. The next two are the two ado-files: `countWords.ado`, which is called by `count_isles.do`, and `wordCount.ado`, which is called by `countWords.ado`. Our target `isles.dta` also depends on these, since, just like the input data, if either of them change, then the output potentially could change,

So, in words, the code above reads

> "The the task named `cmd_isles_data` is to create `output/data/isles.dta`. `StataBuild` tells us that we do that by running the `source` do-file  `count_isles.do` in batch mode.  The files this task depends on are `isles.txt`, `countWords.ado`, and `wordcount.ado`. Check whether the source or any of the dependencies have changed since the last time we build this target. If any have changed, we must re-build the target. If none have changed, we do not need to re-build this target."

## Putting our first example to work

Let's see how our script works.

First, let's start fresh by erasing our target `isles.dta` (if it already exists) using the `clean` option.

~~~~

. statacons, clean
scons: Reading SConscript files ...
scons: done reading SConscript files.
scons: Cleaning targets ...
Removed outputs\data\dta\isles.dta
scons: done cleaning targets.


~~~~

We can use the `dry_run` option to `statacons` to get a preview of what `statacons` will do:

~~~~

. statacons, dry_run
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])
scons: done building targets.


~~~~

`statacons` is telling us that it will do the action `stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])`, but we can get even more information about why it will do this by adding the option  `debug(explain)` (we still include `dry_run `):

~~~~

. statacons, dry_run debug(explain)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: building `outputs\data\dta\isles.dta' because it doesn't exist
stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])
scons: done building targets.


~~~~

`statacons` tells us that it needs to rebuild `outputs\data\dta\isles.dta` because it does not exist.

As one last check before rebuilding, we will get `statacons` to tell us about the status of each file it is considering by using the option `tree(status, prune)`:

~~~~

. statacons, dry_run debug(explain) tree(status,prune)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: building `outputs\data\dta\isles.dta' because it doesn't exist
stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])
 E         = exists
  R        = exists in repository only
   b       = implicit builder
   B       = explicit builder
    S      = side effect
     P     = precious
      A    = always build
       C   = current
        N  = no clean
         H = no cache

[E b      ]+-.
[E b   C  ]  +-code
[E b   C  ]  | +-code\ado
[E b   C  ]  | | +-code\ado\personal
[E     C  ]  | | | +-code\ado\personal\countWords.ado
[E b   C  ]  | | +-code\ado\plus
[E b   C  ]  | |   +-code\ado\plus\w
[E     C  ]  | |     +-code\ado\plus\w\wordfreq.ado
[E     C  ]  | +-code\count_isles.do
[E b   C  ]  +-inputs
[E b   C  ]  | +-inputs\txt
[E     C  ]  |   +-inputs\txt\isles.txt
[E b      ]  +-outputs
[E b      ]  | +-outputs\data
[E b      ]  |   +-outputs\data\dta
[  B P    ]  |     +-outputs\data\dta\isles.dta
[E     C  ]  |       +-code\count_isles.do
[E     C  ]  |       +-inputs\txt\isles.txt
[E     C  ]  |       +-code\ado\personal\countWords.ado
[E     C  ]  |       +-code\ado\plus\w\wordfreq.ado
[E     C  ]  +-SConstruct
scons: done building targets.


~~~~

Notice the entry in the tree for `outputs\data\dta\isles.dta`: `statacons` knows to look for it, since it is a target in our `SConstruct`, but does not find it (no `E`) in the leftmost column and that it has to build it (`B` in the second column). Notice that `statacons` has checked all the dependencies for this target, and has found them all to be current (capital `C` in the third column). The `prune` option makes the tree easier to read by not repeating dependencies -- if a file's dependencies have already been listed, that file will be enclosed in brackets.

Now that we have had a detailed look at what `statacons` is planning to do, let's see what it actually does:

~~~~

. statacons
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\count_isles.do".
  Starting in hidden desktop (pid=23840).
scons: done building targets.


~~~~

As expected, `statacons` has done the action  `stata_run(["outputs\data\dta\isles.dta"], ["code\count_isles.do"])` by sending the `source` (`code\count_isles.do`) to stata by batch mode.

We see that our target has been created and is the same as before:

~~~~

. use outputs/data/dta/isles.dta, clear

. desc, s

Contains data from outputs/data/dta/isles.dta
  obs:         9,215                          
 vars:             3                          10 May 2022 12:59
Sorted by: 

. li in 1/5

     +------------------------+
     | word   freq      share |
     |------------------------|
  1. |  the   3315   .0625483 |
  2. |   of   2185   .0412272 |
  3. |  and   1530   .0288685 |
  4. |   to   1323   .0249627 |
  5. |    a   1132   .0213589 |
     +------------------------+

. clear


~~~~

If we ask `statacons` to rebuild our project now, it will tell us that no rebuilding is necessary because all files are up to date:

~~~~

. statacons, debug(explain) tree(status,prune)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: `.' is up to date.
 E         = exists
  R        = exists in repository only
   b       = implicit builder
   B       = explicit builder
    S      = side effect
     P     = precious
      A    = always build
       C   = current
        N  = no clean
         H = no cache

[E b   C  ]+-.
[E b   C  ]  +-code
[E b   C  ]  | +-code\ado
[E b   C  ]  | | +-code\ado\personal
[E     C  ]  | | | +-code\ado\personal\countWords.ado
[E b   C  ]  | | +-code\ado\plus
[E b   C  ]  | |   +-code\ado\plus\w
[E     C  ]  | |     +-code\ado\plus\w\wordfreq.ado
[E     C  ]  | +-code\count_isles.do
[E b   C  ]  +-inputs
[E b   C  ]  | +-inputs\txt
[E     C  ]  |   +-inputs\txt\isles.txt
[E b   C  ]  +-outputs
[E b   C  ]  | +-outputs\data
[E b   C  ]  |   +-outputs\data\dta
[E B P C  ]  |     +-outputs\data\dta\isles.dta
[E     C  ]  |       +-code\count_isles.do
[E     C  ]  |       +-inputs\txt\isles.txt
[E     C  ]  |       +-code\ado\personal\countWords.ado
[E     C  ]  |       +-code\ado\plus\w\wordfreq.ado
[E     C  ]  +-SConstruct
scons: done building targets.


~~~~


## Adding a second target

We have successfully built `isles.dta` using `statacons`, but now we would like to add `abyss.dta` to the same build process.

We copy `SConstruct` to a new file `SConstruct-addAbyss` and add a second task:

~~~

cmd_abyss_data = env.StataBuild(
    target = 'outputs/data/dta/abyss.dta',
    source = 'code/count_abyss.do'
)
Depends(cmd_abyss_data,
    ['inputs/txt/abyss.txt',
    'code/ado/personal/countWords.ado',
    'code/ado/plus/w/wordfreq.ado']
)

~~~

This is essentially the same as our previous task, and a useful exercise is to try to translate it into words as we did in the first subsection above ("A first example").

Let's see what `statacons` thinks about this task. We use the option `file(SConstruct-addAbyss)` to tell `statacons` to examine our new SConstruct file instead of the default (which is just to use the file called `SConstruct`):


~~~~

. statacons, file(SConstruct-addAbyss) dry_run debug(explain) tree(status,prune
> )
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: Cannot explain why `outputs\data\dta\abyss.dta' is being rebuilt: No pre
> vious build information found
stata_run(["outputs\data\dta\abyss.dta"], ["code\count_abyss.do"])
 E         = exists
  R        = exists in repository only
   b       = implicit builder
   B       = explicit builder
    S      = side effect
     P     = precious
      A    = always build
       C   = current
        N  = no clean
         H = no cache

[E b      ]+-.
[E b   C  ]  +-code
[E b   C  ]  | +-code\ado
[E b   C  ]  | | +-code\ado\personal
[E     C  ]  | | | +-code\ado\personal\countWords.ado
[E b   C  ]  | | +-code\ado\plus
[E b   C  ]  | |   +-code\ado\plus\w
[E     C  ]  | |     +-code\ado\plus\w\wordfreq.ado
[E     C  ]  | +-code\count_abyss.do
[E     C  ]  | +-code\count_isles.do
[E b   C  ]  +-inputs
[E b   C  ]  | +-inputs\txt
[E     C  ]  |   +-inputs\txt\abyss.txt
[E     C  ]  |   +-inputs\txt\isles.txt
[E b      ]  +-outputs
[E b      ]  | +-outputs\data
[E b      ]  |   +-outputs\data\dta
[E B P    ]  |     +-outputs\data\dta\abyss.dta
[E     C  ]  |     | +-code\count_abyss.do
[E     C  ]  |     | +-inputs\txt\abyss.txt
[E     C  ]  |     | +-code\ado\personal\countWords.ado
[E     C  ]  |     | +-code\ado\plus\w\wordfreq.ado
[E B P C  ]  |     +-outputs\data\dta\isles.dta
[E     C  ]  |       +-code\count_isles.do
[E     C  ]  |       +-inputs\txt\isles.txt
[E     C  ]  |       +-code\ado\personal\countWords.ado
[E     C  ]  |       +-code\ado\plus\w\wordfreq.ado
[E     C  ]  +-SConstruct-addAbyss
scons: done building targets.


~~~~

There is an interesting line from the debug: `Cannot explain why outputs/data/dta/abyss.dta is being rebuilt: No previous build information found`. This is a reminder of how `scons` decides whether to rebuild a target: it checks whether the target's dependencies have changed since the last time `scons` built the target. We created `abyss.dta` in the previous module, and have not erased it, so `statacons` sees that it exists. However, since we have not built `abyss.dta` using `statacons` before, `statacons` cannot answer the question "have the dependencies changed since the last time you built `abyss.dta`?"", and will choose to rebuild it.

Notice that there is no `C` in the status report for `abyss.dta` from the tree, since its status is not known to be Current.

Now we rebuild:

~~~~

. statacons, file(SConstruct-addAbyss)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\abyss.dta"], ["code\count_abyss.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\count_abyss.do".
  Starting in hidden desktop (pid=1816).
scons: done building targets.


~~~~

Notice that `statacons` has built `abyss.dta` but not `isles.dta`. (Question for the user: why has `statacons` not rebuilt `isles.dta`? Hint: check the `tree` above.)

## Exercise: Write Two New Rules

0. Create a copy of `SConstruct-addAbyss` and rename it `SConstruct-2NewRules`

1. Write a new do-file `count_last.do` to create a frequency count dataset `last.dta` from the input text `last.txt`.

2. Add a rule to our new SConstruct to build `last.dta`.

3. Update `testZipf.do` to incorporate `last.dta`, but do not re-create `testZipf.txt`.

4. Add a rule in our new SConstruct to build  `testZipf.txt`.

5. Use `SConstruct-2NewRules` to see if any of the targets need to be rebuilt.


