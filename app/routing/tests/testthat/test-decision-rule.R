# One decision rule for every export (R/decision-rule.R): the short, full
# and ethics write-ups, the single-analysis planning document and a study
# plan's target and Registered Report table state the same decision.

rule_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))

# A card's example with some answers changed, calculated, and every output
# a researcher can copy.
decision_outputs <- function(ep, set = list(), seed = 11L) {
  run <- rule_engine("run_spec")
  skip_if(is.null(run), "powerkit's engine isn't available here")
  values <- form_examples[[ep]]
  for (k in names(set)) values[[k]] <- set[[k]]
  fields <- form_fields(form_groups(forms, ep))
  spec <- build_spec(forms, ep, fields, values)
  calc <- suppressWarnings(run_calculation(spec, run, seed = seed))
  expect_identical(calc$status, "ok", label = ep)
  calc$route <- list(app = "routing-prototype", route = "choose", endpoint = ep, came_from = "node",
    ctx = list(), history = list(), form_k = 2L, form_values = values)
  writeup <- planning_writeup(forms, ep, calc$spec, calc$result, fields, values)
  entry <- plan_entry(tree, ep, calc, calc$route)
  row <- plan_design_row(entry, tree, forms)
  list(short = writeup[["short"]], full = writeup[["full"]], ethics = writeup[["ethics"]],
    document = paste(planning_document(tree, forms, calc), collapse = "\n"),
    target = plan_entry_target(calc$spec), analysis = row[[4]], interpretation = row[[6]])
}

expect_no_empty_test <- function(out, label) {
  text <- paste(unlist(out), collapse = "\n")
  expect_no_match(text, "NULL|alpha = ,|alpha = \\.?$", label = label)
}

test_that("non-inferiority and two-sided equivalence read as different decisions everywhere", {
  ni <- decision_outputs("E36", list(comparison = "noninf_independent", ni_margin = "0.3", ni_d = "0", better = "higher"))
  for (part in c("short", "full", "document", "analysis")) expect_match(ni[[part]], "non-inferiority", ignore.case = TRUE, label = part)
  expect_match(ni$ethics, "no worse than the margin", fixed = TRUE)
  expect_match(ni$analysis, "one-sided test against the margin is significant", fixed = TRUE)
  expect_match(ni$interpretation, "no worse than the comparison by more than the margin", fixed = TRUE)
  for (part in c("document", "analysis", "interpretation")) expect_no_match(ni[[part]], "both one-sided|TOST", label = part)
  expect_no_empty_test(ni, "non-inferiority")
  tost <- decision_outputs("E36")
  expect_match(tost$analysis, "both one-sided tests are significant", fixed = TRUE)
  expect_match(tost$document, "Equivalence is shown if both one-sided tests are significant", fixed = TRUE)
  expect_match(tost$ethics, "too small to matter", fixed = TRUE)
})

test_that("the test of not-close fit and the test of exact fit read as different decisions everywhere", {
  near <- decision_outputs("E37", list(question = "model_fit", fit_test = "chi_square_not_close_fit", rmsea = "0.02", rmsea_null = "0.05"))
  for (part in c("short", "full", "document", "analysis")) expect_match(near[[part]], "not-close fit", fixed = TRUE, label = part)
  expect_match(near$ethics, "shows it fits closely", fixed = TRUE)
  expect_match(near$interpretation, "the model fits closely", fixed = TRUE)
  for (part in c("document", "analysis", "interpretation")) expect_no_match(near[[part]], "exact model fit|evidence against no effect", label = part)
  expect_no_empty_test(near, "not-close fit")
  exact <- decision_outputs("E37", list(question = "model_fit", fit_test = "chi_square_exact_fit"))
  expect_match(exact$analysis, "detecting the misfit", fixed = TRUE)
  expect_match(exact$interpretation, "does not fit exactly", fixed = TRUE)
  expect_match(exact$ethics, "If our model is wrong", fixed = TRUE)
})

test_that("a minimum-effect test and an ordinary test read as different decisions everywhere", {
  me <- decision_outputs("E2", list(method = "minimum_effect", margin = "0.2", d = "0.6"))
  for (part in c("short", "full", "document", "analysis")) expect_match(me[[part]], "minimum-effect", label = part)
  expect_match(me$ethics, "shows it is further from zero than d = 0.2, the smallest effect that would matter", fixed = TRUE)
  expect_no_match(me$ethics, "finds it", fixed = TRUE)
  expect_match(me$interpretation, "exceeds the smallest effect of interest (d = 0.2)", fixed = TRUE)
  expect_no_empty_test(me, "minimum effect")
  plain <- decision_outputs("E2")
  expect_match(plain$ethics, "finds it", fixed = TRUE)
  expect_match(plain$interpretation, "evidence against no effect", fixed = TRUE)
})

