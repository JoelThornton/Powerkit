# Backend adapter: wave 2 tests by exact or analytic formula, via pwrss.
#
# Engine groundwork only (not wired into the app or the question tree):
#   one proportion     basic_test/one_proportion: the exact binomial test,
#                      pwrss::power.exact.oneprop()
#   McNemar's test     basic_test/mcnemar: McNemar's exact test,
#                      pwrss::power.exact.mcnemar(method = "exact")
#   Welch's t-test     basic_test/independent_t with welch_t, only when
#                      options > method = "exact" is requested:
#                      pwrss::power.t.welch() (Bulus, 2024's formulas). The
#                      default for Welch's t-test stays Spower simulation.
#   R-squared          multiple_regression/r2_zero and r2_increase: the F
#                      test, pwrss::power.f.regression()
#   Fisher's exact     basic_test/two_proportions with method fisher_exact:
#                      pwrss::power.exact.fisher(method = "exact")
#   goodness of fit    basic_test/chi_square_gof: Cohen's w from
#                      pwrss::probs.to.w() (or given, population > metric
#                      "w"), then pwrss::power.chisq.gof()
#   two correlations   basic_test/two_correlations: Fisher's z test,
#                      pwrss::power.z.twocors()
#   dependent          basic_test/overlapping_correlations (X with Y vs X
#   correlations       with Z) and nonoverlapping_correlations (X1 with Y1
#                      vs X2 with Y2), one group: Steiger's (1980) z test,
#                      pwrss::power.z.twocors.steiger(), unpooled as in
#                      G*Power (Departure 12)
#   ANCOVA             factorial_anova/oneway_ancova and factorial_ancova
#                      (two between factors): Shieh's method,
#                      pwrss::power.f.ancova.shieh(); for two factors the
#                      effect tested is chosen by its rows of pwrss's own
#                      factorial.contrasts() matrix
#   logistic           logistic_regression/single_predictor: the Wald z
#   regression         test of one predictor, pwrss::power.z.logistic()
#                      (Demidenko's 2007 method with its variance
#                      correction, pwrss's default)
#   Poisson            poisson_regression/single_predictor_count: the Wald
#   regression         z test of one predictor, pwrss::power.z.poisson()
#                      (Demidenko's method with its variance correction,
#                      as for logistic regression)
#   ANOVA from an      factorial_anova/oneway_between, 2x2_between,
#   effect size        factorial_between, factorial_three (every factor
#                      between) and the ANCOVAs with population > metric
#                      "eta_squared": the F test of the effect tested from
#                      its partial eta-squared, as G*Power takes it,
#                      pwrss::power.f.ancova() (with the ANCOVA's number of
#                      covariates, which take error df as in G*Power)
#   contrast           factorial_anova/oneway_contrast: a planned
#                      comparison between the levels of one factor, the t
#                      test of a weighted combination of the group means,
#                      pwrss::power.t.contrasts()
# Each is one pwrss call, as a user would make it, at the total sample
# size n. Functions and arguments were checked in pwrss 1.3.3's help pages
# and sources (docs/coverage-roadmap.md, wave 2).

# Templates this adapter runs (Welch's t-test only on request).
pwrss_covers <- function(spec) {
  key <- paste(spec$design, spec$template, sep = "/")
  if (eta_squared_anova(spec) || interaction_r2_change(spec)) return(TRUE)
  key %in% c("basic_test/one_proportion", "basic_test/mcnemar",
             "basic_test/chi_square_gof", "basic_test/two_correlations",
             "basic_test/overlapping_correlations", "basic_test/nonoverlapping_correlations",
             "factorial_anova/oneway_ancova", "factorial_anova/factorial_ancova",
             "factorial_anova/oneway_contrast",
             "multiple_regression/r2_zero", "multiple_regression/r2_increase",
             "logistic_regression/single_predictor",
             "poisson_regression/single_predictor_count") ||
    (identical(key, "basic_test/two_proportions") &&
      identical(spec$target_test$method, "fisher_exact")) ||
    (identical(key, "basic_test/independent_t") &&
      identical(spec$target_test$method, "welch_t") &&
      identical(spec$options$method, "exact"))
}

