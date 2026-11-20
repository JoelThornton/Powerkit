# Replication plans with BUCSS (queue item 28): an ANOVA original reported
# as an F or a partial eta-squared, planned with the engine's
# replication_bucss(), and BUCSS's corrected sample sizes beside a t-test
# or correlation original's goals. The app only lays the numbers out.

skip_if_not_installed("BUCSS")
skip_if_not_installed("BayesRepDesign")

# Shnabel et al. (2009), Study 1: a 2 x 2 mixed-design interaction.
shnabel <- list(rep_design = "anova", rep_anova_kind = "mixed", rep_levels_a = "2", rep_levels_b = "2",
  rep_anova_effect = "interaction", rep_f_from = "f", rep_anova_f = "15.38", rep_n = "120",
  rep_original_alpha = "0.05", rep_alpha = "0.05", rep_power = "0.9", rep_assurance = "0.8", rep_epsilon = "1",
  rep_study = "Shnabel et al. (2009), Study 1")
# Its effect has one degree of freedom, so since 18 November 2026 it goes
# through every goal (test-replication-anova.R) with BUCSS beside them.
# The BUCSS-only route is for an effect with several: the same original
# read as a 2 x 3 mixed interaction (two degrees of freedom).
several <- modifyList(shnabel, list(rep_levels_b = "3"))
run_anova <- function(values = several) {
  replication_run(values, engine_function("replication_planning"), engine_function("replication_bucss"))
}
direct <- engine_function("replication_bucss")("anova_mixed", 15.38, 120, levels_a = 2, levels_b = 3, effect = "interaction",
  power = 0.9, assurance = c(0.5, 0.8, 0.9, 0.95))$sizes
direct_n <- function(a) direct$n[direct$assurance == a]

test_that("an ANOVA original's fields become replication_bucss()'s arguments", {
  args <- replication_args(several)
  expect_identical(replication_engine_name(several), "replication_bucss")
  expect_identical(replication_engine_name(shnabel), "replication_planning")
  expect_identical(replication_engine_name(list(rep_design = "two_groups")), "replication_planning")
  expect_equal(args[c("design", "original_n", "levels_a", "levels_b", "effect", "original_statistic", "power", "epsilon")],
    list(design = "anova_mixed", original_n = 120, levels_a = 2, levels_b = 3, effect = "interaction",
      original_statistic = 15.38, power = 0.9, epsilon = 1))
  expect_equal(args$assurance, c(0.5, 0.8, 0.9, 0.95))
  # In a mixed design the first factor is the between-subjects one.
  expect_identical(replication_args(modifyList(several, list(rep_anova_effect = "factor_b")))$effect, "within")
  # One factor: its own effect, whatever the box says.
  one <- replication_args(modifyList(several, list(rep_anova_kind = "between", rep_levels_a = "3", rep_levels_b = "", rep_anova_effect = "interaction")))
  expect_identical(one$effect, "factor_a")
  expect_null(one$levels_b)
  expect_null(one$epsilon)
  eta <- replication_args(modifyList(several, list(rep_f_from = "eta", rep_eta = "0.115", rep_df_error = "118")))
  expect_null(eta$original_statistic)
  expect_equal(eta[c("original_partial_eta", "original_df_error")], list(original_partial_eta = 0.115, original_df_error = 118))
})

test_that("what an ANOVA original still needs is said in words", {
  expect_length(replication_missing(shnabel), 0)
  missing <- replication_missing(list(rep_design = "anova", rep_anova_kind = "mixed", rep_f_from = "eta"))
  expect_true(all(c("its partial eta-squared", "its F test's error degrees of freedom", "the levels of its first factor",
    "the levels of its second (within-subjects) factor", "the number of people the original study analysed") %in% missing))
  expect_identical(replication_missing(modifyList(shnabel, list(rep_anova_f = ""))), "its F statistic")
})

