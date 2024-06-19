{smcl}

{p 4 4 2}
{it:version 3.0.3}


{title:complete_datasignature}

{p 4 4 2}
{bf:complete_datasignature} creates a signature for a Stata .dta-file that does {bf:not} depend on the embedded timestamp but {bf:does} depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

{p 4 4 2}
{bf:complete_datasignature} extends Stata{c 39}s {bf:datasignature} by allowing the inclusion of different sets of metadata.



{title:Syntax}

{p 8 8 2} complete_datasignature [, dta_file("file.dta") fname("sigfile.ext") nometa fast labels_formats_only]


{p 4 4 2}
By default, {bf:complete_datasignature} will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

{p 4 4 2}{bf:Options}

{col 5}Option{col 33}Description
{space 4}{hline}
{col 5}dta_file("file.dta"){col 33}Use  "file.dta"  instead of dta-file in memory
{col 5}fname("sigfile.ext"){col 33}write signature to "sigfile.ext"
{col 5}nometa{col 33}Do not include any metadata -- equivalent of Stata{c 39}s {bf:datasignature}
{col 5}labels_formats_only{col 33}Include variable formats, variable and value labels
{col 5}fast{col 33}use {bf:_datasignature} in {it:fast} mode -- faster but not machine-independent
{space 4}{hline}



{title:Example(s)}


        . sysuse auto
    (1978 automobile data)
        . datasignature
    74:12(71728):3831085005:1395876116
        . complete_datasignature, nometa
    74:12(71728):3831085005:1395876116
        . complete_datasignature, labels_formats_only
    74:12(71728):3831085005:1395876116:2144891519
        . complete_datasignature
    74:12(71728):3831085005:1395876116:711253444
        . ret li
    macros:
         r(signature) : "74:12(71728):3831085005:1395876116:711253444"
         . _datasignature, fast
       74:12(71728):3831085005:186045760
         . complete_datasignature, nometa fast
    74:12(71728):3831085005:186045760





{title:Stored results}

{p 4 4 2}
{bf:r(signature)}    signature calculated by {bf:complete_datasignature}


{title:Author}

{p 4 4 2}
{bf:statacons} team
{browse "https://github.com/bquistorff/statacons":https://github.com/bquistorff/statacons}


{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package}



