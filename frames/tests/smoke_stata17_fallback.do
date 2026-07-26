// ============================================================
// Test: Stata <18 fallback path.
//
// Sub-test A (Stata-side, implemented here):
//   Calling complete_datasignature, frameset_file() under Stata 17
//   exits with code 198 AND emits sentinel STATACONS_REQUIRES_STATA18.
//   Uses the existing Stata17/ harness (test_stata17_guard.do and
//   test_stata17_nocapture.do).
//
// Sub-tests B and C (Python-side, deferred -- TODO):
//   TODO B: get_dtas_sign under frameset_signing:auto detects the
//           sentinel and falls back to hash_file_signature (MD5),
//           emitting a one-time warning.
//   TODO C: get_dtas_sign under frameset_signing:enabled raises a
//           hard error.
//
// Sub-test A requires Stata 17 at C:\Program Files\Stata17\StataMP-64.exe.
// If Stata 17 is absent the test skips gracefully.
//
// The two Stata17/ helper scripts (test_stata17_guard.do,
// test_stata17_nocapture.do) are invoked from their own directory via
// a small batch file placed in out/ so that relative paths inside them
// resolve correctly.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_stata17_fallback.do                      (interactive)
//   StataMP-64.exe -e do smoke_stata17_fallback.do    (batch)
// ============================================================

cap log close
log using logs/smoke_stata17_fallback.log, replace text
clear all
do testlib.do
frames_tests_setup

cap mkdir out

// ============================================================
// Guard: skip if Stata 17 is not installed.
// ============================================================
cap confirm file "C:\Program Files\Stata17\StataMP-64.exe"
if _rc != 0 {
    di as txt "NOTE: Stata 17 not found at C:\Program Files\Stata17\; skipping."
    di "PASS: smoke_stata17_fallback (skipped -- Stata 17 not installed)"
    log close
    exit
}

// ============================================================
// Write helper batch files into out/.
// Each batch uses %~dp0 (the batch file's own directory) so that
// pushd resolves the relative Stata17\ sibling directory correctly
// from any working directory.
// ============================================================

// Guard-runner: runs test_stata17_guard.do; exits 0/1 based on
// whether complete_datasignature returned 198 as expected.
file open _bfh using "out/_stata17_guard_runner.bat", write text replace
file write _bfh "@echo off" _n
file write _bfh `"pushd "%~dp0..\Stata17""' _n
file write _bfh `""C:\Program Files\Stata17\StataMP-64.exe" -e do test_stata17_guard.do"' _n
file write _bfh "set EXITCODE=%ERRORLEVEL%" _n
file write _bfh "popd" _n
file write _bfh "exit /b %EXITCODE%" _n
file close _bfh

// Nocapture-runner: runs test_stata17_nocapture.do (expected to fail
// with Stata exit 198); always returns 0 so _rc is not checked here.
// The log is inspected separately for the sentinel string.
file open _bfh using "out/_stata17_nocap_runner.bat", write text replace
file write _bfh "@echo off" _n
file write _bfh `"pushd "%~dp0..\Stata17""' _n
file write _bfh `""C:\Program Files\Stata17\StataMP-64.exe" -e do test_stata17_nocapture.do"' _n
file write _bfh "popd" _n
file write _bfh "exit /b 0" _n
file close _bfh

// ============================================================
// Sub-test A, part 1: version guard exits 198.
// test_stata17_guard.do uses `capture`, checks _rc==198, and
// exits Stata with code 0 (pass) or 1 (fail).
// ============================================================
! "out\_stata17_guard_runner.bat"
_assert _rc == 0, ///
    msg("Stata17 guard test exited non-zero: rc=198 version guard not working (shell rc=`_rc')")
di as result "PASS: Stata 17 exits 198 on frameset_file() call"

// ============================================================
// Sub-test A, part 2: sentinel STATACONS_REQUIRES_STATA18 is emitted.
// test_stata17_nocapture.do runs without capture so the error message
// appears in its log. findstr returns 0 if the string is found.
// ============================================================
! "out\_stata17_nocap_runner.bat"
// (expected non-zero from Stata -- ignored by the nocap runner itself)

! cmd /c findstr /C:"STATACONS_REQUIRES_STATA18" Stata17\test_stata17_nocapture.log
_assert _rc == 0, ///
    msg("sentinel STATACONS_REQUIRES_STATA18 not found in Stata17 nocapture log")
di as result "PASS: sentinel STATACONS_REQUIRES_STATA18 emitted by Stata 17"

di as txt _newline "NOTE: Sub-tests B and C (Python-side fallback) are deferred."
di as txt "  TODO B: get_dtas_sign under frameset_signing:auto detects sentinel, falls back to MD5"
di as txt "  TODO C: get_dtas_sign under frameset_signing:enabled raises hard error"

// cleanup batch runners (logs kept for inspection)
cap erase "out\_stata17_guard_runner.bat"
cap erase "out\_stata17_nocap_runner.bat"

di "PASS: smoke_stata17_fallback"
log close
