# export_script(): a standalone script that reproduces a result by calling
# the backend package directly. The reproduction tests run each exported
# script in a fresh R session (R --vanilla) and check that it matches
# powerkit's result: within the validation tolerance, and in fact exactly
# (same seeds and batches, so the same simulated data sets). There is one
# for every end point marked runs_validated in app/routing/tree.yaml
# (E1-E14), plus the other goals and settings that change the script.

# Unit tests ------------------------------------------------------------------

test_that("export_script() needs the spec the result was run from", {
  spec <- small_run_spec("anova_2x2_mixed")
  result <- run_spec(spec)
  other <- spec
  other$population$r <- 0.5
  expect_error(export_script(other, result), "spec hashes differ", class = "powerkit_export_error")
  expect_error(export_script(spec, list()), "result of run_spec", class = "powerkit_export_error")
})

test_that("export_script() returns the script, or writes it and returns it invisibly", {
  spec <- small_run_spec("anova_2x2_mixed")
  result <- run_spec(spec)
  text <- export_script(spec, result)
  expect_type(text, "character")
  expect_length(text, 1)
  expect_no_error(parse(text = text))
  expect_match(text, result$provenance$spec_hash, fixed = TRUE)
  expect_match(text, "library(Superpower)", fixed = TRUE)
  expect_match(text, "sessionInfo()", fixed = TRUE)
  expect_no_match(text, "powerkit::", fixed = TRUE)
  file <- tempfile(fileext = ".R")
  on.exit(unlink(file))
  expect_invisible(export_script(spec, result, file))
  expect_equal(paste(c(readLines(file), ""), collapse = "\n"), text)
})

test_that("a simulated result without per-n seeds can't be exported", {
  spec <- small_run_spec("anova_2x2_mixed", method = "simulation")
  result <- run_quietly(spec)
  result$provenance$simulations <- NULL
  expect_error(export_script(spec, result), "older version", class = "powerkit_export_error")
})

test_that("r_code() writes values that read back exactly", {
  for (x in list(0.4, 0.1 + 0.2, 1 / 3, 1000L, -sqrt(2) * 0.35, c(0.5, 0.65))) {
    expect_identical(eval(parse(text = r_code(x))), as.numeric(x))
  }
  expect_equal(r_code("a \"b\""), "\"a \\\"b\\\"\"")
  expect_equal(r_code(c(TRUE, FALSE)), "c(TRUE, FALSE)")
})

test_that("a simulated run records the seed of each simulated n", {
  spec <- sim_spec("independent_t", goal = list(type = "power", n = 100))
  sims <- run_quietly(spec)$provenance$simulations
  expect_equal(sims, data.frame(
    n = 100, seed = 7L, rejections = sims$rejections, nrep = 100, fitted = NA
  ))
  expect_identical(run_spec(small_run_spec("anova_2x2_mixed"))$provenance$simulations, NA)
})

# Reproduction: one per end point ------------------------------------------------

basic_power_spec <- function(name, n = 100, ...) {
  sim_spec(name, goal = list(type = "power", n = n), ...)
}

test_that("E1 one-sample t-test: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("one_sample_t", n = 30)
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E2 independent-samples t-test: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("independent_t")
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_true(any(grepl("var.equal = FALSE", run$script, fixed = TRUE)))
})

test_that("E3 paired-samples t-test: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("paired_t", n = 40)
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E4 correlation: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("correlation")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E5 two proportions: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("two_proportions", n = 200)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_true(any(grepl("correct = FALSE", run$script, fixed = TRUE)))
})

test_that("E6 chi-square test of independence: the exported Spower script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("chi_square_independence", n = 150)
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E7 2x2 between ANOVA: the exported Superpower script reproduces powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 120))
  expect_script_reproduces_power(spec, run_spec(spec))
})

test_that("E8 2x2 mixed ANOVA: the exported Superpower script reproduces powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- small_run_spec("anova_2x2_mixed")
  expect_script_reproduces_power(spec, run_spec(spec))
})

