clear all
// Producer fixture for the linked-frames blog workflow. This creates
// a linked frameset that exercises frlink-aware .dtas handling.
use "../datasets/persons.dta", clear
frame create counties
frame counties: use "../datasets/txcounty.dta", clear
frlink m:1 countyid, frame(counties)
frames save "outputs/linked_project.dtas", frames(default) linked replace
