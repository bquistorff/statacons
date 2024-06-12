*! version 3.0.3  June 12 2024  statacons team
* Copyright 2023. This work is licensed under a CC BY 4.0 license.
version 16.1

// markdown source for help file is embedded below code
// .sthlp compiled using markdown

program complete_datasignature, rclass
* sometimes due to weird shell issues we have loc 0 as (even when we don't quote the filename: 
* , "dta_file(file name with space)"
loc 0 : subinstr local 0 `", "dta"' ", dta"
loc 0 : subinstr local 0 `")""' ")"
syntax, [dta_file(string) fname(string) nometa fast labels_formats_only]
if "`dta_file'"!="" qui use "`dta_file'"
//datasignature set, saving("`fname'", replace) //sig file has weird format with other stuff
//datasignature
qui _datasignature, `fast'
loc datasig =  r(datasignature)
if "`meta'"!="nometa" {
    //can't use log because that has timestamp, so write out to file
    tempfile meta_fname
	*loc meta_fname meta_fname
    tempname meta_handle
    qui file open `meta_handle' using "`meta_fname'", write text replace

    //value labels. Do seprately from vars as some might not be attached to variables and some might be attached to multiple
    qui label dir
    loc val_labels `r(names)'
    foreach vl_name in `val_labels' {
        file write `meta_handle' "`vl_name'" _newline
        loc vl_len : label `vl_name' maxlength
        file write `meta_handle' "`vl_len'" _newline
        forv i = 1/`vl_len' {
            file write `meta_handle' `"`i': `: label `vl_name' `i', strict'"' _newline //strict means if no value return "" rather than `i'
        }
    }

    //variable formats, labels, and value label attachments
    foreach v of varlist * {
        file write `meta_handle' "`v'" _newline
        file write `meta_handle' "`: format `v''" _newline
        file write `meta_handle' `"`: variable label `v''"' _newline
        file write `meta_handle' "`: value label `v''" _newline
    }

    if "`labels_formats_only'"=="" {
        //don't use describe as that prints timestamp
        file write `meta_handle' `"`: data label'"' _newline

        //chars: includes notes
        //can't use -char dir- as it only prints to screen
        unab vlist : *
        loc evlist _dta `vlist'
        foreach ev in `evlist' {
            file write `meta_handle' "`ev'" _newline
            loc c_list : char `ev'[]
            foreach c in `: list sort c_list' {
                file write `meta_handle' `"`c': `: char `ev'[`c']'"' _newline
            }
        }
    }
    
    //could add the sortlist: -describe, varlist; r(sortlist)-

    file close `meta_handle'
    qui checksum "`meta_fname'"
    loc meta_sig ":`r(checksum)'"
}

if "`fname'"!="" {
    tempname sig_handle
    file open `sig_handle' using "`fname'", write text replace
    file write `sig_handle' "`datasig'`meta_sig'"
    file close `sig_handle'
}
di "`datasig'`meta_sig'"
return local signature "`datasig'`meta_sig'"
end


// complete_datasignature.sthlp markdown code follows
// converted to .sthlp by markdoc
// markdoc complete_datasignature.ado, export(sthlp) replace mini
// see buildHelpFiles.do


/***

_version 3.0.3_

complete_datasignature
======

__complete_datasignature__ creates a signature for a Stata .dta-file that does __not__ depend on the embedded timestamp but __does__ depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

__complete_datasignature__ extends Stata's __datasignature__ by allowing the inclusion of different sets of metadata.


Syntax
------

> complete_datasignature [, dta_file("file.dta") fname("sigfile.ext") nometa fast labels_formats_only]


By default, __complete_datasignature__ will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

### Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| dta_file("file.dta")           | Use  "file.dta"  instead of dta-file in memory       |
| fname("sigfile.ext")           | write signature to "sigfile.ext"     |
| nometa                     | Do not include any metadata -- equivalent of Stata's __datasignature__          |
| labels_formats_only             | Include variable formats, variable and value labels               |
| fast          | use ___datasignature__ in _fast_ mode -- faster but not machine-independent                       |



Example(s)
----------


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




Stored results
----------------

__r(signature)__    signature calculated by __complete_datasignature__

Author
------

__statacons__ team
[https://github.com/bquistorff/statacons](https://github.com/bquistorff/statacons)


- - -

This help file was dynamically produced by
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/)

***/
