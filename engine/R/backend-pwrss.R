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
# Each is one pwrss call, as a user would make it, at the total sample
# size n. Functions and arguments were checked in pwrss 1.3.3's help pages
# and sources (docs/coverage-roadmap.md, wave 2).

# Templates this adapter runs (Welch's t-test only on request).
pwrss_covers <- function(spec) {
  key <- paste(spec$design, spec$template, sep = "/")
  key %in% c("basic_test/one_proportion", "basic_test/mcnemar",
             "multiple_regression/r2_zero", "multiple_regression/r2_increase") ||
    (identical(key, "basic_test/independent_t") &&
      identical(spec$target_test$method, "welch_t") &&
      identical(spec$options$method, "exact"))
}

pwrss_backend <- function(spec, seed = NULL) {
  inputs <- pwrss_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  if (spec$template == "independent_t") {
    # pwrss's Welch formula needs at least 3 degrees of freedom; four people
    # in each group always gives that.
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
    sawtooth = spec$template %in% c("one_proportion", "mcnemar"),
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
