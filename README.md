# Bayesian Multilevel Regression with Partial Pooling  
**Life Expectancy and Economic Development Across Countries**

## Overview

This project was developed for the *Applied Bayesian Data Analysis* course.  
It demonstrates **Bayesian multilevel (hierarchical) regression with partial pooling** using cross-country data on life expectancy and GDP per capita.

The main goal is methodological: to show how partial pooling stabilizes country-specific estimates compared to complete pooling and no pooling approaches, and why hierarchical modeling is a principled solution when data are grouped.

---

## Research Question

**How does economic development relate to life expectancy across countries, and how does Bayesian partial pooling improve the estimation of country-specific baseline life expectancy compared to complete and no pooling models?**

The focus is not causal inference, but:
- hierarchical modeling,
- uncertainty quantification,
- comparison of pooling strategies.

---

## Data

The analysis uses publicly available data from **Our World in Data (OWID)**:

- **Life expectancy at birth** (outcome variable)  
- **GDP per capita, PPP (constant international dollars)** (predictor)

The raw data are downloaded automatically by the analysis scripts and are **not included** in the repository.

A single cross-sectional year (**2019**) is used to focus on cross-country variation rather than time dynamics.

After cleaning and filtering, the final dataset contains **198 countries**.

---

## Models

Three models are estimated and compared:

1. **Complete pooling**  
   - Ignores country differences  
   - Single intercept for all countries  

2. **No pooling**  
   - Country-specific intercepts estimated independently  
   - Equivalent to fixed effects  

3. **Partial pooling (hierarchical model)**  
   - Country-specific intercepts modeled as draws from a common population distribution  
   - Enables shrinkage toward the global mean  

### Hierarchical model structure

y_i = α_{c[i]} + β · log(GDP_i) + ε_i  
α_c ~ Normal(ᾱ, σ_α)

This structure allows countries with limited information to borrow strength from the global population while preserving meaningful differences.

---

## Implementation

- Models are specified using **brms** (R)  
- Posterior inference is performed by **Stan** via Hamiltonian Monte Carlo (HMC)  
- Diagnostics include:
  - posterior predictive checks,
  - examination of the between-country standard deviation (σ_α),
  - comparison of pooling strategies.

---

## Key Results

- Substantial between-country heterogeneity remains after accounting for GDP.
- Partial pooling shrinks extreme country estimates toward the global mean.
- Posterior predictive checks indicate good model fit.
- The hierarchical model provides more stable and interpretable estimates than no pooling.

---

## Project Structure

lifeexp-partial-pooling/
├─ R/
│  ├─ 00_download_data.R
│  ├─ 01_clean_merge.R
│  ├─ 02_fit_models.R
│  ├─ 03_ppc_and_loo.R
│  └─ 04_make_tables_figures.R
├─ data/
│  ├─ raw/
│  └─ processed/
├─ outputs/
│  ├─ figures/
│  ├─ tables/
│  └─ models/
├─ run_all.R
├─ renv.lock
├─ .gitignore
└─ README.md

---

## Reproducibility

This project uses **renv** to ensure reproducibility.

### Steps to reproduce the analysis

1. Clone the repository  
2. Open the project in RStudio  
3. Restore the R environment:
   ```r
   renv::restore()
   ```
4. Install CmdStan:
   ```r
   library(cmdstanr)
   cmdstanr::install_cmdstan()
   ```
5. Run the full analysis:
   ```r
   source("run_all.R")
   ```

All data will be downloaded automatically and all results will be regenerated.

---

## License

This project is licensed under the **MIT License**.

---

## Author

Sadra  
Applied Bayesian Data Analysis  
TU Dortmund University
