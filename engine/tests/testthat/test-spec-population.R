# Checks that the population described by a spec is possible, and that the
# variables, paths and goal fit together.

# Implied R-squared ---------------------------------------------------------

test_that("implied R-squared is right for simple mediation", {
  spec <- example_spec("mediation_simple")
  spec$population$paths <- list("X->M" = 0.5, "M->Y" = 0.3, "X->Y" = 0.2)
  r2 <- implied_r_squared(spec, path_model(spec))$r_squared
  expect_equal(r2[["M"]], 0.5^2)
  # Y = b M + c' X with cov(M, X) = a.
  expect_equal(r2[["Y"]], 0.3^2 + 0.2^2 + 2 * 0.3 * 0.2 * 0.5)
})

test_that("implied R-squared includes the product term for PROCESS model 7", {
  spec <- example_spec("process_7")
  spec$population$correlations <- list("X<->W" = 0.3)
  r2 <- implied_r_squared(spec, path_model(spec))$r_squared
  a1 <- 0.20
  a2 <- 0.10
  a3 <- 0.15
  b <- 0.30
  c1 <- 0.05
  r <- 0.3
  # var(XW) = 1 + r^2 and XW is uncorrelated with X and W.
  expect_equal(r2[["M"]], a1^2 + a2^2 + 2 * a1 * a2 * r + a3^2 * (1 + r^2))
  cov_mx <- a1 + a2 * r
  expect_equal(r2[["Y"]], b^2 + c1^2 + 2 * b * c1 * cov_mx)
})

test_that("implied R-squared includes the M x W product for PROCESS model 14", {
  spec <- example_spec("process_14")
  r2 <- implied_r_squared(spec, path_model(spec))$r_squared
  a <- 0.35
  b1 <- -0.25
  b2 <- 0.15
  b3 <- 0.12
  c1 <- -0.05
  r_xw <- -0.1
  cov_mw <- a * r_xw
  expected_y <- c1^2 + b1^2 + b2^2 + b3^2 * (1 + cov_mw^2) +
    2 * (c1 * b1 * a + c1 * b2 * r_xw + b1 * b2 * cov_mw)
  expect_equal(r2[["M"]], a^2)
  expect_equal(r2[["Y"]], expected_y)
})

test_that("residual correlations between parallel mediators feed into Y", {
  spec <- example_spec("mediation_parallel")
  implied <- implied_r_squared(spec, path_model(spec))
  paths <- spec$population$paths
  psi1 <- 1 - paths[["X->M1"]]^2
  psi2 <- 1 - paths[["X->M2"]]^2
  expect_equal(
    implied$cov["M1", "M2"],
    paths[["X->M1"]] * paths[["X->M2"]] + 0.3 * sqrt(psi1 * psi2)
  )
})

# Impossible populations ----------------------------------------------------

test_that("mediation paths explaining over 100% of a variance are rejected", {
  spec <- example_spec("process_7")
  spec$population$paths[["X->M"]] <- 0.9
  spec$population$paths[["W->M"]] <- 0.5
  spec$population$paths[["XW->M"]] <- 0.5
  expect_spec_problem(spec, "The paths into Perceived threat (M) are impossible together")
  expect_spec_problem(spec, "Make one or more of these paths smaller: 'X->M', 'W->M' or 'XW->M'.")
})

test_that("large but possible paths are accepted", {
  spec <- example_spec("mediation_simple")
  spec$population$paths <- list("X->M" = 0.9, "M->Y" = 0.6, "X->Y" = -0.3)
  expect_valid_spec(spec)
})

test_that("serial mediation checks each mediator in turn", {
  spec <- example_spec("mediation_serial")
  spec$population$paths[["X->M1"]] <- 0.9
  spec$population$paths[["X->M2"]] <- 0.7
  spec$population$paths[["M1->M2"]] <- 0.8
  expect_spec_problem(spec, "The paths into Effort (M2) are impossible together")
})

