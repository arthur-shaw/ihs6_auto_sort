use "`errCheckPath'", clear

/*=============================================================================
CORRECT ERRORS
=============================================================================*/	

/*-----------------------------------------------------------------------------
err_class == 1
-----------------------------------------------------------------------------*/

* inspect pre-correction errors
di as error "Error class 1"
di "ISSUES REMAINING **BEFORE** CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 1)

* filter out inappropriate errors
drop if (err_class == 1) & ( ///
	regexm(comment, "MISSING") | /// SuSo provides count of missings
	regexm(comment, "CRITICAL STRUCTURE") | /// shouldn't exist because of data export; probably Stata coding problem
	regexm(comment, "(merge[d]* with|MERGE[D]* WITH)") | /// shouldn't exist because of data export; probably Stata coding problem
	regexm(comment, "IMPROPER SKIP") | /// SuSo provides count of missings
	(regexm(comment, "OUT OF RANGE") & quest == "HH_A02B") | /// only ones found concern TA code, which is probably prefilled
	(comment == "reason for loss exist but amount loss missing" & quest == "ag_i36a") | /// code checks whether to vars are missing; seems to reference old var numbers
	(comment == "NO HH HEAD INDICATED") | /// overlaps with auto-sort
	(comment == "INCONSISTENT AGE AND YEAR OF BIRTH") /// seems like a coding problem: should be | instead of & between logical statements
	)

* inspect post-correction errors
qui: count if (err_class == 1)
di "ISSUES REMAINING **AFTER** CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 1)

/*-----------------------------------------------------------------------------
err_class == 2
-----------------------------------------------------------------------------*/

* inspect pre-correction errors
di as error "Error class 2"
di "ISSUES REMAINING **BEFORE** CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 2)

* filter out inappropriate errors
drop if (err_class == 2) & ( ///
	regexm(comment, "MISSING REQUIRED") | /// SuSo provides count of missings
	comment == "FOOD CONSUMED - ALL FIELDS EQUAL NO" | /// overlaps with auto-sort
	regexm(comment, "IMPROPER SKIP") | /// SuSo provides count of missings
	comment == "MISSING ENUMERATOR CODE" /// SuSo provides count of missings; info available in interview__actions file
)

* inspect post-correction errors
qui: count if (err_class == 2)
di "ISSUES REMAINING AFTER CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 2)

/*
-------------------------------
VERIFIED THESE; SEEM OK:
-------------------------------

GPS MISSING
MISSING EXPENDITURE
NO ITEMS OWNED IN MODULE
NO ITEMS PURCHASED IN MODULE
COUPON TYPE IN E1 DOESN'T MATCH INPUT /// coding problem: should be | instead of & for second part of condition
QUANTITY INCONSISTENT WITH COUPON TYPE
MISSING UNIT OWN-PRODUCTION
INCONSISTENT AGE WITH MODULE B
INCONSISTENT CONSUMPTION WITH HH_G01
INCONSISTENT RANKING OF SHOCKS /// not quite sure what this does
INORGANIC FERT BUT NOT IN KGS
MISSING EDUCATION INFO FOR INDIVIDUALS /// not sure whether filter by age here
MISSING GARDEN FOR PLOT AG_O2 /// think this is wrong, but will keep
MISSING MODULE /// think some of this may wrong, but will keep
MISSING UNIT GIFTS
MISSING UNIT PURCHASES
*/

/*-----------------------------------------------------------------------------
err_class == 3
-----------------------------------------------------------------------------*/

* inspect pre-correction errors
di as error "Error class 3"
di "ISSUES REMAINING **BEFORE** CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 3)

* filter out inappropriate errors
drop if (err_class == 3) & ( ///
	regexm(comment, "MISSING REQUIRED") | /// SuSo provides count of missings
	regexm(comment, "IMPROPER SKIP") /// SuSo provides count of missings
)

* inspect post-correction errors
qui: count if (err_class == 3)
di "ISSUES REMAINING AFTER CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 3)

/*-----------------------------------------------------------------------------
err_class == 4
-----------------------------------------------------------------------------*/

* inspect pre-correction errors
di as error "Error class 4"
di "ISSUES REMAINING **BEFORE** CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 4)

* filter out inappropriate errors
drop if (err_class == 4) & ( ///
	regexm(comment, "MISSING REQUIRED") | /// SuSo provides count of missings
	regexm(comment, "IMPROPER SKIP") /// SuSo provides count of missings
)

* inspect post-correction errors
qui: count if (err_class == 4)
di "ISSUES REMAINING AFTER CORRECTION: "
di "Number: `r(N)'"
di "List: "
tab comment if (err_class == 4)

/*=============================================================================
Put into format required
=============================================================================*/	

*  identifiers
rename HHID interview__id
gen interview__key = ""

* error descriptors
clonevar issueDesc = comment
gen issueComment = "ERROR: " + quest + " - " + comment
gen issueLoc = ""
gen issueVars = strtrim(strlower(quest)) 

* lump together error levels that share the same desired auto-sort action
gen issueType = .

// rejection
replace issueType = 1 if inlist(err_class, 1, 2)

// review
replace issueType = 4 if inlist(err_class, 3, 4)

* retain only variables expected in issues file
keep interview__id interview__key issueType issueDesc issueComment issueLoc issueVars

tempfile errCheckObs
save "`errCheckObs'"

/*=============================================================================
Append error check observations to file used for rejection/review decision
=============================================================================*/	

use "`issuesPath'", clear
append using "`errCheckObs'"
save "`issuesPath'", replace
