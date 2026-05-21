frames use "outputs/linked_project.dtas", clear
frame change default
fralias add median = median_income, from(counties)
gen income_ratio = income / median
gen median_copy = median
drop median
rename median_copy median
keep personid countyid income median income_ratio
save "outputs/person_ratio_from_dtas.dta", replace
