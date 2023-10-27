# Table of contents

- [Description](#description)
- [Installation](#installation)
    - [Download this repository](#download-this-repository)
    - [Install R](#install-r)
    - [Install RStudio](#install-rstudio)
    - [Install rcall](#installer-rcall)
- [Set-up](#paramétrage)
    - [Put in place resource data sets](#put-in-place-resource-data-sets)
    - [Modify parameters](#modify-parameters)
- [Usage](#mode-demploi)
    - [Reject automatically](#reject-automatically)
    - [Review before rejecting](#review-before-rejecting)
    - [Add observations before rejecting](#add-observations-before-rejecting)
- [Troubleshooting](#troubleshooting)
    - [Known problems](#known-problems)
    - [User-specific problems](#user-specific-problems)
    - [General problems / feature requests](#general-problems--feature-requests)

# Description

This system of programs aims to automate several processes for reviewing and taking action on interviews for the Integrated Household Survey 5 (IHS5). In particular:

- Downloading data from the server
- Preparing data for review
- Creating auxiliary data (e.g., consumption, calories)
- Recommedning an action to take for each interview:
    - Reject
    - Review more closely
    - Approve
- Automating rejetion
- Creating a report on rejections (COMING SOON)

As a by-product, this program creates several useful data sets:

- List of interviews by action (in the `/results/` folder)
    - toReject.dta. Interviews to reject (or that have just been rejected). These interviews have at least 1 serious error.
    - toReview.dta. Interviews to review more carefully (with human judgment). These interviews have any of the following: a serious error but with a (potentially) explanatory interviewer comment on a question involved in the error; any type of interviewer comment, whether on a question or on the interview as a whole; or a Survey Solutions validation error.
- Calories by food item. `caloriesByItem.dta` is saved in `/donnees/derivees/`.
- Total calories per capita per day by household. `totCalories.dta` is saved in `/donnees/derivees/`.
- Food consumption in a single file. `foodConsumption.dta` is saved in `/donnees/derivees/`

# Installation

## Download this repository

- Click on the `Clone or download` button
- Click on the `Download ZIP` option
- Download in the folder on your device where you house this project

## Install R

Whether installing R for the first time or updating it:

- Foll [this link](https://cran.rstudio.com/)
- Click on the appropriate link for your operating system
- Click on `base`
- Download and install

## Install RStudio

While RStudio is not required, it is nevertheless strongly advised to install it, since it makes using and troubleshooting R easier.

- Follow [this link](https://www.rstudio.com/products/rstudio/download/)
- Select RStudio Desktop Open Source License
- Click on the appropriate link for your operating system
- Download and install

## Install rcall

Whether you have already have `rcall` on your computer or not, follow these instructions to install the latest version.

Before isntalling `rcall`, install the Stata ado  `github`. The author of this ado provides installation instructions [here](https://www.rstudio.com/products/rstudio/download/). But the steps, in more details, are:

- Open Stata
- Execute the following command: `net install github, from("https://haghish.github.io/github/")`

After having installed `github`, install `rcall` by following the ado author's instructions [here](https://github.com/haghish/rcall#1-installation).

If you get a Stata error, please try downloading outside of the office. Sometimes, certain organisations block certain web addresss or certain activities. Thus, it is possible that you may not be able to install  `github` or `rcall` at the office, but installation on another network may work well.

To confirm that installation and set-up were successful, execute the following commmand in Stata:

```
rcall sync : print("Hello World")
```

If you see `[1] "Hello World"`, `rcall` is set up properly.

If you see an error message, `rcall` does not know where to find your installation of R, and you need to specify the file path manually.

By default, `rcall` looks for R in certain folders on your computer. If the program does not find R at these locations, one must specify where to find R. To do so, follow these steps :

- Open RStudio
- Select "Global options" from the "Tools" menu
- Click on the "General" tab, et copy the address that appears under "R version"
- Construct the full file path by copying this address and appending `/bin/R.exe` to the end
- Reopen Stata
- Execute the following command, where  `[PATH]` is replaced with the path constructed above : `rcall setpath "[PATH]"`
- Test `rcall` again to make sure set-up is correct. See above the process for testing `rcall`.

If `rcall` doesn't work after several tries, launch R from the command prompt instead. See [this section](#how-to-call-r) for more information.

# Set-up 

## Put in place resource data sets

This program draws from two data sets:

- `IHS4 Conversion Factor Database2.dta`, a set of conversion factors that allow non-standard units to be expressed in the standard units of the following calories data set.
- `calories.dta`, a compilation of calories by food item. It contains columns for the food item ID, the calories per 100g of the food item, and the edible portion of the food item.

Both are distributed with this repository.

But if these files need to be updated, they can be found in the  `/data/resources/` folder. If the files change names, be sure to update the file names in `factorsDta` and `caloriesDta` parameters discussed below.

## Modify parameters

This system of program has several parameters. Some should be modified. Others should not be.

Here are the parameters to modify, organized by file and section.

### configurePrograms.do

As its names suggestions, this programs contains the majority of the parameters.

#### How to call R

The program provides two options for launching R:

1. `shell`. That is, with the operating system's command prompt
2. `rcall`. That is, with the `rcall` ado

Here are the parameters to provide:

- `howCallR`. Prove the value corresponding to the desired method for launching R: `shell`, if by the command prompt; `rcall`, if by the `rcall` ado. While both options work, the former may be slightly preferred. Even though `rcall` has the advantage of showing in the command prompt what R is doing, `shell` has proven a more reliable, if much less informative, method for launching R.
- `rPath`. Needed for the `shell` option. Path to `R.exe` responsible for launching R. To construct this path:
    + Open RStudio
    + Select "Global options" from the "Tools" menu
    + Click on the "General" tab, et copier the address that appears under "R version". This is the path to the R installation used by RStudio.
    + Construct the full file path by copying the address above and adding `/bin/R.exe` to the end of it

#### Server details

- `server`. For cloud servers, use the server "prefix". For example, "demo" would be the value of `server` for a server at the following address: `demo.mysurvey.solutions`. For local servers, use the full address (e.g. `https://192.123.456`).
- `login`. User name for an admin or API users.
- `password`. Password for this user.
- `qnrName`. Questionnaire title. Write the template name as it appears on the server (without the system-generated version numbers). If there are two (or more) versions of the same template that have slightly different names, use a name that identifies them. For example, if the templates are named `IHS5 Cross Section - Q1` and `IHS5 Cross Section - Q2`, take the common core of these two : `IHS5 Cross Section`. If desired, one may also use regular expressions. For example, if one has questionnaires named `Questionnaire - october 2019` et `Questionnaire november 2019`, one could use a regular expression to designate both questionnaires at the same time: `Questionnaire - [a-z]+ber 2019`, since these these two months end in `ber`. If the name contains accented or Unicode characters (e.g., ç, é, À, Ü, etc.), one must replace them with `\\w`. For example, `Questionnaire ménage` must become `Questionnaire m\\wnage`.
- `exportType`. Ne toucher pas. Ce programme a besoin de données Stata pour fonctionner.
- `serverType`. If the server is hosted by the World Bank, leave the default value `"cloud"`. If the server is hosted locally, put `"local"`.

To create an API user, connect to the server as an admin, click on "Teams and Roles", select "API Users", create an account, and use the login and password, respectively for the `login` et `password` described above.

#### Identify interviews to process

Specify the status(es) of interviews to review. If only one status is targeted, write it between the quotes. If more than than one status is targeted, write the codes in a comma-separated list.

The options are:

- `Completed`. Write code `100`.
- `ApprovedBySupervisor`. Write code `120`.

Here are a few examples with explanations:

Exemple 1: 

```
local statusesToReject "120"
```

Set up in this way, the program will only review inteviews approved by the suerpvsor. In this way, the program limits itself to the role of headquarters, processing interviews in its inbox.

Exemple 2:

```
local statusesToReject "100, 120"
```

With these two codes, the program processes interviews that are both approved by the supervisor and completed by the interviewer. In this way, the program acts simultaneously on two levels: first, substituting itself or the supervisor, by processing interviews before the superivsors do; second, processing all interviews approved by a supervisor.

#### Calorie computation data and variables

Describe the files involved in the computation of calories.

For the conversion factors file :

- `factorsDta`. Full file name (with dta extension).
- `factorsByGeo`. Whether the conversion factors are reported by geographic groups (e.g., region, strata, etc.). If yes, put `"true"`. If not, put `"false"`.
- `geoIDs`. There are two cases: 
    - If conversion factors are reported by geographic groups, specify the list of variables that identify geographic groups. Note that the list is space-delimited (e.g., `s00q01 s00q04`). Note also that the variable names must match variable names in the household data set. 
    - If conversion factors are reported simply at the product-unit(-size) level, this parameter can be left blank.
- `prodID_fctrCurr`. Current name of the product ID in the conversion factor data set.
- `prodID_fctrNew`. New name of the product ID variable. Leave the default value as is: `"productID"`.
- `unitIDs_fctrCurr`. Current names of variables that identify units (and unit sizes).
- `unitIDs_fctrNew`. New names for these identifiers. Note that these must match the names in the food consumption data set. For the IHS5 project, leave the default value as is: `"hh_g03b"`.
- `factorVar`. Name of the conversion factor variable.

For other parameters in this section, leave them as is for the IHS5 project.

That being said, here is a brief description of expected.

For the calories data set:

- `caloriesDta`. Full file name (with dta extension).
- `prodID_calCurr`. Current name of the product ID variable.
- `prodID_calNew`. New name for the product ID variable. Note that the name must match the name of the corresponding variables in the conversion factor and food consumption data sets.
- `caloriesVar`. Name of the calorie variable.
- `edibleVar`. Name of the variable that contains the edible portion of the food item.

For the houseold data set:

`memberList`. Name of the variable that captures the list of household members as it appears in Designer.

For the food consumption data set:

`consoDta`. Full file name (with dta extension).
`quantityVar`. Name of the variable that captures the total quantity consumed.

For the output folder:

`outputDir`. Folder in which to save the ouputs of the calorie computation program.

### runAll.do

#### Project file path

Copy and past the path for the project folder--that is, where this repository was downloaded and unzipped. Please note: no need to modify the filepath to anticipate R's needs. The program takes care of this.

#### Parameters of computeCalories

If conversion factors are not reported by geographic groups, delete this line: 

```
geoIDs(`geoIDs')                         /// list of geo IDs
```

Otherwise, leave this line as is, as well as all other lines in this block of code.

# Usage

Here are the various ways that the program may be used, and the steps for each mode.

## Reject automatically

By default, the program takes care of all actions involved in rejection: getting data, preparing data, making decision on rejection, and communicating those decisions to the server.

To do this, launch `runAll.do` from Stata. This program executes all the other programs, both R and Stata, that are part of the rejection process.

## Review before rejecting

<font color="red">!!! NOTE: This will be simplified in the near future !!!</font>

To see the program's recommendations before rejecting, one must stop the program before it communicates its decisions to the server.

To do this, before running  `runAll.do`, open `processInterviews.R` (in any text editor), put a `# ` in front of the lines that launch `postComments.R` and `rejectInterviews.R`. In other words, one needs to make the adjustments below:

```
# -----------------------------------------------------------------------------
# Decide what actions to take for each interview
# -----------------------------------------------------------------------------

source(paste0(progDir, "decideAction.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Make rejection messages
# -----------------------------------------------------------------------------

source(paste0(progDir, "makeRejectMsgs.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Post comments
# -----------------------------------------------------------------------------

# source(paste0(progDir, "postComments.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Reject interviews
# -----------------------------------------------------------------------------

# source(paste0(progDir, "rejectInterviews.R"))
```

Then, run `runAll.do` as usual. This will have the effect of creating the `toReject.dta` data set--that is, the list of interviews to be rejected and the reason(s) why.

Once ready to reject these interviews:

- Open RStudio
- Open the following programs: `filePath.R`, `postComments.R`, and `rejectInterviews.R`
- Run these programs individually in the order indicated above, waiting for `postComments.R` to complete before launching `rejectInterviews.R`.

## Add observations before rejecting

<font color="red">!!! NOTE: This will be simplified in the near future !!!</font>

The program rejects on the basis of issues compiled in this data set `/data/derived/issues.dta`. 

On may, thus, add observations on rejected interviews by adding lines to this data set. 

Here are the columns that need to be filled for these additional observations:

-  `interview__id`. Survey Solutions' 32-character identifier.
-  `interview__key`. Survey Solutions 8-number identifer.
-  `issueType`. Code 1 or 2. Code 1 identifies a reason for rejection, and the associated message will part of the overall rejection message. Code 2 identifies a comment for a particular question.
-  `issueDesc`. Short description of the problem. Maximum 5 words. This will not be seen by the interviewer, but instead will appear in rejection reports seen by headquarters.
-  `issueComment`. Detailed description of the problem. This message will be seen by the interviewer. If `issueType == 1`, it will be part of the overall rejection message. If `issueType == 2`, it will be a comment on specific question in the interivew.
-  `issueVars`. If `issueType == 1`, may be omitted. If `issueType == 2`, this is the question targeted by the comment .
-  `issueLoc`. If `issueType == 2` and the question is in the roster, put the roster row number. If `issueType == 2` and the question is not in a roster, put `null`. If `issueType == 1`, leave blank.

Here is the process for integrating these observations into the rejection process:

Before launching the program, comment out the programs directly involved in making the rejection decision and communicating that decision to the server:

- Open `processInterviews.R` (in any text editor)
- Put `# ` in front of the lines that launch the following programs: `decideAction.R`, `makeRejectMsgs.R`, `postComments.R`, `rejectInterviews.R`.
- Save `processInterviews.R`.

Having modified the program:

- Lancer `runAll.do`
- Add observations to `/data/derived/issues.dta` without modifying existing observations
- Save `issues.dta`
- Open RStudio
- Open the following programs: `filePath.R`, `decideAction.R`, `makeRejectMsgs.R`, `postComments.R`, and `rejectInterviews.R`
- Run these programs individually in the order indicated above, wiating for `postComments.R` to complete before running `rejectInterviews.R`.

# Troubleshooting

## Known problems

### Error at the end of execution

If using `rcall`, Stata displays an error message at the end of executing `runAll.do` that has the following form:

```
invalid '"interview__status' 
r(198);
```

This error does not appear to affect the correct execution of the program. But it does raise some questions.

For this reason, among others, using the `shell` method of launching R is preferred.

### Missing packages

In principle, the program should install all required R packages. If an error message appears about missing packages, install all of the necessary ones by: 

- Opening RStudio
- Copying, pasting, et executing the following command

```
packagesNeeded <- c("httr", "RCurl", "dplyr", "haven", "stringr", "fuzzyjoin")
install.packages(packagesNeeded, 
    repos = 'https://cloud.r-project.org/', dep = TRUE)
```

## User-specific problems

Contact the World Bank CAPI expert for this project.

## General problems / feature requests

Please post the problem on this repository.

### Process

- Create a GitHub account. This is free and easy.
- Sign into GitHub with your account.
- Navigate to this repository.
- Click on the `Issues` tab
- Click on the `New issue` button
- Review the instructions on content [below](#content)
- Fill out the form. 
- (Do not share data on GitHub since this repository may be public.)

### Content

For problems, provide a description that allows someone to reproduce it. At a minimum, give the steps to follow, the result obtained, and the result expected. Screenshots--plural--are welcome. Better still, try to reproduce the problem, identify the likely causes, and offer a solution.

For feature requests, provide a description of the desired behavior, and where it fits into your usual work flow.


