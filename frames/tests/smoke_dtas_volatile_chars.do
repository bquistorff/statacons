// ============================================================
// Test: Volatile characteristics and skip_char() glob.
//
// Locks:
// (a) Default skip_char strips only frlink_*. A non-frlink_* characteristic
//     carrying volatile data (e.g. a timestamp) WILL change the signature
//     run-to-run -- this is documented default behavior.
// (b) The user can recover stability via skip_char() glob using strmatch.
//
// See: complete_datasignature.ado lines 39-40 (inner_skip) and 117-121
//      (strmatch matching).
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_dtas_volatile_chars.do                      (interactive)
//   StataMP-64.exe -e do smoke_dtas_volatile_chars.do    (batch)
// ============================================================

cap log close
log using logs/smoke_dtas_volatile_chars.log, replace text
clear all
do testlib.do
frames_tests_setup

cap mkdir out

// ============================================================
// Build vol1.dtas with a timestamp characteristic on frame A.
// Use c(current_date) and c(current_time) so the value is
// actually different on each run (unlike $S_DATE/$S_TIME which
// are fixed at Stata startup).
// ============================================================
clear all
frame create A
frame A {
    set obs 3
    gen v = _n
}
local ts1 "`c(current_date)' `c(current_time)'"
frame A: char _dta[lastrun] "`ts1'"
frames save "out/vol1.dtas", frames(A) replace
complete_datasignature, frameset_file("out/vol1.dtas")
local sig1 "`r(signature)'"
di as txt "sig1 (vol1) = `sig1'"
di as txt "  timestamp used: `ts1'"

// ============================================================
// Wait, reset, build vol2.dtas with a later timestamp.
// After sleep 1500 the second-resolution clock has advanced.
// ============================================================
sleep 1500
frames reset
frame create A
frame A {
    set obs 3
    gen v = _n
}
local ts2 "`c(current_date)' `c(current_time)'"
frame A: char _dta[lastrun] "`ts2'"
frames save "out/vol2.dtas", frames(A) replace
complete_datasignature, frameset_file("out/vol2.dtas")
local sig2 "`r(signature)'"
di as txt "sig2 (vol2) = `sig2'"
di as txt "  timestamp used: `ts2'"

_assert "`sig1'" != "`sig2'", ///
    msg("timestamp char should change sig by default (ts1='`ts1'' ts2='`ts2'')")
di as result "PASS: volatile timestamp char changes signature by default"

// ============================================================
// Re-sign both files with skip_char("lastrun") -- exact match.
// The signatures should now be identical (same data, skip the char).
// ============================================================
complete_datasignature, frameset_file("out/vol1.dtas") skip_char("lastrun")
local sig1s "`r(signature)'"
complete_datasignature, frameset_file("out/vol2.dtas") skip_char("lastrun")
local sig2s "`r(signature)'"
di as txt "sig1s (skip lastrun) = `sig1s'"
di as txt "sig2s (skip lastrun) = `sig2s'"

_assert "`sig1s'" == "`sig2s'", ///
    msg("skip_char(lastrun) should stabilize over volatile char")
di as result "PASS: skip_char(lastrun) stabilizes signature across timestamp char"

// ============================================================
// Glob variant: skip_char("last*") -- confirms strmatch globbing.
// ============================================================
complete_datasignature, frameset_file("out/vol1.dtas") skip_char("last*")
local sig1g "`r(signature)'"
complete_datasignature, frameset_file("out/vol2.dtas") skip_char("last*")
local sig2g "`r(signature)'"
di as txt "sig1g (skip last*) = `sig1g'"
di as txt "sig2g (skip last*) = `sig2g'"

_assert "`sig1g'" == "`sig2g'", ///
    msg("skip_char(last*) glob should stabilize signature")
di as result "PASS: skip_char glob pattern stabilizes signature"

// cleanup
cap erase "out/vol1.dtas"
cap erase "out/vol2.dtas"
frames reset

di "PASS: smoke_dtas_volatile_chars"
log close
