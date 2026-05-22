*! version 3.1.0-alpha1  22 May 2026  statacons team
* Copyright 2023. This work is licensed under a CC BY 4.0 license.
version 16.1

// markdown source for help file is embedded below code
// .sthlp compiled using markdown

program complete_datasignature, rclass
* sometimes due to weird shell issues we have loc 0 as (even when we don't quote the filename:
* , "dta_file(file name with space)"
loc 0 : subinstr local 0 `", "dta"' ", dta"
loc 0 : subinstr local 0 `")""' ")"
syntax, [dta_file(string) frameset_file(string) fname(string) nometa fast labels_formats_only skip_char(string)]

if "`frameset_file'" != "" {
    // frameset (.dtas) path: sign each frame in the archive and concatenate.
    // In interactive mode, round-trip the user's frames via a temp .dtas so memory
    // is restored on exit. In batch mode, skip the round-trip for speed.
    loc is_batch = ("`c(mode)'" == "batch")
    loc need_restore = 0
    tempfile tempdtas_base
    loc tempdtas "`tempdtas_base'.dtas"

    if !`is_batch' {
        qui frames save "`tempdtas'", frames(_all) replace emptyok
        loc need_restore = 1
    }

    qui frames use "`frameset_file'", clear
    loc fnames "`r(frames)'"

    // Inner per-frame calls always drop frlink_* chars (they carry a timestamp via
    // frlink_date). User-supplied skip_char patterns are appended.
    loc inner_skip "frlink_*"
    if `"`skip_char'"' != "" loc inner_skip "`inner_skip' `skip_char'"

    loc agg ""
    loc sep ""
    foreach f in `: list sort fnames' {
        qui frame change `f'
        qui complete_datasignature, `meta' `fast' `labels_formats_only' skip_char(`"`inner_skip'"')
        loc agg "`agg'`sep'`f'=`r(signature)'"
        loc sep "|"
    }

    if `need_restore' {
        qui frames use "`tempdtas'", clear
        cap erase "`tempdtas'"
    }

    if "`fname'" != "" {
        tempname sig_handle
        file open `sig_handle' using "`fname'", write text replace
        file write `sig_handle' "`agg'"
        file close `sig_handle'
    }
    di "`agg'"
    return local signature "`agg'"
    exit
}

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

    // tolerate empty data (e.g., a .dtas containing an empty frame)
    cap unab vlist : *
    if _rc loc vlist ""
    //value labels. Do seprately from vars as some might not be attached to variables and some might be attached to multiple
    qui label dir
    loc val_labels `r(names)'
    foreach vl_name in `: list sort val_labels' {
        file write `meta_handle' "`vl_name'" _newline
        loc vl_len : label `vl_name' maxlength
        file write `meta_handle' "`vl_len'" _newline
        forv i = 1/`vl_len' {
            file write `meta_handle' `"`i': `: label `vl_name' `i', strict'"' _newline //strict means if no value return "" rather than `i'
        }
    }

    //variable formats, labels, and value label attachments
    foreach v in `: list sort vlist' {
        file write `meta_handle' "`v'" _newline
        file write `meta_handle' "`: format `v''" _newline
        file write `meta_handle' `"`: variable label `v''"' _newline
        file write `meta_handle' "`: value label `v''" _newline
    }

    if "`labels_formats_only'"=="" {
        //don't use describe as that prints timestamp
        file write `meta_handle' `"`: data label'"' _newline

        //chars: includes notes. skip_char is a globlist of patterns to drop
        //(used by the frameset path to skip frlink_* chars whose frlink_date
        //is time-tainted).
        //can't use -char dir- as it only prints to screen
        loc evlist _dta `vlist'
        foreach ev in `: list sort evlist' {
            file write `meta_handle' "`ev'" _newline
            loc c_list : char `ev'[]
            foreach c in `: list sort c_list' {
                loc skip_this 0
                foreach pat in `skip_char' {
                    if strmatch("`c'", "`pat'") loc skip_this 1
                }
                if !`skip_this' file write `meta_handle' `"`c': `: char `ev'[`c']'"' _newline
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

_version 3.1.0-alpha1_

complete_datasignature
======

__complete_datasignature__ creates a signature for a Stata .dta-file or .dtas frameset that does __not__ depend on the embedded timestamp but __does__ depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

__complete_datasignature__ extends Stata's __datasignature__ by allowing the inclusion of different sets of metadata. When called with __frameset_file__, it signs every frame in a __.dtas__ frameset and returns a concatenation keyed by frame name.


Syntax
------

> complete_datasignature [, dta_file("file.dta") frameset_file("file.dtas") fname("sigfile.ext") nometa fast labels_formats_only skip_char("globlist")]


By default, __complete_datasignature__ will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

### Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| dta_file("file.dta")           | Use  "file.dta"  instead of dta-file in memory       |
| frameset_file("file.dtas")     | Sign a __.dtas__ frameset; iterate frames alphabetically and return "frameA=sigA|frameB=sigB|..." |
| fname("sigfile.ext")           | write signature to "sigfile.ext"     |
| nometa                     | Do not include any metadata -- equivalent of Stata's __datasignature__          |
| labels_formats_only             | Include variable formats, variable and value labels               |
| fast          | use ___datasignature__ in _fast_ mode -- faster but not machine-independent                       |
| skip_char("globlist")     | Skip variable/dataset characteristics whose names match any pattern in the space-separated globlist. The __frameset_file__ path always adds __frlink_*__ to this list. |


### Behavior of __frameset_file__

When __frameset_file__ is set, the program:

1. In interactive mode (__c(mode)__ is empty), saves all in-memory frames to a temporary __.dtas__ so user state can be restored on exit. In batch mode, this round-trip is skipped.
2. Loads the target __.dtas__ via __frames use, clear__.
3. For each frame in alphabetical order, computes a per-frame signature using the same metadata options (__nometa__, __fast__, __labels_formats_only__) plus __skip_char("frlink_*")__.
4. Assembles "frameA=sigA|frameB=sigB|...".
5. In interactive mode, restores the user's frames from the temporary __.dtas__.

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

        . complete_datasignature, frameset_file("myframeset.dtas")
    census=74:12(71728):...|housing=50:12(...):...




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
