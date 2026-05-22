// Test: show raw error output from frameset_file() on Stata <18 (no capture).
// The log should contain "STATACONS_REQUIRES_STATA18" -- this is the sentinel
// string Python searches for in get_dtas_sign() to trigger the MD5 fallback.
// Run from frames/tests/Stata17/ with:
//   Start-Process "C:\Program Files\Stata17\StataMP-64.exe" -ArgumentList "/e do test_stata17_nocapture.do" -Wait
adopath ++ "../../../src"
complete_datasignature, frameset_file("../outputs/legacy_myset.dtas") fname("test_sig_out.txt")
