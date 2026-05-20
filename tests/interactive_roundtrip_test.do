// ============================================================
// MANUAL INTERACTIVE TEST -- run by opening Stata interactively,
// NOT with -e do or -b do (those set c(mode)=="batch" and skip
// the round-trip path this script is designed to exercise).
//
// How to run:
//   1. Open Stata interactively.
//   2. cd to C:/Users/rpguiter/Work/statacons/tests
//   3. do interactive_roundtrip_test.do
//
// What passes: all _assert lines exit without error; the final
// "ALL INTERACTIVE ROUND-TRIP TESTS PASSED" message is displayed.
//
// Note: user-defined programs are dropped by frames use ..., clear
// inside complete_datasignature, so all checks use the built-in
// _assert command rather than a helper program.
// ============================================================

clear all
adopath ++ "../src"
cap mkdir outputs

// Guard: abort if accidentally run in batch mode.
if "`c(mode)'" == "batch" {
    di as error "This script must be run interactively (c(mode) is 'batch')."
    di as error "Open Stata and do this file -- do not run it with -e do."
    exit 198
}

// ============================================================
// Setup: build a target .dtas for the tests to sign.
// frames: default (census, 50 obs) + regions (2 vars)
// ============================================================
clear all
sysuse census, clear
frame put state region, into(regions)
frames save "outputs/_rt_target.dtas", frames(default regions) replace
clear all

// ============================================================
// Test 1. Basic round-trip.
//   - User frames before the call: default (auto data) + prices
//   - Target to sign: _rt_target.dtas (census + regions frames)
//   - After the call: user's own frames must be intact.
// ============================================================
di as txt _newline "--- Test 1: basic round-trip ---"

sysuse auto, clear
frame put make price mpg, into(prices)

qui frames dir
local before_frames "`r(frames)'"
local before_N      = _N
local before_price1 = price[1]

complete_datasignature, frameset_file("outputs/_rt_target.dtas")
local sig_t1 "`r(signature)'"

_assert "`sig_t1'" != "", msg("Test 1: signature is empty")
di as result "PASS: Test 1: signature non-empty"

qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Test 1: frame list -- expected `before_frames', got `after_frames'")
di as result "PASS: Test 1: frame list restored (`after_frames')"

_assert _N == `before_N', msg("Test 1: default frame N -- expected `before_N', got `=_N'")
di as result "PASS: Test 1: default frame N = `=_N'"

_assert price[1] == `before_price1', ///
    msg("Test 1: default frame price[1] -- expected `before_price1', got `=price[1]'")
di as result "PASS: Test 1: default frame price[1] intact"

frame prices {
    _assert _N == 74, msg("Test 1: prices frame N -- expected 74, got `=_N'")
    di as result "PASS: Test 1: prices frame N = `=_N'"
    _assert c(k) == 3, msg("Test 1: prices frame k -- expected 3, got `=c(k)'")
    di as result "PASS: Test 1: prices frame k = `=c(k)'"
}

di as result "Test 1 passed."

// ============================================================
// Test 2. Empty default frame.
//   - User default frame is empty; one additional frame has data.
//   - Verifies the emptyok save guard works and the empty default
//     is restored (not replaced by the target's frames).
// ============================================================
di as txt _newline "--- Test 2: empty default frame ---"

clear all
frame create withdata
frame withdata: sysuse auto, clear

qui frames dir
local before_frames "`r(frames)'"   // "default withdata"

complete_datasignature, frameset_file("outputs/_rt_target.dtas")
local sig_t2 "`r(signature)'"

_assert "`sig_t2'" != "", msg("Test 2: signature is empty")
di as result "PASS: Test 2: signature non-empty"

qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Test 2: frame list -- expected `before_frames', got `after_frames'")
di as result "PASS: Test 2: frame list restored (`after_frames')"

_assert _N == 0, msg("Test 2: default frame should be empty, got `=_N' rows")
di as result "PASS: Test 2: default frame still empty"

