// ============================================================
// DEV SCAFFOLD -- not part of the formal statacons_test.do suite.
// Kept in tests/ for quick standalone validation of the .dtas
// signature path during development. The corresponding asserts
// are mirrored into statacons_test.do; this file just runs them
// in isolation without the rest of the harness.
// ============================================================
// Focused regression test for .dtas signature support
// Run from C:/Users/rpguiter/Work/statacons/tests with: StataMP-64.exe -e do smoke_dtas.do

clear all
adopath ++ "../src"
cap mkdir outputs

// ============================================================
// 1. Determinism: identical content, different save times -> identical signatures
// ============================================================
clear all
sysuse auto, clear
frame put make price, into(prices)
frames save "outputs/_dtas_a.dtas", frames(default prices) replace
sleep 1500
frames save "outputs/_dtas_b.dtas", frames(default prices) replace

complete_datasignature, frameset_file("outputs/_dtas_a.dtas")
local dtas_sig_a "`r(signature)'"
complete_datasignature, frameset_file("outputs/_dtas_b.dtas")
local dtas_sig_b "`r(signature)'"

di as txt "sig_a = " as res "`dtas_sig_a'"
di as txt "sig_b = " as res "`dtas_sig_b'"
_assert "`dtas_sig_a'"=="`dtas_sig_b'", msg("determinism across re-save failed")
di as result "PASS: determinism across re-save"

// ============================================================
// 2. Mutation isolation: change one frame -> only that slot differs
// ============================================================
clear all
sysuse auto, clear
frame put make price, into(prices)
replace price = price + 1 in 1
frames save "outputs/_dtas_a.dtas", frames(default prices) replace
complete_datasignature, frameset_file("outputs/_dtas_a.dtas")
local dtas_sig_mut "`r(signature)'"

di as txt "sig_mut = " as res "`dtas_sig_mut'"
_assert "`dtas_sig_a'"!="`dtas_sig_mut'", msg("mutation should change signature")
di as result "PASS: mutation changes aggregate signature"

// inspect: only the default-frame slot should differ
tokenize `"`dtas_sig_a'"', parse("|")
local a_default "`1'"
local a_prices  "`3'"
tokenize `"`dtas_sig_mut'"', parse("|")
local m_default "`1'"
local m_prices  "`3'"
di as txt "default slot orig:    " as res "`a_default'"
di as txt "default slot mut:     " as res "`m_default'"
di as txt "prices  slot orig:    " as res "`a_prices'"
di as txt "prices  slot mut:     " as res "`m_prices'"
_assert "`a_default'"!="`m_default'", msg("default slot should differ (mutated)")
_assert "`a_prices'"=="`m_prices'", msg("prices slot should be stable (unmutated)")
di as result "PASS: mutation isolated to the changed frame"

// ============================================================
// 3. frlink_* insensitivity: re-saving a linked frameset refreshes
//    frlink_date but the .dtas signature MUST stay stable.
// ============================================================
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
local dtas_sig_link1 "`r(signature)'"
di as txt "link sig (1) = " as res "`dtas_sig_link1'"

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
local dtas_sig_link2 "`r(signature)'"
di as txt "link sig (2) = " as res "`dtas_sig_link2'"

_assert "`dtas_sig_link1'"=="`dtas_sig_link2'", msg("frlink_* characteristics leaked into signature")
di as result "PASS: frlink_* characteristics excluded from signature"

// cleanup
cap erase "outputs/_dtas_a.dtas"
cap erase "outputs/_dtas_b.dtas"
cap erase "outputs/_dtas_link.dtas"

di _newline as result "ALL .dtas SMOKE TESTS PASSED"
