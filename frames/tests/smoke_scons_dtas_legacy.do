// ============================================================
// Legacy/simple SCons .dtas smoke test migrated from
// tests\smoke_scons_dtas.do.
//
// This preserves the original small producer -> .dtas -> consumer
// pipeline in frames/tests, alongside the richer blog-style SCons
// checks.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_scons_dtas_legacy.do                   (interactive)
//   StataMP-64.exe -e do smoke_scons_dtas_legacy.do (batch)
// ============================================================

clear all
cap log close _all
do testlib.do
frames_tests_setup

local smoke_log "logs/smoke-scons-dtas-legacy.smcl"
cap log using "`smoke_log'", replace name(smoke_scons_dtas_legacy)
if _rc != 0 {
    di as error "Could not open `smoke_log'"
    exit _rc
}

local config_nohidden "../../tests/config_nohidden.ini"
local sconstruct_legacy "SConstruct-legacy"

capture noisily {
    frames_tests_set_dev_src

    cap noi statacons -f "`sconstruct_legacy'" --config-files="`config_nohidden'" -c
    _assert _rc == 0, msg("legacy SCons clean failed")

    cap noi statacons -f "`sconstruct_legacy'" --config-files="`config_nohidden'" ///
        outputs/legacy_myset.dtas outputs/legacy_foreign_from_dtas.dta
    _assert _rc == 0, msg("legacy .dtas pipeline build failed")

    confirm file "outputs/legacy_myset.dtas"
    confirm file "outputs/legacy_foreign_from_dtas.dta"

    store_modts outputs/legacy_myset.dtas, local(mod1_dtas)
    store_modts outputs/legacy_foreign_from_dtas.dta, local(mod1_dta)

    cap noi statacons -f "`sconstruct_legacy'" --config-files="`config_nohidden'" ///
        outputs/legacy_myset.dtas outputs/legacy_foreign_from_dtas.dta --debug=explain
    _assert _rc == 0, msg("legacy .dtas pipeline rerun failed")

    store_modts outputs/legacy_myset.dtas, local(mod2_dtas)
    store_modts outputs/legacy_foreign_from_dtas.dta, local(mod2_dta)

    _assert "`mod1_dtas'`mod1_dta'" == "`mod2_dtas'`mod2_dta'", ///
        msg("legacy .dtas pipeline rebuilt on an identical rerun")
    di as result "PASS: legacy/simple .dtas pipeline does not rebuild on rerun"
}
local rc = _rc

cap log close smoke_scons_dtas_legacy
exit `rc'
