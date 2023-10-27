# =============================================================================
# Load requirements for this session
# =============================================================================

# -----------------------------------------------------------------------------
# Libraries
# -----------------------------------------------------------------------------

library(dplyr)

# -----------------------------------------------------------------------------
# Files
# -----------------------------------------------------------------------------

# cases to review
cases_to_review <- haven::read_dta(paste0(constructed_dir, casesToReviewDta))

# issues flagged by program plus
issues_plus_miss_and_suso <- haven::read_dta(paste0(derived_dir, issuesDta))

# SuSo comments
comments <- haven::read_dta(paste0(combined_dir, commentsDta))

# which issue values to reject
issues_to_reject <- 1

# interview statistics
suso_diagnostics <- haven:;read_dta(combined_dir, "interview__diagnostics.dta")
interview_stats <- suso_diagnostics %>%
    # rename to match column names from GET /api/v1/interviews/{id}/stats
    dplyr::rename(
        NotAnswered = n_questions_unanswered,
        WithComments = questions__comments,
        Invalid = entities__errors
    ) %>%
    dplyr::select(interview__id, interview__key, NotAnswered, WithComments, Invalid)

# attributes
attribs <- haven::read_dta(derived_dir, "attributes.dta")

# =============================================================================
# Execute actions, if there are cases to review
# =============================================================================

if (nrow(cases_to_review) == 0) {

    warning("Currently no interviews to review")

} else {

    # load


    # make decisions
    # - what to reject
    # - wht to review
    print("---- 03 Make decisions -----")
    source(paste0(script_dir, "03_make_decisions.R"))

    # execute decisions
    # - post comments to individual questions
    # - reject interviews
    if (should_reject == TRUE) {
    print("---- 04 Execute decisions -----")
    source(paste0(script_dir, "04_execute_decisions.R"))
    }

    # save decisions to disk
    print("---- 05 Save decisions to disk -----")
    source(paste0(script_dir, "05_save_results.R"))

}
