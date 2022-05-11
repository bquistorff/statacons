<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


Solution for "Exercise: Write Two New Rules"
==============================================

*1.* Create a copy of `SConstruct-addAbyss` and rename it `SConstruct-2NewRules`.

*2.* Write a new do-file `count_last.do` to create a frequency count dataset `last.dta` from the input text `last.txt`.

Here is `count_last.do` code:

~~~~

version 16.1
quietly include profile.do 

countWords, inputFile("last.txt") outputFile("last.dta")  

exit 


~~~~

And here is the result of running `count_last.do` in Stata:

~~~~

. do "code/count_last.do"

. version 16.1

. quietly include profile.do 
pandoc C:\Program Files\Pandoc\pandoc.exe
wkhtmltopdf C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe

. 
. countWords, inputFile("last.txt") outputFile("last.dta")  
(note: file outputs/data/dta/last.dta not found)
file outputs/data/dta/last.dta saved

. 
. exit 

end of do-file


~~~~

Check the top 5 lines in the output file `last.dta`:

~~~~

. use outputs/data/dta/last.dta, clear

. li in 1/5

     +-------------------------+
     | word    freq      share |
     |-------------------------|
  1. |  the   10684   .0627386 |
  2. |  and    4904   .0287973 |
  3. |   to    4472   .0262605 |
  4. |   of    4326   .0254031 |
  5. |    a    3577   .0210049 |
     +-------------------------+

. clear


~~~~

*3.* Add a rule to our new SConstruct to build last.dta.

In your text editor, open the file called `Sconstruct-2NewRules` and add a new rule:

```

cmd_last_data = env.StataBuild(
	target = 'outputs/data/dta/last.dta',
	source = 'code/count_last.do'
)
Depends(cmd_last_data,
	['inputs/txt/last.txt',
	'code/ado/personal/countWords.ado',
	'code/ado/plus/w/wordfreq.ado']
)

```

*4.* Update `testZipf.do` to incorporate `last.dta`, but do not re-create `testZipf.txt` directly in Stata. (We will update the `SConstruct-2NewRules` and re-create it using `statacons` in the next step.)

Open `testZipf.do` in Do-file editor and add `last` in local inputFiles.

~~~~

local inputFiles isles abyss last

~~~~

(Do not run `testZipf.do` directly in Stata.)

*5.* Add a rule in our new SConstruct to build `testZipf.txt.`

In your text editor, open the file called `Sconstruct-2NewRules` and add new dependencies `'outputs/data/dta/last.dta'` in `Depends` of the task `cmd_results`.

```

cmd_results = env.StataBuild(
	target = 'outputs/tables/testZipf.txt',
	source = 'code/testZipf.do'
)
Depends(cmd_results,
	['outputs/data/dta/last.dta',
	'outputs/data/dta/abyss.dta',
	'outputs/data/dta/isles.dta']
)

```

*6.* Use SConstruct-2NewRules to see if any of the targets need to be rebuilt.

Use option `file(SConstruct-2NewRules)` to assign specific `SConstruct` file and option `dry_run` to get a preview of what `statacons` will do.

~~~~

. statacons, dry_run debug(explain) file(SConstruct-2NewRules)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
scons: Cannot explain why `outputs\data\dta\last.dta' is being rebuilt: No prev
> ious build information found
stata_run(["outputs\data\dta\last.dta"], ["code\count_last.do"])
scons: Cannot explain why `outputs\tables\testZipf.txt' is being rebuilt: No pr
> evious build information found
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipf.do"])
scons: done building targets.


~~~~

Run `statacons`.

~~~~

. statacons, file(SConstruct-2NewRules)
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\last.dta"], ["code\count_last.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\count_last.do".
  Starting in hidden desktop (pid=16676).
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipf.do"])
Running: "C:\Program Files\Stata16\StataMP-64.exe" /e do "code\testZipf.do".
  Starting in hidden desktop (pid=34660).
scons: done building targets.


~~~~

Check if `statacons` re-creates `testZipf.txt`.

~~~~

. type outputs/tables/testZipf.txt
Book    First   Second  Ratio
isles   3315    2185    1.5171624
abyss   3538    2524    1.4017433
last    10684   4904    2.1786296


~~~~



