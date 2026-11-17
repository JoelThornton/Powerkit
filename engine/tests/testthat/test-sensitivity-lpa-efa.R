# Split from test-sensitivity-search.R so that the slow simulated searches
# run as files of their own and the CI parts stay within their time.

test_that("latent profiles and factor recovery find their smallest separation and loading where a fresh simulation has the target power", {
  skip_on_cran()
  # Slow designs: fewer replications than the other simulated searches,
  # and a wider tolerance to match.
  for (name in c("lpa", "efa")) {
    spec <- example_spec(name)
    spec$goal <- list(type = "sensitivity", n = 150L, power = 0.8)
    spec$options$nrep <- 200L
    result <- suppressWarnings(run_quietly(spec))
    s <- result$sensitivity
    expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper, label = name)
    at <- spec
    if (name == "lpa") at$population$separation <- s$effect else at$population$loading <- s$effect
    at$goal <- list(type = "power", n = 150L)
    at$options$nrep <- 2000L
    at$options$seed <- 99L
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.05, label = name)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
})