pwrss_backend <- function(spec, seed = NULL) {
  inputs <- pwrss_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  if (spec$template %in% c("independent_t", "two_correlations")) {
    # pwrss's Welch formula needs at least 3 degrees of freedom, and Fisher's
    # z more than 3 people per group; four in each group gives both.
    while (min(analysed_groups(spec, n_min)) < 4) n_min <- n_min + step
  }
  power_at <- function(n) pwrss_power(inputs, n)
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    details = function(n) pwrss_details(pwrss_output(inputs$fun, inputs$args(n)), inputs$fun),
    # Exact tests of counts: power goes up and down with n.
    sawtooth = spec$template %in% c("one_proportion", "mcnemar") ||
      identical(spec$target_test$method, "fisher_exact"),
    check_run = function() pwrss_check_run(spec, inputs)
  )
}

# A between-participants ANOVA given by the partial eta-squared of the
# effect tested (G*Power's input) rather than by group means.
eta_squared_anova <- function(spec) {
  identical(spec$design, "factorial_anova") && identical(spec$population$metric, "eta_squared") &&
    spec$template %in% eta_squared_templates
}

# Every template that takes an effect given by its partial eta-squared.
eta_squared_templates <- c(
  "oneway_between", "2x2_between", "factorial_between", "factorial_three", "oneway_ancova", "factorial_ancova",
  "oneway_within", "2x2_mixed", "mixed"
)

# Repeated-measures and mixed ANOVA (factor A between, B within, or one
# within factor): pwrss's power.f.mixed.anova().
eta_squared_mixed_templates <- c("oneway_within", "2x2_mixed", "mixed")

# A two-way interaction given by its R-squared change (G*Power's input)
# rather than by InteractionPoweR's correlations: the F test of the
# product term in a model with X, W and XW.
interaction_r2_change <- function(spec) {
  identical(spec$design, "regression_interaction") && identical(spec$template, "two_way") &&
    identical(spec$population$metric, "r2_change")
}

# The key each switch in this adapter dispatches on: the template, or
# "anova_eta_squared" for an ANOVA given by its partial eta-squared, or
# "interaction_r2_change" for an interaction given by its R-squared change.
pwrss_key <- function(spec) {
  if (eta_squared_anova(spec)) return("anova_eta_squared")
  if (interaction_r2_change(spec)) return("interaction_r2_change")
  spec$template
}

# The factor levels and pwrss's name for the effect tested, for
# power.f.ancova(): one factor (no target needed), or two (A, B or A:B).
eta_anova_design <- function(spec) {
  k <- length(spec$variables$A$levels)
  if (identical(spec$template, "oneway_within")) {
    return(list(levels = c(1, k), target = "within", df = k - 1, mixed = TRUE))
  }
  if (spec$template %in% eta_squared_mixed_templates) {
    m <- length(spec$variables$B$levels)
    effect <- spec$target_test$effect %||% "interaction"
    return(list(
      levels = c(k, m),
      target = switch(effect, main_effect_A = "between", main_effect_B = "within", interaction = "interaction"),
      df = switch(effect, main_effect_A = k - 1, main_effect_B = m - 1, interaction = (k - 1) * (m - 1)),
      mixed = TRUE
    ))
  }
  if (spec$template %in% c("oneway_between", "oneway_ancova")) {
    return(list(levels = k, target = NULL, df = k - 1))
  }
  if (identical(spec$template, "factorial_three")) {
    sizes <- c(A = k, B = length(spec$variables$B$levels), C = length(spec$variables$C$levels))
    factors <- switch(spec$target_test$effect %||% "interaction_ABC",
      main_effect_A = "A", main_effect_B = "B", main_effect_C = "C",
      interaction_AB = c("A", "B"), interaction_AC = c("A", "C"), interaction_BC = c("B", "C"),
      interaction_ABC = c("A", "B", "C"))
    return(list(levels = unname(sizes), target = paste(factors, collapse = ":"), df = prod(sizes[factors] - 1)))
  }
  m <- length(spec$variables$B$levels)
  effect <- spec$target_test$effect %||% "interaction"
  list(
    levels = c(k, m),
    target = switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B"),
    df = switch(effect, main_effect_A = k - 1, main_effect_B = m - 1, interaction = (k - 1) * (m - 1))
  )
}

