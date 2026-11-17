# The smallest detectable indirect effect, or index of moderated mediation,
# by the simulated search over the paths that make it up
# (sensitivity-simulated.R, mediation_search()).

mediation_names <- c("mediation_simple", "mediation_parallel", "mediation_serial", "process_7", "process_7_parallel", "process_14")

test_that("the search scales the effect tested and keeps the rest", {
  for (name in mediation_names) {
    spec <- example_spec(name)
    spec$goal <- list(type = "sensitivity", n = 200L, power = 0.8)
    expect_true(mediation_search(spec), label = name)
    plan <- simulated_search_plan(spec, 200L, 0.8)
    tested <- mediation_tested_paths(spec)
    product <- function(s) prod(vapply(tested, function(p) as.numeric(s$population$paths[[p]]), numeric(1)))
    expect_equal(plan$effect(1), product(spec), label = name)
    expect_equal(product(plan$set(spec, 1.7)), 1.7 * product(spec), label = name)
    others <- setdiff(names(spec$population$paths), tested)
    expect_equal(plan$set(spec, 1.7)$population$paths[others], spec$population$paths[others], label = name)
    expect_gt(plan$limit, 1)
  }
  # The index's paths: the moderated link and the other link.
  expect_identical(mediation_tested_paths(example_spec("process_7")), c("XW->M", "M->Y"))
  expect_identical(mediation_tested_paths(example_spec("process_14")), c("X->M", "MW->Y"))
  expect_identical(mediation_tested_paths(example_spec("mediation_serial")), c("X->M1", "M1->M2", "M2->Y"))
  # The difference between conditional indirect effects is not searched.
  expect_false(mediation_search(example_spec("process_58")))
  expect_false(mediation_search(example_spec("process_8")))
})

test_that("the exported script's population values are power4mome's at every size of the effect", {
  for (name in mediation_names) {
    spec <- example_spec(name)
    spec$goal <- list(type = "sensitivity", n = 200L, power = 0.8)
    plan <- simulated_search_plan(spec, 200L, 0.8)
    for (x in c(0.43, 1, 1.7)) {
      env <- new.env()
      env$pop_es <- NULL
      set_effect <- eval(parse(text = c("function(x) {", plan$script_set, "}")), envir = env)
      set_effect(x)
      expect_identical(env$pop_es, power4mome_inputs(plan$set(spec, x))$pop_es, label = paste(name, x))
    }
  }
})

test_that("simple mediation's smallest indirect effect has the target power in a fresh simulation, and the script reproduces it", {
  skip_on_cran()
  spec <- example_spec("mediation_simple")
  spec$goal <- list(type = "sensitivity", n = 150L, power = 0.8)
  spec$options$nrep <- 300L
  result <- suppressWarnings(run_quietly(spec))
  s <- result$sensitivity
  expect_identical(s$effect_name, "indirect_effect")
  expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper)
  at <- simulated_search_plan(spec, 150L, 0.8)$set(spec, s$scale)
  at$goal <- list(type = "power", n = 150L)
  at$options$nrep <- 2000L
  at$options$seed <- 99L
  expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.05)
  file <- withr::local_tempfile(fileext = ".R")
  writeLines(export_script(spec, result), file)
  out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
  expect_true(any(grepl("^Reproduced powerkit's result", out)))
})