test_that("PROCESS model 14 counts the M x W product term", {
  spec <- example_spec("process_14")
  spec$population$paths[["M->Y"]] <- 0.9
  spec$population$paths[["MW->Y"]] <- 0.5
  expect_spec_problem(spec, "The paths into Job performance (Y) are impossible together")
})

test_that("impossible interaction correlations are rejected", {
  spec <- example_spec("regression_interaction")
  spec$population$r_X_Y <- 0.7
  spec$population$r_W_Y <- 0.7
  spec$population$r_X_W <- -0.2
  expect_spec_problem(spec, "These correlations are impossible together")
  expect_spec_problem(spec, "explain 123.5% of the variance in Sleep quality (Y)")
})

test_that("impossible residual correlations among mediators are rejected", {
  spec <- example_spec("mediation_parallel")
  spec$variables$M3 <- list(type = "continuous", label = "Disengagement")
  spec$population$paths[["X->M3"]] <- 0.2
  spec$population$paths[["M3->Y"]] <- 0.1
  spec$population$residual_correlations <- list("M1<->M2" = 0.9, "M1<->M3" = 0.9, "M2<->M3" = -0.9)
  expect_spec_problem(spec, "The residual correlations between the mediators are impossible together")
})

test_that("chi-square cell probabilities must form a proper table", {
  spec <- example_spec("chi_square_independence")
  spec$population$probabilities[[1]][[1]] <- 0.5
  expect_spec_problem(spec, "must add up to 1, but they add up to 1.2")

  spec <- example_spec("chi_square_independence")
  spec$population$probabilities[[2]] <- list(0.1, 0.05, 0.05)
  expect_spec_problem(spec, "every row needs the same number of entries")

  spec <- example_spec("chi_square_independence")
  spec$population$probabilities <- list(list(0.5, 0.5), list(0, 0))
  err <- expect_spec_problem(spec, "is 2 x 2, but Attachment style (X) has 3 levels")
  expect_match(err$problems, "a row or column that is all zero", fixed = TRUE, all = FALSE)
})

test_that("standardised ANOVA means need an SD of 1", {
  spec <- example_spec("anova_2x2_mixed")
  spec$population$sd <- 2
  expect_spec_problem(spec, "'population > sd' must be 1")
})

# Variables and paths fit the template -----------------------------------------

test_that("mediators must be named M, or M1, M2, ... without gaps", {
  spec <- example_spec("mediation_parallel")
  names(spec$variables)[names(spec$variables) == "M2"] <- "M3"
  expect_spec_problem(spec, "Name a single mediator 'M', or several mediators M1, M2, M3, ... with no gaps.")

  spec <- example_spec("mediation_simple")
  spec$variables$M2 <- list(type = "continuous", label = "Shame")
  expect_spec_problem(spec, "The mediators are currently named 'M' and 'M2'.")
})

test_that("missing and extra paths are named", {
  spec <- example_spec("mediation_parallel")
  spec$population$paths[["X->Y"]] <- NULL
  expect_spec_problem(spec, "'population > paths' is missing 'X->Y'. Give every path in the model a value (use 0 for no effect).")

  spec <- example_spec("process_7")
  spec$population$paths[["X*W->M"]] <- spec$population$paths[["XW->M"]]
  spec$population$paths[["XW->M"]] <- NULL
  expect_spec_problem(spec, "'population > paths' has 'X*W->M', which is not a path in PROCESS model 7. Did you mean 'XW->M'?")
})

test_that("mediator-to-mediator paths in a parallel model point to serial mediation", {
  spec <- example_spec("mediation_parallel")
  spec$population$paths[["M1->M2"]] <- 0.2
  expect_spec_problem(spec, "Paths between mediators belong in serial mediation (template 'process_6').")
})

