// ============================================================
// Test: Frame creation and save order do not affect .dtas signatures.
//
// Locks the invariant: complete_datasignature iterates frames via
// `list sort` (alphabetical), so the aggregate signature must be
// identical regardless of:
//   (a) the order in which frames were created in memory, and
//   (b) the order passed to `frames save`.
// See: complete_datasignature.ado line 44 (`foreach f in `: list sort fnames'`)
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_dtas_frame_order.do                      (interactive)
//   StataMP-64.exe -e do smoke_dtas_frame_order.do    (batch)
// ============================================================

cap log close
log using logs/smoke_dtas_frame_order.log, replace text
clear all
do testlib.do
frames_tests_setup

cap mkdir out

// ============================================================
// Build order_AB: A created first, then B; saved frames(A B)
// ============================================================
clear all
frame create A
frame A {
    set obs 5
    gen x = _n
}
frame create B
frame B {
    set obs 5
    gen y = _n * 2
}
frames save "out/order_AB.dtas", frames(A B) replace
complete_datasignature, frameset_file("out/order_AB.dtas")
local sig_AB "`r(signature)'"
di as txt "sig_AB = `sig_AB'"

// ============================================================
// Build order_BA: B created first, then A; saved frames(A B)
// Alphabetical sort must produce the same signature.
// ============================================================
frames reset
frame create B
frame B {
    set obs 5
    gen y = _n * 2
}
frame create A
frame A {
    set obs 5
    gen x = _n
}
frames save "out/order_BA.dtas", frames(A B) replace
complete_datasignature, frameset_file("out/order_BA.dtas")
local sig_BA "`r(signature)'"
di as txt "sig_BA = `sig_BA'"

_assert "`sig_AB'" == "`sig_BA'", msg("creation order must not affect sig")
di as result "PASS: creation order does not affect .dtas signature"

// ============================================================
// Build order_save_BA: A created first, B second; saved frames(B A).
// The ado sorts alphabetically regardless of the save-list order,
// so this signature must equal sig_AB.
// ============================================================
frames reset
frame create A
frame A {
    set obs 5
    gen x = _n
}
frame create B
frame B {
    set obs 5
    gen y = _n * 2
}
frames save "out/order_save_BA.dtas", frames(B A) replace
complete_datasignature, frameset_file("out/order_save_BA.dtas")
local sig_save_BA "`r(signature)'"
di as txt "sig_save_BA = `sig_save_BA'"

_assert "`sig_save_BA'" == "`sig_AB'", msg("save order must not affect sig")
di as result "PASS: save order does not affect .dtas signature"

// ============================================================
// Confirm slot labels are alphabetically ordered (A= first, B= second)
// ============================================================
local sig_tokens : subinstr local sig_AB "|" " ", all
tokenize `"`sig_tokens'"'
_assert substr("`1'", 1, 2) == "A=", ///
    msg("slot 1 should start with A= (alphabetical sort)")
_assert substr("`2'", 1, 2) == "B=", ///
    msg("slot 2 should start with B= (alphabetical sort)")
di as result "PASS: signature slots are in alphabetical frame-name order"

// cleanup
cap erase "out/order_AB.dtas"
cap erase "out/order_BA.dtas"
cap erase "out/order_save_BA.dtas"
frames reset

di "PASS: smoke_dtas_frame_order"
log close
