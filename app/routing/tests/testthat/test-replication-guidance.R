# Replication plan, correctness and guidance (18 November 2026): results
# that say when they are out of date, choices that fit the design, the
# publication filter BUCSS corrects for, and the other routes to a sample
# size beside BUCSS's numbers.

base <- list(rep_design = "two_groups", rep_analysis = "test", rep_effect = "0.6", rep_n1 = "40", rep_n2 = "40",
  rep_original_alpha = "0.05", rep_alpha = "0.05", rep_power = "0.8", rep_tau = "0.05", rep_goal = "significance",
  rep_prior = "uncertain")
run_plan <- function(v) replication_run(v, engine_function("replication_planning"), engine_function("replication_bucss"))
text_of <- function(x) gsub("[ \n]+", " ", gsub("<[^>]+>", " ", as.character(x)))

test_that("the results know which answers they were calculated from", {
  key <- replication_calc_key(base)
  # Whitespace and the write-up's own fields don't make results stale.
  expect_identical(replication_calc_key(modifyList(base, list(rep_effect = " 0.6 ", rep_study = "Smith (2010)"))), key)
  expect_false(identical(replication_calc_key(modifyList(base, list(rep_effect = "0.5"))), key))
  expect_false(identical(replication_calc_key(modifyList(base, list(rep_published = "any"))), key))
  expect_false("rep_study" %in% replication_calc_fields)
})

test_that("the pairs-only effect type shows for pairs only, and sizes name their unit", {
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "input[name=rep_effect_type][value=d_rm]", fixed = TRUE)
  expect_match(html, "input.rep_design == &#39;paired&#39;", fixed = TRUE)
  plan <- list(inputs = list(design = "two_groups"))
  expect_identical(replication_n_words(plan, 128), "128 participants (64 per group)")
  expect_identical(replication_n_words(list(inputs = list(design = "one_sample")), 50), "50 participants")
  expect_identical(replication_n_words(list(inputs = list(design = "paired")), 50), "50 pairs")
})

test_that("Also report is folded, saying what is ticked to start", {
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "<details class=\"rep-also-fold\">", fixed = TRUE)
  expect_match(html, "ticked to start: a criterion that could show the effect is absent", fixed = TRUE)
})

test_that("d33 is explained once when it is both the bound and the yardstick", {
  skip_if_not_installed("BayesRepDesign")
  plan <- run_plan(modifyList(base, list(rep_goal = "agreement")))
  t <- text_of(replication_result_ui(plan))
  expect_equal(lengths(regmatches(t, gregexpr("one-in-three chance", t, fixed = TRUE))), 1)
  expect_match(t, "Small telescopes' yardstick is the same d33.", fixed = TRUE)
})

test_that("an original published whatever it found is corrected for uncertainty only", {
  expect_true("any" %in% replication_published_ui)
  expect_true("rep_published" %in% replication_field_ids)
  expect_false(replication_args(modifyList(base, list(rep_published = "any")))$publication_filter)
  expect_null(replication_args(base)$publication_filter)
  anova <- list(rep_design = "anova", rep_anova_kind = "between", rep_levels_a = "3", rep_n = "60", rep_f_from = "f",
    rep_anova_f = "6", rep_published = "any")
  expect_false(replication_args(anova)$publication_filter)
  report <- paste(replication_report(modifyList(base, list(rep_published = "any"))), collapse = "\n")
  expect_match(report, "Published whatever it found (no publication filter)", fixed = TRUE)
  skip_if_not_installed("BayesRepDesign")
  skip_if_not_installed("BUCSS")
  filtered <- text_of(replication_result_ui(run_plan(base)))
  open <- text_of(replication_result_ui(run_plan(modifyList(base, list(rep_published = "any")))))
  # d = 0.6 with 40 per group: 6,336 at 80% assurance with the filter, 194 without.
  expect_match(filtered, "6,336 participants (3,168 in each group) at 80% assurance", fixed = TRUE)
  expect_match(open, "194 participants (97 in each group) at 80% assurance", fixed = TRUE)
  expect_match(open, "Allowing for uncertainty (BUCSS)", fixed = TRUE)
})

test_that("large corrected numbers are explained, with the other routes offered as equals", {
  skip_if_not_installed("BayesRepDesign")
  skip_if_not_installed("BUCSS")
  t <- text_of(replication_result_ui(run_plan(base)))
  expect_match(t, "This is a finding about the original", fixed = TRUE)
  expect_match(t, "It is not a sample size you have to reach.", fixed = TRUE)
  for (route in c("The smallest effect that would matter.", "What your resources allow.", "A sequential design.",
    "Several originals, or a meta-analysis.", "No publication filter.")) expect_match(t, route, fixed = TRUE)
  expect_match(t, "(Lakens, 2022)", fixed = TRUE)
  expect_match(t, "Why there are several numbers for one goal", fixed = TRUE)
  # Without the filter the numbers stay close: no explanation needed, and
  # the filter isn't offered again.
  open <- text_of(replication_result_ui(run_plan(modifyList(base, list(rep_published = "any")))))
  expect_no_match(open, "This is a finding about the original", fixed = TRUE)
  expect_no_match(open, "No publication filter.", fixed = TRUE)
  expect_match(open, "The smallest effect that would matter.", fixed = TRUE)
})

test_that("an ANOVA original shows 50% assurance beside the chosen 80%", {
  skip_if_not_installed("BUCSS")
  v <- list(rep_design = "anova", rep_anova_kind = "between", rep_levels_a = "2", rep_levels_b = "3",
    rep_anova_effect = "interaction", rep_n = "120", rep_f_from = "f", rep_anova_f = "15.38", rep_assurance = "0.8")
  plan <- run_plan(v)
  t <- text_of(replication_result_ui(plan))
  half <- plan$sizes$n[plan$sizes$assurance == 0.5]
  expect_match(t, sprintf("At 50%% assurance, planning for the corrected estimate itself rather than allowing for it being too large, it needs %s participants",
    format(half, big.mark = ",")), fixed = TRUE)
  expect_match(t, "Other ways to a sample size", fixed = TRUE)
  # Chosen 50%: not repeated.
  expect_no_match(text_of(replication_result_ui(run_plan(modifyList(v, list(rep_assurance = "0.5"))))), "At 50% assurance, planning", fixed = TRUE)
})
