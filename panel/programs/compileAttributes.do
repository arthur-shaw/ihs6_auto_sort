/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Compile "attributes" for each interview. These "attributes"
				are indicators or counts that are used in either reports
				or the reject/review/approve decision--or both.

DEPENDENCIES:	createAttribute.do

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

/*=============================================================================
LOAD DATA FRAME AND HELPER FUNCTIONS
=============================================================================*/

/*-----------------------------------------------------------------------------
Initialise attributes data set
-----------------------------------------------------------------------------*/

clear
capture erase "`attributesPath'"
gen interview__id = ""
gen interview__key = ""
gen attribName = ""
gen attribVal = .
gen attribVars = ""
order interview__id interview__key attribName attribVal attribVars
save "`attributesPath'", replace

/*-----------------------------------------------------------------------------
Load helper functions
-----------------------------------------------------------------------------*/

include "`progDir'/helper/createAttribute.do"

/*=============================================================================
IDENTIFY CASES TO REVIEW
=============================================================================*/

use "`constructedDir'/casesToReview.dta", clear
tempfile casesToReview
save "`casesToReview'"

/*=============================================================================
CREATE ATTRIBUTES
=============================================================================*/

/*-----------------------------------------------------------------------------
HOUSEHOLD
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:1 interview__id interview__key using "`rawDir'/`hhold'", nogen

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
STATUS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* interview status
createAttribute using "`attributesPath'", ///
	extractAttrib(interview__status) ///
	attribName(interviewStatus) ///

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
PANEL TYPE: A, B
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* type A
createAttribute using "`attributesPath'", ///
	genAttrib(hh_a05 == 2) ///
	attribName(panelA)

* type B
createAttribute using "`attributesPath'", ///
	genAttrib(hh_a05 == 3) ///
	attribName(panelB)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

createAttribute using "`attributesPath'", ///
	countVars(hh_g01*) 			///
	varVals(1) 					///
	attribName(numFoodItems) 	///
	attribVars(hh_g01)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
NON-FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* past 1 week
createAttribute using "`attributesPath'", ///
	countVars(hh_i01a*) 		///
	varVals(1) 					///
	attribName(numNonFood_1w) 	///
	attribVars(^hh_i01a)

* past 1 month
createAttribute using "`attributesPath'", ///
	countVars(hh_i04*) 			///
	varVals(1) 					///
	attribName(numNonFood_1m) 	///
	attribVars(^hh_i04)

* past 3 months
createAttribute using "`attributesPath'", ///
	countVars(hh_j01*) 			///
	varVals(1) 					///
	attribName(numNonFood_3m) 	///
	attribVars(^hh_j01)

* past 12 months, purchased
createAttribute using "`attributesPath'", ///
	countVars(hh_k01*) 			///
	varVals(1) 					///
	attribName(numNonFood_12m_purch) ///
	attribVars(^hh_k01)

* past 12 months, not purchased
createAttribute using "`attributesPath'", ///
	countVars(hh_k01a*) 		///
	varVals(1) 					///
	attribName(numNonFood_12m_nonPurch) ///
	attribVars(^hh_k01a)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
NON-FARM ENTERPRISE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

createAttribute using "`attributesPath'", ///
	countList(hh_n09a) 			///
	listMiss("##N/A##") 		///
	attribName(numEnterprises) 	///
	attribVars(^hh_n09a)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
AGRICULTURE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* engaged in agriculture
createAttribute using "`attributesPath'", ///
	genAttrib(hh_x10 == 1) 	///
	attribName(doesAgriculture)		 					///
	attribVars(hh_x10)

	// alternative definition
	// at least 1 plot where crops harvested : hh_f_1_05_1a == 1

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LIVESTOCK
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* owns livestock
createAttribute using "`attributesPath'", ///
	genAttrib(hh_x11 == 1) ///
	attribName(ownsLivestock) ///
	attribVars(hh_x11)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
FISHERIES
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

createAttribute using "`attributesPath'", ///
	genAttrib(hh_x16 == 1) ///
	attribName(doesFishing) ///
	attribVars(hh_x16)

/*-----------------------------------------------------------------------------
MEMBERS
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`members'", nogen

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DEMOGRAPHICS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* number of household heads
createAttribute using "`attributesPath'", ///
	countWhere(hh_b04 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(numHeads) ///
	attribVars(hh_b04)

* household size
createAttribute using "`attributesPath'", ///
	countWhere(!mi(hh_b03)) ///
	byGroup(interview__id interview__key) ///
	attribName(numMembers) ///
	attribVars(hh_b03)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LABOR
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* wage labor
createAttribute using "`attributesPath'", ///
	anyWhere(inlist(hh_e06_8__1, 1, 2)) ///
	byGroup(interview__id interview__key) ///
	attribName(wageIncome) ///
	attribVars(hh_e06_8)

* works in hhold NFE
createAttribute using "`attributesPath'", ///
	anyWhere(inlist(hh_e06_8__2, 1, 2)) ///
	byGroup(interview__id interview__key) ///
	attribName(worksInNFE) ///
	attribVars(hh_e06_8)

* works in hhold ag
createAttribute using "`attributesPath'", ///
	anyWhere(inlist(hh_e06_8__3, 1, 2)) ///
	byGroup(interview__id interview__key) ///
	attribName(worksInAg) ///
	attribVars(hh_e06_8)

* works in hhold livestock
createAttribute using "`attributesPath'", ///
	anyWhere(hh_e06_1b == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(worksInLivestock) ///
	attribVars(hh_e06_1b)

* works in household fishing activities
createAttribute using "`attributesPath'", ///
	anyWhere(hh_e06_1c == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(worksInFisheries) ///
	attribVars(hh_e06_1c)

/*-----------------------------------------------------------------------------
ENTERPRISES
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`enterprises'", nogen

* gets enterprise profit
createAttribute using "`attributesPath'", ///
	anyWhere(hh_n40 >0 & !mi(hh_n40)) ///
	byGroup(interview__id interview__key) ///
	attribName(enterpriseIncome) ///
	attribVars(hh_n40)

/*-----------------------------------------------------------------------------
OTHER INCOME
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`othIncome'", nogen

* whether receive any other income
createAttribute using "`attributesPath'", ///
	anyWhere((hh_p02 >0 & !mi(hh_p02))) ///
	byGroup(interview__id interview__key) ///
	attribName(othIncome) ///
	attribVars(hh_p02)

/*-----------------------------------------------------------------------------
SOCIAL SAFETY NETS
-----------------------------------------------------------------------------*/