test_that("correlation keys must name a valid pair once", {
  spec <- example_spec("mediation_parallel")
  spec$population$residual_correlations <- list("M1<->Y" = 0.2)
  expect_spec_problem(spec, "'population > residual_correlations > M1<->Y' isn't a valid pair.")

  spec$population$residual_correlations <- list("M1<->M2" = 0.2, "M2<->M1" = 0.2)
  expect_spec_problem(spec, "gives the correlation M1<->M2 twice")

  spec <- example_spec("mediation_simple")
  spec$population$residual_correlations <- list("M<->M" = 0.2)
  expect_spec_problem(spec, "only used when there are two or more mediators")

  spec <- example_spec("process_14")
  spec$population$correlations <- list("X<->M" = 0.2)
  expect_spec_problem(spec, "Write pairs as 'A<->B' using 'X' or 'W'.")
})

test_that("the target indirect path must exist in the model", {
  spec <- example_spec("mediation_serial")
  spec$target_test$path <- "X->M2->M1->Y"
  expect_spec_problem(spec, "Choose one of 'X->M1->Y', 'X->M2->Y' or 'X->M1->M2->Y'.")

  spec$target_test$path <- "X -> M1 -> Y"
  expect_valid_spec(spec)
})

test_that("labels must be distinct", {
  spec <- example_spec("correlation")
  spec$variables$Y$label <- spec$variables$X$label
  expect_spec_problem(spec, "Variables 'X' and 'Y' have the same label, 'Trait mindfulness'.")
})

test_that("reliability and allocation ratios are only accepted where supported", {
  spec <- example_spec("independent_t")
  spec$variables$Y$reliability <- 0.8
  expect_spec_problem(spec, "'variables > Y > reliability' can't be used with basic test designs yet")

  spec <- example_spec("correlation")
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "'options > allocation_ratio' only applies to two-group designs")
})

# Goal ----------------------------------------------------------------------------

test_that("n must split into whole groups, with the nearest valid n suggested", {
  spec <- example_spec("anova_2x2_between")
  spec$goal <- list(type = "power", n = 150)
  expect_spec_problem(spec, "'goal > n' must split into 4 equal cells for a 2x2 between-participants design; 150 doesn't. The nearest that do: 148 and 152.")

  spec <- example_spec("anova_2x2_mixed")
  spec$goal$n <- 121
  expect_spec_problem(spec, "split into 2 equal groups")

  spec <- example_spec("independent_t")
  spec$options$allocation_ratio <- 2
  spec$goal <- list(type = "power", n = 100)
  expect_spec_problem(spec, "in the ratio 1 : 2; 100 doesn't. The nearest that do: 99 and 102.")

  spec$goal$n <- 99
  expect_valid_spec(spec)
})

test_that("n must be large enough to fit the model", {
  spec <- example_spec("anova_2x2_between")
  spec$goal <- list(type = "power", n = 4)
  expect_spec_problem(spec, "'goal > n' is 4, but this design needs at least 8 participants.")

  spec <- example_spec("process_14")
  spec$goal <- list(type = "power", n = 6)
  expect_spec_problem(spec, "needs at least 7 participants")
})

test_that("target power must exceed alpha", {
  spec <- example_spec("independent_t")
  spec$goal$power <- 0.05
  expect_spec_problem(spec, "'goal > power' (0.05) must be greater than alpha (0.05)")
})

