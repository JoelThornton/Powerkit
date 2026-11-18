# Replication sample sizes corrected for publication bias and uncertainty
# (BUCSS): powerkit chooses BUCSS's function for the design and passes the
# original's statistic; every number is BUCSS's own.

skip_if_not_installed("BUCSS")

test_that("a mixed-design interaction gives BUCSS's own sample sizes (Shnabel et al., 2009, Study 1)", {
  res <- replication_bucss("anova_mixed", 15.38, 120, levels_a = 2, levels_b = 2, effect = "interaction", power = 0.9)
  direct <- vapply(c(0.5, 0.8), function(a) {
    out <- BUCSS::ss_buc_mixed_anova(F_observed = 15.38, N = 120, levels_between = 2, levels_within = 2,
      effect = "interaction", assurance = a, desired_power = 0.9)
    out$value[out$term == "total_N"]
  }, numeric(1))
  expect_equal(res$sizes$n, direct)
  # The figures recorded when the method was chosen (decisions.md, 17 November 2026).
  expect_equal(res$sizes$n, c(86, 152))
  expect_equal(res$sizes$per_unit, c(43, 76))
  expect_equal(res$df_effect, 1)
  expect_true(all(is.na(res$sizes$reason)))
  expect_identical(res$packages[[1]]$name, "BUCSS")
})

test_that("a partial eta-squared with its error df gives the same plan as its F", {
  eta <- 15.38 / (15.38 + 118)
  from_f <- replication_bucss("anova_mixed", 15.38, 120, levels_a = 2, levels_b = 2, effect = "interaction")
  from_eta <- replication_bucss("anova_mixed", original_partial_eta = eta, original_df_error = 118, original_n = 120,
    levels_a = 2, levels_b = 2, effect = "interaction")
  expect_equal(from_eta$f, 15.38)
  expect_equal(from_eta$sizes$n, from_f$sizes$n)
  # Several numerator degrees of freedom: F = eta / (1 - eta) * df2 / df1.
  three <- replication_bucss("anova_between", original_partial_eta = 0.1, original_df_error = 57, original_n = 60, levels_a = 3)
  expect_equal(three$df_effect, 2)
  expect_equal(three$f, 0.1 / 0.9 * 57 / 2)
})

test_that("each design calls its own BUCSS function", {
  expect_match(replication_bucss("anova_between", 5, 60, levels_a = 3)$function_used, "ss_buc_one_way_anova")
  expect_match(replication_bucss("anova_between", 8, 80, levels_a = 2, levels_b = 2, effect = "factor_b")$function_used,
    "ss_buc_factorial_anova.*effect = \"factor_B\"")
  within <- replication_bucss("anova_within", 6, 30, levels_a = 3, epsilon = 0.8)
  expect_match(within$function_used, "ss_buc_rm_anova.*epsilon = 0.8")
  expect_true(all(is.na(within$sizes$per_unit)))
  expect_match(replication_bucss("paired", 4, 30)$function_used, "ss_buc_paired_t")
  expect_match(replication_bucss("one_sample", 4, 30)$function_used, "ss_buc_one_sample_t")
  expect_match(replication_bucss("correlation", 0.45, 60)$function_used, "ss_buc_correlation")
  two <- replication_bucss("two_groups", -3, 40)
  expect_match(two$function_used, "ss_buc_independent_t\\(t_observed = 3,")
  direct <- BUCSS::ss_buc_independent_t(t_observed = 3, N = 40, assurance = 0.8)
  expect_equal(two$sizes$n[two$sizes$assurance == 0.8], direct$value[direct$term == "total_N"])
})

test_that("a one-sided replication is BUCSS's two-sided test at twice alpha", {
  one <- replication_bucss("two_groups", 3, 40, alpha = 0.025, alternative = "one.sided")
  two <- replication_bucss("two_groups", 3, 40, alpha = 0.05)
  expect_equal(one$sizes$n, two$sizes$n)
  expect_match(one$function_used, "alpha_planned = 0.05")
})

