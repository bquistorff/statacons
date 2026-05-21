clear all
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
frames save "outputs/linked_project.dtas", frames(default) linked replace

