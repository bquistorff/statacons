use "inputs/auto-original.dta", clear
frame put * if foreign==1, into(foreign_cars)
frame put * if foreign==0, into(domestic_cars)
frames save "outputs/myset.dtas", frames(default foreign_cars domestic_cars) replace