frame withdata {
    _assert _N == 74, msg("Test 2: withdata N -- expected 74, got `=_N'")
    di as result "PASS: Test 2: withdata frame N = `=_N'"
}

di as result "Test 2 passed."

// ============================================================
// Test 3. Frame name collision.
//   - One user frame has the same name as a frame inside the
//     target .dtas ("regions"). The user's frame must be
//     restored with the user's content, not the target's.
// ============================================================
di as txt _newline "--- Test 3: frame name collision ---"

clear all
sysuse auto, clear
frame create regions        // same name as a frame in _rt_target
frame regions: sysuse auto, clear   // different data (74 obs, 12 vars)

qui frames dir
local before_frames "`r(frames)'"

complete_datasignature, frameset_file("outputs/_rt_target.dtas")
local sig_t3 "`r(signature)'"

_assert "`sig_t3'" != "", msg("Test 3: signature is empty")
di as result "PASS: Test 3: signature non-empty"

qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Test 3: frame list -- expected `before_frames', got `after_frames'")
di as result "PASS: Test 3: frame list restored (`after_frames')"

// User's "regions" must still hold auto (74 obs, 12 vars),
// not the 2-variable regions frame from the target.
frame regions {
    _assert _N == 74, msg("Test 3: collision frame N -- expected 74, got `=_N'")
    di as result "PASS: Test 3: collision frame N = `=_N'"
    _assert c(k) == 12, msg("Test 3: collision frame k -- expected 12, got `=c(k)'")
    di as result "PASS: Test 3: collision frame k = `=c(k)'"
}

di as result "Test 3 passed."

// ============================================================
// Test 4. Frame count preserved (user has more frames than target).
//   - User has 4 frames; target .dtas has 2.
//   - After the call: still exactly 4 user frames.
// ============================================================
di as txt _newline "--- Test 4: frame count preserved ---"

clear all
sysuse auto, clear
frame create f2
frame f2: sysuse census, clear
frame create f3
frame f3: sysuse auto, clear
frame create f4
frame f4: sysuse auto, clear

qui frames dir
local before_frames "`r(frames)'"   // "default f2 f3 f4"
local before_nframes = wordcount("`before_frames'")

complete_datasignature, frameset_file("outputs/_rt_target.dtas")

qui frames dir
local after_frames "`r(frames)'"
local after_nframes = wordcount("`after_frames'")

_assert `after_nframes' == `before_nframes', ///
    msg("Test 4: frame count -- expected `before_nframes', got `after_nframes'")
di as result "PASS: Test 4: frame count = `after_nframes'"

_assert "`after_frames'" == "`before_frames'", ///
    msg("Test 4: frame list -- expected `before_frames', got `after_frames'")
di as result "PASS: Test 4: frame list restored (`after_frames')"

di as result "Test 4 passed."

// ============================================================
// Test 5. Signature stability across calls.
//   - Calling twice from the same interactive session must return
//     the same value (the round-trip must not mutate state that
//     the signature depends on inside the target file).
// ============================================================
di as txt _newline "--- Test 5: signature stability across calls ---"

clear all
sysuse auto, clear
frame put make price, into(prices)

complete_datasignature, frameset_file("outputs/_rt_target.dtas")
local sig_call1 "`r(signature)'"
complete_datasignature, frameset_file("outputs/_rt_target.dtas")
local sig_call2 "`r(signature)'"

_assert "`sig_call1'" == "`sig_call2'", ///
    msg("Test 5: sig changed between calls -- call1=`sig_call1' call2=`sig_call2'")
di as result "PASS: Test 5: sig stable across calls"

di as result "Test 5 passed."

// ============================================================
// Cleanup
// ============================================================
cap erase "outputs/_rt_target.dtas"

di _newline as result "ALL INTERACTIVE ROUND-TRIP TESTS PASSED"
