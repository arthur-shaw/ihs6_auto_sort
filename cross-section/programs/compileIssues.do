
/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Create "issues" for each interview. Issues are of three types:
				those that warrant rejection, those that are comments (to be
				posted to rejected interviews), and those that are SuSo
				validation errors. Issues are used in the reject/review/approve
				decision.

DEPENDENCIES:	createSimpleIssue.do, createComplexIssue.do

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

/*=============================================================================
LOAD DATA FRAME AND HELPER FUNCTIONS
=============================================================================*/

/*-----------------------------------------------------------------------------
Initialise issues data frame
-----------------------------------------------------------------------------*/

clear
capture erase "`issuesPath'"
gen interview__id = ""
gen interview__key = ""
gen issueType = .
label define types 1 "Critical error" 2 "Comment" 3 "SuSo validation error" 4 "Needs review"
label values issueType types
gen issueDesc = ""
gen issueComment = ""
gen issueLoc = ""
gen issueVars = ""
save "`issuesPath'", replace


/*-----------------------------------------------------------------------------
Load helper functions
-----------------------------------------------------------------------------*/

include "`progDir'/helper/createSimpleIssue.do"

include "`progDir'/helper/createComplexIssue.do"

/*=============================================================================
CREATE ISSUES
=============================================================================*/

/*-----------------------------------------------------------------------------
MEMBERS
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DEMOGRAPHICS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* more than 1 head
createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numHeads) ///
	issueCondit(numHeads > 1) ///
	issueType(1) ///
	issueDesc("More than 1 head") ///
	issueComm("ERROR: More than 1 member recorded as household head")

* no head
createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numHeads) ///
	issueCondit(numHeads == 0) ///	
	issueType(1) ///
	issueDesc("No head") ///
	issueComm("ERROR: No member recorded as household head")

/*-----------------------------------------------------------------------------
CONSUMPTION
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* no food consumption
createComplexIssue , 	///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numFoodItems) ///
	issueCondit(numFoodItems == 0) ///
	issueType(1) ///
	issueDesc("No food consumption") ///
	issueComm("ERROR: No food consumption reported in section G_1")

* calories too high overall
local highCaloriesCom = ///
"ERROR: Reported food consumption is too high. " +	///
"First, check quantities and units reported in G_3" + ///
"Then, confirm that reports concern consumption rather than acquisition" ///

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTooHigh) ///
	issueCondit(caloriesTooHigh == 1) ///
	issueType(1) ///
	issueDesc("Calories too high") ///
	issueComm("`highCaloriesCom'")

/*
* DISABLED UNTIL CONVERSION FILE FIXED
* calories too low overall
local lowCaloriesCom = ///
"ERROR: Reported food consumption is too low. " +	///
"First, confirm that all consumed food items have been reported. " + ///
"Then, verify that all quantities and units of consumption are correct"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTooLow) ///
	issueCondit(caloriesTooLow == 1) ///
	issueType(1) ///
	issueDesc("Calories too low") ///
	issueComm("`lowCaloriesCom'")
*/

* calories too high for one item
local caloriesItemComm = ///
"ERROR. Too many calories from one food item. " + ///
"First, look for the product with the biggest quantity or unit of " + ///
"consommation. " + ///
"Then, confirm that product's level of consumption."

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(highItemCalories) ///
	issueCondit(highItemCalories == 1) ///
	issueType(1) ///
	issueDesc("Calories too high for 1 item") ///
	issueComm("`caloriesItemComm'")

* items for which calories are too high

#delim ;

// names of product ID ranges for each food group
local range_cereales "inrange(productID, 101, 117)";
local range_tubers "inrange(productID, 201, 209)";
local range_nuts "inrange(productID, 301, 310)";
local range_veg "inrange(productID, 401, 414)";
local range_meats "inrange(productID, 501, 515) | 
	inlist(productID, 5021, 5022, 5023, 5031, 5032, 5033, 5121, 5122, 5123)";
local range_fruits "inrange(productID, 601, 610)";
local range_cooked "inrange(productID, 820, 830)";
local range_milk "inrange(productID, 701, 709)";
local range_fats "inrange(productID, 801, 804)";
local range_beverages "inrange(productID, 901, 916)";
local range_spices "inrange(productID, 810, 818)";

local rangeNames = "
range_cereales
range_tubers
range_nuts
range_veg
range_meats
range_fruits
range_cooked
range_milk
range_fats
range_beverages
range_spices
";

// names of quantity variable by food group
local variableNames = "
hh_g03a
hh_g03a_2
hh_g03a_4
hh_g03a_6
hh_g03a_8
hh_g03a_10
hh_g03a_12
hh_g03a_14
hh_g03a_16
hh_g03a_18
hh_g03a_20
";

#delim cr

use "`constructedDir'/`caloriesByItem'", clear

