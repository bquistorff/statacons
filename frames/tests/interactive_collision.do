// ============================================================
// MANUAL INTERACTIVE TEST -- must not be run in batch mode.
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do interactive_collision.do                   (interactive only)
//
// What this tests:
//   When the user's current state has a frame whose name also appears
//   in the target .dtas, the dual-mode round-trip
//   (save-current -> sign-target -> restore-current) restores the
//   user's state -- not the target's -- without name collision and
//   without silent clobber.
//
// Design decision exercised:
//   complete_datasignature.ado lines 28-32 (interactive round-trip via
//   temp .dtas) and lines 51-55 (restore + explicit `frame change`).
//
// What passes: all _assert lines succeed and the final message is
// displayed. This targets c(mode)=="interactive" state preservation.
// ============================================================

clear all
do testlib.do
frames_tests_setup

if "`c(mode)'" == "batch" {
    di as error "This script must be run interactively."
    exit 198
}

cap mkdir out

// ============================================================
// Step 1: Build the target .dtas with small frames X and Y.
// X has 4 obs with v = _n; Y has 4 obs with w = _n * 10.
// ============================================================
frames reset
frame create X
frame X {
    set obs 4
    gen v = _n
}
frame create Y
frame Y {
    set obs 4
    gen w = _n * 10
}
frames save "out/collision_target.dtas", frames(X Y) replace
di as txt "Built target .dtas: X (4 obs, v=1..4) and Y (4 obs, w=10..40)"

// ============================================================
// Step 2: Build colliding current state.
// User's frame X has 7 obs with v = _n * 100 -- very different from
// the target .dtas frame X. The active frame is X.
// ============================================================
frames reset
frame create X
frame X {
    set obs 7
    gen v = _n * 100
}
frame change X

// Capture pre-call invariants
qui count
local n_pre = r(N)
local fname_pre "`c(frame)'"
local v1_pre = v[1]
di as txt "Pre-call: frame=`fname_pre', N=`n_pre', v[1]=`v1_pre'"

// ============================================================
// Step 3: Sign the target while user's colliding X is active.
// The interactive round-trip should:
//   (a) save all current frames to a temp .dtas,
//   (b) load the target for signing,
//   (c) restore the user's frames and re-activate X.
// ============================================================
complete_datasignature, frameset_file("out/collision_target.dtas")
local sig "`r(signature)'"
_assert "`sig'" != "", msg("signature should not be empty after collision test")
di as txt "Signature after collision round-trip: `sig'"

// ============================================================
// Step 4: Verify the user's state is fully restored.
// ============================================================
_assert "`c(frame)'" == "X", ///
    msg("active frame name must be restored (got '`c(frame)'', expected 'X')")

qui count
_assert r(N) == `n_pre', ///
    msg("active frame obs count must be restored (got r(N)=`r(N)', expected `n_pre')")

_assert v[1] == `v1_pre', ///
    msg("active frame data values must match pre-call state (v[1]=`=v[1]', expected `v1_pre')")

di as result "PASS: interactive frame-name collision restores correctly"

// cleanup
cap erase "out/collision_target.dtas"
frames reset

di _newline as result "PASS: interactive_collision"
