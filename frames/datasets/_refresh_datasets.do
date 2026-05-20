// _refresh_datasets.do
// Downloads the correct webuse example datasets and saves them locally.
// Run once from this directory to populate ../datasets/.

cd "C:/Users/rpguiter/Work/StataFrames/documentation/applications/datasets"

foreach ds in persons txcounty discharge1 discharge2 family hsng {
    webuse `ds', clear
    save "`ds'.dta", replace
    di "Saved `ds'.dta"
}