# pwrss's alternative: its one-sided tests run in the direction of the
# specified effect (validate_spec() refuses a one-sided test pointing the
# other way for these templates).
pwrss_alternative <- function(spec) {
  if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) "two.sided" else "one.sided"
}

# Partial R-squared of the tested set: R-squared change over what the
# reduced model leaves unexplained, (R2_full - R2_reduced) / (1 - R2_reduced).
# pwrss's power.f.regression() turns its r.squared.change into Cohen's f^2
# as r / (1 - r), so passing the partial R-squared gives
# f^2 = (R2_full - R2_reduced) / (1 - R2_full), Cohen's (1988) f^2 for an
# R-squared increase. For R-squared against 0 it is R-squared itself.
partial_r_squared <- function(spec) {
  pop <- spec$population
  if (spec$template == "r2_zero") {
    return(pop$r2)
  }
  (pop$r2_full - pop$r2_reduced) / (1 - pop$r2_reduced)
}

# Translate a validated spec into pwrss's terms: the function and its
# arguments at total sample size n.
pwrss_inputs <- function(spec) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  alternative <- pwrss_alternative(spec)
  call <- switch(
    pwrss_key(spec),
    anova_eta_squared = if (isTRUE(eta_anova_design(spec)$mixed)) {
      design <- eta_anova_design(spec)
      # 'published': partial eta-squared as a repeated-measures ANOVA reports
      # it (SPSS, R, JASP), which already reflects the correlation between
      # measurements, so pwrss doesn't adjust it (rho.within = NA).
      # 'planned': G*Power's default, without the correlation, which pwrss
      # then takes from rho.within.
      rho <- if (identical(pop$eta_source, "published")) NA else pop$r
      list(
        fun = "power.f.mixed.anova",
        design = design,
        args = function(n) list(
          eta.squared = pop$eta_squared, factor.levels = design$levels, rho.within = rho, epsilon = 1,
          n.total = n, alpha = alpha, effect = design$target, ceil.n = FALSE, verbose = 0
        )
      )
    } else {
      design <- eta_anova_design(spec)
      list(
        fun = "power.f.ancova",
        design = design,
        args = function(n) c(
          list(eta.squared = pop$eta_squared, factor.levels = design$levels),
          if (!is.null(design$target)) list(target.effect = design$target),
          list(k.covariates = pop$covariates %||% 0, n.total = n, alpha = alpha, ceil.n = FALSE, verbose = 0)
        )
      )
    },
    one_proportion = list(
      fun = "power.exact.oneprop",
      args = function(n) list(
        prob = pop$p, null.prob = pop$p0, n = n, alpha = alpha,
        alternative = alternative, verbose = 0
      )
    ),
    mcnemar = list(
      fun = "power.exact.mcnemar",
      # pwrss's prob10 is "success in case (or after) but failure in matched
      # control (or before)": yes in the second condition only.
      args = function(n) list(
        prob10 = pop$p_second_only, prob01 = pop$p_first_only, n.paired = n,
        alpha = alpha, alternative = alternative, method = "exact",
        ceil.n = FALSE, verbose = 0
      )
    ),
    independent_t = {
      ratio <- spec$options$allocation_ratio %||% 1
      list(
        fun = "power.t.welch",
        args = function(n) {
          n1 <- round(n / (1 + ratio))
          n2 <- n - n1
          # pwrss's n.ratio is n1 / n2; var.ratio is sd1^2 / sd2^2 (the
          # spec's population has one pooled SD, so 1).
          list(
            d = pop$d, var.ratio = 1, n.ratio = n1 / n2, n2 = n2, alpha = alpha,
            alternative = alternative, claim.basis = "md.pval", verbose = 0
          )
        }
      )
    },
    two_proportions = {
      ratio <- spec$options$allocation_ratio %||% 1
      list(
        fun = "power.exact.fisher",
        args = function(n) {
          n1 <- round(n / (1 + ratio))
          n2 <- n - n1
          # pwrss's n.ratio is n1 / n2.
          list(
            prob1 = pop$p1, prob2 = pop$p2, n.ratio = n1 / n2, n2 = n2,
            alpha = alpha, alternative = alternative, method = "exact",
            ceil.n = FALSE, verbose = 0
          )
        }
      )
    },
    two_correlations = {
      ratio <- spec$options$allocation_ratio %||% 1
      list(
        fun = "power.z.twocors",
        args = function(n) {
          n1 <- round(n / (1 + ratio))
          n2 <- n - n1
          list(
            rho1 = pop$r1, rho2 = pop$r2, n.ratio = n1 / n2, n2 = n2,
            alpha = alpha, alternative = alternative, ceil.n = FALSE, verbose = 0
          )
        }
      )
    },
    # pwrss numbers the variables 1 to 4. Overlapping: 1 = X (shared),
    # 2 = Y, 3 = Z, so rho12 and rho13 are compared. Non-overlapping:
    # 1 = X1, 2 = Y1, 3 = X2, 4 = Y2, so rho12 and rho34 are compared.
    # pooled = FALSE: the covariance of the two correlations under the null
    # uses the specified correlations, as G*Power does; pwrss's default
    # (TRUE) uses their average (Departure 12).
    overlapping_correlations = list(
      fun = "power.z.twocors.steiger",
      args = function(n) list(
        rho12 = pop$r_X_Y, rho13 = pop$r_X_Z, rho23 = pop$r_Y_Z,
        n = n, alpha = alpha, alternative = alternative,
        pooled = FALSE, common.index = TRUE, ceil.n = FALSE, verbose = 0
      )
    ),
    nonoverlapping_correlations = list(
      fun = "power.z.twocors.steiger",
      args = function(n) list(
        rho12 = pop$r_X1_Y1, rho34 = pop$r_X2_Y2, rho13 = pop$r_X1_X2,
        rho14 = pop$r_X1_Y2, rho23 = pop$r_Y1_X2, rho24 = pop$r_Y1_Y2,
        n = n, alpha = alpha, alternative = alternative,
        pooled = FALSE, common.index = FALSE, ceil.n = FALSE, verbose = 0
      )
    ),
    chi_square_gof = {
      # Cohen's w and its df from pwrss's own conversion; equal fixed
      # proportions unless given (probs.to.w()'s default).
      w <- gof_w(spec)
      list(
        fun = "power.chisq.gof",
        w = w,
        args = function(n) list(w = w$w, df = w$df, n = n, alpha = alpha, ceil.n = FALSE, verbose = 0)
      )
    },
    oneway_ancova = {
      k <- length(spec$variables$A$levels)
      list(
        fun = "power.f.ancova.shieh",
        args = function(n) list(
          mu.vector = as.numeric(unlist(pop$means)), sd.vector = rep(pop$sd, k),
          n.vector = rep(n / k, k), r.squared = pop$r2_covariates,
          k.covariates = pop$covariates, alpha = alpha, ceil.n = FALSE, verbose = 0
        )
      )
    },
    factorial_ancova = {
      k <- length(spec$variables$A$levels)
      m <- length(spec$variables$B$levels)
      contrasts <- ancova_effect_contrasts(k, m, spec$target_test$effect)
      list(
        fun = "power.f.ancova.shieh",
        contrasts = contrasts,
        args = function(n) list(
          mu.vector = as.numeric(unlist(pop$means)), sd.vector = rep(pop$sd, k * m),
          n.vector = rep(n / (k * m), k * m), factor.levels = c(k, m),
          r.squared = pop$r2_covariates, k.covariates = pop$covariates,
          contrast.matrix = contrasts, alpha = alpha, ceil.n = FALSE, verbose = 0
        )
      )
    },
    single_predictor = {
      distribution <- pwrss_predictor_distribution(spec)
      list(
        fun = "power.z.logistic",
        distribution = distribution,
        args = function(n) list(
          base.prob = pop$base_prob, odds.ratio = pop$odds_ratio, n = n,
          r.squared.predictor = pop$r2_other_predictors %||% 0,
          alpha = alpha, alternative = alternative, method = "demidenko(vc)",
          distribution = distribution, ceil.n = FALSE, verbose = 0
        )
      )
    },
    single_predictor_count = {
      distribution <- pwrss_predictor_distribution(spec)
      list(
        fun = "power.z.poisson",
        distribution = distribution,
        args = function(n) list(
          base.rate = pop$base_rate, rate.ratio = pop$rate_ratio, n = n,
          mean.exposure = pop$mean_exposure %||% 1,
          r.squared.predictor = pop$r2_other_predictors %||% 0,
          alpha = alpha, alternative = alternative, method = "demidenko(vc)",
          distribution = distribution, ceil.n = FALSE, verbose = 0
        )
      )
    },
    oneway_contrast = {
      k <- length(spec$variables$A$levels)
      weights <- as.numeric(unlist(spec$target_test$weights))
      list(
        fun = "power.t.contrasts",
        weights = weights,
        args = function(n) list(
          mu.vector = as.numeric(unlist(pop$means)), sd.vector = rep(pop$sd, k),
          n.vector = rep(n / k, k),
          contrast.matrix = matrix(weights, nrow = 1, dimnames = list("contrast", NULL)),
          # No covariates, and nothing else explaining the outcome: pwrss
          # defaults k.covariates to 1, which would spend a denominator
          # degree of freedom this design doesn't have.
          r.squared = 0, k.covariates = 0,
          alpha = alpha, adjust.alpha = "none", ceil.n = FALSE, verbose = 0
        )
      )
    },
    interaction_r2_change = {
      # pwrss turns r.squared.change into f^2 = r / (1 - r); passing the
      # partial R-squared change, R2_change / (1 - R2_main), gives Cohen's
      # f^2 = R2_change / (1 - R2_full), as G*Power uses.
      partial <- pop$r2_change / (1 - (pop$r2_main %||% 0))
      list(
        fun = "power.f.regression",
        args = function(n) list(
          r.squared.change = partial, k.total = 3, k.tested = 1,
          n = n, alpha = alpha, verbose = 0
        )
      )
    },
    r2_zero = ,
    r2_increase = {
      k_total <- if (spec$template == "r2_zero") pop$predictors else pop$predictors_total
      k_tested <- if (spec$template == "r2_zero") pop$predictors else pop$predictors_tested
      partial <- partial_r_squared(spec)
      list(
        fun = "power.f.regression",
        args = function(n) list(
          r.squared.change = partial, k.total = k_total, k.tested = k_tested,
          n = n, alpha = alpha, verbose = 0
        )
      )
    }
  )
  call$description <- sprintf("pwrss::%s", call$fun)
  call
}

