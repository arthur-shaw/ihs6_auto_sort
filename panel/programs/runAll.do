/*=============================================================================
Project settings
=============================================================================*/

local projDir ""

include "`projDir'/programs/configurePrograms.do"

/*=============================================================================
Load all necessary Stata programs
=============================================================================*/

#delim ;
local programsNeeded "
combineConsumption.do
computeCalories.do
";
#delim cr

local progLoc = "`progDir'"

foreach programNeeded of local programsNeeded {

	* check whether program exists
	capture confirm file "`progLoc'/`programNeeded'"
	
	* if not, issue show an error and stop execution
	if _rc != 0 {
		di as error "Program missing"
		di as error "Expected program: `programNeeded'"
		di as error "Expected location: `progLoc'"
		error 1
	}

	* if so, load the program definition
	else if _rc == 0 {
		include "`progLoc'/`programNeeded'"
	}

}

/*=============================================================================
Download data
=============================================================================*/

* download data with R
if ("`howCallR'" == "rcall") {
	rcall sync : rm(list = ls()) 								// delete prior R session info
	rcall sync : source(paste0("`progDir'", "filePaths.R")) 	// pass parameters and file paths to R
	rcall sync : source(paste0("`progDir'", "_get_data.R")) 	// download data
}
else if ("`howCallR'" == "shell") {
	cd "`progDir'"
	shell "`rPath'" CMD BATCH filePaths.R
	shell "`rPath'" CMD BATCH _get_data.R
}

* confirm that files actually downloaded
local zipList : dir "`downloadDir'" files "*.zip" , nofail respectcase
local zipList : list clean zipList
if ("`zipList'" == "") {
	di as error "No data files downloaded from the server. Please try again."
	di as error "If this error persists, check the following: "
	di as error "1. Internet connection. "
	di as error "2. Server details--that is, the server, login, and password provided in configurePrograms.do"
	di as error "3. Server health. Navigate to the server, log in, and attempt to download a data file manually."
	di as error "4. Failure"
	error 1
}

/*=============================================================================
Combine consumption data
=============================================================================*/

combineConsumption , 					/// 
	rosterDtaList("`consoRosterList'") 	/// list of food consumption files
	varList("`consoVarList'") 			/// list of variables in consumption files
	diffPattern("hh_g01_[a-z_]+_oth hh_g01_oth") /// 
	inputDir("`rawDir'") 				/// where input files can be found
	outputDir("`constructedDir'") 		/// where output file should be saved
	outputDta("`combinedFood'") 		/// name of the output file
	outputID("productID") 				/// name of product ID variable in file

/*=============================================================================
Process data
=============================================================================*/

/*-----------------------------------------------------------------------------
Identify cases to be reviewed for rejection/approval
-----------------------------------------------------------------------------*/

include "`progDir'/identifyCasesToReview.do"

/*-----------------------------------------------------------------------------
Compute number of legitimate missings per hhold
-----------------------------------------------------------------------------*/

include "`progDir'/countLegitMiss.do"

/*-----------------------------------------------------------------------------
Compute calories
-----------------------------------------------------------------------------*/

computeCalories ,							///
	 /// --- CONVERSION FACTORS ---
	factorsDta("`resourceDir'/`factorsDta'") /// file path for conversion factors
	factorsByGeo(`factorsByGeo')			/// whether factors are broken down by geo
	geoIDs(`geoIDs') 						/// list of geo IDs
	prodID_fctrCurr(`prodID_fctrCurr') 		/// current product ID var in factors file
	prodID_fctrNew(`prodID_fctrNew') 		/// new var name for product ID
	unitIDs_fctrCurr(`unitIDs_fctrCurr') 	/// current unit ID vars in factors file
	unitIDs_fctrNew(`unitIDs_fctrNew') 		/// new var name for unit ID vars
	factorVar(`factorVar') 					/// conversion factor var
	 /// -- CALORIES ---
	caloriesDta("`resourceDir'/`caloriesDta'") /// file path for calories per product
	prodID_calCurr(`prodID_calCurr') 		/// current product ID var in calories file
	prodID_calNew(`prodID_calNew') 			/// new var name for product ID
	caloriesVar(`caloriesVar') 				/// calories per 100g in calories
	edibleVar(`edibleVar') 					/// edible portion variable in calories
	 /// --- HOUSEHOLD-LEVEL ---
	hholdDta("`rawDir'/`hhold'") 			/// file path for household-level file
	memberList(`memberList')				/// stub name for list variable (i.e., varname in Designer)
	 /// --- FOOD CONSUMPTION ---
	consoDta("`constructedDir'/`combinedFood'") /// file path for combined food consumption file
	quantityVar(`quantityVar') 				/// total quantity consumed var
	 /// --- OUTPUT ---
	outputDir("`constructedDir'") 			/// where to save output files: calories by item, total calories

/*-----------------------------------------------------------------------------
Compile interview attributes
-----------------------------------------------------------------------------*/

include "`progDir'/compileAttributes.do"

/*-----------------------------------------------------------------------------
Compile interview issues
-----------------------------------------------------------------------------*/

include "`progDir'/compileIssues.do"

/*-----------------------------------------------------------------------------
Add error check program observations to interview issues
-----------------------------------------------------------------------------*/

include "`progDir'/addErrorCheckObs.do"

/*=============================================================================
Decide how to process interviews
=============================================================================*/

/*-----------------------------------------------------------------------------
Run R programs to:

- Check interviews for comments
- Get interview statistics
- Decide what actions to take for each interview
- Make rejection messages
- Post comments
- Reject interviews
-----------------------------------------------------------------------------*/

if ("`howCallR'" == "rcall") {
	rcall sync : source(paste0("`progDir'", "filePaths.R"), echo = TRUE)
	rcall sync : source(paste0("`progDir'", "_execute_workflow.R"), echo = TRUE)
}
else if ("`howCallR'" == "shell") {
	cd "`progDir'"
	shell "`rPath'" CMD BATCH filePaths.R
	shell "`rPath'" CMD BATCH _execute_workflow.R
}

/*=============================================================================
Provide session statistics: numbers processed, to reject, to review, 
=============================================================================*/

* in data
use "`rawDir'/`hhold'", clear
qui : d
local numInData = r(N)

* processed
use "`constructedDir'/casesToReview.dta", clear
qui : d
local numProcessed = r(N)

* to reject / rejected
capture confirm file "`resultsDir'/to_reject_api.dta"
if (_rc == 0) {

	use "`resultsDir'/to_reject_api.dta", clear
	qui : d
	local numToReject = r(N)

}
else if ((_rc != 0) | (`numProcessed' == 0)) {

	local numToReject = 0

}

* to review
capture confirm file "`resultsDir'/to_review_api.dta"
if (_rc == 0) {

	use "`resultsDir'/to_review_api.dta", clear
	qui : d
	local numToReview = r(N)

}
else if ((_rc != 0) | (`numProcessed' == 0)) {

	local numToReview = 0

}

di as text "STATISTICS ON THE RESULTS OF THIS SESSION"
di as text "Here are the number of observations (households) by result :"
di as text "- In downloaded data : " as result "`numInData'"
di as text "- Processed : " as result "`numProcessed'"
di as text "- To reject (or already rejected) automatically : " as result "`numToReject'"
di as text "- To review more closely manually : " as result "`numToReview'"