test_that("a 1-df ANOVA original keeps BUCSS's numbers, beside its goals", {
  plan <- run_anova(shnabel)
  expect_false(isTRUE(plan$anova))
  expect_equal(plan$bias_corrected$sizes$n, c(86, 152))
  expect_match(as.character(replication_result_ui(plan)), "152 participants (76 in each group) at 80% assurance", fixed = TRUE)
})

test_that("an ANOVA original's plan gives BUCSS's sample size at the chosen assurance, and every assurance", {
  plan <- run_anova()
  expect_true(plan$anova)
  expect_equal(plan$sizes$n, direct$n)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, sprintf("the replication needs %s participants (%s in each group)", direct_n(0.8), direct_n(0.8) / 2), fixed = TRUE)
  expect_match(html, "rep-bucss-table", fixed = TRUE)
  expect_match(html, "Validation in progress", fixed = TRUE)
  expect_match(html, "two-factor split-plot (mixed) ANOVA", fixed = TRUE)
  expect_no_match(html, "rep-table", fixed = TRUE)
  at_half <- run_anova(modifyList(several, list(rep_assurance = "0.5")))
  expect_match(as.character(replication_result_ui(at_half)), sprintf("the replication needs %s participants (%s in each group)",
    direct_n(0.5), direct_n(0.5) / 2), fixed = TRUE)
  # From a partial eta-squared, the same F and the same plan: F(2, 236).
  eta <- run_anova(modifyList(several, list(rep_f_from = "eta", rep_eta = format(2 * 15.38 / (2 * 15.38 + 236), digits = 15), rep_df_error = "236")))
  expect_equal(eta$sizes$n, plan$sizes$n)
  expect_match(as.character(replication_result_ui(eta)), "partial eta-squared", fixed = TRUE)
})

test_that("an original too weak to plan from is said in words", {
  weak <- run_anova(modifyList(several, list(rep_anova_f = "4.2")))
  html <- as.character(replication_result_ui(weak))
  if (all(!is.na(weak$sizes$reason))) expect_match(html, "too weak to plan a replication from", fixed = TRUE)
  ns <- run_anova(modifyList(several, list(rep_anova_f = "1.5")))
  expect_match(as.character(replication_result_ui(ns)), "wasn't significant at its level", fixed = TRUE)
})

test_that("an ANOVA original's write-up, references and script come from BUCSS", {
  plan <- run_anova()
  report <- paste(replication_report(several, plan), collapse = "\n")
  expect_match(report, "- Who was in each condition: groups of different people", fixed = TRUE)
  expect_match(report, "- Levels: 2 x 3", fixed = TRUE)
  expect_match(report, "- Reported effect: F = 15.38", fixed = TRUE)
  expect_match(report, "correcting the original's effect for publication bias and uncertainty with BUCSS", fixed = TRUE)
  expect_match(report, sprintf("This gives %s participants (%s in each group).", direct_n(0.8), direct_n(0.8) / 2), fixed = TRUE)
  expect_match(report, sprintf("| 80%% (chosen) | %s participants (%s in each group) |", direct_n(0.8), direct_n(0.8) / 2), fixed = TRUE)
  expect_match(report, "Sample-Size Planning for More Accurate Statistical Power", fixed = TRUE)
  expect_match(report, "The Devil Is in the Design", fixed = TRUE)
  expect_no_match(report, "Pawel", fixed = TRUE)
  expect_identical(replication_ref_keys_used(plan), c("Anderson2017_bucss", "AndersonKelley2024_replication_design"))
  script <- replication_script_text(plan, engine_function("replication_planning_script"))
  expect_match(script, "ss_buc_mixed_anova(F_observed = 15.38", fixed = TRUE)
  # A plan's write-up from its record alone uses the same engine function.
  rec <- plan_set_replication(new_replication_plan(), fields = several)
  reopened_report <- paste(replication_plan_report(rec, tree, forms), collapse = "\n")
  expect_match(reopened_report, "We used BUCSS", fixed = TRUE)
  expect_match(reopened_report, "Publication regardless of result", fixed = TRUE)
})

