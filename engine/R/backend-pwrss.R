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
#                      pwrss::probs.to.w(), then pwrss::power.chisq.gof()
#   two correlations   basic_test/two_correlations: Fisher's z test,
#                      pwrss::power.z.twocors()
#   ANCOVA             factorial_anova/oneway_ancova: Shieh's method,
#                      pwrss::power.f.ancova.shieh()
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
  key %in% c("basic_test/one_proportion", "basic_test/mcnemar",
             "basic_test/chi_square_gof", "basic_test/two_correlations",
             "factorial_anova/oneway_ancova", "factorial_anova/oneway_contrast",
             "multiple_regression/r2_zero", "multiple_regression/r2_increase") ||
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
    # Exact tests of counts: power goes up and down with n.
    sawtooth = spec$template %in% c("one_proportion", "mcnemar") ||
      identical(spec$target_test$method, "fisher_exact"),
    check_run = function() pwrss_check_run(spec, inputs)
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
    spec$template,
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

# Cohen's w for a goodness-of-fit spec, by pwrss::probs.to.w().
gof_w <- function(spec) {
  pop <- spec$population
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
    spec$template,
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
    chi_square_gof = {
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
    oneway_contrast = rbind(
      row("means passed to pwrss (mu.vector)", as.numeric(unlist(pop$means)), args$mu.vector),
      row("contrast weights passed to pwrss (contrast.matrix)", inputs$weights, as.numeric(args$contrast.matrix)),
      row("covariates pwrss used (k.covariates)", 0, args$k.covariates)
    ),
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
