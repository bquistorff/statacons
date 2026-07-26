// _refresh_datasets.do
// Downloads the correct webuse example datasets and saves them locally.
// All paths are relative to the assumed working directory: frames/datasets/
// Run from frames/datasets/ with:
//   do _refresh_datasets.do                    (interactive)
//   StataMP-64.exe -e do _refresh_datasets.do  (batch)

foreach ds in persons txcounty discharge1 discharge2 family hsng {
    webuse `ds', clear
    save "`ds'.dta", replace
    di "Saved `ds'.dta"
}
