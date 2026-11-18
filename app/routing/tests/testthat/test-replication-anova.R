# ANOVA originals' full goals (18 November 2026): an effect with one
# degree of freedom goes through every goal as its two-mean comparison,
# with BUCSS beside them; one with several gets BUCSS and a plan from the
# smallest effect that would matter; the design list says where ANCOVA and
# MANOVA originals go.

anova_values <- list(rep_design = "anova", rep_anova_kind = "mixed", rep_levels_a = "2", rep_levels_b = "2",
  rep_anova_effect = "interaction", rep_n = "120", rep_f_from = "f", rep_anova_f = "15.38", rep_original_alpha = "0.05",
  rep_alpha = "0.05", rep_power = "0.8", rep_tau = "0.05", rep_prior = "uncertain")
run_anova <- function(v) replication_run(v, engine_function("replication_planning"), engine_function("replication_bucss"),
  engine_function("replication_anova_smallest"))
text_of <- function(x) gsub("[ \n]+", " ", gsub("<[^>]+>", " ", as.character(x)))

test_that("an effect with one degree of freedom is told apart from one with several", {
  expect_true(replication_anova_one_df(anova_values))
  expect_true(replication_anova_one_df(modifyList(anova_values, list(rep_anova_kind = "between", rep_levels_b = "",
    rep_anova_effect = "interaction"))))  # one factor: its main effect, two levels
  expect_false(replication_anova_one_df(modifyList(anova_values, list(rep_levels_b = "3"))))
  expect_true(replication_anova_one_df(modifyList(anova_values, list(rep_levels_b = "3", rep_anova_effect = "factor_a"))))
  expect_false(replication_anova_one_df(modifyList(anova_values, list(rep_levels_a = "3", rep_levels_b = ""))))
  expect_false(replication_anova_one_df(list(rep_design = "two_groups")))
  expect_identical(replication_engine_name(anova_values), "replication_planning")
  expect_identical(replication_engine_name(modifyList(anova_values, list(rep_levels_b = "3"))), "replication_bucss")
  args <- replication_args(anova_values)
  expect_identical(args[c("design", "levels_a", "levels_b", "effect", "original_f")],
    list(design = "anova_mixed", levels_a = 2, levels_b = 2, effect = "interaction", original_f = 15.38))
  expect_null(args$original_effect)
  eta <- replication_args(modifyList(anova_values, list(rep_f_from = "eta", rep_eta = "0.115", rep_df_error = "118")))
  expect_identical(eta[c("original_partial_eta", "original_df_error")], list(original_partial_eta = 0.115, original_df_error = 118))
  # A conceptual replication of a 1-df effect gets the one-number settings.
  expect_identical(replication_conceptual_settings(anova_values)$rep_prior, "shrunk")
})

test_that("the Goals step shows every goal for a 1-df effect, and BUCSS with the smallest effect otherwise", {
  html <- as.character(replication_workspace_ui(tree))
  esc <- function(x) htmltools::htmlEscape(x, attribute = TRUE)
  expect_match(html, esc(replication_one_number_js), fixed = TRUE)
  expect_match(html, esc(replication_bucss_only_js), fixed = TRUE)
  expect_match(html, "id=\"rep_anova_smallest\"", fixed = TRUE)
  expect_match(html, "its F is the square of that comparison", fixed = TRUE)
  expect_true("rep_anova_smallest" %in% replication_field_ids)
  expect_true("rep_anova_smallest" %in% replication_calc_fields)
  # The design list says where ANCOVA and MANOVA originals go.
  expect_match(html, "An ANCOVA: its adjusted difference between two groups is one number", fixed = TRUE)
  expect_match(html, "A MANOVA: no published method plans a replication from a MANOVA", fixed = TRUE)
})

test_that("a 1-df ANOVA original's result has every goal, says which comparison it is, and keeps BUCSS beside it", {
  skip_if_not_installed("BayesRepDesign")
  skip_if_not_installed("BUCSS")
  plan <- run_anova(anova_values)
  expect_false(isTRUE(plan$anova))
  t <- text_of(replication_result_ui(plan))
  expect_match(t, "planned as a comparison of two means: F(1, 118) = 15.38 is the square of its t, 3.922", fixed = TRUE)
  expect_match(t, "the difference between the two groups in each person's change", fixed = TRUE)
  expect_match(t, "Every goal under every belief", fixed = TRUE)
  expect_match(t, "114 participants (57 in each group) at 80% assurance", fixed = TRUE)
  report <- paste(replication_report(anova_values, plan), collapse = "\n")
  expect_match(report, "from its F(1, 118) = 15.38, the square of the t (3.922)", fixed = TRUE)
  # A within-subjects comparison counts people, not pairs.
  within <- run_anova(modifyList(anova_values, list(rep_anova_kind = "within", rep_levels_b = "", rep_anova_effect = "factor_a",
    rep_n = "40", rep_anova_f = "8")))
  expect_identical(replication_n_words(within, 30), "30 participants")
})

test_that("an effect with several df shows BUCSS and, when given, the smallest effect's plan by the card's F test", {
  skip_if_not_installed("BUCSS")
  skip_if_not_installed("pwrss")
  several <- modifyList(anova_values, list(rep_levels_b = "3", rep_assurance = "0.8"))
  plain <- run_anova(several)
  expect_true(isTRUE(plain$anova))
  expect_match(text_of(replication_result_ui(plain)), "Enter it under Goals, as a partial eta-squared", fixed = TRUE)
  plan <- run_anova(modifyList(several, list(rep_anova_smallest = "0.06")))
  direct <- engine_function("replication_anova_smallest")("anova_mixed", 2, 3, "interaction", 0.06)
  t <- text_of(replication_result_ui(plan))
  expect_match(t, sprintf("a partial eta-squared of 0.06, the smallest that would matter to you, a significant F test for the interaction (alpha = .05) with 80%% power needs %s participants",
    direct$n), fixed = TRUE)
  expect_match(paste(replication_report(several, plan), collapse = "\n"), "From the smallest effect that would matter to us, a partial eta-squared of 0.06", fixed = TRUE)
  expect_match(replication_script_text(plan, NULL), "library(powerkit)\nreplication_anova_smallest(\"anova_mixed\", levels_a = 2, levels_b = 3", fixed = TRUE)
  # A two-factor within design has no card that takes a partial eta-squared: said in plain words.
  within <- run_anova(modifyList(several, list(rep_anova_kind = "within", rep_anova_effect = "interaction", rep_n = "40",
    rep_anova_smallest = "0.06")))
  expect_match(text_of(replication_result_ui(within)), "No ANOVA card plans a within-subjects design with two factors", fixed = TRUE)
})
