run_example <- function(template) {
  spec <- engine_call(validate_spec(build_spec_2x2(example_values(template))))$value
  out <- run_design(spec)
  expect_true(out$ok)
  out$value
}

between <- run_example("2x2_between")
mixed <- run_example("2x2_mixed")

test_that("the vignette crossover example gives the engine's required N", {
  expect_identical(between$result$provenance$method, "exact")
  expect_equal(between$result$n_required$n, 172)
  expect_true(all(between$result$check_run$ok))
  expect_gte(power_at_required(between$result), 0.90)
})

test_that("the power curve comes from the engine and spans the required N", {
  for (run in list(between, mixed)) {
    curve <- run$curve
    expect_gte(nrow(curve), 5)
    expect_lt(min(curve$n), run$result$n_required$n)
    expect_gt(max(curve$n), run$result$n_required$n)
    expect_true(all(diff(curve$power[order(curve$n)]) > 0))
  }
})

test_that("the methods paragraph uses the run's values", {
  text <- methods_paragraph(between)
  prov <- between$result$provenance
  expect_match(text, "N = 172 (43 per cell)", fixed = TRUE)
  expect_match(text, sprintf("Superpower R package (version %s", prov$packages[["Superpower"]]), fixed = TRUE)
  expect_match(text, "ANOVA_exact()", fixed = TRUE)
  expect_match(text, "α = .05", fixed = TRUE)
  expect_match(text, "Factor A × Factor B interaction", fixed = TRUE)
  expect_match(text, as.character(prov$seed), fixed = TRUE)
  mixed_text <- methods_paragraph(mixed)
  expect_match(mixed_text, "r = .50 between the two Factor B measurements", fixed = TRUE)
  expect_match(mixed_text, "per group", fixed = TRUE)
})

test_that("the methods paragraph refuses a result from a different spec", {
  tampered <- between
  tampered$spec$population$sd <- 3
  expect_error(methods_paragraph(tampered))
})

test_that("the R script reproduces the result with Superpower alone", {
  for (run in list(between, mixed)) {
    path <- tempfile(fileext = ".R")
    writeLines(reproduction_script(run), path, sep = "")
    rscript <- file.path(R.home("bin"), "Rscript")
    output <- suppressWarnings(system2(rscript, c("--vanilla", shQuote(path)), stdout = TRUE, stderr = TRUE))
    expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
    expect_true(any(grepl("^Reproduced: N = ", output)), info = paste(output, collapse = "\n"))
    expect_false(any(grepl("library(powerkit)|powerkit::|run_spec", readLines(path))))
  }
})
