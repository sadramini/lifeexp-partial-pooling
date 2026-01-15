# 01_clean_merge.R
# Cleans + merges data, then creates a cross-sectional dataset for one year.

library(readr)
library(dplyr)
library(stringr)

YEAR <- 2019  # Change here if you want another year

life_path <- "data/raw/life-expectancy.csv"
gdp_path  <- "data/raw/gdp-per-capita-worldbank.csv"

stopifnot(file.exists(life_path), file.exists(gdp_path))

life_raw <- read_csv(life_path, show_col_types = FALSE)
gdp_raw  <- read_csv(gdp_path,  show_col_types = FALSE)

# ---- auto-detect life expectancy value column ----
life_value_col <- setdiff(names(life_raw), c("Entity", "Code", "Year"))
if (length(life_value_col) != 1) {
  stop(
    "Could not uniquely identify life expectancy value column. Found: ",
    paste(life_value_col, collapse = ", ")
  )
}

life <- life_raw %>%
  rename(country = Entity, code = Code, year = Year) %>%
  rename(life_exp = all_of(life_value_col))

# ---- GDP: handle possible extra columns (e.g., OWID region) ----
# We pick the column that contains "GDP per capita" as the value column.
gdp_value_candidates <- setdiff(names(gdp_raw), c("Entity", "Code", "Year"))

gdp_value_col <- gdp_value_candidates[str_detect(gdp_value_candidates, "GDP per capita")]
if (length(gdp_value_col) != 1) {
  stop(
    "Could not uniquely identify GDP value column. Candidates were: ",
    paste(gdp_value_candidates, collapse = ", "),
    " | Matched: ",
    paste(gdp_value_col, collapse = ", ")
  )
}

# Optional: detect region column if present
region_col <- gdp_value_candidates[str_detect(gdp_value_candidates, "World region")]
region_present <- length(region_col) == 1

gdp <- gdp_raw %>%
  rename(country = Entity, code = Code, year = Year) %>%
  rename(gdp_pc = all_of(gdp_value_col))

if (region_present) {
  gdp <- gdp %>% rename(region = all_of(region_col))
} else {
  gdp <- gdp %>% mutate(region = NA_character_)
}

# Merge
df <- life %>%
  inner_join(gdp, by = c("country", "code", "year"))

# Keep only "real countries" (ISO3 codes). This removes World/continents/aggregates.
df <- df %>%
  filter(!is.na(code), str_length(code) == 3)

# Select year
df_year <- df %>%
  filter(year == YEAR) %>%
  filter(is.finite(life_exp), is.finite(gdp_pc), gdp_pc > 0) %>%
  mutate(
    log_gdp = log(gdp_pc),
    country = as.factor(country),
    region = as.factor(region)
  ) %>%
  select(country, code, region, year, life_exp, gdp_pc, log_gdp)

# Save processed
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
out_path <- sprintf("data/processed/cross_section_%d.csv", YEAR)
write_csv(df_year, out_path)

message("Life expectancy value column: ", life_value_col)
message("GDP value column: ", gdp_value_col)
if (region_present) message("Region column: ", region_col)
message("Saved processed dataset: ", out_path)
message("Rows (countries): ", nrow(df_year))
print(head(df_year, 5))
