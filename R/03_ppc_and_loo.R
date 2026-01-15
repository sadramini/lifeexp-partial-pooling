# 03_ppc_and_loo.R
# Posterior predictive checks + LOO model comparison

library(brms)
library(loo)
library(bayesplot)

YEAR <- 2019
options(brms.backend = "cmdstanr")

model_paths <- list(
  pool    = sprintf("outputs/models/m_pool_%d.rds", YEAR),
  nopool  = sprintf("outputs/models/m_nopool_%d.rds", YEAR),
  partial = sprintf("outputs/models/m_partial_%d.rds", YEAR)
)

stopifnot(all(file.exists(unlist(model_paths))))

m_pool <- readRDS(model_paths$pool)
m_nopool <- readRDS(model_paths$nopool)
m_partial <- readRDS(model_paths$partial)

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

# PPC plots (simple but effective)
png(sprintf("outputs/figures/ppc_pool_%d.png", YEAR), width = 1200, height = 800)
print(pp_check(m_pool, ndraws = 200))
dev.off()

png(sprintf("outputs/figures/ppc_partial_%d.png", YEAR), width = 1200, height = 800)
print(pp_check(m_partial, ndraws = 200))
dev.off()

# LOO (predictive performance)
loo_pool <- loo(m_pool)
loo_nopool <- loo(m_nopool)
loo_partial <- loo(m_partial)

cmp <- loo_compare(loo_pool, loo_nopool, loo_partial)

# Save comparison table
cmp_df <- as.data.frame(cmp)
cmp_path <- sprintf("outputs/tables/loo_compare_%d.csv", YEAR)
write.csv(cmp_df, cmp_path, row.names = TRUE)

message("Saved PPC plots to outputs/figures/")
message("Saved LOO comparison to: ", cmp_path)
print(cmp)
