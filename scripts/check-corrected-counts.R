# Reproduce the selected-case evidence archive (independent base-R reference).
# Run from the repository root with this candidate engine installed.
library(powerkit)
source("engine/tests/testthat/helper-corrected-counts.R")
options(powerkit.cores = 1)
read_example <- function(name) unclass(read_spec(file.path("engine/inst/specs", paste0(name, ".json")), validate = FALSE))
cases <- list()
for (alternative in c("two_sided", "greater", "less", "null")) {
  s <- read_example("two_proportions_corrected")
  s$options$nrep <- 10000L
  s$options$seed <- if (alternative == "null") 2026111042L else 2026111041L
  null <- alternative == "null"
  s$goal$n <- if (null) 120 else 180
  s$options$allocation_ratio <- if (null) 1 else 2
  s$target_test$alternative <- if (null) "two_sided" else alternative
  s$population$p2 <- if (null) .5 else if (alternative == "less") .35 else .65
  n1 <- 60; n2 <- if (null) 60 else 120
  ref_alt <- switch(s$target_test$alternative, two_sided = "two.sided", greater = "less", less = "greater")
  reference <- corrected_prop_reference(n1, n2, .5, s$population$p2, alternative = ref_alt)
  result <- run_spec(s)
  cases[[alternative]] <- list(spec = s, power = result$curve$power,
    mcse = result$curve$mcse, reference = reference,
    simulations = result$provenance$simulations,
    provenance = result$provenance)
}
s <- read_example("chi_square_independence_corrected")
s$options$nrep <- 10000L; s$options$seed <- 2026111043L
set.seed(2026111044)
P <- matrix(c(.25, .25, .175, .325), 2, byrow = TRUE)
p <- suppressWarnings(replicate(10000, stats::chisq.test(matrix(rmultinom(1, 340, as.vector(P)), 2), correct = TRUE)$p.value))
result <- run_spec(s)
cases$contingency <- list(spec = s, power = result$curve$power, mcse = result$curve$mcse,
  reference = mean(is.finite(p) & p < .05), reference_nrep = 10000L,
  reference_seed = 2026111044L, simulations = result$provenance$simulations,
  provenance = result$provenance)
files <- c("engine/R/continuity-correction.R", "engine/R/backend-spower.R",
  "engine/inst/schema/design.schema.json", "engine/tests/testthat/helper-corrected-counts.R")
archive <- list(date = "2026-11-10", platform = R.version.string,
  scope = "Selected complete-data fixed-group proportions and fixed-total 2 by 2 count tests; not universal validation or published reference evidence",
  source_sha256 = setNames(lapply(files, function(p) digest::digest(file = p, algo = "sha256")), files), cases = cases)
jsonlite::write_json(archive, "docs/validation/2026-11-10-corrected-counts.json", pretty = TRUE, auto_unbox = TRUE, digits = NA, null = "null")
print(vapply(cases, function(x) c(power = x$power, reference = x$reference, mcse = x$mcse), numeric(3)))
