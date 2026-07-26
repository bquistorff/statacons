// ============================================================
// Test: fralias frameset signature stability.
//
// Locks:
// (a) A frameset containing fralias columns signs identically
//     across re-saves of identical content.
// (b) Mutating the fralias source frame changes the aggregate
//     signature; diagnostic output records which frame slots change.
//
// Mirrors the fralias workflow from
//   frames/examples/example-02-frlink-frget.do  (Section 4).
//
// NOTE: if the first stability assertion (_assert sig1 == sig2) trips,
// that is a real finding -- stop and report rather than patching the test.
// It would mean fralias columns are introducing non-determinism into the
// signing path.
//
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do smoke_dtas_fralias.do                      (interactive)
//   StataMP-64.exe -e do smoke_dtas_fralias.do    (batch)
// ============================================================

cap log close
log using logs/smoke_dtas_fralias.log, replace text
clear all
do testlib.do
frames_tests_setup

cap mkdir out

// ============================================================
// Build fralias1.dtas: persons frame with fralias to txcounty.
// ============================================================
clear all
frame create persons
frame persons: use "../datasets/persons.dta", clear
frame create txcounty
frame txcounty: use "../datasets/txcounty.dta", clear
frame persons {
    frlink m:1 countyid, frame(txcounty)
    fralias add txcounty_median_income = median_income, from(txcounty)
}
frames save "out/fralias1.dtas", frames(persons txcounty) replace

complete_datasignature, frameset_file("out/fralias1.dtas")
local sig1 "`r(signature)'"
di as txt "sig1 (fralias1) = `sig1'"

// ============================================================
// Stability check: re-save identical content to fralias2.dtas.
// After complete_datasignature in batch mode, persons and txcounty
// frames from fralias1 are in memory (no mutation). Re-save and
// re-sign; signatures must be identical.
// ============================================================
sleep 1500
frames save "out/fralias2.dtas", frames(persons txcounty) replace
complete_datasignature, frameset_file("out/fralias2.dtas")
local sig2 "`r(signature)'"
di as txt "sig2 (fralias2) = `sig2'"

_assert "`sig1'" == "`sig2'", ///
    msg("fralias frameset should sign stably across re-saves")
di as result "PASS: fralias frameset signs identically across re-saves"

// ============================================================
// Diagnostic: print per-frame slots so future inspection can
// see exactly what fralias content does to the persons slot.
// Frames are signed alphabetically (persons < txcounty).
// ============================================================
local sig1_tokens : subinstr local sig1 "|" " ", all
tokenize `"`sig1_tokens'"'
local sig1_persons "`1'"
local sig1_txcounty "`2'"
di as txt "  persons  slot: `sig1_persons'"
di as txt "  txcounty slot: `sig1_txcounty'"

// ============================================================
// Mutation sub-test: change one value of median_income in txcounty.
// Must change the overall signature (and the txcounty slot at minimum).
// Diagnostic output records which slots change, locking observed behavior.
// ============================================================
frame txcounty: replace median_income = median_income + 1 in 1
frames save "out/fralias3.dtas", frames(persons txcounty) replace
complete_datasignature, frameset_file("out/fralias3.dtas")
local sig3 "`r(signature)'"
di as txt "sig3 (fralias3, mutated txcounty) = `sig3'"

_assert "`sig1'" != "`sig3'", ///
    msg("mutating fralias source must change overall sig")
di as result "PASS: mutating fralias source changes aggregate signature"

// Diagnostic: which slots changed?
local sig3_tokens : subinstr local sig3 "|" " ", all
tokenize `"`sig3_tokens'"'
local sig3_persons "`1'"
local sig3_txcounty "`2'"

if "`sig1_persons'" != "`sig3_persons'" {
    di as txt "  NOTE: persons slot changed after mutating txcounty source"
    di as txt "        (fralias alias variable materialized live into persons frame)"
}
else {
    di as txt "  NOTE: persons slot UNCHANGED after mutating txcounty source"
    di as txt "        (fralias alias variable materialized at save time)"
}
if "`sig1_txcounty'" != "`sig3_txcounty'" {
    di as txt "  NOTE: txcounty slot changed after mutating txcounty source"
}
else {
    di as txt "  NOTE: txcounty slot UNCHANGED after mutating txcounty (unexpected)"
}

// cleanup
cap erase "out/fralias1.dtas"
cap erase "out/fralias2.dtas"
cap erase "out/fralias3.dtas"
frames reset

di "PASS: smoke_dtas_fralias"
log close
