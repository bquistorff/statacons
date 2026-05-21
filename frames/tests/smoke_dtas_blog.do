// ============================================================
// Focused regression tests for .dtas support using official
// Stata frames workflows and shipped or vendored datasets.
//
// What this file tests:
// - compression-only changes should not affect a .dtas signature
// - adding or dropping frames should affect the aggregate signature
// - mutating one frame should only change that frame's signature slot
// - linked and alias-heavy workflows should be stable across
//   identical rebuilds
// - frame save order is recorded as a diagnostic, because whether it
//   should affect the signature is an implementation choice
//
// In general, a failure means either statacons is missing a real
// content change, or it is treating irrelevant container changes as
// meaningful data changes.
//
// Run from frames/tests with: StataMP-64.exe -e do smoke_dtas_blog.do
// ============================================================

clear all
do testlib.do
frames_tests_setup

// ============================================================
// 1. Compression invariance using the 2023 blog frameset flow.
//    Same frame content, different zip compression -> same sig.
//    A failure here means we are hashing zip/container details rather
//    than just the frame contents that statacons should track.
// ============================================================
clear all
frame create life0
frame create life1
frame create life2
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frame life2: sysuse uslifeexp2, clear

frames save "outputs/_life_default.dtas", frames(life0 life1 life2) replace
frames save "outputs/_life_store.dtas", frames(life0 life1 life2) complevel(0) replace
frames save "outputs/_life_max.dtas", frames(life0 life1 life2) complevel(9) replace

complete_datasignature, frameset_file("outputs/_life_default.dtas")
local sig_default "`r(signature)'"
complete_datasignature, frameset_file("outputs/_life_store.dtas")
local sig_store "`r(signature)'"
complete_datasignature, frameset_file("outputs/_life_max.dtas")
local sig_max "`r(signature)'"

_assert "`sig_default'" == "`sig_store'", msg("compression level 0 changed .dtas signature")
_assert "`sig_default'" == "`sig_max'", msg("compression level 9 changed .dtas signature")
di as result "PASS: compression-only changes do not affect .dtas signatures"

// ============================================================
// 2. Frameset topology changes are visible.
//    Adding or dropping a frame must change the signature.
//    A failure here means the aggregate signature is not sensitive to
//    frame membership, so statacons could miss true dependency changes.
// ============================================================
clear all
frame create life0
frame create life1
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear

frames save "outputs/_life_topology.dtas", frames(life0 life1) replace
complete_datasignature, frameset_file("outputs/_life_topology.dtas")
local sig_two "`r(signature)'"

frame create life2
frame life2: sysuse uslifeexp2, clear
frames modify using "outputs/_life_topology.dtas", add(life2)
complete_datasignature, frameset_file("outputs/_life_topology.dtas")
local sig_three "`r(signature)'"

frames modify using "outputs/_life_topology.dtas", drop(life1)
complete_datasignature, frameset_file("outputs/_life_topology.dtas")
local sig_drop "`r(signature)'"

_assert "`sig_two'" != "`sig_three'", msg("adding a frame did not change .dtas signature")
_assert "`sig_three'" != "`sig_drop'", msg("dropping a frame did not change .dtas signature")
_assert "`sig_two'" != "`sig_drop'", msg("different frame sets produced the same signature")
di as result "PASS: frame add/drop operations change the aggregate signature"

// ============================================================
// 3. Per-frame isolation with 3 frames.
//    Mutating only life1 should change only the middle slot.
//    A failure in slot 1 or slot 3 means unrelated frames are being
//    dirtied. A failure in slot 2 means the changed frame was not
//    reflected in the signature at all.
// ============================================================
clear all
frame create life0
frame create life1
frame create life2
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frame life2: sysuse uslifeexp2, clear

frames save "outputs/_life_slots_a.dtas", frames(life0 life1 life2) replace

frame life1: gen slot_probe = _n
frames save "outputs/_life_slots_b.dtas", frames(life0 life1 life2) replace

complete_datasignature, frameset_file("outputs/_life_slots_a.dtas")
local sig_slots_a "`r(signature)'"
complete_datasignature, frameset_file("outputs/_life_slots_b.dtas")
local sig_slots_b "`r(signature)'"

