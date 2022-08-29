/***
_v. 1.4_

datadoc
=======

generates data documentation template based on CRAN's layout.

Syntax
------

> __datadoc__ [, replace]

### Options

- _replace_ option replaces the existing file                         |

Description
-----------

the output includes a do-file documentation and its Stata help file. 
the command requires a data to be loaded in the memory. 
If not, a template is generated. 

Example
-------

generate _example.md_ documentation layout to be filled manually

        . clear
        . datadoc 

generate a data documentation template for __auto.dta__

        . sysuse auto, clear
        . datadoc 

add notes to the dataset and variables
        
        . sysuse auto, clear
        . notes : this dataset is included in Stata 15
        . notes : for more information see github.com/haghish/datadoc
        . notes price: this is the price of the car
        . notes make: add information about the make variable
        . notes weight: explain ... 
        . datadoc, replace

if a variable includes more than one note, __datadoc__ will present the 
informattion in a different format:

        . notes price: this is the second note of the price variable
        . datadoc, replace

Author
------

E. F. Haghish  
_haghish@med.uni-goesttingen.de_  
[https://github.com/haghish/echo](https://github.com/haghish/echo)  

License
-------

MIT License

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 

***/



*cap prog drop datadoc
program define datadoc

	version 15
	
	syntax [anything]					/// 
	[, 				 ///
	replace 	 	 /// replaces the current sthlp file, if it already exists
	]
	
	if "`c(filename)'" == "" {
	  di as err "no data is loaded in the memory, an empty template is generated called {bf:example.do}"
		local name "example"
	  local script example.do
	}
	else {
		qui abspath "`c(filename)'"
    local name "`r(fname)'"
    local name : subinstr local name ".dta" ""
	  local script `name'.do
	}

	
	// -------------------------------------------------------------------------
	// Part 1: Adding the template 
	// =========================================================================
	tempfile tmp 
	tempname knot 
	qui file open `knot' using `"`tmp'"', write replace


	capture abspath "`c(filename)'"
	local dataname "`r(fname)'"
	if "`dataname'" == "" local dataname "YYY"
	local nvar "`c(k)'"
	if "`nvar'" == "" local nvar "???"
	local nobs "`c(N)'"
	if "`nobs'" == "" local nobs "???"
	
	local len = length("`dataname'") + 8
	
	// get the label of the data
	qui describe
	local datalabel "`r(datalabel)'"
	if "`datalabel'" == "" local datalabel "label of the dataset"
	
	file write `knot' 														          ///
		"/***" _n 																            ///
		"`dataname'" _n                                       ///
		_dup(`len') "=" _n(2)                                 ///
		"`datalabel' ... included in XXX package" _n(2)       ///
		"Description" _n                                      ///
		"----------- " _n(2)                                  ///
		"The __`dataname'__ dataset is about ... " _n(2)       ///
		"Format" _n                                           ///
		"------ " _n(2)                              ///
		"__`dataname'__ dataset includes _`nobs'_ observations and _`nvar'_ variables." _n(2) /// 
		"### Summary of the variables" _n(2)                     
		
	if "`c(filename)'" == "" {
		file write `knot'                                     ///
		"| _Variable_  |  _Type_  | _Description_          |" _n ///
		"|:------------|:---------|:-----------------------|" _n ///
		"| __var1__    | numeric  | explain var1           |" _n ///
		"| __var2__    | string   | explain var2           |" _n(2) 
	}
	else {
		// 15 character for varname, 5 character for type, 60 for description
		
		// get the longest label and check for notes
		local maxlength 0
		foreach var of varlist _all {
			local lab: variable label `var'
			local lablen = length("`lab'")
			if `lablen' > `maxlength' local maxlength `lablen'
			if "``var'[note1]'" != "" local varnotes 1    // define varnotes
			if "``var'[note2]'" != "" {
			  local secondnote 1    // define varnotes
			}
		}
		
		file write `knot'                                     ///
		"| Variable      | Type   | Description "                                             
		
		if `maxlength' > 58 {
			file write `knot' _dup(45) " " "|" _n
		}
		else if `maxlength' > 25  {
			local endpoint1 = `maxlength'-12 
			file write `knot' _dup(`endpoint1') " " "|" _n
		}
		else {
			 file write `knot' _dup(13) " " "|" _n
		}
		
		
		file write `knot' "|:--------------|:-------|:" 
		
		if `maxlength' > 58 {
			file write `knot' "---------------------------------------------------------|" _n 
		}
		else if `maxlength' > 25  {
			file write `knot' _dup(`maxlength') "-" "|" _n
		}
		else {
			 file write `knot' _dup(25) "-" "|" _n
		}
		
		
		
		foreach var of varlist _all {
			local vartype: type `var'
			local lab: variable label `var'
			local lab = substr("`lab'",1,57) 
			//if substr("`vartype'",1,3)=="str" local vartype "str"
			//else if substr("`vartype'",1,5)=="float" local vartype "flt"
			//else if substr("`vartype'",1,4)=="byte" local vartype "byt"
			local varname = abbrev("`var'",12) 
			file write `knot' "| `varname'" _col(16) " | `vartype'" _col(25) " | `lab'" //_col(83) "|" _n
			if `maxlength' > 58 {
				file write `knot' _col(83) "|" _n
			}
			else if `maxlength' > 25  {
				local endpoint = `maxlength'+26
				file write `knot' _col(`endpoint') "|" _n
			}
			else {
				 file write `knot' _col(51) "|" _n
			}
		}
		file write `knot' _n
	}
	
	file write `knot' 														          ///
		"Notes" _n                                            ///
		"----- " _n(2)                                       ///
		"### Dataset" _n(2)
	
	if "`_dta[note1]'" != "" {
	  local notenum 1
		while "`_dta[note`notenum']'" != "" {
		  file write `knot' "`notenum'. `_dta[note`notenum']'" _n
			local notenum = `notenum'+1
		}
	}
	else {
	  file write `knot' "The dataset doesn't include any note" _n
	}
	file write `knot' _n
	
	// variable notes
	file write `knot' _n "### Variables" _n(2)
	
	if missing("`varnotes'") file write `knot' "The variables don't include any note" _n(2)
	else {
	  if !missing("`secondnote'") {
		  foreach var of varlist _all {
				if "``var'[note1]'" != "" {
					file write `knot' "#### `var'" _n(2)
					local notenum 1
					while "``var'[note`notenum']'" != "" {
						file write `knot' "`notenum'. ``var'[note`notenum']'" _n
						local notenum = `notenum'+1
					}
					file write `knot'  _n(2)
				}
			}
		}
	  else {
		  file write `knot'                                     ///
		  "| _Variable_   |  _Note_                                    |" _n ///
		  "|:-------------|:-------------------------------------------|" _n 
			foreach var of varlist _all {
			  if "``var'[note1]'" != "" {
				  local varname = abbrev("`var'",12) 
					local varnote = substr("``var'[note1]'",1,43)  
					file write `knot' "| `varname'" _col(16) "| `varnote'" _col(60) " |" _n
				}
			}
			file write `knot' _n
		}
	}
		
	file write `knot' 														          ///
		"Source" _n                                           ///
		"------ " _n(2)                              ///
		"Cite the source ..." _n(2)                           ///
		"References" _n                                       ///
		"---------- " _n(2)                              ///
		"Cite the references ..." _n                          ///
		"***/" _n(2)
		
	file close `knot'
	capture copy "`tmp'" "`script'", replace public
	
	confirm file "`script'"
	
	cap findfile sthlp.ado
	if _rc == 0 {
		qui sthlp `script', export(sthlp) `replace'
	
		if _rc == 0 {
			di as txt "{p}(MarkDoc created "`"{bf:{browse "`script'"}} and {bf:{browse "`name'.sthlp"}})"' 
		}
	}
	else {
	  di as txt "{p}(datadoc created "`"{bf:{browse "`script'"}})"' _n
	  di as err `"install {browse "https://github.com/haghish/markdoc":markdoc} package to generate the Stata help file from a script file"'
	}
	
	

		
end


