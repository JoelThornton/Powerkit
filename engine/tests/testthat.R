# This file is part of the standard setup for testthat.
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

library(testthat)
library(powerkit)

# The full suite takes hours of simulation, far over the time CRAN allows
# for a package's checks, so on CRAN (NOT_CRAN not "true") only these quick
# files run: spec checks, exact formula results, exports and the messages
# users see. They need only the packages in Imports. GitHub runs every file
# on every change (.github/workflows/R-CMD-check.yaml, NOT_CRAN = "true").
cran_files <- c(
  "all-tests-target", "analysis-requirements", "backend-chisq-w", "backend-generic",
  "backend-interaction-r2", "backend-variance", "backend-welch-anova",
  "critical-effect", "effect-from-units", "joint-power-methods",
  "optional-packages", "power-picture", "project-record-integrity", "read-spec",
  "safeguard", "sample-allocation", "sample-structure", "search-n",
  "simulation-outcomes", "spec-hash", "spec-messages", "spec-population", "study-plan"
)
on_cran <- !identical(Sys.getenv("NOT_CRAN"), "true")

test_check("powerkit", filter = if (on_cran) paste0("^(", paste(cran_files, collapse = "|"), ")$"))