local sig_slots_a_tokens : subinstr local sig_slots_a "|" " ", all
local sig_slots_b_tokens : subinstr local sig_slots_b "|" " ", all
tokenize `"`sig_slots_a_tokens'"'
local a1 "`1'"
local a2 "`2'"
local a3 "`3'"
tokenize `"`sig_slots_b_tokens'"'
local b1 "`1'"
local b2 "`2'"
local b3 "`3'"

_assert "`a1'" == "`b1'", msg("life0 slot changed despite no mutation")
_assert "`a2'" != "`b2'", msg("life1 slot did not change after mutation")
_assert "`a3'" == "`b3'", msg("life2 slot changed despite no mutation")
di as result "PASS: only the mutated frame slot changes"

// ============================================================
// 4. Linked-save stability using the 2023 linked frameset flow.
//    This checks that reconstructing the same linked workflow twice
//    yields the same .dtas signature. A failure means volatile linked
//    metadata is leaking into the signature.
// ============================================================
clear all
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
frames save "outputs/_linked_a.dtas", frames(default) linked replace
complete_datasignature, frameset_file("outputs/_linked_a.dtas")
local linked_sig_a "`r(signature)'"

clear all
sleep 1500
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
frames save "outputs/_linked_b.dtas", frames(default) linked replace
complete_datasignature, frameset_file("outputs/_linked_b.dtas")
local linked_sig_b "`r(signature)'"

_assert "`linked_sig_a'" == "`linked_sig_b'", ///
    msg("linked frameset signature changed across identical relink and re-save")
di as result "PASS: linked framesets stay stable across identical relink and re-save"

// ============================================================
// 5. Alias-variable workflow stability from the 2023 blog post.
//    This is the alias-heavy analogue of test 4. A failure means
//    alias mechanics are introducing instability into the signature.
// ============================================================
clear all
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
fralias add median = median_income, from(counties)
gen income_ratio = income / median
frames save "outputs/_alias_a.dtas", frames(default counties) replace
complete_datasignature, frameset_file("outputs/_alias_a.dtas")
local alias_sig_a "`r(signature)'"

clear all
sleep 1500
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
fralias add median = median_income, from(counties)
gen income_ratio = income / median
frames save "outputs/_alias_b.dtas", frames(default counties) replace
complete_datasignature, frameset_file("outputs/_alias_b.dtas")
local alias_sig_b "`r(signature)'"

_assert "`alias_sig_a'" == "`alias_sig_b'", ///
    msg("alias-variable workflow changed .dtas signature across identical re-save")
di as result "PASS: alias-variable workflow is stable across identical re-save"

// ============================================================
// 6. Diagnostic: same frames, different save order.
//    This does not fail the suite; it documents current behavior.
//    Unlike the SCons smoke test, this is the place where we ask
//    whether frame order changes the signature.
// ============================================================
clear all
frame create life0
frame create life1
frame create life2
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frame life2: sysuse uslifeexp2, clear

frames save "outputs/_life_order_a.dtas", frames(life0 life1 life2) replace
frames save "outputs/_life_order_b.dtas", frames(life2 life1 life0) replace
complete_datasignature, frameset_file("outputs/_life_order_a.dtas")
local order_sig_a "`r(signature)'"
complete_datasignature, frameset_file("outputs/_life_order_b.dtas")
local order_sig_b "`r(signature)'"

if "`order_sig_a'" == "`order_sig_b'" {
    di as txt "NOTE: frame save order did not change the .dtas signature"
}
else {
    di as txt "NOTE: .dtas signature depends on frame save order"
}

// cleanup
cap erase "outputs/_life_default.dtas"
cap erase "outputs/_life_store.dtas"
cap erase "outputs/_life_max.dtas"
cap erase "outputs/_life_topology.dtas"
cap erase "outputs/_life_slots_a.dtas"
cap erase "outputs/_life_slots_b.dtas"
cap erase "outputs/_linked_a.dtas"
cap erase "outputs/_linked_b.dtas"
cap erase "outputs/_alias_a.dtas"
cap erase "outputs/_alias_b.dtas"
cap erase "outputs/_life_order_a.dtas"
cap erase "outputs/_life_order_b.dtas"

di _newline as result "ALL .dtas blog-style smoke tests passed"
