// ============================================================
// Legacy interactive round-trip checks migrated from
// tests\interactive_roundtrip_test.do.
//
// MANUAL INTERACTIVE TEST -- must not be run in batch mode.
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do interactive_roundtrip_legacy.do         (interactive only) These checks cover small but still useful interactive
// restoration cases that are separate from the newer blog-style script.
// ============================================================

clear all
do testlib.do
frames_tests_setup

if "`c(mode)'" == "batch" {
    di as error "This script must be run interactively."
    exit 198
}

cap mkdir outputs

// ============================================================
// Setup: build a target .dtas file for the legacy round-trip checks.
// ============================================================
clear all
sysuse census, clear
frame put state region, into(regions)
frames save "outputs/_rt_target_legacy.dtas", frames(default regions) replace
clear all

// ============================================================
// Test 1. Basic round-trip.
// ============================================================
sysuse auto, clear
frame put make price mpg, into(prices)

qui frames dir
local before_frames "`r(frames)'"
local before_N = _N
local before_price1 = price[1]

complete_datasignature, frameset_file("outputs/_rt_target_legacy.dtas")
local sig_t1 "`r(signature)'"

_assert "`sig_t1'" != "", msg("Legacy test 1: signature is empty")
qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Legacy test 1: frame list was not restored")
_assert _N == `before_N', ///
    msg("Legacy test 1: default frame row count changed")
_assert price[1] == `before_price1', ///
    msg("Legacy test 1: default frame contents changed")
frame prices {
    _assert _N == 74, msg("Legacy test 1: prices frame row count changed")
    _assert c(k) == 3, msg("Legacy test 1: prices frame column count changed")
}
di as result "PASS: legacy interactive basic round-trip"

// ============================================================
// Test 2. Empty default frame stays empty.
// ============================================================
clear all
frame create withdata
frame withdata: sysuse auto, clear

qui frames dir
local before_frames "`r(frames)'"

complete_datasignature, frameset_file("outputs/_rt_target_legacy.dtas")
local sig_t2 "`r(signature)'"

_assert "`sig_t2'" != "", msg("Legacy test 2: signature is empty")
qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Legacy test 2: frame list was not restored")
_assert _N == 0, msg("Legacy test 2: default frame should still be empty")
frame withdata {
    _assert _N == 74, msg("Legacy test 2: withdata frame row count changed")
}
di as result "PASS: legacy interactive empty-default restoration"

// ============================================================
// Test 3. Frame count is preserved.
// ============================================================
clear all
sysuse auto, clear
frame create f2
frame f2: sysuse census, clear
frame create f3
frame f3: sysuse auto, clear
frame create f4
frame f4: sysuse auto, clear

qui frames dir
local before_frames "`r(frames)'"
local before_nframes = wordcount("`before_frames'")

complete_datasignature, frameset_file("outputs/_rt_target_legacy.dtas")

qui frames dir
local after_frames "`r(frames)'"
local after_nframes = wordcount("`after_frames'")

_assert `after_nframes' == `before_nframes', ///
    msg("Legacy test 3: frame count changed")
_assert "`after_frames'" == "`before_frames'", ///
    msg("Legacy test 3: frame list was not restored")
di as result "PASS: legacy interactive frame-count preservation"

// ============================================================
// Test 4. Signature stability across repeated calls.
// ============================================================
clear all
sysuse auto, clear
frame put make price, into(prices)

complete_datasignature, frameset_file("outputs/_rt_target_legacy.dtas")
local sig_call1 "`r(signature)'"
complete_datasignature, frameset_file("outputs/_rt_target_legacy.dtas")
local sig_call2 "`r(signature)'"

_assert "`sig_call1'" == "`sig_call2'", ///
    msg("Legacy test 4: signature changed across repeated calls")
di as result "PASS: legacy interactive repeated-call stability"

cap erase "outputs/_rt_target_legacy.dtas"

di _newline as result "ALL legacy interactive round-trip tests passed"