* pre-coded safety nets
use "`rawDir'/`safetyNets'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`safetyNets'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere((hh_r02a > 0 & !mi(hh_r02a)) | (hh_r02b > 0 & !mi(hh_r02b)) | (hh_r02c > 0 & !mi(hh_r02c))) ///
		byGroup(interview__id interview__key) ///
		attribName(safetyNetIncome_main) ///
		attribVars(hh_r02[abc]$)

}
else if `numObs' == 0 {
	preserve
		use "`casesToReview'", clear
		gen attribName = "safetyNetIncome_main"
		gen attribVal = 0
		gen attribVars = "hh_r02[abc]$"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore
}

* other safety nets
use "`rawDir'/`safetyNetsOth'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`safetyNetsOth'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere((hh_r02a_1 > 0 & !mi(hh_r02a_1)) | (hh_r02b_1 > 0 & !mi(hh_r02b_1)) | (hh_r02c_1 > 0 & !mi(hh_r02c_1))) ///
		byGroup(interview__id interview__key) ///
		attribName(safetyNetIncome_oth) ///
		attribVars(hh_r02[abc]_[123])

}
else if `numObs' == 0 {
	preserve
		use "`casesToReview'", clear
		gen attribName = "safetyNetIncome_oth"
		gen attribVal = 0
		gen attribVars = "hh_r02[abc]_[123]"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore
}

