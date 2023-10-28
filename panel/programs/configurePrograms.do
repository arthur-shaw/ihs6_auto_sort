/*=============================================================================
CONFIGURATION PARAMETERS
=============================================================================*/

set more 1

/*-----------------------------------------------------------------------------
How to call R
-----------------------------------------------------------------------------*/

local howCallR 	""	// values: rcall, shell
local rPath 	"" // values: blank or path to R.exe

/*-----------------------------------------------------------------------------
Server details
-----------------------------------------------------------------------------*/

local server 		= 	"" 	// complete server URL (e.g., "https://my-server.domain")
local workspace 	= 	""	// workspace
local login			= 	"" 	// login for API user or admin
local password		= 	"" 	// password for user whose login is provided above
local qnrName 		=	"IHS6 Panel[_ ]Visit1" 	// questionnaire title--that is, title, not questionnaire variable

/*-----------------------------------------------------------------------------
Identify interviews to process
-----------------------------------------------------------------------------*/

* by Survey Solutions status
local statusesToReject "100, 120"	// enter as a comma-separated list of numeric codes

	// possible values listed here: 
	// 100	Completed
	// 120	ApprovedBySupervisor
	// read here for more: // https://support.mysurvey.solutions/headquarters/export/system-generated---export-file-anatomy/#coding_status

* by expression that indicated a "complete" interview
# delim ;

* !!! TODO: See whether this is needed for IHS5. Eliminate if not !!! ;

local completedInterview `"

(consent == 1) & !regexm(comment, "[Cc]all[ -]*[Bb]ack")

"';
#delim cr

* maximum number of unanswered answers to allow
local maxUnanswered = 5

/*-----------------------------------------------------------------------------
Construct file paths
-----------------------------------------------------------------------------*/

* construct paths relative to projet root
local dataDir			"`projDir'/data/"
local resourceDir 		"`projDir'/data/00_resource/"
local downloadDir 		"`projDir'/data/01_downloaded/"
local rawDir 			"`projDir'/data/02_combined/"
local constructedDir 	"`projDir'/data/03_derived/"
local progDir 			"`projDir'/programs/"
local resultsDir 		"`projDir'/output/"
local logDir 			"`projDir'/logs/"

* make paths R-friendly
local filePaths "downloadDir rawDir constructedDir resourceDir progDir resultsDir logDir"

foreach filePath of local filePaths {

	* replace backslashes with slashes
	local `filePath' = subinstr("``filePath''", "\", "/", .)
	
	* ensure path has a terminal slash
	capture assert substr("``filePath''", -1, 1) == "/"
	if _rc != 0 {
		local `filePath' = "``filePath''" + "/"
	}

} 