zero_effect_cases <- list(
  one_sample_t = function(s) within(s, population$d <- 0),
  independent_t = function(s) within(s, population$d <- 0),
  paired_t = function(s) within(s, population$dz <- 0),
  correlation = function(s) within(s, population$r <- 0),
  two_proportions = function(s) within(s, population$p2 <- population$p1),
  chi_square_independence = function(s) {
    p <- outer(c(0.5, 0.2, 0.3), c(0.6, 0.4))
    s$population$probabilities <- lapply(seq_len(nrow(p)), function(i) as.list(p[i, ]))
    s
  },
  anova_2x2_between = function(s) within(s, population$means <- list(list(10, 12), list(11, 13))),
  anova_2x2_between_unequal = function(s) within(s, population$means <- list(list(20, 18), list(30, 28))),
  anova_2x2_mixed = function(s) within(s, population$means <- list(list(0, -0.2), list(0, -0.2))),
  regression_interaction = function(s) within(s, population$r_XW_Y <- 0),
  regression_interaction_binary = function(s) within(s, population$r_XW_Y <- 0),
  crossed_two_condition = function(s) within(s, population$difference <- 0),
  mixed_two_level = function(s) within(s, population$b_XW <- 0),
  crossed_conditions = function(s) within(s, population$means <- list(600, 600, 590)),
  meta_mean_effect = function(s) within(s, population$effect <- 0),
  meta_subgroups = function(s) within(s, population$effects <- list(0.3, 0.3)),
  mediation_simple = function(s) within(s, population$paths[["X->M"]] <- 0),
  mediation_parallel = function(s) within(s, population$paths[["M2->Y"]] <- 0),
  mediation_serial = function(s) within(s, population$paths[["M1->M2"]] <- 0),
  process_7 = function(s) within(s, population$paths[["XW->M"]] <- 0),
  process_14 = function(s) within(s, population$paths[["MW->Y"]] <- 0),
  regression_three_way = function(s) within(s, population$b_XWZ <- 0),
  ordinal_two_groups = function(s) within(s, population$odds_ratio <- 1),
  logistic_factorial = function(s) within(s, population$probabilities <- list(list(0.3, 0.4, 0.25), list(0.3, 0.4, 0.25))),
  process_7_parallel = function(s) within(s, population$paths[["XW->M1"]] <- 0),
  anova_oneway_between = function(s) within(s, population$means <- list(12, 12, 12)),
  anova_oneway_within = function(s) within(s, population$means <- list(620, 620, 620)),
  # Parallel lines over time: no interaction, though both main effects exist.
  anova_mixed = function(s) within(s, population$means <- list(list(20, 16, 15), list(22, 18, 17))),
  # Parallel lines: no interaction, though both main effects exist.
  anova_factorial_within = function(s) within(s, population$means <- list(list(400, 410, 420), list(430, 440, 450))),
  # Parallel lines: no interaction, though both main effects exist.
  anova_factorial_ancova = function(s) within(s, population$means <- list(list(20, 19, 18), list(17, 16, 15))),
  anova_factorial_between = function(s) within(s, population$means <- list(list(0, 0.1, 0.2), list(0.3, 0.4, 0.5))),
  # Additive means: no three-way interaction, though every main effect exists.
  anova_factorial_three = function(s) within(s, population$means <- list(list(list(80, 60), list(81, 61)), list(list(82, 62), list(83, 63)))),
  regression_r2_zero = function(s) within(s, population$r2 <- 0),
  regression_r2_increase = function(s) within(s, population$r2_full <- population$r2_reduced),
  one_proportion = function(s) within(s, population$p <- population$p0),
  mcnemar = function(s) within(s, population$p_second_only <- population$p_first_only),
  fisher_exact = function(s) within(s, population$p2 <- population$p1),
  chi_square_gof = function(s) within(s, population$probabilities <- list(1 / 3, 1 / 3, 1 / 3)),
  two_correlations = function(s) within(s, population$r2 <- population$r1),
  # Dependent correlations: one-sided, since pwrss's Steiger test can't give
  # two-sided power for equal correlations (powerkit refuses that case).
  overlapping_correlations = function(s) {
    s$population$r_X_Z <- s$population$r_X_Y
    s$target_test$alternative <- "greater"
    s
  },
  nonoverlapping_correlations = function(s) {
    s$population$r_X2_Y2 <- s$population$r_X1_Y1
    s$target_test$alternative <- "greater"
    s
  },
  logistic_regression = function(s) within(s, population$odds_ratio <- 1),
  poisson_regression = function(s) within(s, population$rate_ratio <- 1),
  anova_oneway_ancova = function(s) within(s, population$means <- list(18, 18, 18)),
  anova_oneway_ancova = function(s) within(s, population$means <- list(18, 18, 18)),
  # Equal means make every contrast zero, whatever its weights.
  anova_oneway_contrast = function(s) within(s, population$means <- list(2, 2, 2, 2)),
  anova_oneway_ancova = function(s) within(s, population$means <- list(18, 18, 18)),
  one_variance = function(s) within(s, population$var0 <- population$var),
  two_variances = function(s) within(s, population$var2 <- population$var1),
  proportion_trend = function(s) within(s, population$proportions <- list(0.3, 0.3, 0.3, 0.3)),
  paired_variances = function(s) within(s, population$var2 <- population$var1),
  manova = function(s) within(s, population$means <- rep(population$means[1], length(population$means))),
  hotelling_one = function(s) within(s, population$means <- population$mu0),
  cluster_randomised = function(s) within(s, population$d <- 0),
  multisite = function(s) within(s, population$d <- 0),
  cluster_randomised_binary = function(s) within(s, population$p2 <- population$p1),
  multisite_binary = function(s) within(s, population$p2 <- population$p1),
  group_treatment = function(s) within(s, population$d <- 0),
  group_treatment_binary = function(s) within(s, population$p2 <- population$p1)
)

