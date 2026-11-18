# ANOVA originals in a replication plan (18 November 2026): an effect with
# one degree of freedom goes through every goal as its two-mean
# comparison, F(1, df) = t^2; one with several is planned from the
# smallest effect that would matter, through the matching card's F test.

test_that("a 1-df ANOVA effect is planned as its two-group or paired comparison, t = sqrt(F)", {
  skip_if_not_installed("BayesRepDesign")
  skip_if_not_installed("BUCSS")
  # Shnabel et al. (2009), Study 1: the 2 x 2 mixed interaction, F(1, 118) = 15.38.
  anova <- replication_planning("anova_mixed", original_f = 15.38, original_n = 120, levels_a = 2, levels_b = 2,
    effect = "interaction", tau = 0.1, smallest_effect = 0.2)
  t_test <- replication_planning("two_groups", sqrt(15.38), original_n1 = 60, original_n2 = 60,
    original_effect_type = "t", tau = 0.1, smallest_effect = 0.2)
  expect_identical(anova$anova_effect$design, "two_groups")
  expect_equal(anova$anova_effect$t, sqrt(15.38))
  expect_equal(anova$goals, t_test$goals)
  expect_identical(anova$inputs$anova$effect, "interaction")
  # BUCSS's number is the ANOVA's own function; for this design it agrees
  # with the two-group t, whose error df are the same (N - 2).
  expect_match(anova$bias_corrected$function_used, "ss_buc_mixed_anova", fixed = TRUE)
  expect_equal(anova$bias_corrected$sizes$n, t_test$bias_corrected$sizes$n)
  script <- replication_planning_script(anova)
  expect_match(script, "F(1, 118) = 15.38 is the square of a two-group t", fixed = TRUE)
  expect_match(script, "ss_buc_mixed_anova", fixed = TRUE)
})

test_that("each 1-df effect maps to the comparison it is", {
  map <- function(...) replication_anova_one_df(original_f = 9, ...)
  expect_identical(map("anova_between", 80, 2)$design, "two_groups")
  expect_identical(map("anova_between", 80, 2, 2, "interaction")$design, "two_groups")
  expect_identical(map("anova_between", 90, 2, 3, "factor_a")$df_error, 84)
  expect_identical(map("anova_within", 30, 2)$design, "paired")
  expect_identical(map("anova_within", 30, 2, 2, "interaction")$n, 30)
  expect_identical(map("anova_mixed", 60, 2, 4, "between")$design, "two_groups")
  within <- map("anova_mixed", 60, 3, 2, "within")
  expect_identical(within$design, "paired")
  expect_identical(c(within$df_error, within$df_t), c(57, 59))
  # A partial eta-squared with its error df gives the same F (Lakens, 2013).
  eta <- replication_anova_one_df("anova_between", 80, 2, original_partial_eta = 9 / (9 + 78), original_df_error = 78)
  expect_equal(eta$f, 9)
  expect_error(map("anova_between", 60, 3), "2 degrees of freedom", class = "powerkit_error")
  expect_error(map("anova_mixed", 60, 2, 3, "interaction"), "2 degrees of freedom", class = "powerkit_error")
})

test_that("a one-sided replication of a 1-df effect is planned as for a t-test", {
  skip_if_not_installed("BayesRepDesign")
  skip_if_not_installed("BUCSS")
  one <- replication_planning("anova_within", original_f = 6.25, original_n = 40, levels_a = 2, alternative = "one.sided")
  paired <- replication_planning("paired", 2.5, original_n = 40, original_effect_type = "t", alternative = "one.sided")
  expect_equal(one$goals, paired$goals)
  expect_equal(one$bias_corrected$sizes$n, replication_bucss("anova_within", 6.25, 40, levels_a = 2,
    alpha = 0.1, assurance = c(0.5, 0.8))$sizes$n)
})

test_that("an effect with several df is planned from the smallest effect, by the card's own F test", {
  skip_if_not_installed("pwrss")
  one_way <- replication_anova_smallest("anova_between", levels_a = 3, smallest_effect = 0.06)
  direct <- pwrss::power.f.ancova(eta.squared = 0.06, factor.levels = 3, n.total = one_way$n, alpha = 0.05,
    ceil.n = FALSE, verbose = 0)$power
  expect_gte(direct, 0.8)
  expect_lt(pwrss::power.f.ancova(eta.squared = 0.06, factor.levels = 3, n.total = one_way$n - 3, alpha = 0.05,
    ceil.n = FALSE, verbose = 0)$power, 0.8)
  expect_equal(one_way$power, direct)
  expect_identical(one_way$per_unit, one_way$n / 3)
  expect_identical(one_way$function_used, "pwrss::power.f.ancova")
  # The plan is the card's: run_spec() on the same spec gives the same n.
  expect_identical(run_spec(one_way$spec)$n_required$n, one_way$n)
  mixed <- replication_anova_smallest("anova_mixed", 2, 3, "interaction", 0.06)
  expect_identical(mixed$function_used, "pwrss::power.f.mixed.anova")
  expect_identical(mixed$spec$population$eta_source, "published")
  expect_error(replication_anova_smallest("anova_within", 2, 3, "interaction", 0.06), "two factors", class = "powerkit_error")
  expect_error(replication_anova_smallest("anova_between", 3, smallest_effect = 1.2), "between 0 and 1", class = "powerkit_error")
})
