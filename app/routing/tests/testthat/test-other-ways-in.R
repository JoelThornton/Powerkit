# Other ways to give the numbers (input-screen review of 28 November 2026):
# one regression coefficient from its t or partial r, a yes/no predictor's
# odds ratio from the two groups' proportions, worked examples for the
# mixed models' SDs, and a line where a design needs the means.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

fields_of <- function(ep) form_fields(form_groups(forms, ep))
ids_shown <- function(ep, values) {
  vapply(Filter(function(f) field_applies(f, values), fields_of(ep)), function(f) f$id, "")
}

test_that("one coefficient can be given by its t statistic and df, or its partial correlation", {
  base <- modifyList(form_examples$E24, list(question = "single_coefficient", coef_test = "f_test", goal = "sample_size", power = "0.8"))
  t_route <- modifyList(base, list(r2_given = "coef_t", coef_t = "3", coef_t_df = "96"))
  expect_true(all(c("coef_t", "coef_t_df") %in% ids_shown("E24", t_route)))
  expect_false("partial_r2" %in% ids_shown("E24", t_route))
  spec <- build_spec(forms, "E24", fields_of("E24"), t_route)
  expect_identical(spec$effect_justification$conversion$from, "t")
  expect_equal(spec$effect_justification$conversion$df_error, 96L)
  # The other questions don't offer it.
  r2 <- Filter(function(f) identical(f$id, "r2_given"), fields_of("E24"))[[1]]
  expect_identical(r2$choices_shown_if$coef_t[[1]]$is, "single_coefficient")
  skip_without_run()
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$effect_conversion$converted, 9 / 105)
})

test_that("a yes/no predictor's odds ratio can come from the two groups' proportions", {
  values <- modifyList(form_examples$E27, list(X_type = "binary", X_level1 = "Control", X_level2 = "Treatment", x_prob = "0.5",
    or_given = "proportions", or_p2 = "0.4", base_prob = "0.25", goal = "sample_size", power = "0.8"))
  values$odds_ratio <- NULL
  expect_true("or_p2" %in% ids_shown("E27", values))
  expect_false("odds_ratio" %in% ids_shown("E27", values))
  # A score keeps the odds ratio.
  expect_false("or_given" %in% ids_shown("E27", form_examples$E27))
  skip_without_run()
  calc <- run_calculation(build_spec(forms, "E27", fields_of("E27"), values), run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$effect_conversion$converted, 2)
})

test_that("the mixed models' SDs give a worked example, and two designs say why they need the means", {
  for (ep in c("E63", "E67")) for (id in c("sd_participant", "sd_residual")) {
    f <- Filter(function(f) identical(f$id, id), fields_of(ep))[[1]]
    expect_match(f$help, "Brysbaert & Stevens, 2018", fixed = TRUE, label = paste(ep, id))
  }
  note <- function(ep) paste(unlist(lapply(form_groups(forms, ep), `[[`, "note")), collapse = " ")
  expect_match(note("E19"), "can't stand in for them", fixed = TRUE)
  expect_match(note("E20"), "can't yet take a partial eta-squared", fixed = TRUE)
})
