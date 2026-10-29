# A 2 x 2 between-participants ANOVA with unequal cells (options >
# cell_ratio): simulated with Superpower's ANOVA_power().

unequal_spec <- function(goal = list(type = "power", n = 120), ...) {
  spec <- read_spec(system.file("specs", "anova_2x2_between_unequal.json", package = "powerkit"))
  spec$goal <- goal
  spec$options <- utils::modifyList(spec$options, list(...))
  spec
}

test_that("unequal cells are simulated by ANOVA_power() with each cell's own n", {
  spec <- unequal_spec(nrep = 200)
  result <- suppressWarnings(run_spec(spec))
  expect_identical(result$provenance$method, "simulation")
  expect_identical(result$provenance$backend_function, "Superpower::ANOVA_power")
  expect_true(all(result$check_run$ok))
  inputs <- superpower_inputs(validate_spec(spec))
  expect_equal(superpower_cell_n(inputs, 120), c(40, 40, 20, 20))
})

test_that("unequal cells agree with pwrss's Shieh formula with a null covariate", {
  spec <- unequal_spec(goal = list(type = "power", n = 300), nrep = 2000, seed = 7)
  result <- suppressWarnings(run_spec(spec))
  shieh <- pwrss::power.f.ancova.shieh(
    mu.vector = c(20, 18, 30, 24), sd.vector = rep(8, 4), n.vector = c(100, 100, 50, 50),
    factor.levels = c(2, 2), r.squared = 0, k.covariates = 1,
    contrast.matrix = matrix(c(0.25, -0.25, -0.25, 0.25), nrow = 1), verbose = 0
  )$power
  expect_lt(abs(result$curve$power - shieh), 4 * result$curve$mcse)
})

test_that("unequal cells refuse what Superpower can't do, in plain English", {
  expect_error(validate_spec(unequal_spec(method = "exact")), "Superpower's exact method takes equal cells only")
  expect_error(validate_spec(unequal_spec(goal = list(type = "sensitivity", n = 120, power = 0.8))),
    "smallest detectable effect isn't available with unequal cells")
  expect_error(validate_spec(unequal_spec(goal = list(type = "power", n = 121))), "ratio 2 : 2 : 1 : 1")
  mixed <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
  mixed$options$cell_ratio <- list(list(1, 1), list(2, 2))
  expect_error(validate_spec(mixed), "only applies to the 2 x 2 between-participants")
})

test_that("recruitment and the exported script use the unequal cells", {
  spec <- validate_spec(unequal_spec(attrition = 0.2))
  expect_equal(analysed_groups(spec, 120), c(40, 40, 20, 20))
  result <- suppressWarnings(run_spec(unequal_spec(nrep = 200)))
  script <- export_script(unequal_spec(nrep = 200), result)
  expect_true(any(grepl("cell_ratio <- c(2, 2, 1, 1)", script, fixed = TRUE)))
  expect_true(any(grepl("n_total * cell_ratio / sum(cell_ratio)", script, fixed = TRUE)))
})
