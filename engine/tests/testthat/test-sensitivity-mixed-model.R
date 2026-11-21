# The smallest detectable effect of the mixed models simr fits, by the
# simulated search (sensitivity-simulated.R, mixed_model_search()). The
# searches themselves take minutes each, so the full check (a fresh
# simulation at the effect found, and the exported script reproducing it)
# runs with the high-replication validation tests.

mixed_specs <- function() {
  binary <- example_spec("crossed_two_condition")
  binary$variables$Y$type <- "binary"
  binary$population[c("difference", "sd_residual")] <- NULL
  binary$population$probabilities <- list(0.6, 0.7)
  binary$target_test$method <- "wald"
  binary$population$metric <- "probability"
  pairwise <- example_spec("crossed_conditions")
  list(
    crossed_two_condition = example_spec("crossed_two_condition"),
    crossed_binary = binary,
    crossed_conditions = pairwise,
    item_predictor = example_spec("item_predictor"),
    mixed_three_level = example_spec("mixed_three_level"),
    mixed_two_level = example_spec("mixed_two_level")
  )
}

test_that("each mixed model's search sets the effect tested and keeps the rest, and the script sets the same", {
  specs <- mixed_specs()
  for (name in names(specs)) {
    spec <- specs[[name]]
    spec$goal <- list(type = "sensitivity", n = 60L, power = 0.8)
    expect_true(mixed_model_search(spec), label = name)
    plan <- simulated_search_plan(spec, 60L, 0.8)
    at <- plan$set(spec, 1.3)
    changed <- names(Filter(isTRUE, Map(function(a, b) !identical(a, b), at$population, spec$population)))
    expect_length(changed, 1)
    # The script's set_effect() gives the same value.
    script_name <- switch(changed, b_XW = "b_xw", changed)
    env <- new.env()
    assign(script_name, NULL, envir = env)
    assign("fixed", NULL, envir = env)
    set_effect <- eval(parse(text = c("function(x) {", plan$script_set, "}")), envir = env)
    set_effect(1.3)
    expect_identical(as.numeric(env[[script_name]]), as.numeric(unlist(at$population[[changed]])), label = name)
  }
  # The effect reported.
  s <- specs$crossed_two_condition
  expect_equal(simulated_search_plan(s, 60L, 0.8)$effect(25), 25)
  expect_equal(simulated_search_plan(specs$crossed_binary, 60L, 0.8)$effect(1), 0.7 / 0.3 / (0.6 / 0.4))
  m <- unlist(specs$crossed_conditions$population$means)
  expect_equal(simulated_search_plan(specs$crossed_conditions, 60L, 0.8)$effect(2), 2 * abs(m[1] - m[2]))
  expect_identical(simulated_search_plan(specs$crossed_conditions, 60L, 0.8)$effect_name, "mean_difference")
  # The slope's sign is kept.
  expect_equal(simulated_search_plan(specs$item_predictor, 60L, 0.8)$effect(10), -10)
  # Several coefficients tested together are not searched.
  several <- example_spec("mixed_two_level")
  several$target_test$effect <- "within_and_interaction"
  expect_false(mixed_model_search(several))
})

test_that("a mixed model's smallest effect has the target power in a fresh simulation, and the script reproduces it", {
  skip_unless_full_validation()
  spec <- example_spec("crossed_two_condition")
  spec$goal <- list(type = "sensitivity", n = 60L, power = 0.8)
  spec$options$nrep <- 300L
  result <- suppressWarnings(run_quietly(spec))
  s <- result$sensitivity
  expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper)
  at <- spec
  at$population$difference <- s$effect
  at$goal <- list(type = "power", n = 60L)
  at$options$nrep <- 2000L
  at$options$seed <- 99L
  expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.05)
  file <- withr::local_tempfile(fileext = ".R")
  writeLines(export_script(spec, result), file)
  out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
  expect_true(any(grepl("^Reproduced powerkit's result", out)))
})