test_that("a zero target effect can't be the basis of a sample size search", {
  # Generic tests have no sample-size goal (their noncentrality already
  # reflects the sample size), and an equivalence test expects no
  # difference by design (what it needs is a bound above 0, which the
  # schema requires), so they aren't in this list. Nor is model fit for a
  # structural equation model: the schema refuses an RMSEA of 0, because
  # semPower does.
  expect_setequal(names(zero_effect_cases), grep("^(generic|tost|noninf|sem)_", example_spec_names(), value = TRUE, invert = TRUE))
  for (name in names(zero_effect_cases)) {
    spec <- zero_effect_cases[[name]](example_spec(name))
    spec$goal <- list(type = "sample_size", power = 0.8)
    err <- tryCatch(validate_spec(spec), powerkit_spec_error = function(e) e)
    expect_s3_class(err, "powerkit_spec_error")
    expect_match(err$problems, "The effect you want to detect is zero", fixed = TRUE, all = FALSE, label = name)
  }
})

test_that("a zero target effect is fine at a fixed n (Type I error checks)", {
  for (name in names(zero_effect_cases)) {
    spec <- zero_effect_cases[[name]](example_spec(name))
    spec$goal <- list(type = "power", n = 240)
    result <- tryCatch(
      {
        validate_spec(spec)
        "valid"
      },
      error = conditionMessage
    )
    expect_identical(result, "valid", label = name)
  }
})

# Advice ----------------------------------------------------------------------

test_that("pilot-study effect sizes give a warning, not an error", {
  spec <- example_spec("independent_t")
  spec$effect_justification <- list(type = "pilot_study", source = "Our pilot, n = 20")
  expect_warning(out <- validate_spec(spec), "Pilot estimates are very imprecise", class = "powerkit_spec_warning")
  expect_s3_class(out, "powerkit_spec")
})

test_that("an effect size from the finished study itself (observed power) gives a warning, not an error", {
  spec <- example_spec("independent_t")
  spec$effect_justification <- list(type = "own_study_result", source = "Our study's d")
  expect_warning(out <- validate_spec(spec), "useless at best, misleading at worst", class = "powerkit_spec_warning")
  expect_s3_class(out, "powerkit_spec")
})

test_that("low replication counts and high attrition give warnings", {
  spec <- example_spec("independent_t")
  spec$options$nrep <- 200
  expect_warning(validate_spec(spec), "only accurate to about +/- 0.055", fixed = TRUE, class = "powerkit_spec_warning")

  spec <- example_spec("independent_t")
  spec$options$attrition <- 0.6
  expect_warning(validate_spec(spec), "more than half of those recruited", class = "powerkit_spec_warning")
})

test_that("only the first impossible variable is reported, not knock-on effects", {
  spec <- example_spec("mediation_simple")
  spec$population$paths <- list("X->M" = 1.2, "M->Y" = 0.5, "X->Y" = 0.5)
  err <- expect_spec_problem(spec, "The paths into Defensiveness (M) are impossible together")
  expect_length(err$problems, 1)
})
