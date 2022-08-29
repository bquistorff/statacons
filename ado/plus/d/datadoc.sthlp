{smcl}
{it:v. 1.4}


{title:datadoc}

{p 4 4 2}
generates data documentation template based on CRAN{c 39}s layout.


{title:Syntax}

{p 8 8 2} {bf:datadoc} [, replace]

{p 4 4 2}{bf:Options}

{break}    - {it:replace} option replaces the existing file                         |


{title:Description}

{p 4 4 2}
the output includes a do-file documentation and its Stata help file. 
the command requires a data to be loaded in the memory. 
If not, a template is generated. 


{title:Example}

{p 4 4 2}
generate {it:example.md} documentation layout to be filled manually

        . clear
        . datadoc 

{p 4 4 2}
generate a data documentation template for {bf:auto.dta}

        . sysuse auto, clear
        . datadoc 

{p 4 4 2}
add notes to the dataset and variables

        . sysuse auto, clear
        . notes : this data set is included in Stata 15
        . notes : for more information see github.com/haghish/datadoc
        . notes price: this is the price of the car
        . notes make: add information about the make variable
        . notes weight: explain ... 
        . datadoc, replace

{p 4 4 2}
if a variable includes more than one note, {bf:datadoc} will present the 
informattion in a different format:

        . notes price: this is the second note of the price variable
        . datadoc, replace


{title:Author}

{p 4 4 2}
E. F. Haghish    {break}
{it:haghish@med.uni-goesttingen.de}    {break}
{browse "https://github.com/haghish/echo":https://github.com/haghish/echo}    {break}


{title:License}

{p 4 4 2}
MIT License

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 