/*-----------------------------------------------------------------------------
PARCELS (GARDENS)
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`parcels'", nogen

* number gardens

	// TODO: ask whether only interested in cultivated parcels?

* number of rainy gardens
createAttribute using "`attributesPath'", ///
	countWhere(hh_f_1_05_1 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(numParcelsRainy) ///
	attribVars(hh_f_1_05_1)

* number dimba gardens
createAttribute using "`attributesPath'", ///
	countWhere(hh_f_1_05_2 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(numParcelsDimba) ///
	attribVars(hh_f_1_05_2)

* number of tree/permanent crop gardens
createAttribute using "`attributesPath'", ///
	countWhere(hh_f_1_05_3 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(numParcelsPerm) ///
	attribVars(hh_f_1_05_3)

* cultivating crops in the rainy/dry season
createAttribute using "`attributesPath'", ///
	anyWhere(hh_f_1_05_1 == 1 & hh_f_1_05_2 == 1) /// at least 1 plot with crops that was harvested in rainy/dry season
	byGroup(interview__id interview__key) ///
	attribName(growsAnnualCrops) ///
	attribVars(hh_f_1_05_1|hh_f_1_05_2)

* cultivating rainy season crops
createAttribute using "`attributesPath'", ///
	anyWhere(hh_f_1_05_1 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(growsRainyCrops) ///
	attribVars(hh_f_1_05_1)

* cultivating dimba season crops
createAttribute using "`attributesPath'", ///
	anyWhere(hh_f_1_05_2 == 1) /// at least 1 plot with crops that was harvested in rainy/dry season
	byGroup(interview__id interview__key) ///
	attribName(growsDimbaCrops) ///
	attribVars(hh_f_1_05_2)

* cultivating tree / permanent crops
createAttribute using "`attributesPath'", ///
	anyWhere(hh_f_1_05_3 == 1) /// at least 1 plot with crops that is tree/permanent
	byGroup(interview__id interview__key) ///
	attribName(growsPermCrops) ///
	attribVars(hh_f_1_05_3)

* number of gardens NOT measured with GPS
createAttribute using "`attributesPath'", ///
	countWhere((hh_f_1_05_1 == 1 | hh_f_1_05_2 == 1 | hh_f_1_05_3 == 1) & inlist(hh_f_1_02e, 1, 2, 3, 4)) ///
	byGroup(interview__id interview__key) ///
	attribName(numGardensNotMeasured) ///
	attribVars(hh_f_1_02e)

	/*TODO: update # gardens measured based on which are gardens of interest */

/*-----------------------------------------------------------------------------
PLOTS, RAINY
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsRainy'", nogen

* number of plots
local plotIDVar = subinstr("`plotsRainy'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`plotIDVar')) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsRainy) ///
	attribVars(`plotIDVar')

* number plot NOT measured
createAttribute using "`attributesPath'", ///
	countWhere(inlist(ag_c05c, 1, 2, 3, 4)) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsRainyNotMeasured) ///
	attribVars(ag_c05c)

* number of crops
preserve
	
	* identify crop variables
	qui: d ag_d20*, varlist
	local cropVars = r(varlist)
	local othCrop "ag_d20_oth"
	local cropVars : list cropVars - othCrop

	* calculate total crops
	egen numCrops = anycount(`cropVars'), values(1 2 3 4 5)
	collapse (sum) numCrops, by(interview__id interview__key)

	* define attributes
	gen attribName 	= "numCropsRainy"
	gen attribVal 	= numCrops
	gen attribVars 	= "^ag_d20"

	* save attribute to attribute file
	keep interview__id interview__key attribName attribVal attribVars
	order interview__id interview__key attribName attribVal attribVars
	append using "`attributesPath'"
	sort interview__id
	save "`attributesPath'", replace

restore

* grows staple crops
/* TODO: Update once have definition of staple crop */
egen growsMaize = anymatch(ag_d20__1 ag_d20__2 ag_d20__3 ag_d20__4), values(1 2 3 4 5)
egen growsBeans = anymatch(ag_d20__34 ag_d20__36), values(1 2 3 4 5)
egen growsRice = anymatch(ag_d20__17 ag_d20__18 ag_d20__19 ag_d20__20 ag_d20__21 ag_d20__22 ag_d20__23 ag_d20__24 ag_d20__25 ag_d20__26), values(1 2 3 4 5)

