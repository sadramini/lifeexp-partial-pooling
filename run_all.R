# run_all.R
# Master script to reproduce the entire analysis pipeline

message("=== Starting full analysis pipeline ===")

source("R/00_download_data.R")
source("R/01_clean_merge.R")
source("R/02_fit_models.R")
source("R/03_ppc_and_loo.R")
source("R/04_make_tables_figures.R")

message("=== Analysis pipeline completed successfully ===")
