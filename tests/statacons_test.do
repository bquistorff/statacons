* This tests statacons from inside Stata. Tests that require looking at the output are marked with MANUAL

* To do:
* - How to get stata_exe config?

cap log close _all
log using statacons_test.int.log, name(statacons_test) replace

*************************** Setup ***************************
doenv using "../.env"
loc py_env "`r(python_env)'"
if "`py_env'"!="`c(python_exec)'" {
	set python_exec "`r(python_env)'"
}
if substr(`"$S_ADO"',3,6)!="../src" {
	adopath ++ "`c(pwd)'/../src"
}

cap program drop store_modts
program store_modts
	syntax anything, local(string)
	
	filesys `c(pwd)'/`anything', attr
	c_local `local' "`r(modifiednum)'"
end

cap program drop write_txt
program write_txt
	syntax anything, fname(string)
	
	file open hand using "`fname'", write text replace
	file write hand "`anything'"
	file close hand
end

cap program drop touch_dta
program touch_dta
	syntax anything
	
	preserve
	use `anything', clear
	save `anything', replace
end

*************************** Test output ***************************
*MANUAL: make sure these are different
sysuse auto, clear
complete_datasignature
complete_datasignature, nometa
complete_datasignature, fast
complete_datasignature, labels_formats_only


*************************** Test output ***************************
*MANUAL look at all of these
* Test info
statacons --show-config
statacons --help
statacons --tree=status,prune
stataconsign

* Test silent
statacons -c
statacons --silent

*************************** Test correctness ***************************
*Test that running twice doesn't re-run anything. test debug=explain
statacons -c
statacons
store_modts outputs/auto-modified.dta, local(mod1a)
store_modts outputs/auto-modified2.dta, local(mod1b)
statacons --debug=explain
store_modts outputs/auto-modified.dta, local(mod2a)
store_modts outputs/auto-modified2.dta, local(mod2b)
_assert "`mod1a'`mod1b'"=="`mod2a'`mod2b'", msg("Re-ran something'")

*Test early stopping
statacons -c
statacons
store_modts outputs/auto-modified2.dta, local(mod1)
rm outputs/auto-modified.dta //to rebuild the first step
statacons
store_modts outputs/auto-modified2.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Didn't do early stopping")
*MANUAL: Check that dta sig was called in second run 

*************************** Test options ***************************
*Test assume-built (easier to test these with timestamp Decider).
* Alternatively could delete the sconsdb file and then re-run.
statacons -f SConstruct-timestamp -c
statacons -f SConstruct-timestamp
touch_dta outputs/auto-modified.dta
//statacons -f SConstruct-timestamp //rebuilds
statacons -f SConstruct-timestamp --assume-done="code/analysis.do" //will touch output
//MANUAL: check output that the previous didn't actually rebuild anything

store_modts outputs/auto-modified2.dta, local(mod2)
statacons -f SConstruct-timestamp
store_modts outputs/auto-modified2.dta, local(mod3)
_assert "`mod2'"=="`mod3'", msg("Rebuilt something")
*Test assume-done
touch_dta outputs/auto-modified.dta
statacons -f SConstruct-timestamp --debug=explain --assume-built="outputs/auto-modified2.dta" //will touch output
//MANUAL: check output that the previous didn't actually rebuild anything

store_modts outputs/auto-modified2.dta, local(mod2)
statacons -f SConstruct-timestamp --debug=explain
store_modts outputs/auto-modified2.dta, local(mod3)
_assert "`mod2'"=="`mod3'", msg("Rebuilt something")
*Test skip newer1
write_txt 1, fname("inputs/simple-input.txt")
statacons -f SConstruct-content-then-newer
write_txt 2, fname("inputs/simple-input.txt")
do code/dataprep.do
store_modts outputs/auto-modified.dta, local(mod1)
statacons -f SConstruct-content-then-newer
store_modts outputs/auto-modified.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Accidentally rebuilt")
*Test skip newer2
write_txt 1, fname("inputs/simple-input.txt")
statacons -f SConstruct-content-then-newer2
write_txt 2, fname("inputs/simple-input.txt")
do code/dataprep.do
store_modts outputs/auto-modified.dta, local(mod1)
statacons -f SConstruct-content-then-newer2
store_modts outputs/auto-modified.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Accidentally rebuilt")


* Test alternate cwd's for Stata
statacons outputs/auto-modified-cwd_abs.dta --config-files=config_cwd_abs.ini
statacons outputs/auto-modified-cwd_source.dta --config-files=config_cwd_source.ini

statacons -c
statacons outputs/auto-modified.dta --config-files=config_dta_mod_slow.ini

* Test other sig types
* MANUAL: make sure the output changes appropriately
statacons outputs/auto-modified.dta --config-files=config_datasignature_DataOnly.ini
statacons outputs/auto-modified.dta --config-files=config_datasignature_False.ini
statacons outputs/auto-modified.dta --config-files=config_datasignature_VV.ini

*Test 
statacons -c
statacons outputs/auto-modified.dta --config-files=config_success_log_dir.ini
rm dataprep.log

* Test escapes
cap rm outputs/auto-modified-escape.dta
statacons outputs/auto-modified-escape.dta
store_modts outputs/auto-modified-escape.dta, local(mod1)
statacons outputs/auto-modified-escape.dta
store_modts outputs/auto-modified-escape.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Accidentally rebuilt")

*************************** Test Stata-style syntax ***************************
statacons, help
statacons, show_config
statacons, clean file(SConstruct)
statacons outputs/auto-modified.dta
statacons, clean
statacons "outputs/auto-modified.dta"
statacons, clean
statacons, dry_run
statacons, q tree(all)
statacons, clean
statacons, debug(explain) sconstruct("SConstruct") config_files("config_success_log_dir.ini")
statacons, assume_done("*.do")
statacons, assume_built("*.dta")
* TODO currently don't test: cache_debug(string asis) cache_disable cache_force cache_readonly cache_show


*************************** Test errors ***************************
* Test errors stopping. Make sure the logs come the right place
cap noi statacons outputs/error.pdf
_assert _rc==7103, msg("Expected error")
rm error.log
cap noi statacons outputs/error.pdf --config-files=config_cwd_abs.ini
_assert _rc==7103, msg("Expected error")
rm error.log
cap noi statacons outputs/error.pdf --config-files=config_cwd_source.ini
_assert _rc==7103, msg("Expected error")
rm error.log

*************************** Test cachedir ***************************
cd test_cachedir
cd projCopy1
statacons
cd ../projCopy2
statacons -c
statacons
* MANUAL: check output that everything retrieved from cachedir
cd ../..

*************************** End ***************************
log close _all
