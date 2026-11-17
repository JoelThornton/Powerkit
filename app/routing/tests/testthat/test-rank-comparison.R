# The rank tests beside the tests they stand in for (17 November 2026): a
# rank test's result shows the card's default test's answer by formula, and
# the default test's result offers the rank test, to be chosen before the
# data are seen.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

rank_values <- function(ep, rank, shape, goal = "power", n = "60") {
  pair <- rank_pairs[[ep]]
  v <- modifyList(form_examples[[ep]], list(goal = goal, n = n, score_shape = shape))
  if (identical(pair$field, "test_version")) v$method <- NULL
  v[[pair$field]] <- rank
  v
}

test_that("each card with a rank test names a real choice and its default parametric test", {
  for (ep in names(rank_pairs)) {
    pair <- rank_pairs[[ep]]
    f <- Filter(function(x) identical(x$id, pair$field), form_fields(form_groups(forms, ep)))
    expect_length(f, 1)
    expect_true(pair$rank %in% names(f[[1]]$choices), label = ep)
    expect_false(identical(rank_pair_default(forms, ep), pair$rank), label = ep)
    expect_true(rank_pair_default(forms, ep) %in% pair$params, label = ep)
    expect_true(all(pair$params %in% names(f[[1]]$choices)), label = ep)
  }
})

test_that("a rank test's result gives the default test's answer and says why they differ", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E2"))
  # The rank test's own result is stood in by a power, so only the formula
  # runs here; the words follow the numbers.
  v <- rank_values("E2", "mann_whitney", "normal")
  # As on the input screen, Welch's SD ratio isn't asked for a rank test.
  v$welch_sd_ratio <- NULL
  spec <- build_spec(forms, "E2", fields, v)
  low <- rank_comparison_line(forms, "E2", v, spec, list(goal_type = "power", curve = list(power = 0.20)), run, seed = 1L)
  expect_match(low, "With Welch's t-test instead, by formula assuming normal scores, the power is", fixed = TRUE)
  expect_match(low, "a rank test has a little less power, because it uses only the order of the scores", fixed = TRUE)
  heavy <- rank_values("E2", "mann_whitney", "heavy_tailed")
  spec_h <- build_spec(forms, "E2", fields, heavy)
  high <- rank_comparison_line(forms, "E2", heavy, spec_h, list(goal_type = "power", curve = list(power = 0.60)), run, seed = 1L)
  expect_match(high, "With the heavy-tailed scores you assumed, the Mann-Whitney test has more power", fixed = TRUE)
  expect_match(high, "doesn't say how Welch's t-test itself would do with these scores", fixed = TRUE)
  # A sample size: the default test's number of people, with its groups.
  n <- rank_comparison_line(forms, "E2", modifyList(v, list(goal = "sample_size")), spec,
    list(goal_type = "sample_size", n_required = list(n = 400)), run, seed = 1L)
  expect_match(n, "Planned for Welch's t-test instead, by formula assuming normal scores, the answer is", fixed = TRUE)
  expect_match(n, "needs a few more people", fixed = TRUE)
  # Friedman's test says why its gap is large; the ANOVA's own choices
  # (its method) start at their defaults.
  fields54 <- form_fields(form_groups(forms, "E54"))
  v54 <- rank_values("E54", "friedman", "normal", n = "30")
  spec54 <- build_spec(forms, "E54", fields54, v54)
  f54 <- rank_comparison_line(forms, "E54", v54, spec54, list(goal_type = "power", curve = list(power = 0.5)), run, seed = 1L)
  expect_match(f54, "With the repeated-measures ANOVA instead", fixed = TRUE)
  expect_match(f54, "ranks each person's scores only against their own other scores", fixed = TRUE)
  # Not on the default test's own result, nor on Brunner-Munzel's.
  expect_null(rank_comparison_line(forms, "E2", form_examples$E2, build_spec(forms, "E2", fields, modifyList(form_examples$E2, list(goal = "power", n = "60"))),
    list(goal_type = "power", curve = list(power = 0.3)), run, seed = 1L))
  bm <- rank_values("E2", "brunner_munzel", "normal")
  expect_null(rank_comparison_line(forms, "E2", bm, build_spec(forms, "E2", fields, bm), list(goal_type = "power", curve = list(power = 0.3)), run, seed = 1L))
})

test_that("the default test's result offers the rank test, chosen before the data are seen", {
  fields <- form_fields(form_groups(forms, "E2"))
  spec <- build_spec(forms, "E2", fields, modifyList(form_examples$E2, list(goal = "power", n = "60")))
  html <- as.character(rank_switch_ui(forms, "E2", spec, list(goal_type = "power")))
  expect_match(html, "Plan with the Mann-Whitney test instead", fixed = TRUE)
  expect_match(html, "id=\"rank_switch\"", fixed = TRUE)
  expect_match(html, "Rochon, Gondan and Kieser, 2012", fixed = TRUE)
  bib <- paste(readLines(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"), encoding = "UTF-8"), collapse = "\n")
  expect_match(bib, "@Article{Rochon2012_pretest,", fixed = TRUE)
  # Not on a rank test's result, a Bayes factor's, or a sensitivity analysis.
  mw <- build_spec(forms, "E2", fields, rank_values("E2", "mann_whitney", "normal"))
  expect_null(rank_switch_ui(forms, "E2", mw, list(goal_type = "power")))
  st <- spec; st$target_test$method <- "student_t"
  expect_match(as.character(rank_switch_ui(forms, "E2", st, list(goal_type = "power"))), "Mann-Whitney", fixed = TRUE)
  bf <- spec; bf$target_test$method <- "bayes_factor"
  expect_null(rank_switch_ui(forms, "E2", bf, list(goal_type = "power")))
  expect_null(rank_switch_ui(forms, "E2", spec, list(goal_type = "sensitivity")))
  expect_null(rank_switch_ui(forms, "E5", spec, list(goal_type = "power")))
  # The switch sets the input screen's test field.
  app_code <- paste(readLines(file.path(routing_dir, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app_code, "observeEvent(input$rank_switch", fixed = TRUE)
})
