* Allows checking additionally the meta-data and allows writing to file.
* fast = faster algo, and machine depedent.
* nometa = no meta-data (just normal datasig)
* vv_labels_only = for meta-data, just use variable and value labels
program complete_datasignature, rclass
syntax, [dta_file(string) fname(string) nometa fast vv_labels_only]
if "`dta_file'"!="" qui use "`dta_file'"
//datasignature set, saving("`fname'", replace) //sig file has weird format with other stuff
//datasignature
qui _datasignature, `fast' 
loc datasig =  r(datasignature)
if "`meta'"!="nometa" {
    //can't use log because that has timestamp, so write out to file
    tempfile meta_fname
    qui file open meta_handle using "`meta_fname'", write text replace
    
    //value labels. Do seprately from vars as some might not be attached to variables and some might be attached to multiple
    qui label dir
    loc val_labels `r(names)' 
    foreach vl_name in `val_labels' {
        file write meta_handle "`vl_name'" _newline
        loc vl_len : label `vl_name' maxlength
        file write meta_handle "`vl_len'" _newline
        forv i = 1/`vl_len' {
            file write meta_handle "`i': `: label `vl_name' `i', strict'" _newline //strict means if no value return "" rather than `i'
        }
    }

    //variable formats, labels, and value label attachments
    foreach v of varlist * {
        file write meta_handle "`v'" _newline
        file write meta_handle "`: format `v''" _newline
        file write meta_handle "`: variable label `v''" _newline
        file write meta_handle "`: value label `v''" _newline
    }
    
    if "`vv_labels_only'"=="vv_labels_only" {
        //don't use describe as that prints timestamp
        file write meta_handle "`: data label'" _newline

        //chars: includes notes
        //can't use -char dir- as it only prints to screen
        unab vlist : *
        loc evlist _dta `vlist'
        foreach ev in `evlist' {
            file write meta_handle "`ev'" _newline
            loc c_list : char `ev'[]
            foreach c in `c_list' {
                file write meta_handle "`c': `: char `ev'[`c']'" _newline
            }
        }
    }
    
    file close meta_handle
    qui checksum "`meta_fname'"
    loc meta_sig ":`r(checksum)'"
}

if "`fname'"!="" {
    file open sig_handle using "`fname'", write text replace
    file write sig_handle "`datasig'`meta_sig'"
    file close sig_handle
}
di "`datasig'`meta_sig'"
return local signature "`datasig'`meta_sig'"
end