local numGroups : word count `rangeNames'
forvalues i = 1/`numGroups' {

	local idRange 		: word `i' of `rangeNames'
	local quantityVar 	: word `i' of `variableNames'

	createSimpleIssue using "`issuesPath'", ///
		flagWhere(highItemCalories == 1 & (``idRange'')) ///
		issueType(2) ///
		issueDesc("Calories higher than 1500 for this item") ///
		issueComm("Calories too high for this item") ///
		issueLocIDs(productID) ///
		issueVar(`quantityVar')

}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
NON-FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* no non-food consumption
#delim ;
local nonFoodVars "
numNonFood_1w 
numNonFood_1m 
numNonFood_3m 
numNonFood_12m_purch 
numNonFood_12m_nonPurch
";

local nonFoodCondit "
numNonFood_1w ==0  			& 
numNonFood_1m == 0 			& 
numNonFood_3m ==0  			& 
numNonFood_12m_purch ==0 	& 
numNonFood_12m_nonPurch ==0
";
#delim cr

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(`nonFoodVars') ///
	issueCondit(`nonFoodCondit') ///
	issueType(1) ///
	issueDesc("No non-food consumption") ///
	issueComm("ERROR: No non-food consumption reported (sections I, J, K)")

/*-----------------------------------------------------------------------------
INCOME
-----------------------------------------------------------------------------*/

* no income
#delim ;
local incomeVars "
wageIncome
enterpriseIncome
othIncome
safetyNetIncome_main
safetyNetIncome_oth
salesRainy
salesDimba
salesPerm
salesLivestock
salesLivestockProducts
salesFishHigh
salesFishTrHi
salesFishLow
salesFishTrLo
";

local incomeCondit "
wageIncome 	== 0 			&
enterpriseIncome == 0 		&
othIncome == 0 				&
safetyNetIncome_main == 0 	&
safetyNetIncome_oth == 0 	&
salesRainy == 0 			&
salesDimba == 0 			&
salesPerm == 0 				&
salesLivestock == 0 		&
salesLivestockProducts == 0 &
salesFishHigh == 0 			&
salesFishTrHi == 0 			&
salesFishLow == 0 			&
salesFishTrLo == 0
";
#delim cr

local incomeComm = 	///
"ERROR: No income source reported for this household: " + ///
"wage income (section E), " + ///
"enterprise income (section N), " + ///
"other income (section P), " + ///
"safety net income (section R), " + ///
"crop sales income (sections AG-I, AG-O, AG-Q), " + ///
"livestock sales (AG-R), " + ///
"livestock product sales (AG-S), " + ///
"fish sales (FS-E, FS-I), " + ///
"fish trading sales (FS-F, FS-J) "

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(`incomeVars') ///
	issueCondit(`incomeCondit') ///
	issueType(1) ///
	issueDesc("No income") ///
	issueComm("`incomeComm'")

/*-----------------------------------------------------------------------------
CRITICAL INCONSISTENCIES
-----------------------------------------------------------------------------*/

* work in NFE, but no NFE reported
local entrepriseComm = 														///
"ERROR: At least 1 member works in a household enterprise (section E). " + 	/// 
"But no household enterprise is reported (section N)."

createComplexIssue , ///
	attributesFile(`attributes') ///
	issuesFile(`issues') ///
	whichAttributes(worksInNFE numEnterprises) ///
	issueCondit(worksInNFE == 1 & numEnterprises == 0) ///
	issueType(1) ///
	issueDesc("Work in NFE, but no NFE reported") ///
	issueComm("`entrepriseComm'")

* work in ag, but not ag activity reported
local agricComm = 															///
"ERROR: At least 1 member works in household agriculture (section E). " + 	///
"But no agricultural activity is reported (section X)."

createComplexIssue , ///
	attributesFile(`attributes') ///
	issuesFile(`issues') ///
	whichAttributes(worksInAg doesAgriculture) ///
	issueCondit(worksInAg == 1 & doesAgriculture == 0) ///
	issueType(1) ///
	issueDesc("Work in ag, but not ag activity reported") ///
	issueComm("`agricComm'")

* work in livestock, but no livestock activity reported
local livestockComm = 														///
"ERROR: At least 1 member works in household livestock (section E). " +		///
"But no livestock activity is reported (section X)."

createComplexIssue , ///
	attributesFile(`attributes') ///
	issuesFile(`issues') ///
	whichAttributes(worksInLivestock ownsLivestock) ///
	issueType(1) ///
	issueCondit(worksInLivestock == 1 & ownsLivestock == 0) ///
	issueDesc("Work in livestock, but no livestock activity reported") ///
	issueComm("`livestockComm'")

* work in fisheries, but no fisheries activity reported
local fishComm = 															///
"ERROR: At least 1 member works in fisheries (section E). " + 	///
"But no fisheries activity is reported (section X)."

createComplexIssue , ///
	attributesFile(`attributes') ///
	issuesFile(`issues') ///
	whichAttributes(worksInFisheries doesFishing) ///
	issueType(1) ///
	issueCondit(worksInFisheries == 1 &  doesFishing == 0) ///
	issueDesc("Work in fisheries, but no fisheries activity reported") ///
	issueComm("`fishComm'")

