// ============================================================
// Focused SCons regression test for the frames/tests .dtas
// harness.
//
// What this file tests:
// 1. statacons can build the blog-style .dtas producer and
//    consumer pipelines end to end.
// 2. A second identical statacons invocation is a true no-op:
//    the output files are left untouched rather than rebuilt.
//
// What failures mean:
// - a producer-build failure means statacons could not sign or
//   build the upstream .dtas target.
// - a consumer-build failure means statacons could build the
//   .dtas but could not consume it correctly downstream.
// - the final timestamp-comparison failure means an identical
//   rerun rebuilt at least one output when it should not have.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_scons_dtas_blog.do                     (interactive)
//   StataMP-64.exe -e do smoke_scons_dtas_blog.do   (batch)
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

    // Start from a clean tree so later no-rebuild checks are about
    // the second run only, not leftover outputs from earlier runs.
    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" -c
    _assert _rc == 0, msg("statacons -c failed")

    // Producer target: build the frameset itself.
    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog.dtas
    _assert _rc == 0, msg("initial life_blog producer build failed")
    sleep 3000

    // Consumer target: reopen the built frameset and save a derived .dta.
    // If this fails, .dtas consumption inside the pipeline is broken.
    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog_subset.dta
    _assert _rc == 0, msg("initial life_blog consumer build failed")

    // Repeat the same clean -> build -> consume pattern for the linked
    // frames workflow that uses frlink/fralias-style state.
    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" -c
    _assert _rc == 0, msg("linked_project clean failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/linked_project.dtas
    _assert _rc == 0, msg("initial linked_project producer build failed")
    sleep 3000

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/person_ratio_from_dtas.dta
    _assert _rc == 0, msg("initial linked_project consumer build failed")

    // These confirms distinguish "statacons exited 0" from "the target
    // file we expected was actually produced on disk".
    confirm file "outputs/life_blog.dtas"
    confirm file "outputs/life_blog_subset.dta"
    confirm file "outputs/linked_project.dtas"
    confirm file "outputs/person_ratio_from_dtas.dta"

    // Capture output mtimes after the first successful build.
    // The rerun below should leave all four mtimes unchanged.
    store_modts outputs/life_blog.dtas, local(mod1_life_dtas)
    store_modts outputs/life_blog_subset.dta, local(mod1_life_dta)
    store_modts outputs/linked_project.dtas, local(mod1_linked_dtas)
    store_modts outputs/person_ratio_from_dtas.dta, local(mod1_ratio_dta)

    // Rerun the exact same targets with no input changes. --debug=explain
    // helps show why statacons thinks a target is or is not dirty.
    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog.dtas --debug=explain
    _assert _rc == 0, msg("life_blog producer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_life'" --config-files="`config_nohidden'" outputs/life_blog_subset.dta --debug=explain
    _assert _rc == 0, msg("life_blog consumer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/linked_project.dtas --debug=explain
    _assert _rc == 0, msg("linked_project producer rerun with --debug=explain failed")

    cap noi statacons -f "`sconstruct_linked'" --config-files="`config_nohidden'" outputs/person_ratio_from_dtas.dta --debug=explain
    _assert _rc == 0, msg("linked_project consumer rerun with --debug=explain failed")

    // Capture mtimes again after the identical rerun.
    store_modts outputs/life_blog.dtas, local(mod2_life_dtas)
    store_modts outputs/life_blog_subset.dta, local(mod2_life_dta)
    store_modts outputs/linked_project.dtas, local(mod2_linked_dtas)
    store_modts outputs/person_ratio_from_dtas.dta, local(mod2_ratio_dta)

    // This is a no-rebuild check, not a signature-order check.
    // If it fails, at least one target was rewritten on rerun, meaning
    // statacons treated an unchanged pipeline as dirty.
    _assert "`mod1_life_dtas'`mod1_life_dta'`mod1_linked_dtas'`mod1_ratio_dta'" == ///
        "`mod2_life_dtas'`mod2_life_dta'`mod2_linked_dtas'`mod2_ratio_dta'", ///
        msg("frames/tests SCons .dtas pipeline rebuilt on an identical rerun")

    di as result "PASS: frames/tests SCons .dtas pipeline does not rebuild on rerun"
}
local rc = _rc

cap log close smoke_scons_dtas_blog
exit `rc'