test_that("an original too weak to plan from is reported, not an error", {
  res <- replication_bucss("two_groups", 2.21, 40)
  expect_true(all(res$sizes$reason == "not_plannable"))
  expect_true(all(is.na(res$sizes$n)))
  expect_true(all(replication_bucss("two_groups", 1.5, 40)$sizes$reason == "not_significant"))
  expect_match(res$script, "tryCatch(", fixed = TRUE)
})

test_that("the script repeats BUCSS's calculation", {
  res <- replication_bucss("anova_mixed", 15.38, 120, levels_a = 2, levels_b = 2, effect = "interaction", power = 0.9)
  expect_match(res$script, "library(BUCSS)", fixed = TRUE)
  call <- sub("^BUCSS::", "BUCSS::", res$function_used)
  out <- eval(parse(text = call), list(a = 0.8))
  expect_equal(out$value[out$term == "total_N"], 152)
  eta <- replication_bucss("anova_mixed", original_partial_eta = 0.1, original_df_error = 118, original_n = 120,
    levels_a = 2, levels_b = 2, effect = "interaction")
  expect_match(eta$script, "partial eta-squared (0.1) with F(1, 118)", fixed = TRUE)
})

test_that("plain refusals", {
  expect_error(replication_bucss("anova_mixed", 5, 60, levels_a = 2, levels_b = 2, effect = "interaction",
    alternative = "one.sided"), "no direction", class = "powerkit_error")
  expect_error(replication_bucss("anova_mixed", 5, 60, levels_a = 2), "between-subjects and its within", class = "powerkit_error")
  expect_error(replication_bucss("anova_between", 5, 60, levels_a = 1), "at least 2", class = "powerkit_error")
  expect_error(replication_bucss("anova_between", 5, 60, levels_a = 2, levels_b = 2, effect = "between"),
    "factor_a", class = "powerkit_error")
  expect_error(replication_bucss("anova_between", original_partial_eta = 0.1, original_n = 60, levels_a = 3),
    "error degrees of freedom", class = "powerkit_error")
  expect_error(replication_bucss("anova_between", 5, original_partial_eta = 0.1, original_df_error = 57,
    original_n = 60, levels_a = 3), "not both", class = "powerkit_error")
  expect_error(replication_bucss("anova_between", 5, 4, levels_a = 2, levels_b = 2, effect = "interaction"),
    "more than its 4 groups", class = "powerkit_error")
  expect_error(replication_bucss("anova_within", 5, 30, levels_a = 3, epsilon = 1.2), "epsilon", class = "powerkit_error")
  expect_error(replication_bucss("correlation", 1.2, 30), "between -1 and 1", class = "powerkit_error")
  expect_error(replication_bucss("two_groups", 3, 40, assurance = 0.3), "0.5", class = "powerkit_error")
})

test_that("a t-test or correlation original's plan carries BUCSS's sample sizes beside its goals", {
  skip_if_not_installed("BayesRepDesign")
  plan <- replication_planning("two_groups", 0.9, original_n1 = 30, original_n2 = 30, power = 0.8)
  t <- 0.9 / sqrt(1 / 30 + 1 / 30)
  direct <- replication_bucss("two_groups", t, 60)
  expect_equal(plan$bias_corrected$sizes, direct$sizes)
  expect_true("BUCSS" %in% vapply(plan$packages, `[[`, "", "name"))
  expect_match(replication_planning_script(plan), "ss_buc_independent_t", fixed = TRUE)
  r <- replication_planning("correlation", 0.45, original_n = 60)
  expect_equal(r$bias_corrected$sizes, replication_bucss("correlation", 0.45, 60)$sizes)
  # Not for an original analysed with Bayes factors, or another design.
  generic <- replication_planning("generic", 0.5, original_n = 100, original_se = 0.1)
  expect_null(generic$bias_corrected)
})
