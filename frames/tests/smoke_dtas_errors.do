// ============================================================
// Hard-error tests for malformed .dtas inputs.
// Run from frames/tests with: StataMP-64.exe -e do smoke_dtas_errors.do
// ============================================================

clear all
do testlib.do
frames_tests_setup
frames_tests_require_python

// Build one valid source frameset from official Stata datasets.
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