createAttribute using "`attributesPath'", ///
	anyWhere(growsRice == 1 | growsBeans == 1 | growsRice == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(growsStapleRainy) ///
	attribVars(^ag_d20)

/*-----------------------------------------------------------------------------
PLOTS, DIMBA
-----------------------------------------------------------------------------*/
* not relevant for panel visit 1
/*
use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsDimba'", nogen

* number of plots
local plotIDVar = subinstr("`plotsDimba'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`plotIDVar')) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsDimba) ///
	attribVars(`plotIDVar')

* number plot NOT measured
createAttribute using "`attributesPath'", ///
	countWhere(inlist(ag_j05c, 1, 2, 3, 4)) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsDimbaNotMeasured) ///
	attribVars(ag_j05c)

* number of crops
preserve
	
	* identify crop variables
	qui: d ag_k21*, varlist
	local cropVars = r(varlist)
	local othCrop "ag_k21_oth"
	local cropVars : list cropVars - othCrop

	* calculate total crops
	egen numCrops = anycount(`cropVars'), values(1 2 3 4 5)
	collapse (sum) numCrops, by(interview__id interview__key)

	* define attributes
	gen attribName 	= "numCropsDimba"
	gen attribVal 	= numCrops
	gen attribVars 	= "^ag_k21"

	* save attribute to attribute file
	keep interview__id interview__key attribName attribVal attribVars
	order interview__id interview__key attribName attribVal attribVars
	append using "`attributesPath'"
	sort interview__id
	save "`attributesPath'", replace

restore

* grows staple crops
/* TODO: Update once have definition of staple crop */
egen growsMaize = anymatch(ag_k21__1 ag_k21__2 ag_k21__3 ag_k21__4), values(1 2 3 4 5)
egen growsBeans = anymatch(ag_k21__34 ag_k21__36), values(1 2 3 4 5)
egen growsRice = anymatch(ag_k21__17 ag_k21__18 ag_k21__19 ag_k21__20 ag_k21__21 ag_k21__22 ag_k21__23 ag_k21__24 ag_k21__25 ag_k21__26), values(1 2 3 4 5)

createAttribute using "`attributesPath'", ///
	anyWhere(growsRice == 1 | growsBeans == 1 | growsRice == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(growsStapleDimba) ///
	attribVars(^ag_k21)
*/
/*-----------------------------------------------------------------------------
PLOTS, PERMANENT/TREE
-----------------------------------------------------------------------------*/
* not relevant for panel visit 1
/*
use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`plotsPerm'", nogen

* number of plots
local plotIDVar = subinstr("`plotsPerm'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`plotIDVar')) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsPerm) ///
	attribVars(`plotIDVar')

* number plot NOT measured
createAttribute using "`attributesPath'", ///
	countWhere(inlist(ag_o_2_05c, 1, 2, 3, 4)) ///
	byGroup(interview__id interview__key) ///
	attribName(numPlotsPermNotMeasured) ///
	attribVars(ag_o_2_05c)

* number of crops
preserve
	
	* identify crop variables
	qui: d ag_p0_crops*, varlist
	local listVars = r(varlist)

	* remove missing marker
	local listMiss = "##N/A##"
	foreach listVar of local listVars {
		replace `listVar' = "" if (`listVar' == "`listMiss'")
	}

	* calculate total crops
	egen numCrops = rownonmiss(`listVars'), strok
	collapse (sum) numCrops, by(interview__id interview__key)

	* define attributes
	gen attribName 	= "numCropsPerm"
	gen attribVal 	= numCrops
	gen attribVars 	= "^ag_p0_crops"

	* save attribute to attribute file
	keep interview__id interview__key attribName attribVal attribVars
	order interview__id interview__key attribName attribVal attribVars
	append using "`attributesPath'"
	sort interview__id
	save "`attributesPath'", replace

restore*/

/*-----------------------------------------------------------------------------
SALES, RAINY
-----------------------------------------------------------------------------*/
* not relevant for panel visit 1
/*
use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`salesRainy'", nogen

* any rainy season sales
createAttribute using "`attributesPath'", ///
	anyWhere((ag_i03 > 0 & !mi(ag_i03)) | (ag_i34a > 0 & !mi(ag_i34a))) ///
	byGroup(interview__id interview__key) ///
	attribName(salesRainy) ///
	attribVars(ag_i03|ag_i34a)
*/
/*-----------------------------------------------------------------------------
SALES, DIMBA
-----------------------------------------------------------------------------*/
* not relevant for panel visit 1
/*
use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`salesDimba'", nogen

* any dimba sales
createAttribute using "`attributesPath'", ///
anyWhere((ag_o03 > 0 & !mi(ag_o03)) | (ag_o34a > 0 & !mi(ag_o34a))) ///
byGroup(interview__id interview__key) ///
attribName(salesDimba) ///
attribVars(ag_o03|ag_o34a)
*/
/*-----------------------------------------------------------------------------
SALES, TREE/PERMANENT
-----------------------------------------------------------------------------*/
* not relevant for panel visit 1
/*
use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`salesPerm'", nogen

* any tree sales
createAttribute using "`attributesPath'", ///
	anyWhere((ag_q03 > 0 & !mi(ag_q03)) | (ag_q33a > 0 & !mi(ag_q33a))) ///
	byGroup(interview__id interview__key) ///
	attribName(salesPerm) ///
	attribVars(ag_q03|ag_q33a)
*/
/*-----------------------------------------------------------------------------
LIVESTOCK
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`livestock'", nogen

* number of livestock
createAttribute using "`attributesPath'", ///
	countWhere(!mi(livestock__id)) ///
	byGroup(interview__id interview__key) ///
	attribName(numLivestock) ///
	attribVars(livestock__id)

* any sales of livestock
createAttribute using "`attributesPath'", ///
	anyWhere(ag_r17 > 0 & !mi(ag_r17)) ///
	byGroup(interview__id interview__key) ///
	attribName(salesLivestock) ///
	attribVars(ag_r17)

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`livestockProd'", nogen

* any sales of livestock products
createAttribute using "`attributesPath'", ///
	anyWhere(ag_s06 > 0 & !mi(ag_s06)) ///
	byGroup(interview__id interview__key) ///
	attribName(salesLivestockProducts) ///
	attribVars(ag_s06)

/*-----------------------------------------------------------------------------
FISHERIES
-----------------------------------------------------------------------------*/

* any high season sales
use "`rawDir'/`salesFishHigh'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`salesFishHigh'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere(((fs_e08a > 0 & !mi(fs_e08a)) &  (fs_e08f > 0 & !mi(fs_e08f))) | ((fs_e08g > 0 & !mi(fs_e08g)) & (fs_e08l > 0 & !mi(fs_e08l)))) ///
		byGroup(interview__id interview__key) ///
		attribName(salesFishHigh) ///
		attribVars(fs_e08a|fs_e08f|fs_e08g|fs_e08l)

}
else if `numObs' == 0 {

	preserve
		use "`casesToReview'", clear
		gen attribName = "salesFishHigh"
		gen attribVal = 0
		gen attribVars = "fs_e08a|fs_e08f|fs_e08g|fs_e08"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore

}