* ensure R.exe file path has slashes instead of backslashes
local rPath = subinstr("`rPath'", "\", "/", .)

/*-----------------------------------------------------------------------------
Calorie computation data and variables
-----------------------------------------------------------------------------*/

* conversion factors (country-specific)
local factorsDta 		"IHS4 units to IHS5 units converstion factor.dta" 					// name of conversion factors file				// name of conversion factors file
local factorsByGeo		"true" 				// whether factors reported by geo: "true" or "false"
local geoIDs 			"ihs_region"		// geographic ID variables common to conversion factors and hhold data
local prodID_fctrCurr 	"item" 		// current product ID
local prodID_fctrNew 	"productID" 		// new productID
local unitIDs_fctrCurr 	"unit_code sub_unit_code" 	// current unit IDs in factors file
local unitIDs_fctrNew 	"hh_g03b hh_g03c" // new unit IDs in factors file
local factorVar 		"factor" // variable name for conversion factor

* calories (project-specific)
local caloriesDta 		"calories_updated_05_08.dta"
local prodID_calCurr 	"item"
local prodID_calNew 	"productID"
local caloriesVar		"cal_100g"		// variable name for calories per 100g
local edibleVar			"edible_p" 	// variable names for % edible

* hhold (project-specific)
local memberList 		"hh_b02" 		// variable name of list of hhold members

* food consumption (project-specific)
local consoDta 			"foodConsumption.dta" // name of the combined food consumption data set
local quantityVar 		"hh_g03a" 			// total quantity in combined food data set

* output (project-specific)
local outputDir 		"`constructedDir'" 	// folder where calories files should be saved

/*-----------------------------------------------------------------------------
Raw data
-----------------------------------------------------------------------------*/

local hhold 		"Panel_Visit1.dta" 					
local members 		"t0_hhroster.dta" 						
local enterprises 	"enterpriseRoster.dta"
local othIncome 	"other_income_roster.dta"
local safetyNets 	"social_safety_nets_roster.dta"
local safetyNetsOth "r_other_social_safety_roster.dta"
local parcels 		"hh_f_1_garden_roster.dta" 	
local plotsRainy 	"ag_c_plot_roster.dta"
* local plotsDimba 	"ag_J_plot_roster.dta"		// NA in visit 1
* local plotsPerm 	"ag_o_2_plot_roster.dta" 	// NA in visit 1
* local salesRainy 	"ag_H_seed_roster.dta" 		// NA in visit 1
* local salesDimba 	"ag_n_seeds_roster.dta" 	// NA in visit 1
* local salesPerm 	"ag_Q_storage_roster.dta" 	// NA in visit 1
local livestock 	"livestock.dta"
local livestockProd "livestockProducts.dta"
local salesFishHigh "fs_e_outputroster.dta"
local salesFishTrHi "fs_f_fishtrading.dta"
local salesFishLow 	"roster_fisheriesoutput.dta"
local salesFishTrLo "fs_j_fishspecies.dta"

#delim ;
local necessaryFiles = "
hhold
members
enterprises
othIncome
safetyNets
safetyNetsOth
parcels
plotsRainy
livestock
livestockProd
salesFishHigh
salesFishTrHi
salesFishLow
salesFishTrLo
";
#delim cr

* not applicable in visit 1: 
* plotsDimba
* plotsPerm
* salesRainy
* salesDimba
* salesPerm

/*-----------------------------------------------------------------------------
Generated data
-----------------------------------------------------------------------------*/

local attributes 		"attributes.dta"
local issues			"issues.dta"
local combinedFood 		"foodConsumption.dta"
local caloriesTot 		"totCalories.dta"
local caloriesByItem 	"caloriesByItem.dta"

/*-----------------------------------------------------------------------------
Construct full paths for select files
-----------------------------------------------------------------------------*/

local attributesPath 	"`constructedDir'/`attributes'"
local issuesPath 		"`constructedDir'/`issues'"
local errCheckPath 		""

/*-----------------------------------------------------------------------------
Consumption data and variables
-----------------------------------------------------------------------------*/

#delim ;

* data files names ;
local consoRosterList "
g_cereal_grains_roster
g_roots_tubers_roster
g_nuts_pulses
g_vegetables_roster
g_meat_fish_roster
g_fruits_roster
g_cooked_foods_roster
g_milk_roster
g_sugar_fats_roster
g_beverages_roster
g_spices_roster
";

* variable names ;
local consoVarList "
hh_g03a
hh_g03b
hh_g03b_oth
hh_g03c
hh_g04a
hh_g04b
hh_g04b_oth
hh_g04c
hh_g05
hh_g06a
hh_g06b
hh_g06b_oth
hh_g06c
hh_g07a
hh_g07b
hh_g07b_oth
hh_g07c
";

#delim cr

/*=============================================================================
PASS PARAMETERS TO R
=============================================================================*/

/*-----------------------------------------------------------------------------
Server details
-----------------------------------------------------------------------------*/

file open  serverDetails using "`progDir'/serverDetails.R", write replace
file write serverDetails `"server 	<- "`server'""' 	_n
file write serverDetails `"workspace <- "`workspace'""'	_n
file write serverDetails `"login 	<- "`login'""' 		_n
file write serverDetails `"password <- "`password'""' 	_n
file close serverDetails

/*-----------------------------------------------------------------------------
Location of files and folders
-----------------------------------------------------------------------------*/

* capture Stata version ; fix ceiling at 14 for R's purposes (because of haven)
local stataVersion = c(version)
local stataVersion = int(`stataVersion') 
if (`stataVersion' >= 14) {
	local stataVersion "14"
}

file open filePaths using "`progDir'/filePaths.R", write replace
file write filePaths "# folders" 										_n
file write filePaths `"data_dir			<- "`dataDir'""'				_n
file write filePaths `"download_dir		<- "`downloadDir'""'			_n
file write filePaths `"combined_dir		<- "`rawDir'""'					_n
file write filePaths `"derived_dir 		<- "`constructedDir'""'			_n
file write filePaths `"prog_dir			<- "`progDir'""' 				_n
file write filePaths `"log_dir 			<- "`logDir'""' 				_n
file write filePaths `"output_dir 		<- "`resultsDir'""'				_n
file write filePaths "" 												_n
* NOTE: update these valus as needed
file write filePaths "# files" 											_n
file write filePaths `"commentsDta 		<- "interview__comments.dta""' 	_n
file write filePaths `"issuesDta 		<- "issues.dta""' 				_n
file write filePaths `"casesToReviewDta <- "casesToReview.dta""' 		_n
file write filePaths `"interviewStatsDta <- "interviewStats.dta""' 		_n
file write filePaths `"numLegitMissDta 	<- "numLegitMiss.dta""' 		_n
file write filePaths "" 												_n
file write filePaths `"# parameters"' 									_n
file write filePaths `"serverDetails 	<- "serverDetails.R""' 			_n
file write filePaths `"stataVersion 	<- `stataVersion'"'				_n
file write filePaths `"statusesToReject <- c(`statusesToReject')"' 		_n
file write filePaths `"qnr_expr 		<- "`qnrName'""' 				_n
file write filePaths "maxUnanswered 	<- `maxUnanswered'" 			_n
file close filePaths
