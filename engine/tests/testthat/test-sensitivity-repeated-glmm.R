# The smallest detectable effect of the repeated-measures card for a count,
# yes/no or ordered outcome (E75) and of Cochran's Q (E78), by the
# simulated search (sensitivity-simulated.R, repeated_glmm_search()). The
# searches take minutes each, so the full check (a fresh simulation at the
# effect found, and the exported script reproducing it) runs with the
# high-replication validation tests.

repeated_specs <- function() {
  count <- example_spec("repeated_glmm")
  nb <- count
  nb$population$dispersion <- 0.4
  binary <- count
  binary$variables$Y$type <- "binary"
  binary$population$metric <- "probability"
  binary$population$rates <- NULL
  binary$population$probabilities <- list(0.3, 0.2)
  binary$target_test$method <- "likelihood_ratio"
  binary$population$measurements <- 2
  ordinal <- count
  ordinal$variables$Y <- list(type = "categorical", label = "Rating", levels = list("Low", "Middle", "High"))
  ordinal$population$metric <- "proportion"
  ordinal$population$rates <- NULL
  ordinal$population$category_probabilities <- list(0.3, 0.4, 0.3)
  ordinal$population$odds_ratios <- list(1, 1.8)
  ordinal$target_test$method <- "likelihood_ratio"
  int_count <- example_spec("repeated_glmm_interaction")
  int_binary <- int_count
  int_binary$variables$Y$type <- "binary"
  int_binary$population$metric <- "probability"
  int_binary$population$rates <- NULL
  int_binary$population$probabilities <- list(list(0.3, 0.3), list(0.3, 0.15))
  int_ordinal <- int_count
  int_ordinal$variables$Y <- ordinal$variables$Y
  int_ordinal$population$metric <- "proportion"
  int_ordinal$population$rates <- NULL
  int_ordinal$population$category_probabilities <- list(0.3, 0.4, 0.3)
  int_ordinal$population$odds_ratios <- list(list(1, 1), list(1.2, 2.4))
  list(count = count, nb = nb, binary = binary, ordinal = ordinal, cochran = example_spec("repeated_glmm_cochran"),
    int_count = int_count, int_binary = int_binary, int_ordinal = int_ordinal)
}

test_that("each repeated-measures search scales the differences tested and keeps the rest, and the script sets the same", {
  specs <- repeated_specs()
  for (name in names(specs)) {
    spec <- specs[[name]]
    spec$goal <- list(type = "sensitivity", n = 60L, power = 0.8)
    expect_true(simulated_search_available(spec), label = name)
    expect_true(simulated_search_scales_pattern(spec), label = name)
    plan <- simulated_search_plan(spec, 60L, 0.8)
    # At 1, the population entered.
    same <- repeated_glmm_inputs(plan$set(spec, 1))
    expect_equal(same$centre, repeated_glmm_inputs(spec)$centre, label = name)
    at <- plan$set(spec, 1.4)
    changed <- names(Filter(isTRUE, Map(function(a, b) !isTRUE(all.equal(a, b)), at$population, spec$population)))
    expect_length(changed, 1)
    before <- repeated_glmm_inputs(spec)
    after <- repeated_glmm_inputs(at)
    if (before$interaction) {
      # The interaction coefficients times 1.4, the other coefficients kept.
      tested <- grepl(":", before$fixef_names, fixed = TRUE)
      expect_equal(after$fixef[tested], 1.4 * before$fixef[tested], label = name)
      expect_equal(after$fixef[!tested], before$fixef[!tested], label = name)
    } else {
      expect_equal(after$centre - after$centre[1], 1.4 * (before$centre - before$centre[1]), label = name)
      expect_equal(after$centre[1], before$centre[1], label = name)
    }
    # The script's set_effect() gives the same values (with groups, as a
    # matrix, one row per group, and simr's fixed effects with them).
    env <- new.env()
    env$conditions <- before$levels
    env$groups <- before$groups
    if (before$interaction) {
      env$cells <- expand.grid(cond = factor(before$levels, levels = before$levels), group = factor(before$groups, levels = before$groups))
    }
    env[[changed]] <- NULL
    env$fixed_effects <- NULL
    set_effect <- eval(parse(text = c("function(x) {", plan$script_set, "}")), envir = env)
    set_effect(1.4)
    script_values <- if (before$interaction) as.vector(t(env[[changed]])) else as.numeric(env[[changed]])
    expect_equal(script_values, as.numeric(unlist(at$population[[changed]])), tolerance = 1e-12, label = name)
    if (before$interaction && !(before$nb || before$ordinal)) {
      expect_equal(env$fixed_effects, after$fixef, tolerance = 1e-10, label = name)
    }
  }
  # The effect reported: the ratio of the conditions furthest apart, or the
  # ratio of ratios.
  expect_equal(simulated_search_plan(specs$count, 60L, 0.8)$effect(1), 2 / 1.6)
  expect_identical(simulated_search_plan(specs$count, 60L, 0.8)$effect_name, "rate_ratio")
  expect_equal(simulated_search_plan(specs$binary, 60L, 0.8)$effect(2), ((0.3 / 0.7) / (0.2 / 0.8))^2)
  expect_identical(simulated_search_plan(specs$ordinal, 60L, 0.8)$effect_name, "odds_ratio")
  expect_equal(simulated_search_plan(specs$int_count, 60L, 0.8)$effect(1), 2 / 1.4)
  expect_identical(simulated_search_plan(specs$int_count, 60L, 0.8)$effect_name, "ratio_of_rate_ratios")
  expect_equal(simulated_search_plan(specs$int_ordinal, 60L, 0.8)$effect(1), 2)
  expect_identical(simulated_search_plan(specs$int_binary, 60L, 0.8)$effect_name, "ratio_of_odds_ratios")
})

test_that("a repeated-measures card with no difference entered has nothing to scale", {
  spec <- example_spec("repeated_glmm")
  spec$population$rates <- list(2, 2)
  spec$goal <- list(type = "sensitivity", n = 40L, power = 0.8)
  expect_error(validate_spec(spec), class = "powerkit_error")
})

test_that("a repeated-measures card's smallest effect has the target power in a fresh simulation, and the script reproduces it", {
  skip_unless_full_validation()
  specs <- repeated_specs()[c("count", "cochran", "int_binary")]
  for (name in names(specs)) {
    spec <- specs[[name]]
    n <- if (name == "int_binary") 120L else 40L
    spec$goal <- list(type = "sensitivity", n = n, power = 0.8)
    spec$options$nrep <- 300L
    result <- suppressWarnings(run_quietly(spec))
    s <- result$sensitivity
    expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper, label = name)
    at <- simulated_search_plan(spec, n, 0.8)$set(spec, s$scale)
    at$goal <- list(type = "power", n = n)
    at$options$nrep <- 2000L
    at$options$seed <- 99L
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.05, label = name)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
})
