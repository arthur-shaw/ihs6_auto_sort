# =============================================================================
# Execute actions to purge stale data, get new data, and combined data
# =============================================================================

# prepare
# - set file paths
# - purge prior data
print("---- 00 Preparation -----")
source(paste0(script_dir, "00_setup.R"))

# get data
# - fetch
print("---- 01 Get data -----")
source(paste0(script_dir, "01_get_data.R"))

# combine data
# - unpack data
# - combine and save unzipped Stata data
print("---- 02 Combine data -----")
source(paste0(script_dir, "02_combine_data.R"))
