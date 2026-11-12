# Bayesian write-ups: the Bayes factor versions' methods paragraph and
# plain-words version in Bayesian terms (a Bayes factor design analysis,
# Schonbrodt & Wagenmakers, 2018, with the analysis prior and the design
# prior named apart), and the write-up for a plan that reports a p-value
# and a Bayes factor together (bayes_companion_writeup()).

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

bayes_writeup <- function(ep, change) {
  fields <- form_fields(form_groups(forms, ep))
  values <- modifyList(form_examples[[ep]], c(change, list(just_source = "A meta-analysis.", alpha = NULL)))
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$status, "ok")
  writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values)
}

test_that("a Bayes factor plan is written up as a design analysis, with its analysis and design priors", {
  skip_without_run()
  w <- bayes_writeup("E2", list(method = "bayes_factor", evidence_threshold = "10", effect_sd = "0.1", goal = "sample_size", power = 0.8))
  short <- w[["short"]]
  expect_match(short, "An a priori Bayes factor design analysis (Schönbrodt & Wagenmakers, 2018) was conducted", fixed = TRUE)
  expect_match(short, "Cauchy analysis prior of scale 0.707", fixed = TRUE)
  expect_match(short, "The design prior is centred on the planned effect, Cohen's d = 0.4", fixed = TRUE)
  expect_match(short, "a normal design prior on the effect size with an SD of 0.1", fixed = TRUE)
  expect_match(short, "assurance; O'Hagan, Stevens & Campbell, 2005", fixed = TRUE)
  expect_match(short, "For a target probability of strong evidence for the effect (BF10 of at least 10) of 80%", fixed = TRUE)
  expect_match(short, "The probabilities of strong evidence were calculated", fixed = TRUE)
  # A methods paragraph speaks of the study, not to the reader, and a
  # Bayes factor plan has no power or alpha.
  for (word in c(" you", "your", "Power was", "power analysis", "α")) expect_no_match(short, word, fixed = TRUE, label = word)
  ethics <- w[["ethics"]]
  expect_match(ethics, "This number comes from a Bayes factor design analysis.", fixed = TRUE)
  expect_match(ethics, "Averaged over the effect sizes we think plausible", fixed = TRUE)
  expect_match(ethics, "could not find strong evidence that there is no effect", fixed = TRUE)
})

test_that("a point design prior says so, and the chance of evidence for no effect is given", {
  skip_without_run()
  w <- bayes_writeup("E4", list(method = "bayes_factor", evidence_threshold = "10", prior_width = "1", r_sd = "0", goal = "power", n = 900))
  expect_match(w[["short"]], "The design prior is a point at that value", fixed = TRUE)
  expect_match(w[["short"]], "stretched beta prior of width 1 on the correlation as the analysis prior", fixed = TRUE)
  expect_match(w[["short"]], "If there were no effect, the probability of strong evidence for its absence (BF01 of at least 10) would be", fixed = TRUE)
  expect_match(w[["ethics"]], "If that effect is real", fixed = TRUE)
})

test_that("a plan that reports both has a write-up with the Bayes factor as its secondary analysis", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples$E2, list(goal = "sample_size", power = 0.8, just_source = "A meta-analysis."))
  values$het_tau <- NULL
  spec <- build_spec(forms, "E2", fields, values)
  calc <- run_calculation(spec, run, seed = 1L)
  n <- calc$result$n_required$n
  comp <- engine_function("bayes_companion")(calc$spec, n, target = 0.8)
  w <- bayes_companion_writeup(forms$forms$E2, calc$spec, calc$result, fields, values, comp)
  base <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, values)
  # The card's own paragraph first, then the Bayes factor's.
  expect_true(startsWith(w[["short"]], base[["short"]]))
  expect_match(w[["short"]], "As a secondary analysis, the Bayes factor (BF10) will be computed with the Bayes factor t-test", fixed = TRUE)
  expect_match(w[["short"]], "The main analysis is a two-sided Welch's t-test: if the two disagree", fixed = TRUE)
  expect_match(w[["short"]], sprintf("at %s participants, with the planned effect as a point design prior", whole(n)), fixed = TRUE)
  expect_match(w[["short"]], sprintf("the study needs %s participants in total", whole(comp$n_for_both$n_both[1])), fixed = TRUE)
  expect_match(w[["full"]], "As a secondary analysis", fixed = TRUE)
  expect_match(w[["ethics"]], "We will also analyse the data with a Bayes factor", fixed = TRUE)
  html <- as.character(bayes_companion_ui(calc$spec, calc$result, comp, w))
  expect_match(html, "Write-up for both", fixed = TRUE)
  expect_match(html, "writeup_both_short", fixed = TRUE)
  # With no reasoning given, the write-up says so.
  expect_match(as.character(bayes_companion_ui(calc$spec, calc$result, comp)), "Wording for your plan", fixed = TRUE)
  expect_match(bayes_companion_writeup(forms$forms$E2, calc$spec, calc$result, fields, modifyList(values, list(just_source = "")), comp)[["short"]],
    "No justification for the effect size was recorded.", fixed = TRUE)
})
