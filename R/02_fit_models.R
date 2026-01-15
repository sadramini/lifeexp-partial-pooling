# 02_fit_models.R
# Fits 3 models:
# 1) complete pooling
# 2) no pooling (country fixed effects)
# 3) partial pooling (country random intercepts)

library(brms)
library(readr)
library(dplyr)

YEAR <- 2019
data_path <- sprintf("data/processed/cross_section_%d.csv", YEAR)
stopifnot(file.exists(data_path))

df <- read_csv(data_path, show_col_types = FALSE) %>%
  mutate(country = as.factor(country))

# ---- IMPORTANT: Use cmdstanr backend (recommended) ----
# Install cmdstan once:
# cmdstanr::install_cmdstan()
options(brms.backend = "cmdstanr")

# Priors (explicit, proper, weakly informative)
# life expectancy is around 50-85 typically; we use broad priors.
priors_pool <- c(
  prior(normal(70, 20), class = "Intercept"),
  prior(normal(0, 5), class = "b"),
  prior(exponential(1), class = "sigma")
)

priors_partial <- c(
  prior(normal(70, 20), class = "Intercept"),
  prior(normal(0, 5), class = "b"),
  prior(exponential(1), class = "sigma"),
  prior(exponential(1), class = "sd")  # sd of country random intercepts
)

dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)

# Model 1: Complete pooling
m_pool <- brm(
  life_exp ~ log_gdp,
  data = df,
  prior = priors_pool,
  chains = 4, cores = 4, iter = 2000,
  seed = 123,
  file = sprintf("outputs/models/m_pool_%d", YEAR)
)

# Model 2: No pooling (fixed effects)
m_nopool <- brm(
  life_exp ~ log_gdp + country,
  data = df,
  prior = priors_pool,
  chains = 4, cores = 4, iter = 2000,
  seed = 123,
  file = sprintf("outputs/models/m_nopool_%d", YEAR)
)

# Model 3: Partial pooling (hierarchical)
m_partial <- brm(
  life_exp ~ log_gdp + (1 | country),
  data = df,
  prior = priors_partial,
  chains = 4, cores = 4, iter = 2000,
  seed = 123,
  file = sprintf("outputs/models/m_partial_%d", YEAR)
)

message("Models fit and saved in outputs/models/")