test_that("a t-test original's plan shows BUCSS's corrected sample sizes beside its goals", {
  values <- list(rep_design = "two_groups", rep_effect = "0.9", rep_n1 = "30", rep_n2 = "30", rep_original_alpha = "0.05",
    rep_tau = "0.05", rep_alpha = "0.05", rep_power = "0.8", rep_goal = "significance", rep_prior = "uncertain")
  plan <- replication_run(values, engine_function("replication_planning"), engine_function("replication_bucss"))
  expect_false(is.null(plan$bias_corrected))
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "Allowing for publication bias (BUCSS)", fixed = TRUE)
  b <- plan$bias_corrected$sizes
  expect_match(html, sprintf("%s participants (%s in each group) at 50%% assurance", b$n[b$assurance == 0.5], b$n[b$assurance == 0.5] / 2), fixed = TRUE)
  report <- paste(replication_report(values, plan), collapse = "\n")
  expect_match(report, "For comparison, correcting the original's effect for publication bias and uncertainty with BUCSS", fixed = TRUE)
  expect_true("Anderson2017_bucss" %in% replication_ref_keys_used(plan))
  # A weak original: BUCSS can't plan from it, and says why.
  weak <- replication_run(modifyList(values, list(rep_effect = "0.55")), engine_function("replication_planning"),
    engine_function("replication_bucss"))
  if (all(!is.na(weak$bias_corrected$sizes$reason))) {
    expect_match(as.character(replication_result_ui(weak)), "too weak to plan a replication from", fixed = TRUE)
  }
})

test_that("the server plans an ANOVA original from its fields", {
  testServer(function(input, output, session) replication_server(input, output, session), {
    do.call(session$setInputs, c(several, list(rep_run = 1)))
    expect_match(as.character(output$rep_result$html), "rep-bucss-table", fixed = TRUE)
    session$setInputs(rep_levels_a = "", rep_run = 2)
    expect_match(as.character(output$rep_result$html), "the levels of its first factor", fixed = TRUE)
  })
})

test_that("a conceptual replication of an ANOVA original changes no setting, and says why", {
  # BUCSS's assurance allows for the original's sampling error and
  # publication bias, not a changed procedure: the researcher chooses it.
  for (a in c("0.5", "0.8", "0.9", "0.95")) {
    expect_identical(replication_conceptual_settings(list(rep_design = "anova", rep_assurance = a)), list())
  }
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, htmltools::htmlEscape(paste("input.rep_keeps == 'conceptual' &&", replication_bucss_only_js), attribute = TRUE), fixed = TRUE)
  expect_match(html, "powerkit changes no setting for you", fixed = TRUE)
  expect_match(html, "plan from the smallest effect that would matter to you, under Goals", fixed = TRUE)
  # The button that sets the shrunk belief and more variation is for the
  # one-number designs only.
  expect_match(html, htmltools::htmlEscape(paste("input.rep_keeps == 'conceptual' &&", replication_one_number_js), attribute = TRUE), fixed = TRUE)
  expect_identical(replication_conceptual_settings(list(rep_design = "two_groups"))$rep_prior, "shrunk")
})

