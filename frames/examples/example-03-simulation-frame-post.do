// example-03-simulation-frame-post.do
// Demonstrates: frame create (with newvarlist), frame post, simulation loop
//
// Replicates the simulation use case from [D] frames intro and [P] frame post.
// Runs a small Monte Carlo experiment: tests whether a 95% CI for the slope
// in a simple OLS regression actually covers the true value 95% of the time.
//
// Datasets required: none
// ----------------------------------------------------------------

clear all
set seed 12345

local reps  = 1000   // number of simulation replications
local n     = 50     // sample size per replication
local beta  = 2      // true slope

// ---- 1. Create the results frame ----
frame create results double(b se covered)
// 'results' is now a 0-obs dataset with three double-precision variables

// ---- 2. Simulation loop ----
forvalues i = 1/`reps' {
    quietly {
        clear
        set obs `n'
        gen x = rnormal()
        gen y = 1 + `beta'*x + rnormal()   // true slope = beta
        regress y x
    }
    // Post one observation to the results frame
    frame post results ///
        (_b[x])        ///   estimated slope
        (_se[x])       ///   standard error
        (el(r(table),5,1) < `beta' & `beta' < el(r(table),6,1))  // 95% CI coverage
}

// ---- 3. Analyze results ----
frame change results
summarize b se covered

di "95% CI coverage rate: " r(mean) " (should be ~0.95)"