test_that("validating a prediction model and developing one read as different decisions everywhere", {
  val <- decision_outputs("E77", list(purpose = "validation", outcome = "binary", c_statistic = "0.75", prevalence = "0.2",
    lp_distribution = "normal", lp_mean = "-1.75", lp_sd = "0.9"))
  for (part in c("document", "target", "analysis")) expect_match(val[[part]], "validat", label = part)
  # The document's answers list repeats the question ("Are you developing
  # a new model, or validating an existing one?"); its decision doesn't.
  for (part in c("target", "analysis")) expect_no_match(val[[part]], "developing|shrinkage", label = part)
  expect_no_match(val$document, "developing a prediction model|shrinkage", label = "document")
  expect_no_match(val$analysis, "test at|significant", label = "validation")
  expect_no_empty_test(val, "validation")
  dev <- decision_outputs("E77", list(purpose = "development"))
  for (part in c("document", "target", "analysis")) expect_match(dev[[part]], "developing a prediction model", fixed = TRUE, label = part)
  expect_no_empty_test(dev, "development")
})

test_that("a precision plan states its interval and width, not a test", {
  p <- decision_outputs("E46", list(estimate = "proportion"))
  expect_match(p$analysis, "Wilson confidence interval", fixed = TRUE)
  expect_match(p$analysis, "expected (average) width", fixed = TRUE)
  expect_match(p$document, "Precision planning for a 95% Wilson confidence interval", fixed = TRUE)
  for (part in c("document", "analysis", "interpretation", "target")) expect_no_match(p[[part]], "alpha|significance test|test at", label = part)
})

test_that("the one-proportion z test and the exact binomial test are named as chosen everywhere", {
  z <- decision_outputs("E25", list(method = "z_test_corrected"))
  for (part in c("short", "full", "document", "analysis")) expect_match(z[[part]], "z test of one proportion", fixed = TRUE, label = part)
  expect_match(z$analysis, "with the continuity correction", fixed = TRUE)
  expect_no_match(z$analysis, "exact binomial", fixed = TRUE)
  exact <- decision_outputs("E25")
  for (part in c("short", "analysis")) expect_match(exact[[part]], "exact binomial test", fixed = TRUE, label = part)
})

test_that("factor recovery and choosing profiles have no significance test in any output", {
  # No calculation needed: the decision is built from the spec alone.
  for (case in list(list(ep = "E73", words = "every factor's loadings are recovered", target = "chance of recovering every factor"),
                    list(ep = "E58", words = "the BIC chooses 3 profiles", target = "chance of the BIC choosing 3 profiles"))) {
    spec <- build_spec(forms, case$ep, form_fields(form_groups(forms, case$ep)), form_examples[[case$ep]])
    rule <- decision_rule(spec, form = forms$forms[[case$ep]])
    expect_match(rule$rule, "not a significance decision", fixed = TRUE, label = case$ep)
    expect_match(rule$analysis, case$words, fixed = TRUE, label = case$ep)
    expect_match(plan_entry_target(spec), case$target, fixed = TRUE, label = case$ep)
    for (part in c("rule", "analysis", "interpretation")) {
      expect_no_match(rule[[part]], "alpha|significant|two-sided", label = paste(case$ep, part))
    }
  }
})

test_that("an omnibus F test is not called two-sided, and a reliability test names its value to beat", {
  anova <- build_spec(forms, "E18", form_fields(form_groups(forms, "E18")), form_examples$E18)
  expect_no_match(decision_rule_text(anova), "two-sided", fixed = TRUE)
  expect_match(decision_rule_text(anova), "an F test, which detects a difference in any direction", fixed = TRUE)
  icc <- build_spec(forms, "E69", form_fields(form_groups(forms, "E69")), form_examples$E69)
  expect_match(decision_rule(icc)$interpretation, "Significant: evidence that the ICC is above", fixed = TRUE)
})

test_that("the full paragraph asks where the reproducing code is shared, and what a fixed sample's data are for", {
  # Lakens (2022, refs.bib Lakens2022_justification), Tables 3 and 4.
  planned <- decision_outputs("E2")
  expect_match(planned$full, "[Say where the R script or saved plan that reproduces this calculation is shared", fixed = TRUE)
  expect_no_match(planned$full, "what the data will be used for", fixed = TRUE)
  expect_no_match(planned$short, "[Say where", fixed = TRUE)
  fixed <- decision_outputs("E2", list(goal = "power", n = "120", situation = "fixed"))
  expect_match(fixed$full, "[Say what the data will be used for at this sample size", fixed = TRUE)
})

test_that("the full paragraph asks why the significance level and target power were chosen when no reason is given", {
  # Lakens (2022), Table 4; decided 22 November 2026.
  bare <- decision_outputs("E2", list(alpha_reason = "", power_reason = ""))
  expect_match(bare$full, "[Say why this significance level was chosen.]", fixed = TRUE)
  expect_match(bare$full, "[Say why this target power was chosen.]", fixed = TRUE)
  expect_no_match(bare$short, "[Say why", fixed = TRUE)
  given <- decision_outputs("E2", list(alpha_reason = "the claim is new", power_reason = "a miss would waste a year"))
  expect_match(given$full, "The significance level of .05 was chosen because the claim is new.", fixed = TRUE)
  expect_no_match(given$full, "[Say why this", fixed = TRUE)
  # No target power for the power goal, so no prompt for it.
  power <- decision_outputs("E2", list(goal = "power", n = "120", power_reason = ""))
  expect_no_match(power$full, "[Say why this target power", fixed = TRUE)
})
