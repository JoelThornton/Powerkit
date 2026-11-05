# Differential item functioning (DIF) in a 2PL model, by irtpwr's analytical
# method with its DIF preset (its hypothesis built from the parameters
# chosen, and corrected so that a single parameter works). Translation, agreement with the package's own
# preset where that works, the check run, refusals and the exported script;
# accuracy is checked by test-validation-irt.R.

dif_spec <- function(n = 600, method = "likelihood_ratio") {
  spec <- example_spec("irt_dif")
  spec$target_test$method <- method
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("DIF runs on irtpwr and passes its check run", {
  result <- run_quietly(dif_spec())
  expect_equal(result$provenance$backend, "irtpwr")
  expect_true(all(c("irtpwr", "mirt") %in% names(result$provenance$packages)))
  expect_true(all(result$check_run$ok))
  expect_gt(result$curve$power, 0.5)
  # Each statistic can be chosen; the Wald test is a little less powerful
  # here, as irtpwr reports.
  wald <- run_quietly(dif_spec(method = "wald"))$curve$power
  expect_lt(abs(wald - result$curve$power), 0.05)
})

test_that("the corrected preset gives the package's own preset's power where that works", {
  # Only the differing parameters free: the package's own choice.
  spec <- dif_spec()
  spec$population$dif_items <- list(1, 2)
  spec$population$b_shift <- list(0.4, 0.3)
  spec$target_test$free_parameters <- "differing"
  inputs <- irt_inputs(validate_spec(spec))
  own <- irtpwr::irtpwr(hyp = irtpwr::setup.hypothesis(type = "DIF2PL", altpars = list(inputs$reference, inputs$focal)), N = 600, alpha = 0.05)
  expect_equal(summary(irt_result(inputs), N = 600, alpha = 0.05)$result, summary(own, N = 600, alpha = 0.05)$result, tolerance = 1e-6)
  # Both parameters free, with both differing: the same hypothesis again.
  spec$target_test$free_parameters <- "both"
  spec$population$a_change <- list(0.3, -0.2)
  inputs <- irt_inputs(validate_spec(spec))
  own <- irtpwr::irtpwr(hyp = irtpwr::setup.hypothesis(type = "DIF2PL", altpars = list(inputs$reference, inputs$focal)), N = 600, alpha = 0.05)
  expect_equal(summary(irt_result(inputs), N = 600, alpha = 0.05)$result, summary(own, N = 600, alpha = 0.05)$result, tolerance = 1e-6)
})

test_that("Departure 20: testing both of a DIF item's parameters (the default) costs power when only its difficulty differs", {
  # docs/conventions.md: the usual likelihood-ratio DIF test frees the
  # item's discrimination and difficulty (2 df); irtpwr's preset frees only
  # what differs (1 df). For the example spec at n = 600: 0.536 against
  # 0.641.
  both <- run_quietly(dif_spec())$curve$power
  spec <- dif_spec()
  spec$target_test$free_parameters <- "differing"
  differing <- run_quietly(spec)$curve$power
  expect_equal(both, 0.536, tolerance = 0.002)
  expect_equal(differing, 0.641, tolerance = 0.002)
})

test_that("difficulties become irtpwr's intercepts, and the DIF item changes in the focal group only", {
  inputs <- irt_inputs(validate_spec(dif_spec()))
  expect_equal(inputs$reference$d, -c(1.2, 0.9, 1.5, 1.0, 1.3, 0.8, 1.1, 1.4) * c(-1.0, -0.5, 0.0, 0.3, 0.6, 1.0, -0.2, 0.4))
  expect_equal(inputs$focal$d[1], -1.2 * (-1.0 + 0.4))
  expect_equal(inputs$focal$d[-1], inputs$reference$d[-1])
})

test_that("plain-English refusals for DIF", {
  spec <- dif_spec()
  spec$population$dif_items <- list(9)
  expect_spec_problem(spec, "beyond the 8 given")
  spec <- dif_spec()
  spec$population$b <- spec$population$b[1:5]
  expect_spec_problem(spec, "needs one difficulty for each")
  spec <- dif_spec()
  spec$population$b_shift <- NULL
  expect_spec_problem(spec, "Give the DIF")
  spec <- dif_spec()
  spec$population$a <- spec$population$a[1:3]
  spec$population$b <- spec$population$b[1:3]
  spec$population$dif_items <- list(1, 2, 3)
  spec$population$b_shift <- list(0.2, 0.2, 0.2)
  expect_spec_problem(spec, "an anchor item")
})

test_that("the R script reproduces the run with only the differing parameters free", {
  skip_unless_scripts_can_run()
  spec <- dif_spec()
  spec$target_test$free_parameters <- "differing"
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-8)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- dif_spec()
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-8)
})