# The predictor's distribution for pwrss's logistic and Poisson regression:
# a standardised score (normal, mean 0, SD 1), so the odds or rate ratio is
# per SD and the base probability or rate is at X's mean; or a yes/no group
# (Bernoulli, with the proportion in X's second level).
pwrss_predictor_distribution <- function(spec) {
  if (identical(spec$variables$X$type, "binary")) {
    list(dist = "bernoulli", prob = spec$population$x_prob %||% 0.5)
  } else {
    list(dist = "normal", mean = 0, sd = 1)
  }
}

# Cohen's w for a goodness-of-fit spec, by pwrss::probs.to.w().
gof_w <- function(spec) {
  pop <- spec$population
  # Cohen's w given directly (as G*Power takes it), with its df.
  if (chisq_by_w(spec)) return(list(w = pop$w, df = chisq_df(spec)))
  args <- list(prob.matrix = as.numeric(unlist(pop$probabilities)), verbose = 0)
  if (!is.null(pop$null_probabilities)) args$null.prob.matrix <- as.numeric(unlist(pop$null_probabilities))
  call_backend("pwrss", quietly(do.call(pwrss::probs.to.w, args)))
}

pwrss_power <- function(inputs, n) {
  fun <- getExportedValue("pwrss", inputs$fun)
  call_backend("pwrss", quietly(do.call(fun, inputs$args(n))))$power
}

