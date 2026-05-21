// ============================================================
// Focused SCons regression test for the frames/tests .dtas
// harness. Verifies no rebuild on a second identical run.
// Run from frames/tests with: StataMP-64.exe -e do smoke_scons_dtas_blog.do
// ============================================================

clear all
cap log close _all
do testlib.do
frames_tests_setup

local smoke_log "logs/smoke-scons-dtas-blog.smcl"
cap log using "`smoke_log'", replace name(smoke_scons_dtas_blog)
if _rc != 0 {
    di as error "Could not open `smoke_log'"
    exit _rc
}

local config_nohidden "../../tests/config_nohidden.ini"
local sconstruct_life "SConstruct-life"
local sconstruct_linked "SConstruct-linked"

capture noisily {
    which statacons 
    which complete_datasignature

    frames_tests_set_dev_src

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" -c
    _assert _rc == 0, msg("statacons -c failed")

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog.dtas
    _assert _rc == 0, msg("initial life_blog producer build failed")
    sleep 3000

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog_subset.dta
    _assert _rc == 0, msg("initial life_blog consumer build failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" -c
    _assert _rc == 0, msg("linked_project clean failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/linked_project.dtas
    _assert _rc == 0, msg("initial linked_project producer build failed")
    sleep 3000

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/person_ratio_from_dtas.dta
    _assert _rc == 0, msg("initial linked_project consumer build failed")

    confirm file "outputs/life_blog.dtas"
    confirm file "outputs/life_blog_subset.dta"
    confirm file "outputs/linked_project.dtas"
    confirm file "outputs/person_ratio_from_dtas.dta"

    store_modts outputs/life_blog.dtas, local(mod1_life_dtas)
    store_modts outputs/life_blog_subset.dta, local(mod1_life_dta)
    store_modts outputs/linked_project.dtas, local(mod1_linked_dtas)
    store_modts outputs/person_ratio_from_dtas.dta, local(mod1_ratio_dta)

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog.dtas --debug=explain
    _assert _rc == 0, msg("life_blog producer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog_subset.dta --debug=explain
    _assert _rc == 0, msg("life_blog consumer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/linked_project.dtas --debug=explain
    _assert _rc == 0, msg("linked_project producer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/person_ratio_from_dtas.dta --debug=explain
    _assert _rc == 0, msg("linked_project consumer rerun with --debug=explain failed")

    store_modts outputs/life_blog.dtas, local(mod2_life_dtas)
    store_modts outputs/life_blog_subset.dta, local(mod2_life_dta)
    store_modts outputs/linked_project.dtas, local(mod2_linked_dtas)
    store_modts outputs/person_ratio_from_dtas.dta, local(mod2_ratio_dta)

    _assert "`mod1_life_dtas'`mod1_life_dta'`mod1_linked_dtas'`mod1_ratio_dta'" == ///
        "`mod2_life_dtas'`mod2_life_dta'`mod2_linked_dtas'`mod2_ratio_dta'", ///
        msg("frames/tests SCons .dtas pipeline rebuilt on an identical rerun")

    di as result "PASS: frames/tests SCons .dtas pipeline does not rebuild on rerun"
}
local rc = _rc

cap log close smoke_scons_dtas_blog
exit `rc'
