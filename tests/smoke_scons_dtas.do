// ============================================================
// DEV SCAFFOLD -- not part of the formal statacons_test.do suite.
// Kept in tests/ for quick standalone validation of the SCons
// .dtas pipeline (producer -> .dtas -> consumer -> .dta) during
// development. Mirrors the SCons-end-to-end section in
// statacons_test.do; this file just runs it in isolation.
// ============================================================
// Focused SCons end-to-end test for .dtas signature path
// Verifies that the Python env-var dev hatch works from within Stata.

clear all
adopath ++ "../src"

local dev_src "`c(pwd)'/../src"
di as txt "dev_src = `dev_src'"
python: import os; os.environ['STATACONS_DEV_SRC'] = r"`dev_src'"
python: import os; print('STATACONS_DEV_SRC =', os.environ.get('STATACONS_DEV_SRC'))

// Clean and build
statacons -c
statacons outputs/myset.dtas outputs/foreign_from_dtas.dta

cap program drop store_modts
program store_modts
    syntax anything, local(string)
    filesys `c(pwd)'/`anything', attr
    c_local `local' "`r(modifiednum)'"
end

cap store_modts outputs/myset.dtas, local(mod1_dtas)
cap store_modts outputs/foreign_from_dtas.dta, local(mod1_dta)
di as txt "After first build: mod1_dtas = `mod1_dtas'  mod1_dta = `mod1_dta'"

// Re-run -- should be a no-op
statacons outputs/myset.dtas outputs/foreign_from_dtas.dta
cap store_modts outputs/myset.dtas, local(mod2_dtas)
cap store_modts outputs/foreign_from_dtas.dta, local(mod2_dta)
di as txt "After second run:  mod2_dtas = `mod2_dtas'  mod2_dta = `mod2_dta'"

_assert "`mod1_dtas'`mod1_dta'"=="`mod2_dtas'`mod2_dta'", msg(".dtas pipeline re-ran despite no input change")
di as result "PASS: .dtas pipeline does not rebuild on re-run with identical inputs"
