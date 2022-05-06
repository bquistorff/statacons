<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


Solution for "Exercise: Parameters"
==============================================

*1.* Create a copy of `SConstruct-parameters-isles` and rename it `SConstruct-parameters-all`.

*2.* Add `cmd_last_data` and `cmd_abyss_data` in `SConstruct-parameters-all` using `countWords.do` as a source with parameters.

Add `params='"inputfilesName"'` in `SConstruct-parameters-solutions`.

~~~

cmd_abyss_data = env.StataBuild(
    target = 'outputs/data/dta/abyss.dta',
    source = 'code/countWords.do',
    params='"abyss"')
Depends=(cmd_abyss_data,
    ['inputs/txt/abyss.txt']
)

cmd_last_data = env.StataBuild(
    target = 'outputs/data/dta/last.dta',
    source = 'code/countWords.do',
    params='"last"')
Depends=(cmd_last_data,
    ['inputs/txt/last.txt']
)

~~~


*2.* Change `textZipf.do` to `textZipfArg.do` that takes the input file names as arguments.

Instead of updating `testZipf.do`, we can make `testZipfArgs.do`, a version of `testZipf.do` which takes the input file names as arguments. Then, we can call it with parameters.

a. Copy `testZipf.do` and rename it `testZipfArgs.do`

b. Open `testZipfArgs.do` in Stata do-file editor and edit the first part of do-file. Include `args inputFiles` and remove the `local inputFiles` variable list.

~~~

args inputFiles
// local inputFiles isles last abyss

~~~

Sample do-file:

~~~

. type code/testZipfArgs.do
version 16.1
quietly include profile.do

args inputFiles

//local inputFiles 
noi di `"local inputFiles: "`inputFiles'" "'

foreach file of local inputFiles {
        cap confirm file "outputs/data/dta/`file'.dta"
  if _rc==0 {
        local LoopOver `LoopOver' `file'
  }
}
noi di `"local LoopOver: "`LoopOver'" "'

preserve 

  // set up tempfile
  tempname myName
  tempfile myFile

  postfile `myName' str100(Book) long(First Second) using `myFile'



  foreach inputFile of local LoopOver {
    use outputs/data/dta/`inputFile'.dta, clear 
    keep freq
    gsort - freq 
    keep in 1/2
    
    post `myName' ("`inputFile'") (freq[1]) (freq[2])
    
  }

  postclose `myName'

  use `myFile', clear
  gen Ratio = First / Second 
  format Ratio %4.3f
  compress 
  save outputs/data/dta/testZipf.dta, replace 

  export delimited using outputs/tables/testZipf.txt, ///
    delimiter(tab) replace

restore 


~~~

*3.* Add a rule in our new SConstruct to build new `textZpif.txt`.

Update `SConstruct-parameters-all` to apply our new rules using parameters.

Include `params='"isles last abyss"'` in `cmd_results` and `outputs/data/dta/abyss.dta','outputs/data/dta/last.dta'` in `depends`.

~~~

cmd_results = env.StataBuild(
    target = 'outputs/tables/testZipf.txt',
    source = 'code/testZipfArgs.do',
	params='"isles last abyss"'
)
Depends = (cmd_results,
    ['outputs/data/dta/isles.dta',
	'outputs/data/dta/abyss.dta',
	'outputs/data/dta/last.dta',]
)

~~~

*4.* Use `SConstruct-parameters-all` to see if any of the targets need to be rebuilt.

Clear your `output/dta` directory before running if the outputs already exist.

~~~

. statacons --sconstruct=SConstruct-parameters-all -c
scons: Reading SConscript files ...
scons: done reading SConscript files.
scons: Cleaning targets ...
Removed outputs\data\dta\abyss.dta
Removed outputs\data\dta\isles.dta
Removed outputs\data\dta\last.dta
Removed outputs\tables\testZipf.txt
scons: done cleaning targets.

. statacons --sconstruct=SConstruct-parameters-all
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\abyss.dta"], ["code\countWords.do"])
Running: StataMP-64.exe /e do "code\countWords.do" "abyss". log=countWords-8e4b
> f7a2.log.
  Starting in hidden desktop (pid=25532).
stata_run(["outputs\data\dta\isles.dta"], ["code\countWords.do"])
Running: StataMP-64.exe /e do "code\countWords.do" "isles". log=countWords-fad1
> dc5c.log.
  Starting in hidden desktop (pid=18268).
stata_run(["outputs\data\dta\last.dta"], ["code\countWords.do"])
Running: StataMP-64.exe /e do "code\countWords.do" "last". log=countWords-3cf89
> 5f1.log.
  Starting in hidden desktop (pid=15988).
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipfArgs.do"])
Running: StataMP-64.exe /e do "code\testZipfArgs.do" "isles last abyss". log=te
> stZipfArgs-b47d1d91.log.
  Starting in hidden desktop (pid=22348).
scons: done building targets.

. type outputs/tables/testZipf.txt
Book    First   Second  Ratio
isles   3315    2185    1.5171624
last    10684   4904    2.1786296
abyss   3538    2524    1.4017433

. 

~~~

Note: `statacons` and `SConstruct` file allow us to create `abyss.dta` and `last.dta` without editing the Stata do-file.