test_that("E9 regression interaction: the exported InteractionPoweR script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- sim_spec("regression_interaction", goal = list(type = "power", n = 200))
  spec <- continuous_and_reliable(spec)
  spec$variables$X$reliability <- 0.8
  expect_script_reproduces_power(spec, run_for_export(spec))
})

mediation_power_spec <- function(name) {
  continuous_and_reliable(sim_spec(name, goal = list(type = "power", n = 150)))
}

test_that("E10 simple mediation: the exported power4mome script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- mediation_power_spec("mediation_simple")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E11 parallel mediation: the exported power4mome script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- mediation_power_spec("mediation_parallel")
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_true(any(grepl("\"M1 ~~ M2\"", run$script, fixed = TRUE)))
})

test_that("E12 serial mediation: the exported power4mome script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- mediation_power_spec("mediation_serial")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E13 moderated mediation (PROCESS model 7): the exported power4mome script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- mediation_power_spec("process_7")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("E14 moderated mediation (PROCESS model 14): the exported power4mome script reproduces powerkit", {
  skip_unless_scripts_can_run()
  spec <- mediation_power_spec("process_14")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

# Reproduction: other goals and settings ---------------------------------------------

test_that("one-sided tests: the script reproduces powerkit's directional test (Departure 4)", {
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("independent_t")
  spec$target_test$alternative <- "greater"
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_true(any(grepl("one_sided_p <- function", run$script, fixed = TRUE)))
  expect_false(any(grepl("two.tailed", sub("#.*$", "", run$script), fixed = TRUE)))
})

test_that("a simulated required n is reproduced, with its interval and every simulated point", {
  skip_unless_scripts_can_run()
  spec <- sim_spec("independent_t", goal = list(type = "sample_size", power = 0.8))
  result <- run_for_export(spec)
  run <- run_exported_script(spec, result)
  expect_n_near(result$n_required, run$reproduced$n)
  expect_equal(run$reproduced[c("n", "lower", "upper")], result$n_required)
  expect_equal(run$reproduced$power, result$curve$power, tolerance = 1e-10)
})

test_that("an exact required n is reproduced (2x2 mixed)", {
  skip_unless_scripts_can_run()
  spec <- small_run_spec("anova_2x2_mixed", goal = list(type = "sample_size", power = 0.9))
  result <- run_spec(spec)
  run <- run_exported_script(spec, result)
  expect_equal(run$reproduced$n, result$n_required$n)
  expect_equal(run$reproduced$power, result$curve$power, tolerance = 1e-10)
})

test_that("a smallest detectable effect is reproduced (2x2 between)", {
  skip_unless_scripts_can_run()
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "sensitivity", n = 120, power = 0.8))
  result <- run_spec(spec)
  run <- run_exported_script(spec, result)
  s <- result$sensitivity
  expect_equal(run$reproduced, list(scale = s$scale, effect = s$effect, cohen_f = s$cohen_f, power = s$power),
    tolerance = 1e-10
  )
})

test_that("a 2x2 simulation run is reproduced with ANOVA_power()", {
  skip_unless_scripts_can_run()
  spec <- small_run_spec("anova_2x2_mixed", method = "simulation")
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("a run on several cores is reproduced with the same batches", {
  # Spower runs one batch per core, so the script splits the replications
  # the same way (here on Windows too, where the batches run one after
  # another). Two cores, the most CRAN allows.
  skip_unless_scripts_can_run()
  spec <- basic_power_spec("correlation")
  result <- run_for_export(spec, cores = 2)
  run <- expect_script_reproduces_power(spec, result)
  expect_true(any(grepl("min(2, replications)", run$script, fixed = TRUE)))
})

test_that("power4mome batches are reproduced (several batches)", {
  skip_unless_scripts_can_run()
  local_mocked_bindings(power4mome_batch_size = function(...) 30L)
  spec <- mediation_power_spec("mediation_simple")
  result <- run_for_export(spec)
  expect_equal(result$provenance$batch_size, 30L)
  run <- expect_script_reproduces_power(spec, result)
  expect_true(any(grepl("batch_size <- 30", run$script, fixed = TRUE)))
})
