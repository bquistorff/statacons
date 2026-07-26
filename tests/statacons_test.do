* This tests statacons from inside Stata. Tests that require looking at the output are marked with MANUAL
* All paths are relative to the assumed working directory: tests/
* Run from tests/ with:
*   do statacons_test.do                        (interactive)
*   StataMP-64.exe -e do statacons_test.do      (batch)

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


*************************** Test output ***************************
sysuse auto, clear
complete_datasignature
loc r1 = "`r(signature)''"
complete_datasignature, nometa
loc r2 = "`r(signature)''"
complete_datasignature, fast
loc r3 = "`r(signature)''"
complete_datasignature, labels_formats_only
loc r4 = "`r(signature)''"
_assert "`r1'"!="`r2'", msg("Should be different")
_assert "`r1'"!="`r3'", msg("Should be different")
_assert "`r1'"!="`r4'", msg("Should be different")
_assert "`r2'"!="`r3'", msg("Should be different")
_assert "`r2'"!="`r4'", msg("Should be different")
_assert "`r3'"!="`r4'", msg("Should be different")


*************************** Test .dtas signature: determinism, mutation, frlink ***************************
* 1. Determinism: identical content saved at different times -> identical signatures
clear all
sysuse auto, clear
frame put make price, into(prices)
frames save "outputs/_dtas_a.dtas", frames(default prices) replace
sleep 1500
frames save "outputs/_dtas_b.dtas", frames(default prices) replace
complete_datasignature, frameset_file("outputs/_dtas_a.dtas")
loc dtas_sig_a "`r(signature)'"
complete_datasignature, frameset_file("outputs/_dtas_b.dtas")
loc dtas_sig_b "`r(signature)'"
_assert "`dtas_sig_a'"=="`dtas_sig_b'", msg(".dtas signature changed on re-save with identical content")

* 2. Mutation isolation: change one frame -> aggregate signature differs
clear all
sysuse auto, clear
frame put make price, into(prices)
replace price = price + 1 in 1
frames save "outputs/_dtas_a.dtas", frames(default prices) replace
complete_datasignature, frameset_file("outputs/_dtas_a.dtas")
loc dtas_sig_mut "`r(signature)'"
_assert "`dtas_sig_a'"!="`dtas_sig_mut'", msg("Mutating a frame didn't change .dtas signature")

* 3. frlink_* insensitivity: re-saving a linked frameset refreshes frlink_date
*    in the link variable's characteristics; the .dtas signature MUST stay stable.
clear all
sysuse auto, clear
frame put rep78 if !mi(rep78), into(quality)
frame change quality
contract rep78
gen quality_label = "rating " + string(rep78)
frame change default
frlink m:1 rep78, frame(quality)
frames save "outputs/_dtas_link.dtas", frames(default quality) replace
complete_datasignature, frameset_file("outputs/_dtas_link.dtas")
loc dtas_sig_link1 "`r(signature)'"

clear all
sysuse auto, clear
frame put rep78 if !mi(rep78), into(quality)
frame change quality
contract rep78
gen quality_label = "rating " + string(rep78)
frame change default
sleep 1500
frlink m:1 rep78, frame(quality)
frames save "outputs/_dtas_link.dtas", frames(default quality) replace
complete_datasignature, frameset_file("outputs/_dtas_link.dtas")
loc dtas_sig_link2 "`r(signature)'"
_assert "`dtas_sig_link1'"=="`dtas_sig_link2'", msg("frlink_* characteristics leaked into .dtas signature")

cap erase "outputs/_dtas_a.dtas"
cap erase "outputs/_dtas_b.dtas"
cap erase "outputs/_dtas_link.dtas"


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
store_modts output space/auto-modified.dta, local(mod1a)
store_modts outputs/auto-modified2.dta, local(mod1b)
statacons --debug=explain
store_modts output space/auto-modified.dta, local(mod2a)
store_modts outputs/auto-modified2.dta, local(mod2b)
di "`mod1a'.`mod1b'==`mod2a'`mod2b'"
_assert "`mod1a'`mod1b'"=="`mod2a'`mod2b'", msg("Re-ran something'")

