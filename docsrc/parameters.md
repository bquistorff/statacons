<head>
  <link rel="stylesheet" type="text/css" href="stmarkdown.css">

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>


Parameters
==============================================

Our do-file and SConstruct file have repeated contents. Instead of having `count_isles.do`, `count_abyss.do`, `count_last.do`, we will call `countWords.do` with arguments.

*1.* Instead of calling do-file `count_last.do`, we call `countWords.do` to create a frequency count dataset `isle.dta` from the input text `last.txt`.

Here is an example of calling countWords with argument to create  `*.dta` in Stata:

~~~~

. type code/countWords.do
args inputFileName 

preserve

  wordfreq using inputs/txt/`inputFileName'.txt, clear
  egen totalsum = total(freq)
  gen share = freq / totalsum 
  drop totalsum 
  gsort - freq 
  save outputs/data/dta/`inputFileName'.dta, replace 

restore


~~~~

`countWords.do` requires one argument (args): `inputfileName`. In our example, inputfileName is `isles`. `countWords.do` automatically loads `isles.txt` and creates outputfile named `isles.dta`.
We call `countWords.do` with an argument in Stata.

~~~~

. do code/countWords.do "isles"

. args inputFileName 

. 
. preserve

. 
.   wordfreq using inputs/txt/`inputFileName'.txt, clear

.   egen totalsum = total(freq)

.   gen share = freq / totalsum 

.   drop totalsum 

.   gsort - freq 

.   save outputs/data/dta/`inputFileName'.dta, replace 
file outputs/data/dta/isles.dta saved

. 
. restore

. 
end of do-file


~~~~

Check the top 5 lines in the output file `isles.dta`:

~~~~

. use outputs/data/dta/isles.dta, clear

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

And, do not re-create `testZipf.txt` directly in Stata. (We will update the `SConstruct-parameters` and re-create it using `statacons` in the next step.)

*2.* Create a copy of `SConstruct-2NewRules` and rename it `SConstruct-parameters-isles`.

*3.* Add parameters in SConstruct file.

Now, we learn how to include `parameters` in our `SConstruct` file.

In your text editor, open the file called `Sconstruct-parameters-isles` you created in step *2*. In `cmd_isles_data`, edit the source to `code/countWords.do` and add `params='"isles"'`. This will lead `statacons` to run the do-file `code/countWords.do` with an argument `"isles"`.

```

cmd_isles_data = env.StataBuild(
    target = 'outputs/data/dta/isles.dta',
    source = 'code/countWords.do',
    params='"isles"')
Depends=(cmd_isles_data,
    ['inputs/txt/isles.txt']
)

```

Next, to update `testZipf.txt`, include following command in `SConstruct-parameters-isles`.

~~~

cmd_results = env.StataBuild(
    target = 'outputs/tables/testZipf.txt',
    source = 'code/testZipf.do'
)
Depends(cmd_results,
    ['outputs/data/dta/last.dta',
    'outputs/data/dta/abyss.dta',
    'outputs/data/dta/isles.dta']
)

~~~

*4.* Use `SConstruct-parameters-isles` to see if any of the targets need to be rebuilt.

Use option `--sconstruct=SConstruct-parameters-isles` to assign the specific `SConstruct` file, and
use `-n` to get a preview of what `statacons` will do.

~~~~

. statacons -n --debug=explain --sconstruct=SConstruct-parameters-isles
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
scons: Cannot explain why `outputs\data\dta\isles.dta' is being rebuilt: No pre
> vious build information found
stata_run(["outputs\data\dta\isles.dta"], ["code\countWords.do"])
scons: Cannot explain why `outputs\data\dta\last.dta' is being rebuilt: No prev
> ious build information found
stata_run(["outputs\data\dta\last.dta"], ["code\count_last.do"])
scons: Cannot explain why `outputs\tables\testZipf.txt' is being rebuilt: No pr
> evious build information found
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipf.do"])
scons: done building targets.


~~~~

Run `statacons`. `statacons` will rebuild `isles.dta` and `textZipf.txt` only.

~~~~

. statacons --sconstruct=SConstruct-parameters-isles
scons: Reading SConscript files ...
Using 'LabelsFormatsOnly' custom_datasignature.
Calculates timestamp-independent checksum of dataset, 
  including variable formats, variable labels and value labels.
Edit use_custom_datasignature in config_project.ini to change.
  (other options are Strict, DataOnly, False)
scons: done reading SConscript files.
scons: Building targets ...
stata_run(["outputs\data\dta\abyss.dta"], ["code\count_abyss.do"])
Running: StataMP-64.exe /e do "code\count_abyss.do".
  Starting in hidden desktop (pid=19232).
stata_run(["outputs\data\dta\isles.dta"], ["code\countWords.do"])
Running: StataMP-64.exe /e do "code\countWords.do" "isles". log=countWords-fad1
> dc5c.log.
  Starting in hidden desktop (pid=3788).
stata_run(["outputs\data\dta\last.dta"], ["code\count_last.do"])
Running: StataMP-64.exe /e do "code\count_last.do".
  Starting in hidden desktop (pid=11544).
stata_run(["outputs\tables\testZipf.txt"], ["code\testZipf.do"])
Running: StataMP-64.exe /e do "code\testZipf.do".
  Starting in hidden desktop (pid=15768).
scons: done building targets.


~~~~


Check if `statacons` re-creates `textZipf.txt`.

~~~

.  type outputs/tables/testZipf.txt
Book    First   Second  Ratio
isles   3315    2185    1.5171624
abyss   3538    2524    1.4017433
last    10684   4904    2.1786296


~~~

## Parameters: Exercise

1. Create a copy of `SConstruct-parameters-isles` and rename it `SConstruct-parameters-all`.

2. Add `cmd_last_data` and `cmd_abyss_data` in `SConstruct-parameters-all` using `countWords.do` as a source with parameters.

3. Replace `textZipf.do` to `textZipfArg.do` that takes the input file names as arguments.

4. Add a rule in our new SConstruct to build new `textZpif.txt`.

5. Use `SConstruct-parameters-all` to see if any of the targets need to be rebuilt.

    Hint: See `abyss` and `Two New Rules` solutions. See how `contWords.do` takes arguments in Stata. Apply `param` in `SConstruct` file.





## Parameters: Using statacons with dyndoc in literate programming

As a final example of the use of parameters, this web tutorial consists of several web pages, each created from a Markdown `.md` file. Each of these `.md` files was created from a Stata `dyndoc` file. For example, this web page is produced from a Markdown file `parameters.md`, which in turn was created by `parameters.dyndoc`. We used `statacons` to manage this process. See *statacons and Literate Programming* on our project Wiki page for the code.
