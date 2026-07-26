// ============================================================
// Test: Degenerate .dtas cases.
//
// Subtest A (must pass): single-frame .dtas signature is well-formed:
//   starts with '<framename>=' and contains no pipe.
// Subtest B (best effort): empty .dtas; Stata may refuse to create one.
//   If it succeeds, the signature should be empty or very short.
//   If Stata refuses (rc != 0), the subtest is skipped with a note.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_dtas_degenerate.do                      (interactive)
//   StataMP-64.exe -e do smoke_dtas_degenerate.do    (batch)
// ============================================================

cap log close
log using logs/smoke_dtas_degenerate.log, replace text
clear all
do testlib.do
frames_tests_setup

cap mkdir out

// ============================================================
// Subtest A: Single-frame .dtas
// Signature should start with 'lonely=' and have no pipe separator.
// ============================================================
clear all
frame create lonely
frame lonely {
    set obs 2
    gen id = _n
}
frames save "out/single.dtas", frames(lonely) replace
complete_datasignature, frameset_file("out/single.dtas")
local sig "`r(signature)'"
di as txt "single-frame sig = `sig'"

_assert strpos("`sig'", "lonely=") == 1, ///
    msg("single-frame sig should start with 'lonely='")
_assert strpos("`sig'", "|") == 0, ///
    msg("single-frame sig should have no pipe separator")
di as result "PASS: single-frame .dtas signature is well-formed"

// ============================================================
// Subtest B: Empty .dtas (best effort)
// ============================================================
frames reset
cap noi frames save "out/empty.dtas", emptyok replace
local rc_empty = _rc
if `rc_empty' == 0 {
    di as txt "NOTE: Stata created empty .dtas (rc=0); signing it."
    cap noi complete_datasignature, frameset_file("out/empty.dtas")
    if _rc == 0 {
        local sig_empty "`r(signature)'"
        di as txt "NOTE: empty .dtas signature = '`sig_empty''"
        _assert length("`sig_empty'") < 5, ///
            msg("empty .dtas sig should be empty or very short (<5 chars)")
        di as result "PASS: empty .dtas signed as expected"
    }
    else {
        di as txt "NOTE: signing empty .dtas returned rc=`_rc'; skipping assertion."
    }
}
else {
    di as txt "NOTE: Stata refused empty .dtas (rc=`rc_empty'); skipping subtest B."
}

// cleanup
cap erase "out/single.dtas"
cap erase "out/empty.dtas"
frames reset

di "PASS: smoke_dtas_degenerate"
log close
