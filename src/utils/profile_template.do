
// keep all user-written ado-files local to this project 
sysdir set PLUS code/ado/plus
sysdir set PERSONAL code/ado/personal
sysdir set OLDPLACE code/ado

/* if using another folder for statacons ado and python */
// adopath + path/to/statacons

if "`c(mode)'"=="batch" {
  set graphics off
}
else {
  set graphics on
}
