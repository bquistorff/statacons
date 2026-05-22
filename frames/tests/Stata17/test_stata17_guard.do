// Test: complete_datasignature frameset_file() should return rc=198 on Stata <18.
// Run from frames/tests/Stata17/ with:
//   Start-Process "C:\Program Files\Stata17\StataMP-64.exe" -ArgumentList "/e do test_stata17_guard.do" -Wait
adopath ++ "../../../src"
capture complete_datasignature, frameset_file("../outputs/legacy_myset.dtas") fname("test_sig_out.txt")
loc rc = _rc
di "return code: `rc'"
if `rc' == 198 {
    di as result "PASS: exit 198 as expected on Stata `=int(`c(stata_version)')'"
}
else {
    di as error "FAIL: unexpected return code `rc'"
    exit 1
}
