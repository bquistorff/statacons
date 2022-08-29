// debugging-checklist.do
version 16.0
local 0 , `0'
syntax [ , SCONSTRUCT(string) SCONSIGN(string) EXECUTE] ///
  [LOG LOGFILE(string)]
// user note: to call a do-file with options,
// do *not* include the comma that would typically be
//  included when calling an ado-file
// that is, call as
// . do debugging_checklist log execute
// not
// . do debugging_checklist, log execute


cap prog drop findMyCode
prog def findMyCode

  di `"** display adopath: "'
  noi adopath
  di _n `"** display sysdir: "'
  noi sysdir
  di _n `" ** look for ado-files  ** "' _n
  local adoFiles statacons stataconsign complete_datasignature
  foreach adoFile of local adoFiles {
    di `"look for `adoFile'.ado "'
    cap which `adoFile'
    if _rc==0 {
      which `adoFile'
      di _n
    }
    if _rc!=0 {
      di as err `"** `adoFile'.ado not found "' _n
    }
  }

  di `" ** look for py-files  ** "'
  local pyFiles runscons sconsign-script sconstruct_fns
  foreach pyFile of local pyFiles {
    di `"look for `pyFile'.py "'
    cap findfile `pyFile'.py
    if _rc==0 {
      di `"findfile returned: "`r(fn)'" "' _n
    }
    if _rc!=0 {
      di as err `"** `pyFile'.py not found "' _n
    }
  }
end

cap log close debugging_log

di `"** running debugging_checklist  **"'

if "`sconstruct'"=="" {
  loc sconstruct "SConstruct"
  di `" argument sconstruct not specified, assigning default value "`sconstruct'"  "'
}
else {
  di `"argument sconstruct specified as "`sconstruct'"  "'
}

if "`sconsign'"=="" {
  loc sconsign ".sconsign"
  di `" argument sconsign not specified, assigning default value "`sconsign'"  "'
}
else {
  di `"argument sconsign specified as "`sconsign'"  "'
}

if "`log'"=="log" & "`logfile'"~="" {
  di as err `"** at most one of log and logfile can be specified **"'
  di as err `"** log specified as "`log'" **"'
  di as err `"** logfile specified as "`logfile'" **"'
  exit 999
}
else if "`log'"=="log" & "`logfile'"=="" {
  di `"** option log invoked: "'
  di `"** logging with "debugging-checklist.smcl" in current directory ** "'
  loc log_line `"log using "debugging-checklist.smcl", name(debugging_log) replace"'
}
else if "`log'"=="" & "`logfile'"~="" {
  di `"** option logfile invoked as "`logfile'" **"'
  if substr("`logfile'",-5,.)==".smcl" | substr("`logfile'",-4,.)==".log"  {
    loc logfile "`logfile'"
  }
  else {
    loc logfile "`logfile'.smcl"
  }
  di `"** logging with "`logfile'" relative to current directory **"'
  loc log_line `"log using "`logfile'", name(debugging_log) replace"'
}
else {
  di "** neither log nor logfile specified, not logging **"
  loc log_line ""
}

`log_line'



cap confirm file ./`sconstruct'
if _rc!=0 {
  di as err `"** sconstruct file "`sconstruct'" not found in current directory  "'
}
else {
	di `"** SConstruct file "`sconstruct'"  "'
}

cap confirm file ./`sconsign'.dblite
if _rc!=0 {
  di as err `"** sconsign file "`sconsign'.dblite" not found in current directory  "'
}
else {
	di `"** sconsign file "`sconsign'.dblite"  "'
}


di _n `"** running findMyCode to look for key ado-and python files"' _n
findMyCode


cap confirm file ./profile.do
if _rc==0 {
  di `"** "profile.do" found in this directory "'
  di `"** running "profile.do"  "'
  noi do profile.do
  di `"** repeating findMyCode after running profile.do "'
  noi findMyCode
}
else {
  di as err `"** "profile.do" not found in this directory"' _n
}


// path to stata
di "`c(sysdir_stata)'"

// os
di "`c(os)'"


// stata version
di "`c(stata_version)'"

if `c(stata_version)'<16 {
  di as err "statacons requires Stata V16+"
  exit
}


// find stata flavor/edition
if `c(stata_version)'<17 {
	if `c(SE)'==0 {
		loc stata_flavor "IC"
	}
	else if `c(SE)'==1 & `c(MP)'==0 {
		loc stata_flavor "SE"
	}
	else if `c(SE)'==1 & `c(MP)'==1 {
		loc stata_flavor "MP"
	}
  di `"stata flavor is "`stata_flavor'" "'
}
else {
  di `"stata edition is: "`c(edition_real)'" "'
}


// ** check python settings
di "`c(python_exec)'"
python query



// check whether SCons is installed (essential)
// check whether pystatacons is installed
python
import SCons
print(SCons.__version__)
import pystatacons
print(pystatacons.__version__)
end

python which SCons
python which pystatacons


// ** check contents of config_local.ini
cap confirm file "./config_local.ini"
if _rc==0 {
  di `"** config_local.ini found in current directory "'
  type "./config_local.ini"
}
else {
  di as err `"config_local.ini not found in current directory"'
}

// ** check contents of config_project.ini
cap confirm file "./config_project.ini"
if _rc==0 {
  di `"** config_project.ini found in current directory "'
  type "./config_project.ini"
}
else {
  di as err `"config_project.ini not found in current directory"'
}


// check that statacons is configured as we expect
statacons -n --version
statacons -n -k --show-config
statacons -n --help



// run statacons in dry_run mode
statacons -n -k --file=`sconstruct'
statacons -n -k --file=`sconstruct' --debug=explain
statacons -n -k --file=`sconstruct' --tree=status,prune

stataconsign `sconsign'


// run statacons without dry_run mode (if "execute" selected)
if "`execute'"=="execute" {
  di `" ** option "execute" invoked, running statacons without dry_run mode **"'
  statacons -k --debug=explain --file=`sconstruct'
  // just to be sure, clean everything and try again
  rm `sconsign'.dblite
  statacons -c --file=`sconstruct'
  statacons -k --debug=explain --tree=status,prune --file=`sconstruct'
  stataconsign `sconsign'
}
  else {
    di `"** di option "execute" not invoked, **"' _n
    di `"**   statacons run only in dry_run mode **"' _n
}


cap log close debugging_log

exit
