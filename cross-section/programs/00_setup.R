# =============================================================================
# Set file paths
# =============================================================================

# data
data_dir <- paste0(proj_dir, "data/") # /data/
resource_dir <- paste0(data_dir, "00_resource/")  # /00_resource/
download_dir <- paste0(data_dir, "01_downloaded/")  # /01_downloaded/
combined_dir <- paste0(data_dir, "02_combined/")  # /02_combined/
derived_dir <- paste0(data_dir, "03_derived/")   # /03_derived/

# scripts
script_dir <- prog_dir

# outputs
output_dir <- paste0(proj_dir, "output/")    # /output/

# =============================================================================
# Install packages
# =============================================================================

# -----------------------------------------------------------------------------
# Install packages used for provisioning other packages
# -----------------------------------------------------------------------------

# for package installation
if (!require("pak")) {
    install.packages("pak")
}

# for iteration over list of packages
if (!require("purrr")) {
    install.packages("purrr")
}

if (!require("stringr")) {
  install.packages("stringr")
}

# -----------------------------------------------------------------------------
# Install any missing requirements
# -----------------------------------------------------------------------------

#' Install package if missing on system
#' 
#' @param package Character. Name of package to install.
#' @importFrom stringr str_detect str_locate str_sub
#' @importFrom pak pak
install_if_missing <- function(package) {

    # preserve original package specification
    package_original <- package

    # create package name that strips out package name from repo address
    slash_pattern <- "\\/"
    if (stringr::str_detect(string = package, pattern = slash_pattern) ) {
        slash_position <- stringr::str_locate(
            string = package,
            pattern = slash_pattern
        )
        package <- stringr::str_sub(
            string = package,
            start = slash_position[[1]] + 1
        )
    }

    if (!require(package, character.only = TRUE)) {
        pak::pak(package_original)
    }

}

# enumerate packages required
required_packages <- c(
    # _get_data.R
    "fs",
    "arthur-shaw/susoapi",
    "arthur-shaw/susoflows",
    "glue",
    "dplyr",
    "zip",
    "haven",
    # _execute_workflow.R
    "arthur-shaw/susoreview",
    "writexl"
)

# install any missing requirements
purrr::walk(
    .x = required_packages,
    .f = ~ install_if_missing(.x)
)

# =============================================================================
# Purge stale data
# =============================================================================

# -----------------------------------------------------------------------------
# Downloaded
# -----------------------------------------------------------------------------

# remove zip files
zips_to_delete <- fs::dir_ls(
    path = download_dir, 
    recurse = FALSE, 
    type = "file", 
    regexp = "\\.zip$"
)
fs::file_delete(zips_to_delete)

# remove unzipped folders and the data they contain
dirs_to_delete <- fs::dir_ls(
    path = download_dir, 
    recurse = FALSE, 
    type = "directory"
)
fs::dir_delete(dirs_to_delete)

# -----------------------------------------------------------------------------
# Combined
# -----------------------------------------------------------------------------

data_to_delete <- fs::dir_ls(
    path = combined_dir, 
    recurse = FALSE, 
    type = "file",
    regexp = "\\.dta"
)
fs::file_delete(data_to_delete)

# -----------------------------------------------------------------------------
# Derived
# -----------------------------------------------------------------------------

data_to_delete <- fs::dir_ls(
    path = derived_dir, 
    recurse = FALSE, 
    type = "file",
    regexp = "\\.dta"
)
fs::file_delete(data_to_delete)

# =============================================================================
# Purge stale outputs
# =============================================================================

# remove Excel and Stata files
results_to_delete <- fs::dir_ls(
    path = output_dir, 
    recurse = FALSE, 
    type = "file", 
    regexp = "\\.xlsx$|\\.dta$"
)
fs::file_delete(results_to_delete)
