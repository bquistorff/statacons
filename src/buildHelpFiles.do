// buildHelpFiles.do
version 16.1

// to be run from statacons/src
loc myPwd "`c(pwd)'"
if lower(substr("`c(pwd)'",-3,.)) != "src" {
  di as err "to be run from statacons/src"
  exit 999
}

loc old_plus "`c(sysdir_plus)'"
loc old_personal "`c(sysdir_personal)'"

// point adopath to markdoc and friends
sysdir set PLUS ../ado/plus
sysdir set PERSONAL ../ado/personal

which markdoc
foreach FILE in statacons stataconsign complete_datasignature {
  foreach FMT in sthlp md {
    markdoc `FILE'.ado, export(`FMT') replace mini
  }
}


// restore adopath
sysdir set PLUS "`old_plus'"
sysdir set PERSONAL "`old_personal'"

exit