* any high season fish trading sales
use "`rawDir'/`salesFishTrHi'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`salesFishTrHi'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere(((fs_f03a > 0 & !mi(fs_f03a)) & (fs_f03f > 0 & !mi(fs_f03f))) | ((fs_f03h > 0 & !mi(fs_f03h)) & (fs_03m > 0 & !mi(fs_03m)))) ///
		byGroup(interview__id interview__key) ///
		attribName(salesFishTrHi) ///
		attribVars(fs_f03a|fs_f03f|fs_f03h|fs_03m)

}
else if `numObs' == 0 {

	preserve
		use "`casesToReview'", clear
		gen attribName = "salesFishTrHi"
		gen attribVal = 0
		gen attribVars = "fs_f03a|fs_f03f|fs_f03h|fs_03m"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore

}

* any low season sales
use "`rawDir'/`salesFishLow'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`salesFishLow'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere(((fs_i08a > 0 & !mi(fs_i08a)) & (fs_i08f > 0 & !mi(fs_i08f))) | ((fs_i08g > 0 & !mi(fs_i08g)) & (fs_i08l > 0 & !mi(fs_i08l)))) ///
		byGroup(interview__id interview__key) ///
		attribName(salesFishLow) ///
		attribVars(fs_i08a|fs_i08f|fs_i08g|fs_i08l)

}
else if `numObs' == 0 {
	preserve
		use "`casesToReview'", clear
		gen attribName = "salesFishLow"
		gen attribVal = 0
		gen attribVars = "fs_i08a|fs_i08f|fs_i08g|fs_i08l"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore
}