* Try without pywin32
statacons -c
statacons --config-files=config_nohidden.ini
store_modts output space/auto-modified.dta, local(mod1a)
store_modts outputs/auto-modified2.dta, local(mod1b)
statacons --config-files=config_nohidden.ini
store_modts output space/auto-modified.dta, local(mod2a)
store_modts outputs/auto-modified2.dta, local(mod2b)
di "`mod1a'.`mod1b'==`mod2a'`mod2b'"
_assert "`mod1a'`mod1b'"=="`mod2a'`mod2b'", msg("Re-ran something'")

*Test early stopping
statacons -c
statacons
store_modts outputs/auto-modified2.dta, local(mod1)
rm "output space/auto-modified.dta" //to rebuild the first step
statacons
store_modts outputs/auto-modified2.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Didn't do early stopping")
*MANUAL: Check that dta sig was called in second run

*Test .dtas signature in SCons: build a frameset pipeline, then re-run -> no rebuild
* When running against the dev tree (editable pystatacons install), point statacons
* at the dev .ado source so signature recipes find our complete_datasignature.ado
* (the released version installed in plus/ predates the frameset_file() option).
local dev_src "`c(pwd)'/../src"
python: import os; os.environ['STATACONS_DEV_SRC'] = r"`dev_src'"
statacons -c
statacons outputs/myset.dtas outputs/foreign_from_dtas.dta
store_modts outputs/myset.dtas, local(mod1_dtas)
store_modts outputs/foreign_from_dtas.dta, local(mod1_dta)
statacons outputs/myset.dtas outputs/foreign_from_dtas.dta --debug=explain
store_modts outputs/myset.dtas, local(mod2_dtas)
store_modts outputs/foreign_from_dtas.dta, local(mod2_dta)
_assert "`mod1_dtas'`mod1_dta'"=="`mod2_dtas'`mod2_dta'", msg("Re-ran .dtas pipeline despite no input change")

*************************** Test options ***************************
*Test assume-built (easier to test these with timestamp Decider).
* Alternatively could delete the sconsdb file and then re-run.
statacons -f SConstruct-timestamp -c
statacons -f SConstruct-timestamp
touch_dta "output space/auto-modified.dta"
//statacons -f SConstruct-timestamp //rebuilds
statacons -f SConstruct-timestamp --assume-done="code/analysis.do" //will touch output
//MANUAL: check output that the previous didn't actually rebuild anything

store_modts outputs/auto-modified2.dta, local(mod2)
statacons -f SConstruct-timestamp
store_modts outputs/auto-modified2.dta, local(mod3)
_assert "`mod2'"=="`mod3'", msg("Rebuilt something")
*Test assume-done
touch_dta "output space/auto-modified.dta"
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
store_modts output space/auto-modified.dta, local(mod1)
statacons -f SConstruct-content-then-newer --debug=explain
store_modts output space/auto-modified.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Accidentally rebuilt")
*Test skip newer2
write_txt 1, fname("inputs/simple-input.txt")
statacons -f SConstruct-content-then-newer2
write_txt 2, fname("inputs/simple-input.txt")
do code/dataprep.do
store_modts output space/auto-modified.dta, local(mod1)
statacons -f SConstruct-content-then-newer2
store_modts output space/auto-modified.dta, local(mod2)
_assert "`mod1'"=="`mod2'", msg("Accidentally rebuilt")


* Test alternate cwd's for Stata
statacons outputs/auto-modified-cwd_abs.dta --config-files=config_cwd_abs.ini
statacons outputs/auto-modified-cwd_source.dta --config-files=config_cwd_source.ini

statacons -c
statacons "output space/auto-modified.dta" --config-files=config_dta_mod_slow.ini

* Test other sig types
* MANUAL: make sure the output changes appropriately
statacons "output space/auto-modified.dta" --config-files=config_datasignature_DataOnly.ini
statacons "output space/auto-modified.dta" --config-files=config_datasignature_False.ini
statacons "output space/auto-modified.dta" --config-files=config_datasignature_VV.ini

*Test 
statacons -c
statacons "output space/auto-modified.dta" --config-files=config_success_log_dir.ini
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
statacons "output space/auto-modified.dta"
statacons, clean
statacons outputs/auto-modified2.dta
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
