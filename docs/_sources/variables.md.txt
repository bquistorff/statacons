<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


Variables
==============================================

Our do-file and SConstruct file still have repeated content -- we repeat the same material for each of `isles`, `abyss` and `last`. We can make our code more compact and efficient by using *variables*.

*1.* Create a copy of `SConstruct-parameters-all` and rename it `SConstruct-variables`.

In your text editor, open the file `SConstruct-variables` and replace the `cmd_isles_data`, `cmd_abyss_data`, and `cmd_last_data` sections with the following code:

~~~~
cmds={}
for opt in ["isles","abyss","last"]:
    cmds[opt]=env.StataBuild(
    target = 'outputs/data/dta/'+opt+'.dta',
    source = 'code/countWords.do',
    params='"'+opt+'"',
    depends=['inputs/txt/'+opt+'.txt']
)
~~~~

** Python tips for beginner **

> * Here, we use a python `for` loop. you can replace `opt` to other characters if you want.

> * Scons is based on python, so python can be applied in SConstruct file.

> * `cmds={}` creates an empty "dictionary" (a set of key-value pairs). Then, inside the loop, we assign the output of the command to a value of new key-value pair, where the key is `opt`.

> * Use `+` for stiring concatenation (adding strings together) in python.


*2.* Use `SConstruct-variables` to see if any of the targets need to be rebuilt.

~~~~
. statacons, clean file(SConstruct-variables)
scons: Reading SConscript files ...
scons: done reading SConscript files.
scons: Cleaning targets ...
Removed outputs\data\dta\abyss.dta
Removed outputs\data\dta\isles.dta
Removed outputs\data\dta\last.dta
Removed outputs\tables\testZipf.txt
scons: done cleaning targets.

. statacons, dry_run debug(explain) file(SConstruct-variables)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: building `outputs\data\dta\abyss.dta' because it doesn't exist
stata_run(["outputs\data\dta\abyss.dta"], ["code\countWords.do"])
scons: building `outputs\data\dta\isles.dta' because it doesn't exist
stata_run(["outputs\data\dta\isles.dta"], ["code\countWords.do"])
scons: building `outputs\data\dta\last.dta' because it doesn't exist
stata_run(["outputs\data\dta\last.dta"], ["code\countWords.do"])
scons: building `outputs\tables\testZipf.txt' because it doesn't exist
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipfArgs.do"])
scons: done building targets.

. statacons, file(SConstruct-variables)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\abyss.dta"], ["code\countWords.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\countWords.do" "
> abyss". log=countWords-8e4bf7a2.log.
  Starting in hidden desktop (pid=27364).
stata_run(["outputs\data\dta\isles.dta"], ["code\countWords.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\countWords.do" "
> isles". log=countWords-fad1dc5c.log.
  Starting in hidden desktop (pid=22752).
stata_run(["outputs\data\dta\last.dta"], ["code\countWords.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\countWords.do" "
> last". log=countWords-3cf895f1.log.
  Starting in hidden desktop (pid=28564).
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipfArgs.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\testZipfArgs.do"
>  "isles last abyss". log=testZipfArgs-b47d1d91.log.
  Starting in hidden desktop (pid=6296).
scons: done building targets.

. 
~~~~
