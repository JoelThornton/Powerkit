# Precision planning (design "precision"): the sample size for a target
# confidence-interval width, or the width at a given n, from MBESS (Cohen's
# d, d_z, a standardised mean) and presize (a correlation, a proportion).
# Agreement with simulated intervals: test-validation-precision.R.

precision_spec <- function(name, ...) {
  spec <- example_spec(name)
  changes <- list(...)
  for (path in names(changes)) {
    parts <- strsplit(path, ".", fixed = TRUE)[[1]]
    spec[[parts]] <- changes[[path]]
  }
  spec
}

precision_two_group_spec <- function(goal = list(type = "precision", width = 0.4)) {
  precision_spec("precision_two_groups", goal = goal)
}

test_that("a correlation's sample size and width are presize's prec_cor()", {
  r <- run_quietly(precision_spec("precision_correlation"))
  expect_identical(r$goal_type, "precision")
  expect_identical(r$provenance$backend, "presize")
  expect_identical(r$provenance$method, "exact")
  direct <- suppressWarnings(presize::prec_cor(r = 0.3, conf.width = 0.2, conf.level = 0.95, method = "pearson"))
  expect_identical(r$precision$n, as.integer(ceiling(direct$n - 1e-9)))
  expect_identical(r$n_required$n, r$precision$n)
  at_n <- presize::prec_cor(r = 0.3, n = r$precision$n, conf.level = 0.95, method = "pearson")
  expect_equal(r$precision$width, at_n$conf.width)
  expect_lte(r$precision$width, 0.2)
  # One fewer would be too wide.
  expect_gt(presize::prec_cor(r = 0.3, n = r$precision$n - 1, conf.level = 0.95, method = "pearson")$conf.width, 0.2)
  expect_true(all(r$check_run$ok))
  # Spearman's and Kendall's coefficients get presize's own variances.
  sp <- run_quietly(precision_spec("precision_correlation", target_test.method = "spearman"))
  expect_identical(sp$precision$n, as.integer(ceiling(presize::prec_cor(r = 0.3, conf.width = 0.2, method = "spearman")$n - 1e-9)))
})

test_that("a proportion's sample size and width are presize's prec_prop(), for each interval", {
  for (m in c("wilson", "agresti_coull", "exact", "wald")) {
    r <- run_quietly(precision_spec("precision_proportion", target_test.method = m))
    method <- if (m == "agresti_coull") "agresti-coull" else m
    direct <- presize::prec_prop(p = 0.3, conf.width = 0.1, conf.level = 0.95, method = method)
    expect_identical(r$precision$n, as.integer(ceiling(direct$n - 1e-9)), label = m)
    expect_lte(r$precision$width, 0.1 + 1e-9)
  }
  at <- run_quietly(precision_spec("precision_proportion", goal = list(type = "precision", n = 200L)))
  expect_equal(at$precision$width, presize::prec_prop(p = 0.3, n = 200, method = "wilson")$conf.width)
  expect_true(is.na(at$n_required))
  expect_true(is.na(at$precision$target_width))
  # A 90% interval needs fewer people than a 95% one.
  ninety <- run_quietly(precision_spec("precision_proportion", target_test.alpha = 0.1))
  expect_lt(ninety$precision$n, run_quietly(precision_spec("precision_proportion"))$precision$n)
})

test_that("Cohen's d between two groups is MBESS's ss.aipe.smd(), and the width its ci.smd() at d", {
  skip_if_not_installed("MBESS")
  r <- run_quietly(precision_two_group_spec())
  expect_identical(r$provenance$backend, "MBESS")
  per_group <- MBESS::ss.aipe.smd(delta = 0.5, conf.level = 0.95, width = 0.4)
  expect_identical(r$precision$n, as.integer(2 * per_group))
  lims <- MBESS::ci.smd(smd = 0.5, n.1 = per_group, n.2 = per_group, conf.level = 0.95)
  expect_equal(r$precision$width, lims$Upper.Conf.Limit.smd - lims$Lower.Conf.Limit.smd)
  expect_lte(r$precision$width, 0.4)
  # MBESS changes the warning level; powerkit puts it back.
  old <- getOption("warn")
  run_quietly(precision_two_group_spec())
  expect_identical(getOption("warn"), old)
})

test_that("assurance raises the sample size, as MBESS computes it", {
  skip_if_not_installed("MBESS")
  plain <- run_quietly(precision_two_group_spec())
  sure <- run_quietly(precision_two_group_spec(list(type = "precision", width = 0.4, assurance = 0.8)))
  expect_gt(sure$precision$n, plain$precision$n)
  expect_identical(sure$precision$n, as.integer(2 * MBESS::ss.aipe.smd(delta = 0.5, conf.level = 0.95, width = 0.4, assurance = 0.8)))
  expect_equal(sure$precision$assurance, 0.8)
})

test_that("a standardised mean and d_z are MBESS's ss.aipe.sm()", {
  skip_if_not_installed("MBESS")
  one <- example_spec("precision_two_groups")
  one$template <- "one_group"
  one$variables <- list(Y = list(type = "continuous", label = "Anxiety"))
  r <- run_quietly(one)
  expect_identical(r$precision$n, as.integer(MBESS::ss.aipe.sm(sm = 0.5, width = 0.4, conf.level = 0.95)))
  paired <- one
  paired$template <- "paired"
  paired$variables <- list(X = list(type = "within_factor", label = "Time", levels = list("Before", "After")), Y = list(type = "continuous", label = "Anxiety"))
  paired$population <- list(metric = "standardised", dz = 0.5)
  expect_identical(run_quietly(paired)$precision$n, r$precision$n)
  lims <- MBESS::ci.sm(sm = 0.5, N = r$precision$n, conf.level = 0.95)
  expect_equal(r$precision$width, lims$Upper.Conf.Limit.Standardized.Mean - lims$Lower.Conf.Limit.Standardized.Mean)
})