* any low season fish trading sales
use "`rawDir'/`salesFishTrLo'", clear
qui : d
local numObs = r(N)
if `numObs' > 0 {

	use "`casesToReview'", clear
	merge 1:m interview__id interview__key using "`rawDir'/`salesFishTrLo'", nogen
	createAttribute using "`attributesPath'", ///
		anyWhere(((fs_j03a > 0 & !mi(fs_j03a)) & (fs_j03f > 0 & !mi(fs_j03f))) | ((fs_j03g > 0 & !mi(fs_j03g)) & (fs_j03l > 0 & !mi(fs_j03l)))) ///
		byGroup(interview__id interview__key) ///
		attribName(salesFishTrLo) ///
		attribVars(fs_j03a|fs_j03f|fs_j03g|fs_j03l)

}
else if `numObs' == 0 {
	preserve
		use "`casesToReview'", clear
		gen attribName = "salesFishTrLo"
		gen attribVal = 0
		gen attribVars = "fs_j03a|fs_j03f|fs_j03g|fs_j03l"
		order interview__id interview__key attribName attribVal attribVars
		append using "`attributesPath'"
		save "`attributesPath'", replace
	restore
}

/*-----------------------------------------------------------------------------
CONSTRUCTED DATA
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TOTAL CALORIES
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`constructedDir'/`caloriesTot'", nogen

* level of calories per person per day
createAttribute using "`attributesPath'", ///
	extractAttrib(totCalories) ///
	attribName(totalCalories) ///
	attribVars(^hh_g01_|^hh_g03a|^hh_g03b|^hh_g03c)

* too many calories (i.e., x > 4000)
createAttribute using "`attributesPath'", ///
	extractAttrib(caloriesTooHigh) ///
	attribName(caloriesTooHigh) ///
	attribVars(^hh_g01_|^hh_g03a|^hh_g03b|^hh_g03c)

/*
* DISABLED UNTIL CONVERSION FILE FIXED
* too few calories (i.e., x < 800)
createAttribute using "`attributesPath'", ///
	extractAttrib(caloriesTooLow) ///
	attribName(caloriesTooLow) ///
	attribVars(^hh_g01_|^hh_g03a|^hh_g03b|^hh_g03c)
*/
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
CALORIES BY ITEM
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`constructedDir'/`caloriesByItem'", nogen

* too many calories for one item (i.e., x > 1500)
createAttribute using "`attributesPath'", ///
	anyWhere(highItemCalories == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(highItemCalories) ///
	attribVars(^hh_g01_|^hh_g03a|^hh_g03b|^hh_g03c)

/*-----------------------------------------------------------------------------
CORRECT INDICATORS WHERE MODULES NOT ADMINISTERED
-----------------------------------------------------------------------------*/

use "`attributesPath'", clear
merge m:1 interview__id interview__key using "`rawDir'/`hhold'", nogen keepusing(hh_a05)

* number of food items
replace attribVal = . if (attribName == "numFoodItems" & hh_a05 == 3)

* number of non-food items
replace attribVal = . if (regexm(attribName, "^numNonFood_") & hh_a05 == 3)

* number of enterprises
replace attribVal = . if ((attribName == "numEnterprises") & hh_a05 == 3)

drop hh_a05

save "`attributesPath'", replace
