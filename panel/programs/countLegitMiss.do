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
gen numMiss_headName = (t0_headname1 == "##N/A##")
gen numMiss_hhsize = inlist(t0_hhsize, "", "##N/A##")
gen numMiss_y3Id = inlist(t0_y3_hhid, "", "##N/A##")
gen numMiss_hh_a09_hidden = inlist(hh_a09_hidden, "", "##N/A##")
gen numMiss_networkRoster = inlist(ag_net_1__0, "", "##N/A##")

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

* count missings
gen numMiss_pid = (pid_ihps == "##N/A##" & _merge == 3)
gen numMiss_e19 = (hh_e19_code == .a & _merge == 3 & interview__status == 100)
gen numMiss_e20 = (hh_e20_code == "##N/A##" & _merge == 3 & interview__status == 100)

* flag missings
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

* flag missings
gen numMiss_gardenID = (hh_f_1_panel == "##N/A##" & _merge == 3 )
gen numMiss_gardenArea = (hh_f_1_2a2 == .a & _merge == 3 & !mi(hh_f_1_02e))

* count missings
egen numMiss_garden = rowtotal(numMiss_gardenID numMiss_gardenArea)
collapse (sum) numMiss_garden, by(interview__id)

tempfile missGarden
save "`missGarden'"

/*-----------------------------------------------------------------------------
2016 rainy plot level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/t0_rsplotroster.dta"

* flag missings
gen numMiss_plotid_ihps = (plotid_ihps == "##N/A##" & _merge == 3)
gen numMiss_v = (v == "##N/A##" & _merge == 3)
gen numMiss_w = (w == "##N/A##" & _merge == 3)
gen numMiss_x = (x == "##N/A##" & _merge == 3)
gen numMiss_y = (y == "##N/A##" & _merge == 3)
gen numMiss_z = (z == "##N/A##" & _merge == 3)

* count missings
egen numMiss2016Rainy = rowtotal(numMiss*)
collapse (sum) numMiss2016Rainy, by(interview__id)

tempfile miss2016Rainy
save "`miss2016Rainy'"

/*-----------------------------------------------------------------------------
Rainy plot level
-----------------------------------------------------------------------------*/

use "`constructedDir'/casesToReview.dta", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsRainy'"

gen numMiss_plotsRainy = (ag_c04c == .a & _merge == 3 & !mi(ag_c05c))
collapse (sum) numMiss_plotsRainy, by(interview__id)

tempfile missPlotRainy
save "`missPlotRainy'"

/*=============================================================================
Calculate overall number of legitimate missing
=============================================================================*/

* combine temp files
use "`constructedDir'/casesToReview.dta", clear

local filesWMiss = "missHhold missMember missEnterprise missChild missGarden miss2016Rainy missPlotRainy"

foreach fileWMiss of local filesWMiss {

	merge 1:1 interview__id using "``fileWMiss''", nogen

}

* compute total legitimate missings
egen numLegitMiss = rowtotal(numMiss*)

* save result
save "`constructedDir'/numLegitMiss.dta", replace
