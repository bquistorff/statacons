{smcl}

{p 4 4 2}
{it:version 3.1.0-alpha2}


{title:complete_datasignature}

{p 4 4 2}
{bf:complete_datasignature} creates a signature for a Stata .dta-file or .dtas frameset that does {bf:not} depend on the embedded timestamp but {bf:does} depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

{p 4 4 2}
{bf:complete_datasignature} extends Stata{c 39}s {bf:datasignature} by allowing the inclusion of different sets of metadata. When called with {bf:frameset_file}, it signs every frame in a {bf:.dtas} frameset and returns a concatenation keyed by frame name.



{title:Syntax}

{p 8 8 2} complete_datasignature [, dta_file("file.dta") frameset_file("file.dtas") fname("sigfile.ext") nometa fast labels_formats_only skip_char("globlist")]


{p 4 4 2}
By default, {bf:complete_datasignature} will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

{p 4 4 2}{bf:Options}

{col 5}Option{col 33}Description
{space 4}{hline}
{col 5}dta_file("file.dta"){col 33}Use  "file.dta"  instead of dta-file in memory
{col 5}frameset_file("file.dtas"){col 33}Sign a {bf:.dtas} frameset; iterate frames alphabetically and return "frameA=sigA|frameB=sigB|..."
{col 5}fname("sigfile.ext"){col 33}write signature to "sigfile.ext"
{col 5}nometa{col 33}Do not include any metadata -- equivalent of Stata{c 39}s {bf:datasignature}
{col 5}labels_formats_only{col 33}Include variable formats, variable and value labels
{col 5}fast{col 33}use {bf:_datasignature} in {it:fast} mode -- faster but not machine-independent
{col 5}skip_char("globlist"){col 33}Skip variable/dataset characteristics whose names match any pattern in the space-separated globlist. The {bf:frameset_file} path always adds {bf:frlink_*} to this list.
{space 4}{hline}

{p 4 4 2}{bf:Behavior of {bf:frameset_file__}

{p 4 4 2}
When {bf:frameset_file} is set, the program:

{break}    1. In interactive mode ({it:_c(mode)} is empty), saves all in-memory frames to a temporary {bf:.dtas} so user state can be restored on exit. In batch mode, this round-trip is skipped.
{break}    2. Loads the target {bf:.dtas} via {bf:frames use, clear}.
{break}    3. For each frame in alphabetical order, computes a per-frame signature using the same metadata options ({it:_nometa}, {bf:fast}, {bf:labels_formats_only_}) plus {bf:skip_char("frlink_*")}.
{break}    4. Assembles "frameA=sigA|frameB=sigB|...".
{break}    5. In interactive mode, restores the user{c 39}s frames from the temporary {bf:.dtas}.


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

        . complete_datasignature, frameset_file("myframeset.dtas")
    census=74:12(71728):...|housing=50:12(...):...





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



