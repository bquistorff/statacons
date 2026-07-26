// ============================================================
// Hard-error tests for malformed .dtas inputs.
//
// What this file tests:
// - non-zip junk with a .dtas suffix
// - missing .frameinfo manifest
// - missing embedded .dta members
// - malformed .frameinfo contents
//
// Every case below should fail loudly. A failure of this test file
// means complete_datasignature accepted a broken frameset that should
// have been rejected instead of silently hashed.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_dtas_errors.do                    (interactive)
//   StataMP-64.exe -e do smoke_dtas_errors.do  (batch)
// ============================================================

clear all
do testlib.do
frames_tests_setup
frames_tests_require_python

// Build one valid source frameset from official Stata datasets.
// The Python helper mutates this known-good file into several broken
// variants, so if the helper step fails we never created the fixtures.
frame create life0
frame create life1
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frames save "outputs/_valid_source.dtas", frames(life0 life1) replace

local py_script "`c(pwd)'/make_malformed_dtas.py"
local valid_src "`c(pwd)'/outputs/_valid_source.dtas"
local out_dir "`c(pwd)'/outputs"

! "`c(python_exec)'" "`py_script'" "`valid_src'" "`out_dir'"
_assert _rc == 0, msg("failed to create malformed .dtas fixtures")

// Each assertion below checks "must error", not "must return a
// particular rc". The important contract is hard failure, not the
// exact code path used to reject the bad archive.
cap noi complete_datasignature, frameset_file("outputs/not_a_zip.dtas")
local rc_not_zip = _rc
_assert `rc_not_zip' != 0, msg("plain-text .dtas unexpectedly signed successfully")

cap noi complete_datasignature, frameset_file("outputs/missing_frameinfo.dtas")
local rc_missing_frameinfo = _rc
_assert `rc_missing_frameinfo' != 0, msg("missing .frameinfo unexpectedly signed successfully")

cap noi complete_datasignature, frameset_file("outputs/missing_member.dtas")
local rc_missing_member = _rc
_assert `rc_missing_member' != 0, msg("missing embedded .dta unexpectedly signed successfully")

cap noi complete_datasignature, frameset_file("outputs/bad_frameinfo.dtas")
local rc_bad_frameinfo = _rc
_assert `rc_bad_frameinfo' != 0, msg("malformed .frameinfo unexpectedly signed successfully")

di as result "PASS: malformed .dtas files fail loudly"

cap erase "outputs/_valid_source.dtas"
cap erase "outputs/not_a_zip.dtas"
cap erase "outputs/missing_frameinfo.dtas"
cap erase "outputs/missing_member.dtas"
cap erase "outputs/bad_frameinfo.dtas"

di _newline as result "ALL malformed .dtas smoke tests passed"
