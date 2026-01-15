# 04_make_tables_figures.R
# Creates the key "presentation plots":
# 1) Scatter plot with regression line (partial pooling)
# 2) Shrinkage plot: no pooling vs partial pooling country intercepts
# 3) Posterior of sigma_alpha (between-country SD)

library(brms)
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(posterior)

YEAR <- 2019
options(brms.backend = "cmdstanr")

data_path <- sprintf("data/processed/cross_section_%d.csv", YEAR)
stopifnot(file.exists(data_path))

df <- read_csv(data_path, show_col_types = FALSE) %>%
  mutate(country = as.factor(country))

m_nopool <- readRDS(sprintf("outputs/models/m_nopool_%d.rds", YEAR))
m_partial <- readRDS(sprintf("outputs/models/m_partial_%d.rds", YEAR))

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

# ---- Plot 1: Life expectancy vs log GDP with fitted line (partial pooling) ----
# We’ll plot points + a single global fitted line using posterior mean of beta/intercept.
fixef_partial <- fixef(m_partial)
alpha_bar <- fixef_partial["Intercept", "Estimate"]
beta_hat  <- fixef_partial["log_gdp", "Estimate"]

p1 <- ggplot(df, aes(x = log_gdp, y = life_exp)) +
  geom_point(alpha = 0.7) +
  geom_abline(intercept = alpha_bar, slope = beta_hat, linewidth = 1) +
  labs(
    title = sprintf("Life expectancy vs log(GDP per capita), %d", YEAR),
    x = "log(GDP per capita, PPP)",
    y = "Life expectancy (years)"
  )

ggsave(sprintf("outputs/figures/scatter_fit_partial_%d.png", YEAR), p1,
       width = 9, height = 6, dpi = 150)

# ---- Shrinkage plot: compare country intercepts (no pooling vs partial pooling) ----
# No pooling: intercept per country is (Intercept + countryX coefficient)
# Partial pooling: alpha_i = population intercept + random effect for country

# Extract no-pooling country intercepts
# Baseline is Intercept (reference country). Add country coefficients.
fe <- fixef(m_nopool)[, "Estimate", drop = TRUE]
intercept_np <- fe["Intercept"]
country_levels <- levels(df$country)

# brms names country coefficients like "countryCountryName"
coef_names <- names(fe)

alpha_np <- tibble(country = country_levels) %>%
  mutate(
    alpha_nopool = intercept_np +
      sapply(country, function(cty) {
        nm <- paste0("country", cty)
        if (nm %in% coef_names) fe[[nm]] else 0
      })
  )

# Extract partial-pooling country intercepts: alpha_bar + r_country
re <- ranef(m_partial)$country[, , "Intercept"]
alpha_partial <- tibble(
  country = rownames(re),
  alpha_partial = alpha_bar + re[, "Estimate"]
)

shrink_df <- alpha_np %>%
  inner_join(alpha_partial, by = "country") %>%
  arrange(alpha_nopool) %>%
  mutate(country = factor(country, levels = country))

p2 <- ggplot(shrink_df, aes(x = alpha_nopool, y = alpha_partial)) +
  geom_point(alpha = 0.7) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  labs(
    title = sprintf("Shrinkage of country baselines (α): No pooling vs Partial pooling, %d", YEAR),
    x = "No pooling country baseline (fixed effects)",
    y = "Partial pooling country baseline (hierarchical)"
  )

ggsave(sprintf("outputs/figures/shrinkage_alpha_%d.png", YEAR), p2,
       width = 9, height = 6, dpi = 150)

# Save top/bottom examples (nice for presentation)
top_bottom <- shrink_df %>%
  arrange(alpha_partial) %>%
  summarise(
    lowest5  = paste(head(as.character(country), 5), collapse = ", "),
    highest5 = paste(tail(as.character(country), 5), collapse = ", ")
  )
write.csv(top_bottom, sprintf("outputs/tables/top_bottom_countries_%d.csv", YEAR), row.names = FALSE)

# ---- Plot 3: Posterior of between-country SD (sigma_alpha) ----
# In brms, sd parameters are in posterior draws as "sd_country__Intercept"
draws <- as_draws_df(m_partial)
sd_name <- "sd_country__Intercept"
stopifnot(sd_name %in% names(draws))

p3 <- ggplot(draws, aes(x = .data[[sd_name]])) +
  geom_histogram(bins = 40) +
  labs(
    title = sprintf("Posterior of between-country SD (σ_α), %d", YEAR),
    x = expression(sigma[alpha]),
    y = "Frequency"
  )

ggsave(sprintf("outputs/figures/posterior_sigma_alpha_%d.png", YEAR), p3,
       width = 9, height = 6, dpi = 150)

message("Saved figures to outputs/figures/")
message("Saved tables to outputs/tables/")
