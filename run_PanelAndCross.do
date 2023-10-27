/*=============================================================================
Program properties
=============================================================================*/

* root project folders
local autoRootDir "C:/Users/wb393438/IHS5/auto-sort" 	// auto-sort
local reportRootDir "C:/Users/wb393438/IHS5/hq-reports" 	// hq reports

set more 1

/*=============================================================================
Run auto-sort programs for both cross-section and panel
=============================================================================*/

* cross-section
include "`autoRootDir'/cross-section/programs/runAll.do" 

* panel
include "`autoRootDir'/panel/programs/runAll.do"

/*=============================================================================
Combine data for reports
=============================================================================*/

/*-----------------------------------------------------------------------------
Derived data
-----------------------------------------------------------------------------*/

* totCalories.dta
local dsets "attributes.dta"

foreach dset of local dsets {

	* append same-named data sets
	use "`autoRootDir'/cross-section/data/derived/`dset'", clear
	append using "`autoRootDir'/panel/data/derived/`dset'", generate(source)
	
	* create string variable to indicate each observation's source
	tostring source, replace
	replace source = "cross-section" if (source == "0")
	replace source = "panel" if (source == "1")
	
	* save resulting file
	save "`reportRootDir'/dataInput/`dset'", replace

}

/*-----------------------------------------------------------------------------
Raw data with same name in panel and cross-section
-----------------------------------------------------------------------------*/

local dsets "interview__actions.dta interview__comments.dta"

foreach dset of local dsets {

	* append same-named data sets
	use "`autoRootDir'/cross-section/data/combined/`dset'", clear
	append using "`autoRootDir'/panel/data/combined/`dset'", generate(source)
	
	* create string variable to indicate each observation's source
	tostring source, replace
	replace source = "cross-section" if (source == "0")
	replace source = "panel" if (source == "1")
	
	* save resulting file
	save "`reportRootDir'/dataInput/`dset'", replace

}

/*-----------------------------------------------------------------------------
Rejection results from panel and cross-section
-----------------------------------------------------------------------------*/


* append same-named data sets
use "`autoRootDir'/cross-section/results/toReject.dta", clear
append using "`autoRootDir'/panel/results/toReject.dta", generate(source)

* create string variable to indicate each observation's source
tostring source, replace
replace source = "cross-section" if (source == "0")
replace source = "panel" if (source == "1")

* save resulting file
save "`reportRootDir'/dataInput/toReject.dta", replace


/*-----------------------------------------------------------------------------
Raw data with different names in panel and cross-section
-----------------------------------------------------------------------------*/

* append same-named data sets
use "`autoRootDir'/panel/data/combined/Panel_Visit1.dta", clear
append using "`autoRootDir'/cross-section/data/combined/Cross_Section.dta", ///
	generate(source) force

* create string variable to indicate each observation's source
tostring source, replace
replace source = "panel" if (source == "0")
replace source = "cross-section" if (source == "1")

* save resulting file
save "`reportRootDir'/dataInput/household.dta", replace
