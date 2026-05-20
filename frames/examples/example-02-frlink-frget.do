// example-02-frlink-frget.do
// Demonstrates: frlink (m:1 and 1:1), frget, frval(), fralias add
//
// Datasets used (from Stata Press webuse):
//   persons:    personid, countyid, income           (20 obs)
//   txcounty:   countyid, median_income              (8 obs)
//   discharge1: patientid, age, sex, billed, ...     (1980 obs)
//   discharge2: patientid, age, sex, billed, ...     (1980 obs, same structure)
//   family:     pid, pid_m, pid_f, x1-x5            (639 obs)
// ----------------------------------------------------------------

clear all

cd "C:/Users/rpguiter/Work/statacons/frames/examples"
local datasets "../datasets"

// ---- 1. m:1 linkage: persons linked to Texas counties ----
// persons has countyid; txcounty has the county-level median income
use "`datasets'/persons", clear
frame create txcounty
frame txcounty: use "`datasets'/txcounty", clear

frames dir
// persons: 20 person-level obs with countyid and income
// txcounty: 8 county-level obs with countyid and median_income

// Create the linkage (m:1: many persons per county)
frlink m:1 countyid, frame(txcounty)

// Inspect the linkage
frlink dir
frlink describe txcounty

// Copy median_income from txcounty into the persons frame
frget median_income, from(txcounty)

// Check result
describe
list countyid income median_income in 1/10

// ---- 2. Using frval() for inline access ----
// Flag persons whose income exceeds their county median -- no variable copy needed
generate above_median = (income > frval(txcounty, median_income))
tabulate above_median

// ---- 3. 1:1 linkage: discharge data ----
// discharge1 and discharge2 have the same structure (same patients, two records).
// Use frget syntax 2 (newvar = oldvar) to pull variables with explicit renaming.
clear all
use "`datasets'/discharge1", clear
frame create discharge2
frame discharge2: use "`datasets'/discharge2", clear

frlink 1:1 patientid, frame(discharge2)
frlink describe discharge2

// Pull billed amount from discharge2, renamed to distinguish from discharge1's billed
frget billed2 = billed, from(discharge2)
list patientid billed billed2 in 1/5

// ---- 4. fralias add (Stata 18+): memory-efficient alternative to frget ----
clear all
use "`datasets'/persons", clear
frame create txcounty2
frame txcounty2: use "`datasets'/txcounty", clear

frlink m:1 countyid, frame(txcounty2)

// Create aliases instead of copies -- uses very little extra memory
fralias add median_income, from(txcounty2)
fralias describe

// Aliases work in most commands just like regular variables
summarize median_income income
regress income median_income

// ---- 5. Generational data: linking a frame to itself ----
clear all
use "`datasets'/family", clear
frame create family
frame family: use "`datasets'/family", clear    // same data in a second frame named 'family'

// Link each person to their mother and father
frlink m:1 pid_m, frame(family pid) generate(m)
frlink m:1 pid_f, frame(family pid) generate(f)

// Get grandparent IDs via intermediate links
frget pid_mm = pid_m, from(m)   // mother's mother
frget pid_mf = pid_f, from(m)   // mother's father
frget pid_fm = pid_m, from(f)   // father's mother
frget pid_ff = pid_f, from(f)   // father's father

// Create links to all four grandparents
frlink m:1 pid_mm, frame(family pid) generate(mm)
frlink m:1 pid_mf, frame(family pid) generate(mf)
frlink m:1 pid_fm, frame(family pid) generate(fm)
frlink m:1 pid_ff, frame(family pid) generate(ff)

list pid pid_m pid_f pid_mm pid_mf pid_fm pid_ff in 1/10
