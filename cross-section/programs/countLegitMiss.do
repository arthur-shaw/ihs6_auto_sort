/*=============================================================================
Compute number of legitimate missings per hhold per file
=============================================================================*/

/*-----------------------------------------------------------------------------
Household level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:1 interview__id interview__key using "`rawDir'/`hhold'", nogen

* flag missings
gen numMiss_comment = (comment == "##N/A##")
gen numMiss_networkRoster = (ag_net_1__0 == "##N/A##")

* count missings
egen numMiss_hhold = rowtotal(numMiss*) 
keep interview__id numMiss_hhold

tempfile missHhold
save "`missHhold'"

/*-----------------------------------------------------------------------------
Member level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`members'"

* flag missings
gen numMiss_e19 = (hh_e19_code == .a & _merge == 3 & interview__status == 100)
gen numMiss_e20 = (hh_e20_code == "##N/A##" & _merge == 3 & interview__status == 100)

* count missings
egen numMiss_member = rowtotal(numMiss*)

collapse (sum) numMiss_member, by(interview__id)

tempfile missMember
save "`missMember'"

/*-----------------------------------------------------------------------------
Enterprise level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`enterprises'"

gen numMiss_enterprise = (hh_n09b == "##N/A##" & _merge == 3 & interview__status == 100)
collapse (sum) numMiss_enterprise, by(interview__id)

tempfile missEnterprise
save "`missEnterprise'"

/*-----------------------------------------------------------------------------
Elsewhere member level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/childrenElsewhere.dta"

gen numMiss_child = (hh_o10b == "##N/A##" & _merge == 3 & interview__status == 100)
collapse (sum) numMiss_child, by(interview__id)

tempfile missChild
save "`missChild'"

/*-----------------------------------------------------------------------------
Garden level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`parcels'"

gen numMiss_garden = (hh_f_1_2a2 == .a & _merge == 3 & !mi(hh_f_1_02e))
collapse (sum) numMiss_garden, by(interview__id)

tempfile missGarden
save "`missGarden'"

/*-----------------------------------------------------------------------------
Rainy plot level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsRainy'"

gen numMiss_plotsRainy = (ag_c04c == .a & _merge == 3 & !mi(ag_c05c))
collapse (sum) numMiss_plotsRainy, by(interview__id)

tempfile missPlotRainy
save "`missPlotRainy'"

/*-----------------------------------------------------------------------------
Dimba plot level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsDimba'"

gen numMiss_plotsDimba = (ag_j04c == .a & _merge == 3 & !mi(ag_j05c))
collapse (sum) numMiss_plotsDimba, by(interview__id)

tempfile missPlotDimba
save "`missPlotDimba'"

/*-----------------------------------------------------------------------------
Tree/permanent plot level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsPerm'"

gen numMiss_plotsPerm = (ag_o_2_4c == .a & _merge == 3 & !mi(ag_o_2_05c))
collapse (sum) numMiss_plotsPerm, by(interview__id)

tempfile missPlotPerm
save "`missPlotPerm'"

/*=============================================================================
Calculate overall number of legitimate missing
=============================================================================*/

* combine temp files
use "`constructedDir'/casesToReview.dta", clear

local filesWMiss = "missHhold missMember missEnterprise missChild missGarden missPlotRainy missPlotDimba missPlotPerm"

foreach fileWMiss of local filesWMiss {

	merge 1:1 interview__id using "``fileWMiss''", nogen

}

* compute total legitimate missings
egen numLegitMiss = rowtotal(numMiss*)

* save result
save "`constructedDir'/numLegitMiss.dta", replace
