
/***
_V 1.5_

md2smcl
=======

a Stata module to convert Markdown syntax in coumpound double-string 
to Stata Control and Markup Language (SMCL).

Syntax
======

> __md2smcl__ _`"compound double-string"'_

Description
===========

The __md2smcl__ command was originally written for {help markdoc} package to 
generate Stata help files from Markdown code. However, it can be incorporated in 
other user packages that deal with Markdown and SMCL. 

The package [is hosted on GitHub](https://github.com/haghish/md2smcl), where 
you can read more about the package, see examples, and even contribute to the 
package.  

The __md2smcl__ command returns a _rclass_ macro named __r(md)__, which 
includes the SMCL code. 

Example
=================

The examples below demonstrate how to use the __md2smcl__ command to style text 
in SMCL. Moreover, the syntax for creating titles and hyperlinks is shown:

        . md2smcl `"# Title"'
        . md2smcl `"_italic_, __bold__, and ___underlined___ text"'
        . md2smcl `"[md2smcl Homepage](http://www.github.com/haghish/md2smcl)"'

The __md2smcl__ engine can also be used to create a straight line or a tab. 
There are several alternatives for creating a straight line in Markdown but this 
package only supports the "- - -" syntax. Combining "- - -" with a word or 
sentence will result in a tab in SMCL. The latter is not Markdown syntax but is 
made for Stata for further convenience. 

        . md2smcl `"- - -"'

Author
======

__E. F. Haghish__     
Center for Medical Biometry and Medical Informatics     
University of Freiburg, Germany     
_and_        
Department of Mathematics and Computer Science       
University of Southern Denmark     
haghish@imbi.uni-freiburg.de        

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 
***/

