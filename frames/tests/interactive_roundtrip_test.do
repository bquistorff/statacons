// ============================================================
// MANUAL INTERACTIVE TEST -- must not be run in batch mode.
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do interactive_roundtrip_test.do           (interactive only)
//
// What passes: all _assert lines succeed and the final message is
// displayed. This targets c(mode)=="interactive" state restoration.
//
// What failures mean:
// - Test 1 failures mean signature computation did not fully restore
//   the user's linked/alias session state after loading the frameset.
// - Test 2 failures mean temporary frame-name collisions during
//   signing clobbered pre-existing interactive frames.
// ============================================================

clear all
do testlib.do
frames_tests_setup

if "`c(mode)'" == "batch" {
    di as error "This script must be run interactively."
    exit 198
}

cap mkdir outputs

// Build target framesets used by the interactive checks. These are
// just fixtures; the real tests are about what happens to the user's
// live interactive session after complete_datasignature runs.
frame create life0
frame create life1
frame create life2
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frame life2: sysuse uslifeexp2, clear
frames save "outputs/_rt_life.dtas", frames(life0 life1 life2) replace

clear all
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
frames save "outputs/_rt_linked.dtas", frames(default) linked replace

// ============================================================
// Test 1. Linked + alias user state is restored after signing.
// If this block fails, the interactive-mode preservation logic is not
// putting the user's original working state back correctly.
// ============================================================
clear all
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
fralias add median = median_income, from(counties)
gen income_ratio = income / median

qui frames dir
local before_frames "`r(frames)'"
local before_obs = _N
local before_ratio = income_ratio[1]

complete_datasignature, frameset_file("outputs/_rt_life.dtas")
local sig_linked_alias "`r(signature)'"
_assert "`sig_linked_alias'" != "", msg("Test 1: signature is empty")

qui frames dir
local after_frames "`r(frames)'"
_assert "`after_frames'" == "`before_frames'", ///
    msg("Test 1: frame list was not restored")
_assert _N == `before_obs', msg("Test 1: default frame row count changed")
_assert income_ratio[1] == `before_ratio', msg("Test 1: alias-derived value changed")
confirm variable median
frame counties: _assert _N == 8, msg("Test 1: linked counties frame was not restored")

di as result "PASS: interactive linked + alias state restores correctly"

// ============================================================
// Test 2. Name collisions with life* frames do not clobber the user.
// If this fails, temporary frames created while reading the .dtas file
// are overwriting or failing to restore user frames of the same names.
// ============================================================
clear all
frame create life1
frame create life2
sysuse auto, clear
frame life1: sysuse census, clear
frame life2: sysuse auto, clear

qui frames dir
local before_collision_frames "`r(frames)'"

complete_datasignature, frameset_file("outputs/_rt_life.dtas")
local sig_collision "`r(signature)'"
_assert "`sig_collision'" != "", msg("Test 2: signature is empty")

qui frames dir
local after_collision_frames "`r(frames)'"
_assert "`after_collision_frames'" == "`before_collision_frames'", ///
    msg("Test 2: colliding frame names were not restored")

frame life1 {
    _assert _N == 50, msg("Test 2: life1 frame row count changed")
    _assert c(k) == 7, msg("Test 2: life1 frame column count changed")
}
frame life2 {
    _assert _N == 74, msg("Test 2: life2 frame row count changed")
    _assert c(k) == 12, msg("Test 2: life2 frame column count changed")
}

di as result "PASS: interactive frame-name collisions restore correctly"

cap erase "outputs/_rt_life.dtas"
cap erase "outputs/_rt_linked.dtas"

di _newline as result "ALL frames/tests interactive checks passed"
