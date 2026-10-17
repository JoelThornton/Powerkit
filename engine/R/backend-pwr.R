# Backend adapter: basic tests by exact analytic formula, via pwr.
#
# The default for basic tests (one-sample, Student's independent and paired
# t-tests, correlation, two proportions, chi-square test of independence),
# because an exact answer exists for them and a formula has no Monte Carlo
# noise (docs/decisions.md, 17 October 2026; docs/conventions.md, Departure
# 9). Spower simulation stays available with options > method =
# "simulation", and is used for Welch's t-test, which pwr doesn't cover.
#
# Each template is one pwr call, as a user would make it:
#   one-sample, paired t   pwr.t.test(type = "one.sample" / "paired");
#                          the paired test's d is d_z
#   independent t          pwr.t.test(type = "two.sample") for equal
#                          groups, pwr.t2n.test() otherwise
#   correlation            pwr.r.test() (Fisher's z approximation)
#   two proportions        pwr.2p2n.test() with Cohen's h = ES.h(p2, p1)
#                          (the arcsine approximation)
#   chi-square             pwr.chisq.test() with Cohen's w = ES.w2(P),
#                          df = (rows - 1) x (columns - 1)
# The spec's effects are group 2 minus group 1 (d, h) and second minus first
# condition (dz), so the spec's "greater" is pwr's "greater".

# Basic-test templates pwr covers (Welch's t-test isn't covered).
pwr_covers <- function(spec) {
  spec$design == "basic_test" &&
    !identical(spec$target_test$method, "welch_t")
}

pwr_backend <- function(spec, seed = NULL) {
  inputs <- pwr_inputs(spec)
  step <- valid_n_step(spec)
  # pwr.r.test() needs n > 3; every other call accepts the design's minimum.
  n_min <- step * ceiling(max(minimum_n(spec), 4) / step)
  power_at <- function(n) pwr_power(inputs, n)
  list(
    name = "pwr",
    packages = "pwr",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() pwr_check_run(spec, inputs)
  )
}

# Translate a validated basic-test spec into pwr's terms: the function and
# its arguments at total sample size n.
pwr_inputs <- function(spec) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  groups <- function(n) {
    n1 <- round(n / (1 + ratio))
    c(n1, n - n1)
  }
  equal <- isTRUE(all.equal(ratio, 1))
  call <- switch(
    spec$template,
    one_sample_t = list(
      fun = "pwr.t.test",
      args = function(n) list(n = n, d = pop$d, type = "one.sample", alternative = alternative)
    ),
    independent_t = if (equal) {
      list(
        fun = "pwr.t.test",
        args = function(n) list(n = n / 2, d = pop$d, type = "two.sample", alternative = alternative)
      )
    } else {
      list(
        fun = "pwr.t2n.test",
        args = function(n) {
          g <- groups(n)
          list(n1 = g[1], n2 = g[2], d = pop$d, alternative = alternative)
        }
      )
    },
    paired_t = list(
      fun = "pwr.t.test",
      args = function(n) list(n = n, d = pop$dz, type = "paired", alternative = alternative)
    ),
    correlation = list(
      fun = "pwr.r.test",
      args = function(n) list(n = n, r = pop$r, alternative = alternative)
    ),
    two_proportions = list(
      fun = "pwr.2p2n.test",
      args = function(n) {
        g <- groups(n)
        list(h = pwr_h(pop), n1 = g[1], n2 = g[2], alternative = alternative)
      }
    ),
    chi_square_independence = {
      p <- probability_matrix(spec)
      list(
        fun = "pwr.chisq.test",
        args = function(n) list(w = pwr_w(p), N = n, df = (nrow(p) - 1) * (ncol(p) - 1))
      )
    }
  )
  call$alpha <- spec$target_test$alpha
  call$description <- sprintf("pwr::%s", call$fun)
  call
}

pwr_alternative <- function(alternative) {
  switch(alternative, two_sided = "two.sided", greater = "greater", less = "less")
}

# Cohen's h for p2 versus p1 (positive when p2 > p1).
pwr_h <- function(pop) pwr::ES.h(pop$p2, pop$p1)

# Cohen's w for a table of cell probabilities (independence as the null).
pwr_w <- function(p) pwr::ES.w2(p)

# Power at total sample size n, from the pwr call.
pwr_power <- function(inputs, n) {
  args <- c(inputs$args(n), list(sig.level = inputs$alpha))
  fun <- getExportedValue("pwr", inputs$fun)
  call_backend("pwr", quietly(do.call(fun, args)))$power
}

# Check run: there is no simulated data to recover the population from, so
# the check confirms the effect size pwr receives is the one the spec gives
# (for proportions and tables, Cohen's h and w computed from them).
pwr_check_run <- function(spec, inputs) {
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
    one_sample_t = row("d passed to pwr", pop$d, args$d),
    independent_t = row("d passed to pwr (group 2 minus group 1)", pop$d, args$d),
    paired_t = row("d_z passed to pwr", pop$dz, args$d),
    correlation = row("r passed to pwr", pop$r, args$r),
    two_proportions = row(
      "Cohen's h passed to pwr (2 asin(sqrt(p2)) - 2 asin(sqrt(p1)))",
      2 * asin(sqrt(pop$p2)) - 2 * asin(sqrt(pop$p1)), args$h
    ),
    chi_square_independence = {
      p <- probability_matrix(spec)
      expected <- outer(rowSums(p), colSums(p))
      row("Cohen's w passed to pwr", sqrt(sum((p - expected)^2 / expected)), args$w)
    }
  )
}