test_that("the exported script reproduces the sample size and width with the package alone", {
  skip_unless_scripts_can_run()
  for (name in c("precision_correlation", "precision_proportion")) {
    spec <- example_spec(name)
    result <- run_quietly(spec)
    run <- run_exported_script(spec, result)
    expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
    expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
  }
  skip_if_not_installed("MBESS")
  spec <- precision_two_group_spec(list(type = "precision", width = 0.4, assurance = 0.8))
  result <- run_quietly(spec)
  run <- run_exported_script(spec, result)
  expect_true(any(grepl("ss.aipe.smd(", run$script, fixed = TRUE)))
  expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
})

test_that("precision goals and designs are refused in plain words where they don't fit", {
  both <- precision_spec("precision_proportion", goal = list(type = "precision", width = 0.1, n = 100L))
  expect_error(validate_spec(both), "either 'goal > width'", class = "powerkit_error")
  neither <- precision_spec("precision_proportion", goal = list(type = "precision"))
  expect_error(validate_spec(neither), "either 'goal > width'", class = "powerkit_error")
  sure <- precision_spec("precision_correlation", goal = list(type = "precision", width = 0.2, assurance = 0.8))
  expect_error(validate_spec(sure), "assurance", class = "powerkit_error")
  wide <- precision_spec("precision_proportion", goal = list(type = "precision", width = 1.2))
  expect_error(validate_spec(wide), "below 1", class = "powerkit_error")
  odd <- precision_two_group_spec(list(type = "precision", n = 51L))
  expect_error(validate_spec(odd), "should be even", class = "powerkit_error")
  wald <- precision_spec("precision_proportion", target_test.method = "wald", goal = list(type = "precision", n = 10L))
  expect_error(validate_spec(wald), "Wald interval needs", class = "powerkit_error")
  t_test <- example_spec("independent_t")
  t_test$goal <- list(type = "precision", width = 0.3)
  expect_error(validate_spec(t_test), "only for the precision design", class = "powerkit_error")
  power <- example_spec("precision_proportion")
  power$goal <- list(type = "power", n = 100L)
  expect_error(validate_spec(power), class = "powerkit_error")
})

# More estimates (1 November 2026): a raw mean difference, an odds ratio,
# an ICC (presize) and a standardised regression coefficient (MBESS).
test_that("a raw mean difference and an odds ratio are presize's, for two equal groups", {
  md <- run_quietly(precision_spec("precision_mean_difference"))
  direct <- suppressWarnings(presize::prec_meandiff(delta = 5, sd1 = 12, conf.width = 6, variance = "equal"))
  expect_identical(md$precision$n, 2L * as.integer(ceiling(direct$n1)))
  expect_lte(md$precision$width, 6)
  or <- run_quietly(precision_spec("precision_odds_ratio"))
  # The second group's odds over the first's.
  expect_equal(or$precision$effect, (0.45 / 0.55) / (0.3 / 0.7))
  expect_true(or$precision$lower < or$precision$effect && or$precision$effect < or$precision$upper)
  direct <- suppressWarnings(presize::prec_or(p1 = 0.45, p2 = 0.3, conf.width = 1, method = "indip_smooth"))
  expect_identical(or$precision$n, 2L * as.integer(ceiling(direct$n1)))
})

test_that("an ICC is presize's prec_icc(), which gives the width but not the limits", {
  icc <- run_quietly(precision_spec("precision_icc"))
  direct <- suppressWarnings(presize::prec_icc(rho = 0.7, k = 3, conf.width = 0.2))
  expect_identical(icc$precision$n, as.integer(ceiling(direct$n)))
  expect_true(is.na(icc$precision$lower))
  expect_lte(icc$precision$width, 0.2)
})

test_that("a regression coefficient is MBESS's ss.aipe.reg.coef(), and the width at n inverts it", {
  skip_if_not_installed("gsl")
  reg <- run_quietly(precision_spec("precision_regression_coefficient"))
  direct <- suppressWarnings(MBESS::ss.aipe.reg.coef(Rho2.Y_X = 0.3, Rho2.j_X.without.j = 0.2, p = 4, b.j = 0.25, width = 0.2,
    sigma.Y = 1, sigma.X = 1, Suppress.Statement = TRUE))
  expect_identical(reg$precision$n, as.integer(unlist(direct)[1]))
  at_n <- run_quietly(precision_spec("precision_regression_coefficient", goal = list(type = "precision", n = reg$precision$n)))
  expect_lte(at_n$precision$width, 0.2 + 1e-6)
  expect_gt(at_n$precision$width, 0.18)
  sure <- run_quietly(precision_spec("precision_regression_coefficient", goal = list(type = "precision", width = 0.2, assurance = 0.9)))
  expect_gt(sure$precision$n, reg$precision$n)
})

test_that("the exported scripts reproduce the new estimates with the package alone", {
  for (name in c("precision_mean_difference", "precision_odds_ratio", "precision_icc", "precision_regression_coefficient")) {
    if (name == "precision_regression_coefficient" && !requireNamespace("gsl", quietly = TRUE)) next
    for (goal in list(NULL, list(type = "precision", n = 120L))) {
      spec <- if (is.null(goal)) precision_spec(name) else precision_spec(name, goal = goal)
      result <- run_quietly(spec)
      run <- run_exported_script(spec, result)
      expect_equal(run$reproduced, run$powerkit, tolerance = 1e-6, label = name)
    }
  }
})
