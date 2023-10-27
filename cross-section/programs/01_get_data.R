# =============================================================================
# Load server details saved by Stata
# =============================================================================

source(prog_dir, "serverDetails.R")

# =============================================================================
# Set credentials
# =============================================================================

susoapi::set_credentails(
    server = server,
    workspace = workspace,
    user = login,
    password = password
)

# =============================================================================
# Fetch data
# =============================================================================

susoflows::download_matching(
    workspace = workspace,
    matches = qnr_expr, 
    export_type = "STATA",
    path = download_dir
)