test_that("an ANOVA card opens the plan on the ANOVA design, and says so", {
  fields <- replication_fields_for_card(list(), forms, "E8")
  expect_identical(fields[c("rep_design", "rep_anova_kind")], list(rep_design = "anova", rep_anova_kind = "mixed"))
  expect_identical(replication_fields_for_card(list(), forms, "E54")$rep_anova_kind, "within")
  expect_identical(replication_fields_for_card(list(), forms, "E18")$rep_anova_kind, "between")
  # An F already entered is kept, not overwritten.
  kept <- replication_fields_for_card(list(rep_design = "generic", rep_anova_f = "5"), forms, "E8")
  expect_identical(kept$rep_design, "generic")
  expect_match(replication_card_effect_note(forms, "E18"), "An ANOVA effect", fixed = TRUE)
  expect_no_match(replication_card_effect_note(forms, "E27"), "An ANOVA effect", fixed = TRUE)
  for (ep in names(Filter(function(e) !is.null(e$anova), forms$replication_effects))) {
    expect_true(forms$replication_effects[[ep]]$anova %in% replication_anova_kinds_ui, label = ep)
  }
  expect_true(all(c("rep_anova_kind", "rep_anova_f", "rep_eta", "rep_df_error", "rep_assurance") %in% replication_field_ids))
})

test_that("unknown publication compares both assumptions throughout the replication plan", {
  values <- list(rep_design = "two_groups", rep_analysis = "test", rep_goal = "significance",
    rep_effect = "0.6", rep_n1 = "40", rep_n2 = "40", rep_alpha = "0.05", rep_power = "0.8", rep_published = "unknown")
  engine <- engine_function("replication_planning")
  bucss <- engine_function("replication_bucss")
  plan <- replication_run(values, engine, bucss)
  expect_equal(plan$bias_corrected$sizes$n[2], 6336)
  expect_equal(plan$without_publication_filter$sizes$n[2], 194)
  html <- as.character(replication_result_ui(plan))
  report <- paste(replication_report(values, plan), collapse = "\n")
  for (output in c(html, report)) {
    expect_match(output, "Significance required", fixed = TRUE)
    expect_match(output, "Publication regardless of result", fixed = TRUE)
    expect_match(output, "6,336 participants", fixed = TRUE)
    expect_match(output, "194 participants", fixed = TRUE)
  }
  script <- replication_script_text(plan, engine_function("replication_planning_script"))
  expect_match(script, "alpha_prior = 0.05", fixed = TRUE)
  expect_match(script, "alpha_prior = 1", fixed = TRUE)
  expect_no_error(parse(text = script))
  weak <- replication_run(modifyList(values, list(rep_effect = "0.43")), engine, bucss)
  expect_true(all(is.na(weak$bias_corrected$sizes$n)))
  expect_true(any(is.finite(weak$without_publication_filter$sizes$n)))
  expect_match(as.character(replication_result_ui(weak)), "Original did not meet the significance requirement", fixed = TRUE)
})

test_that("an omnibus ANOVA from partial eta-squared compares publication assumptions", {
  values <- list(rep_design = "anova", rep_anova_kind = "between", rep_levels_a = "3", rep_n = "90",
    rep_f_from = "eta", rep_eta = "0.15", rep_df_error = "87", rep_anova_smallest = "0.08", rep_assurance = "0.9",
    rep_alpha = "0.05", rep_power = "0.8", rep_published = "unknown")
  bucss <- engine_function("replication_bucss")
  plan <- replication_run(values, NULL, bucss, engine_function("replication_anova_smallest"))
  expect_true(replication_bucss_filtered(plan))
  expect_false(replication_bucss_filtered(plan$without_publication_filter))
  expect_gt(plan$smallest$n, 0)
  expect_match(as.character(replication_result_ui(plan)), "90% (chosen)", fixed = TRUE)
  report <- paste(replication_report(values, plan), collapse = "\n")
  expect_match(report, "Publication regardless of result", fixed = TRUE)
  expect_match(report, "the same F test with 80% power needs", fixed = TRUE)
})

test_that("the assurance choices run from 50% upward with BUCSS's 80% selected", {
  expect_identical(unname(replication_assurances_ui), c("0.5", "0.8", "0.9", "0.95"))
  expect_identical(replication_field_defaults$rep_assurance, "0.8")
  expect_match(as.character(replication_planner_sections()), "value=\"0.8\" checked=\"checked\"", fixed = TRUE)
})
