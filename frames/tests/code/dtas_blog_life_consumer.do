frames use "outputs/life_blog.dtas", clear
// Consumer fixture for the life-blog pipeline. If this file fails in
// the SCons smoke test, statacons built the .dtas but downstream code
// could not reopen it and save a derived .dta.
frame change life1
keep in 1/10
save "outputs/life_blog_subset.dta", replace