# Check run: no simulated data, so the check confirms pwrss receives the
# values the spec gives (and, for R-squared, that the f^2 it will use is
# Cohen's f^2 for the specified R-squared values).
pwrss_check_run <- function(spec, inputs) {
  args <- inputs$args(1000)
  pop <- spec$population
  row <- function(parameter, specified, passed) {
    data.frame(
      parameter = parameter, specified = specified, recovered = passed,
      ok = isTRUE(all.equal(specified, passed))
    )
  }
  switch(
    pwrss_key(spec),
    anova_eta_squared = {
      # pwrss's own result: the df of the effect it tested, and Cohen's f^2
      # recovered from its noncentrality (lambda = f^2 * N, as in G*Power).
      out <- pwrss_output(inputs$fun, args)
      if (isTRUE(eta_anova_design(spec)$mixed)) {
        rbind(
          row("partial eta-squared passed to pwrss (eta.squared)", pop$eta_squared, args$eta.squared),
          row("numerator df of the effect pwrss tested (df1)", eta_anova_design(spec)$df, out$df1),
          row("correlation between measurements passed to pwrss (rho.within; NA = already in the eta-squared)",
              if (identical(pop$eta_source, "published")) NA_real_ else pop$r, as.numeric(args$rho.within))
        )
      } else {
        rbind(
          row("partial eta-squared passed to pwrss (eta.squared)", pop$eta_squared, args$eta.squared),
          row("numerator df of the effect pwrss tested (df1)", eta_anova_design(spec)$df, out$df1),
          row("Cohen's f^2 = eta^2 / (1 - eta^2), from pwrss's noncentrality / N",
              pop$eta_squared / (1 - pop$eta_squared), out$ncp / args$n.total),
          # Error df as in G*Power: N minus the cells minus the covariates.
          row("error df: N minus the groups minus the covariates (df2)",
              args$n.total - prod(eta_anova_design(spec)$levels) - (pop$covariates %||% 0), out$df2)
        )
      }
    },
    one_proportion = rbind(
      row("p passed to pwrss (prob)", pop$p, args$prob),
      row("p0 passed to pwrss (null.prob)", pop$p0, args$null.prob)
    ),
    mcnemar = rbind(
      row("yes in the second condition only, passed to pwrss (prob10)", pop$p_second_only, args$prob10),
      row("yes in the first condition only, passed to pwrss (prob01)", pop$p_first_only, args$prob01)
    ),
    independent_t = row("d passed to pwrss", pop$d, args$d),
    two_proportions = rbind(
      row("p1 passed to pwrss (prob1)", pop$p1, args$prob1),
      row("p2 passed to pwrss (prob2)", pop$p2, args$prob2)
    ),
    two_correlations = rbind(
      row("r1 passed to pwrss (rho1)", pop$r1, args$rho1),
      row("r2 passed to pwrss (rho2)", pop$r2, args$rho2)
    ),
    overlapping_correlations = rbind(
      row("r_X_Y passed to pwrss (rho12)", pop$r_X_Y, args$rho12),
      row("r_X_Z passed to pwrss (rho13)", pop$r_X_Z, args$rho13),
      row("r_Y_Z passed to pwrss (rho23)", pop$r_Y_Z, args$rho23)
    ),
    nonoverlapping_correlations = rbind(
      row("r_X1_Y1 passed to pwrss (rho12)", pop$r_X1_Y1, args$rho12),
      row("r_X2_Y2 passed to pwrss (rho34)", pop$r_X2_Y2, args$rho34),
      row("r_X1_X2 passed to pwrss (rho13)", pop$r_X1_X2, args$rho13),
      row("r_X1_Y2 passed to pwrss (rho14)", pop$r_X1_Y2, args$rho14),
      row("r_Y1_X2 passed to pwrss (rho23)", pop$r_Y1_X2, args$rho23),
      row("r_Y1_Y2 passed to pwrss (rho24)", pop$r_Y1_Y2, args$rho24)
    ),
    chi_square_gof = if (chisq_by_w(spec)) {
      rbind(
        row("Cohen's w passed to pwrss (w)", pop$w, args$w),
        row("degrees of freedom (categories - 1)", length(spec$variables$Y$levels) - 1, args$df)
      )
    } else {
      p <- as.numeric(unlist(pop$probabilities))
      p0 <- as.numeric(unlist(pop$null_probabilities %||% rep(1 / length(p), length(p))))
      rbind(
        row("fixed proportions pwrss used (null.prob.matrix)", p0, as.numeric(inputs$w$null.prob.matrix)),
        row("degrees of freedom (categories - 1)", length(p) - 1, args$df)
      )
    },
    oneway_ancova = rbind(
      row("adjusted means passed to pwrss (mu.vector)", as.numeric(unlist(pop$means)), args$mu.vector),
      row("covariates' R-squared passed to pwrss (r.squared)", pop$r2_covariates, args$r.squared)
    ),
    factorial_ancova = {
      k <- length(spec$variables$A$levels)
      m <- length(spec$variables$B$levels)
      rbind(
        row("adjusted cell means passed to pwrss (mu.vector, A1:B1, A1:B2, ...)", as.numeric(unlist(pop$means)), args$mu.vector),
        row("covariates' R-squared passed to pwrss (r.squared)", pop$r2_covariates, args$r.squared),
        row("numerator df of the effect tested (contrast rows)",
            switch(spec$target_test$effect, main_effect_A = k - 1, main_effect_B = m - 1, interaction = (k - 1) * (m - 1)),
            nrow(args$contrast.matrix))
      )
    },
    single_predictor = rbind(
      row("odds ratio passed to pwrss (odds.ratio)", pop$odds_ratio, args$odds.ratio),
      row("base probability passed to pwrss (base.prob)", pop$base_prob, args$base.prob),
      row("R-squared of X on the other predictors (r.squared.predictor)", pop$r2_other_predictors %||% 0, args$r.squared.predictor),
      if (identical(args$distribution$dist, "bernoulli")) {
        row("proportion in X's second level (distribution prob)", pop$x_prob %||% 0.5, args$distribution$prob)
      } else {
        row("X standardised: mean and SD passed to pwrss", c(0, 1), c(args$distribution$mean, args$distribution$sd))
      }
    ),
    single_predictor_count = rbind(
      row("rate ratio passed to pwrss (rate.ratio)", pop$rate_ratio, args$rate.ratio),
      row("base rate passed to pwrss (base.rate)", pop$base_rate, args$base.rate),
      row("mean exposure passed to pwrss (mean.exposure)", pop$mean_exposure %||% 1, args$mean.exposure),
      row("R-squared of X on the other predictors (r.squared.predictor)", pop$r2_other_predictors %||% 0, args$r.squared.predictor),
      if (identical(args$distribution$dist, "bernoulli")) {
        row("proportion in X's second level (distribution prob)", pop$x_prob %||% 0.5, args$distribution$prob)
      } else {
        row("X standardised: mean and SD passed to pwrss", c(0, 1), c(args$distribution$mean, args$distribution$sd))
      }
    ),
    oneway_contrast = rbind(
      row("means passed to pwrss (mu.vector)", as.numeric(unlist(pop$means)), args$mu.vector),
      row("contrast weights passed to pwrss (contrast.matrix)", inputs$weights, as.numeric(args$contrast.matrix)),
      row("covariates pwrss used (k.covariates)", 0, args$k.covariates)
    ),
    interaction_r2_change = {
      r <- args$r.squared.change
      r2_main <- pop$r2_main %||% 0
      rbind(
        row("Cohen's f^2 pwrss will use, R2_change / (1 - R2_full)", pop$r2_change / (1 - r2_main - pop$r2_change), r / (1 - r)),
        row("predictors in the model (X, W, XW) and tested (XW)", c(3, 1), c(args$k.total, args$k.tested))
      )
    },
    r2_zero = ,
    r2_increase = {
      r <- args$r.squared.change
      expected_f2 <- if (spec$template == "r2_zero") {
        pop$r2 / (1 - pop$r2)
      } else {
        (pop$r2_full - pop$r2_reduced) / (1 - pop$r2_full)
      }
      row("Cohen's f^2 pwrss will use (r.squared.change / (1 - r.squared.change))", expected_f2, r / (1 - r))
    }
  )
}

# The rows of pwrss's own contrast matrix for a k x m design (deviation
# coding, pwrss::factorial.contrasts()) that test one effect: rows named
# A1, A2, ... for A's main effect, B1, ... for B's, and A1:B1, ... for the
# interaction. pwrss's power.f.ancova.shieh() tests only the interaction
# when given factor.levels and no contrast matrix.
ancova_effect_contrasts <- function(k, m, effect) {
  full <- call_backend("pwrss", quietly(pwrss::factorial.contrasts(
    factor.levels = c(k, m), intercept = FALSE, verbose = 0
  )))$contrast.matrix
  pattern <- switch(effect, main_effect_A = "^A[0-9]+$", main_effect_B = "^B[0-9]+$", interaction = ":")
  full[grepl(pattern, rownames(full)), , drop = FALSE]
}
