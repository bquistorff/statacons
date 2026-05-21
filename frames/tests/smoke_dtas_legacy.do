// ============================================================
// Legacy/simple .dtas smoke test migrated from tests\smoke_dtas.do.
//
// This keeps the older small-data checks in frames/tests so the
// top-level tests tree no longer carries a separate branch-only
// standalone .dtas script.
// ============================================================

clear all
do testlib.do
frames_tests_setup

// ============================================================
// 1. Determinism: identical content, different save times.
// ============================================================
clear all
sysuse auto, clear
frame put make price, into(prices)
frames save "outputs/_legacy_dtas_a.dtas", frames(default prices) replace
sleep 1500
frames save "outputs/_legacy_dtas_b.dtas", frames(default prices) replace

complete_datasignature, frameset_file("outputs/_legacy_dtas_a.dtas")
local dtas_sig_a "`r(signature)'"
complete_datasignature, frameset_file("outputs/_legacy_dtas_b.dtas")
local dtas_sig_b "`r(signature)'"

_assert "`dtas_sig_a'" == "`dtas_sig_b'", ///
    msg("legacy determinism check failed across identical re-save")
di as result "PASS: legacy determinism across re-save"

// ============================================================
// 2. Mutation isolation: change one frame -> aggregate signature differs.
// ============================================================
clear all
sysuse auto, clear
frame put make price, into(prices)
replace price = price + 1 in 1
frames save "outputs/_legacy_dtas_a.dtas", frames(default prices) replace
complete_datasignature, frameset_file("outputs/_legacy_dtas_a.dtas")
local dtas_sig_mut "`r(signature)'"

_assert "`dtas_sig_a'" != "`dtas_sig_mut'", ///
    msg("legacy mutation check did not change aggregate signature")
di as result "PASS: legacy mutation changes aggregate signature"

// Only the default-frame slot should differ here.
tokenize `"`dtas_sig_a'"', parse("|")
local a_default "`1'"
local a_prices  "`3'"
tokenize `"`dtas_sig_mut'"', parse("|")
local m_default "`1'"
local m_prices  "`3'"
_assert "`a_default'" != "`m_default'", ///
    msg("legacy mutation did not affect the changed default-frame slot")
_assert "`a_prices'" == "`m_prices'", ///
    msg("legacy mutation changed the unmodified prices slot")
di as result "PASS: legacy mutation stays isolated to the changed frame"

// ============================================================
// 3. frlink_* insensitivity.
// ============================================================
clear all
sysuse auto, clear
frame put rep78 if !mi(rep78), into(quality)
frame change quality
contract rep78
gen quality_label = "rating " + string(rep78)
frame change default
frlink m:1 rep78, frame(quality)
frames save "outputs/_legacy_dtas_link.dtas", frames(default quality) replace
complete_datasignature, frameset_file("outputs/_legacy_dtas_link.dtas")
local dtas_sig_link1 "`r(signature)'"

clear all
sysuse auto, clear
frame put rep78 if !mi(rep78), into(quality)
frame change quality
contract rep78
gen quality_label = "rating " + string(rep78)
frame change default
sleep 1500
frlink m:1 rep78, frame(quality)
frames save "outputs/_legacy_dtas_link.dtas", frames(default quality) replace
complete_datasignature, frameset_file("outputs/_legacy_dtas_link.dtas")
local dtas_sig_link2 "`r(signature)'"

_assert "`dtas_sig_link1'" == "`dtas_sig_link2'", ///
    msg("legacy frlink_* characteristics leaked into the .dtas signature")
di as result "PASS: legacy frlink_* metadata is excluded from the signature"

cap erase "outputs/_legacy_dtas_a.dtas"
cap erase "outputs/_legacy_dtas_b.dtas"
cap erase "outputs/_legacy_dtas_link.dtas"

di _newline as result "ALL legacy/simple .dtas smoke tests passed"
