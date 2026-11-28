# One earlier study's F on the ANOVA screens (input-screen review of 28
# November 2026): BUCSS's correction for publication bias and uncertainty,
# offered first and for a sample size, shown beside the plan's own and
# written up; or safeguard power, the lower end of the interval around the
# partial eta-squared, as on the t-tests.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))

published_f <- function(...) {
  modifyList(modifyList(form_examples$E18, list(metric = "eta_squared", test_version = "anova_f", conv_from = "F",
    conv_value = "6.2", conv_df1 = "2", conv_df = "57", goal = "sample_size", power = "0.8",
    just_type = "prior_study", just_source = "An earlier study")), list(...))
}
ids_shown <- function(ep, values) {
  vapply(Filter(function(f) field_applies(f, values), form_fields(form_groups(forms, ep))), `[[`, "", "id")
}

test_that("one study's F is asked how to plan from it, BUCSS first, with nothing chosen", {
  expect_true("sg_use" %in% ids_shown("E18", published_f()))
  expect_false("sg_use" %in% ids_shown("E18", published_f(just_type = "meta_analysis")))
  expect_false("sg_use" %in% ids_shown("E18", published_f(conv_from = "f")))
  sg <- Filter(function(f) identical(f$id, "sg_use"), form_fields(form_groups(forms, "E18")))[[1]]
  expect_null(sg[["default"]])
  expect_identical(names(sg$choices), c("bucss", "yes", "no"))
  # BUCSS gives a sample size, so it is offered for that goal.
  expect_identical(sg$choices_shown_if$bucss[[1]], list(field = "goal", is = "sample_size"))
  expect_true(all(c("bc_n", "bc_published") %in% ids_shown("E18", published_f(sg_use = "bucss"))))
  expect_false("bc_n" %in% ids_shown("E18", published_f(sg_use = "bucss", goal = "power", n = "60")))
  expect_true("sg_protection" %in% ids_shown("E18", published_f(sg_use = "yes")))
  # The ANCOVAs offer safeguard power only: BUCSS has no design with covariates.
  ancova <- Filter(function(f) identical(f$id, "sg_use"), form_fields(form_groups(forms, "E23")))[[1]]
  expect_identical(names(ancova$choices), c("yes", "no"))
})

test_that("safeguard power plans with the lower end of the interval and says so", {
  skip_if(is.null(run), "powerkit's engine isn't available here")
  fields <- form_fields(form_groups(forms, "E18"))
  values <- published_f(sg_use = "yes", sg_protection = "0.8")
  spec <- build_spec(forms, "E18", fields, values)
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$safeguard$lower, effectsize::F_to_eta2(6.2, 2, 57, ci = 0.6, alternative = "two.sided")$CI_low[[1]])
  expect_match(safeguard_sentence(calc$result), "from its F with 2 and 57 degrees of freedom", fixed = TRUE)
  text <- paste(writeup_text(forms$forms$E18, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "computed with the effectsize package's F_to_eta2()", fixed = TRUE)
})

test_that("BUCSS's sizes are shown beside the plan's and written up", {
  skip_if(is.null(run), "powerkit's engine isn't available here")
  skip_if_not_installed("BUCSS")
  fields <- form_fields(form_groups(forms, "E18"))
  values <- published_f(sg_use = "bucss", bc_n = "60", bc_published = "significant")
  spec <- build_spec(forms, "E18", fields, values)
  expect_identical(spec$effect_justification$bias_correction, list(n = 60L, published = "significant"))
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  sentence <- bias_correction_sentence(calc$result)
  expect_match(sentence, "Corrected for publication bias and uncertainty", fixed = TRUE)
  expect_match(sentence, "at 50% assurance", fixed = TRUE)
  text <- paste(writeup_text(forms$forms$E18, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "with BUCSS (Anderson, Kelley & Maxwell, 2017; ss_buc_one_way_anova()", fixed = TRUE)
  expect_no_match(text, "No adjustment for the uncertainty", fixed = TRUE)
})
