{smcl}
{it:V 1.5}


{title:md2smcl}

{p 4 4 2}
a Stata module to convert Markdown syntax in coumpound double-string 
to Stata Control and Markup Language (SMCL).


{title:Syntax}

{p 8 8 2} {bf:md2smcl} {it:"compound double-string"{c 39}}


{title:Description}

{p 4 4 2}
The {bf:md2smcl} command was originally written for {help markdoc} package to 
generate Stata help files from Markdown code. However, it can be incorporated in 
other user packages that deal with Markdown and SMCL. 

{p 4 4 2}
The package  {browse "https://github.com/haghish/md2smcl":is hosted on GitHub}, where 
you can read more about the package, see examples, and even contribute to the 
package.    {break}

{p 4 4 2}
The {bf:md2smcl} command returns a {it:rclass} macro named {bf:r(md)}, which 
includes the SMCL code. 


{title:Example}

{p 4 4 2}
The examples below demonstrate how to use the {bf:md2smcl} command to style text 
in SMCL. Moreover, the syntax for creating titles and hyperlinks is shown:

        . md2smcl `"# Title"' 
        . md2smcl `"_italic_, __bold__, and ___underlined___ text"'
        . md2smcl `"[md2smcl Homepage](http://www.github.com/haghish/md2smcl)"' 

{p 4 4 2}
The {bf:md2smcl} engine can also be used to create a straight line or a tab. 
There are several alternatives for creating a straight line in Markdown but this 
package only supports the "- - -" syntax. Combining "- - -" with a word or 
sentence will result in a tab in SMCL. The latter is not Markdown syntax but is 
made for Stata for further convenience. 

        . md2smcl `"- - -"'


{title:Author}

{p 4 4 2}
{bf:E. F. Haghish}       {break}
Center for Medical Biometry and Medical Informatics       {break}
University of Freiburg, Germany       {break}
{it:and}          {break}
Department of Mathematics and Computer Science         {break}
University of Southern Denmark       {break}
haghish@imbi.uni-freiburg.de          {break}

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 


