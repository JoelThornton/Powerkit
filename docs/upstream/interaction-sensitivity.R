# Matched-route check, not an independent-package or published benchmark.
# Run at repository root with the candidate powerkit engine installed.
library(powerkit)
options(powerkit.cores = 1)
base <- unclass(read_spec("engine/inst/specs/regression_interaction.json", validate = FALSE))
cases <- list()
for (i in seq_len(3)) {
  s <- base
  s$goal <- list(type = "sensitivity", n = if (i == 1) 100 else 300, power = .8)
  s$options$seed <- 2026111100L + i
  s$options$nrep <- 10000L
  if (i == 3) {
    s$variables$X$reliability <- 1
    s$variables$W$reliability <- 1
  }
  analytic <- run_spec(s)
  check <- s
  check$population$r_XW_Y <- analytic$sensitivity$effect
  check$goal <- list(type = "power", n = s$goal$n)
  check$options$seed <- 2026111110L + i
  simulated <- run_spec(check)
  cases[[i]] <- list(sensitivity_spec = s, formula_effect = analytic$sensitivity$effect,
    target_power = .8, simulated_spec = check, simulated_power = simulated$curve$power,
    mcse = simulated$curve$mcse, power_interval_99 = power_interval(simulated, level = .99),
    difference_from_target = simulated$curve$power - .8,
    provenance = simulated$provenance)
  print(c(case = i, n = s$goal$n, effect = analytic$sensitivity$effect,
    simulated_power = simulated$curve$power, mcse = simulated$curve$mcse))
}
archive <- list(date = "2026-11-10", scope = paste(
  "Three selected correlation-route OLS interaction plans; check the analytic sensitivity threshold with fresh simulated studies.",
  "Same InteractionPoweR backend, not an independent DGP, software equivalence, published benchmark or universal discrepancy bound."),
  source_sha256 = list(adapter = digest::digest(file = "engine/R/backend-interactionpower.R", algo = "sha256"),
    script = digest::digest(file = "docs/upstream/interaction-sensitivity.R", algo = "sha256")), cases = cases)
jsonlite::write_json(archive, "docs/validation/2026-11-10-interaction-sensitivity.json", pretty = TRUE,
  auto_unbox = TRUE, digits = NA, null = "null")