*cap prog drop md2smcl
program define md2smcl, rclass
	
	//DEFINE a functionality shift
	//ENGINE1: smclmarkdown (limited functionalities)
	
	local version = int(`c(stata_version)')
	if `version' <= 13 {
		local trim trim
		local strlen strlen
		local version 11
	}
	if `version' > 13 {
		local trim ustrltrim
		local strlen ustrlen
		local version 14
	}
	version `version'
	
	
	
	// Remove trailing double quotations when the input is `"`macval(line)'"'
	local length = `strlen'(`"`macval(0)'"') 
	if `length' > 2 {
		local 0 = substr(`"`macval(0)'"', 3,`length'-4)
	}
	
	//fixing grave accent (NEEDS DEVELOPMENT)

	
	// quote and doublequote (NEEDS CORRECTION)
	// -------------------------------------------------------------------------		
	if substr(`trim'(`"`macval(0)'"'),1,5) == "> > >" {
		local 0 : subinstr local 0 "> > >" "{p 24 24 2}"
	}
	
	if substr(`trim'(`"`macval(0)'"'),1,3) == "> >" {
		local 0 : subinstr local 0 "> >" "{p 16 16 2}"
	}
	
	if substr(`trim'(`"`macval(0)'"'),1,1) == ">" {
		local 0 : subinstr local 0 ">" "{p 8 8 2}"
	}
	
	
	// Create Markdown Horizontal line
	// -------------------------------------------------------------------------
	if `trim'(`"`macval(0)'"') == "- - - -" {
		local 0 : subinstr local 0 "- - - -"  "    {hline}" 
	}
	if `trim'(`"`macval(0)'"') == "- - -" {
		local 0 : subinstr local 0 "- - -"  "    {hline}" 
	}
	if `trim'(`"`macval(0)'"') == "---" {
		local 0 : subinstr local 0 "---"  "{hline}" 
	}
	if `trim'(`"`macval(0)'"') == "* * *" {
		local 0 : subinstr local 0 "* * *"  "{hline}" 
	}
	
	
	
	// Add Line Break
	// -------------------------------------------------------------------------
	if substr(`"`macval(0)'"', -2,.) == "  " {
		local 0 `"`macval(0)'  {break}"'
	}
	
	// Avoid string quotations and also grave accesnts
	// -------------------------------------------------------------------------
	*local 0 : subinstr local 0 `"""' "{c 34}", all
	
	// Stata SMCL is always monospace! 
	local 0 : subinstr local 0 "__`" "__", all
	local 0 : subinstr local 0 "`__" "__", all
	local 0 : subinstr local 0 "_`" "_", all
	local 0 : subinstr local 0 "`_" "_", all
	local 0 : subinstr local 0 "[`" "[", all
	local 0 : subinstr local 0 "`]" "]", all
	local 0 : subinstr local 0 "(`" "(", all
	local 0 : subinstr local 0 "`)" ")", all
	local 0 : subinstr local 0 "`" "{c 96}", all
	local 0 : subinstr local 0 "'" "{c 39}", all
	*local 0 : subinstr local 0 "=" "{c 61}", all
	
	
	// Hyperlink
	// -------------------------------------------------------------------------
	forvalues i = 1/27 {
		if strpos(`"`macval(0)'"', "](") != 0 {
			local a = strpos(`"`macval(0)'"', "](")
			local 0 : subinstr local 0 "](" ""
			local l1 = substr(`"`macval(0)'"',1,`a'-1) 
			local l2 = substr(`"`macval(0)'"',`a',.) 
			*di as err "l1>`l1'<"
			*di as err "l2>`l2'<"
			
			// Extract the image syntax & link text
			if strpos(`"`macval(l1)'"', "![") != 0 {
				local a = strpos(`"`macval(l1)'"', "![")
				local l1 : subinstr local l1 "![" " "
				local text = substr(`"`macval(l1)'"',1,`a') 
				local hypertext = substr(`"`macval(l1)'"',`a'+1,.) 
				local image 1
			}
			
			// Extract the hypertext syntax & link text
			else if strpos(`"`macval(l1)'"', "[") != 0 {
				local a = strpos(`"`macval(l1)'"', "[")
				local l1 : subinstr local l1 "[" " "
				local text = `trim'(substr(`"`macval(l1)'"',1,`a'))
				local hypertext = `trim'(substr(`"`macval(l1)'"',`a'+1,.))
				*di as err "text>`text'<"
				*di as err "hypertext>`hypertext'<"
			}
			
			// interpret the hypertext
			capture md2smcl `"`hypertext'"'
			if _rc == 0 local hypertext `r(md)'
			
			//Extract the name
			if strpos(`"`macval(l2)'"', ")") != 0 {
				local a = strpos(`"`macval(l2)'"', ")")
				local l2 : subinstr local l2 ")" ""
				local link = substr(`"`macval(l2)'"',1,`a'-1) 
				local rest = substr(`"`macval(l2)'"',`a',.) 
				*di as err "link>`link'<"
				*di as err "rest>`rest'<"
			}
			
			if "`image'" != "1" {
				local 0 : di `"`macval(text)'{browse "`macval(link)'":`macval(hypertext)'}`macval(rest)'"'
			}
			else {
				local 0 : di `"`macval(text)'`macval(rest)'"'
			}
		}
	}
	
	
	// Text styling
	// -------------------------------------------------------------------------
	*forvalues i = 1/27 {
	*	local 0 : subinstr local 0 "_____" "{bf:{ul:"
	*	local 0 : subinstr local 0 "_____" "}}"
	*}
	
	*forvalues i = 1/27 {
	*	local 0 : subinstr local 0 "____" "{it:{ul:"
	*	local 0 : subinstr local 0 "____" "}}"
	*}
	
	forvalues i = 1/27 {
		local 0 : subinstr local 0 "**" "{ul:"
		local 0 : subinstr local 0 "**" "}"
	}
	
	if substr(`trim'(`"`macval(0)'"'),1,2) == "__" & 							///
	substr(`trim'(`"`macval(0)'"'),1,3) != "___" {
		local 0 : subinstr local 0 "__" "{bf:"
		local 0 : subinstr local 0 "__ " "} "
	}
	
	if substr(`trim'(`"`macval(0)'"'),1,1) == "_" & 							///
	substr(`trim'(`"`macval(0)'"'),1,2) != "__" {
		local 0 : subinstr local 0 "_" "{it:"
		local 0 : subinstr local 0 "_ " "} "
	}
	
	
	forvalues i = 1/27 {
		local 0 : subinstr local 0 " __" " {bf:"
		local 0 : subinstr local 0 "=__" "={bf:"
		local 0 : subinstr local 0 "[__" "[{bf:"
		local 0 : subinstr local 0 "__ " "} "
	
	}		
	
	
	forvalues i = 1/27 {
		local 0 : subinstr local 0 "__." "}."
		local 0 : subinstr local 0 "__," "},"
		local 0 : subinstr local 0 "__;" "};"
		local 0 : subinstr local 0 "__:" "}:"
		local 0 : subinstr local 0 "__!" "}!"
		local 0 : subinstr local 0 "__?" "}?"
		local 0 : subinstr local 0 "__]" "}]"
	}	
	forvalues i = 1/27 {
		local 0 : subinstr local 0 " _" " {it:"
		local 0 : subinstr local 0 "|__" "|{bf:"
		local 0 : subinstr local 0 "|_" "|{it:"
		local 0 : subinstr local 0 "=_" "={it:"
		local 0 : subinstr local 0 "(_" "({it:"
		local 0 : subinstr local 0 "[_" "[{it:"
		local 0 : subinstr local 0 "_ " "} "
	}
	forvalues i = 1/27 {
		local 0 : subinstr local 0 "_)" "})"
		local 0 : subinstr local 0 "_]" "}]"
		local 0 : subinstr local 0 "_." "}."
		local 0 : subinstr local 0 "_!" "}!"
		local 0 : subinstr local 0 "_?" "}?"
		local 0 : subinstr local 0 "_," "},"
		local 0 : subinstr local 0 "_;" "};"
		local 0 : subinstr local 0 "_:" "}:"
	}
	
	// Secondary syntax for headers
	// -------------------------------------------------------------------------
	if substr(`trim'(`"`macval(0)'"'),1,2) == "# " {
		local 0 : subinstr local 0 "# " ""
		local 0  "{title:`0'}"
	}
	else if substr(`trim'(`"`macval(0)'"'),1,3) == "## " {
		local 0 : subinstr local 0 "## " ""
		local 0  "{title:`0'}"
	}
	else if substr(`trim'(`"`macval(0)'"'),1,4) == "### " {
		local 0 : subinstr local 0 "### " ""
		//local 0  "{title:`0'}"
		local 0  "{p 4 4 2}{bf:`0'}" 
	}
	else if substr(`trim'(`"`macval(0)'"'),1,5) == "#### " {
		local 0 : subinstr local 0 "#### " ""
		//local 0  "{title:`0'}"
		local 0  "{p 4 4 2}{it:`0'}" 
	}
	
	// process the last character of the line
	// -------------------------------------------------------------------------
	if substr(`trim'(`"`macval(0)'"'),-3,.) == "___" {
		local 0 : subinstr local 0 "___" "}"
	}
	if substr(`trim'(`"`macval(0)'"'),-2,.) == "__" {
		local 0 : subinstr local 0 "__" "}"
	}
	if substr(`trim'(`"`macval(0)'"'),-1,.) == "_" {
		local 0 : subinstr local 0 "_" "}"
	}

	*substr("abcdef",-3,.) = "def"
	
	
	
	
	
	
	// Add list
	// -------------------------------------------------------------------------
	if substr(`trim'(`"`macval(0)'"'),1,1) == "-" |           ///
	   substr(`trim'(`"`macval(0)'"'),1,1) == "+" |           ///
		 substr(`trim'(`"`macval(0)'"'),1,1) == "*" {
		local n 16
		forvalues i = 1/16 {
			local trailspace : display _dup(`n') " "
			if substr(`"`macval(0)'"',1,`n') == "`trailspace'" {
				local 0 : subinstr local 0 "`trailspace'" "{space `n'}"
			}
			local n = `n'-1
		}
		local 0 `"{break}    `macval(0)'"'
	}

	
	// Add numbered list (NEEDS CORRECTION)
	// -------------------------------------------------------------------------
	if substr(`trim'(`"`macval(0)'"'),1,1) == "1" | substr(`trim'(`"`macval(0)'"'),1,1) == "2" |  ///
	   substr(`trim'(`"`macval(0)'"'),1,1) == "3" | substr(`trim'(`"`macval(0)'"'),1,1) == "4" |  ///
	   substr(`trim'(`"`macval(0)'"'),1,1) == "5" | substr(`trim'(`"`macval(0)'"'),1,1) == "6" |  ///
	   substr(`trim'(`"`macval(0)'"'),1,1) == "7" | substr(`trim'(`"`macval(0)'"'),1,1) == "8" |  /// 
	   substr(`trim'(`"`macval(0)'"'),1,1) == "9"  {
		local 0 `"{break}    `macval(0)'"'
	}
	
	// preserve trail white space securely
	// -------------------------------------------------------
	local n 16
	forvalues i = 1/16 {
	  local trailspace : display _dup(`n') " "
		if substr(`"`macval(0)'"',1,`n') == "`trailspace'" {
		  local 0 : subinstr local 0 "`trailspace'" "{space `n'}"
		}
		local n = `n'-1
	}

	
	
	
	
	
	
	// Create SMCL Tab
	// -------------------------------------------------------------------------
	/*
	if `trim'(`"`macval(0)'"') != "- - -" &										///
	substr(`trim'(`"`macval(0)'"'),1,5) == "- - -" {
		local 0 : subinstr local 0 "- - -" "{dlgtab:" 
		local 0 = `"`macval(0)' "' + "}"
	}
	*/
	
	
	// AT LAST
	// =========================================================================
	/*forvalues i = 1/10 {
		local 0 : subinstr local 0 "__" " {bf:"
		local 0 : subinstr local 0 "__" "}"
	}
	*/
						
	
	display as txt `"`macval(0)'"'
	return local md `"`macval(0)'"'
	
	*return local md `macval(0)'
	
end

*markdoc md2smcl.ado, exp(sthlp) replace //build
