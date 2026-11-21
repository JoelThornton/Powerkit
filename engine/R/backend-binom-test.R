# Tests of one proportion whose power is worked out exactly over the
# counts: power is the probability of every possible count times whether
# the test rejects on it, summed over all counts. Two tests run this way:
# the exact binomial test with R's binom.test() p-value (method
# "binom_test"), and the z test of one proportion, R's prop.test(), without
# or with its continuity correction ("z_test", "z_test_corrected").
#
# Two-sided exact binomial tests differ in how they form the p-value.
# pwrss's power.exact.oneprop() (the default route, backend-pwrss.R) puts
# alpha / 2 in each tail. R's stats::binom.test() instead adds up the
# probability of every count no more likely than the one observed (with a
# relative tolerance of 1e-7), so its two tails need not hold alpha / 2
# each. No package computes power for binom.test()'s rule, so it is summed
# here from binom.test() itself, as backend-corrected-exact.R does for
# prop.test(). binom_test_p() is binom.test()'s p-value written for every
# count at once, checked against binom.test() on every count in
# test-backend-binom-test.R; no approximation to power is used. One-sided,
# binom.test() is the usual one-tailed exact test.
#
# The z test (the score test: the difference from p0 over its standard
# error under p0, or its square, a chi-square on 1 degree of freedom, as
# prop.test() reports it) is usually planned with a normal approximation
# to its power, as pwrss's power.z.oneprop() does. Its decisions are made
# on whole counts, so its real power is a sum over them, as for the exact
# tests; pwrss's approximation differs from that sum by a few
# percentage points either way (83.0% against 80.1% at 94 people for 20%
# against 10%; test-backend-binom-test.R), and
# the continuity correction often changes no decision at all at a given
# n. So powerkit sums prop.test()'s own decisions: prop_test_p() is
# prop.test()'s p-value for every count at once, checked against
# prop.test() on every count in test-backend-binom-test.R (powerkit's
# Departure 36, conventions.md).
#
# Power goes up and down with n for tests of counts, so the sample-size
# search checks every n below the bisection's answer (`sawtooth`).

# binom.test()'s p-value for each count x of n, against the proportion p0,
# vectorised over x: the same steps as stats::binom.test() (R 4.5).
binom_test_p <- function(x, n, p0, alternative = "two.sided") {
  if (identical(alternative, "less")) return(stats::pbinom(x, n, p0))
  if (identical(alternative, "greater")) return(stats::pbinom(x - 1, n, p0, lower.tail = FALSE))
  rel_err <- 1 + 1e-7
  d <- stats::dbinom(x, n, p0)
  m <- n * p0
  p <- rep(1, length(x))
  if (m > 0 && m < n) {
    # Densities on the far side of the mean, sorted, so the counts of those
    # no larger than d * rel_err come from findInterval() (which counts the
    # values at or below each point, as binom.test()'s sum(... <= ...) does).
    upper <- sort(stats::dbinom(seq.int(ceiling(m), n), n, p0))
    lower <- sort(stats::dbinom(seq.int(0, floor(m)), n, p0))
    below <- x < m
    above <- x > m
    y <- findInterval(d[below] * rel_err, upper)
    p[below] <- stats::pbinom(x[below], n, p0) + stats::pbinom(n - y, n, p0, lower.tail = FALSE)
    y <- findInterval(d[above] * rel_err, lower)
    p[above] <- stats::pbinom(y - 1, n, p0) + stats::pbinom(x[above] - 1, n, p0, lower.tail = FALSE)
  }
  pmin(1, p)
}

# prop.test()'s p-value for each count x of n against p0, vectorised over
# x: the same steps as stats::prop.test() with one proportion (R 4.5). The
# statistic is the chi-square over the two cells (yes and no), with Yates'
# correction of up to 0.5 when `correct`; one-sided, its signed square
# root against the normal.
prop_test_p <- function(x, n, p0, alternative = "two.sided", correct = FALSE) {
  yates <- if (correct) pmin(0.5, abs(x - n * p0)) else 0
  statistic <- (abs(x - n * p0) - yates)^2 * (1 / (n * p0) + 1 / (n * (1 - p0)))
  if (identical(alternative, "two.sided")) return(stats::pchisq(statistic, 1, lower.tail = FALSE))
  z <- sign(x / n - p0) * sqrt(statistic)
  stats::pnorm(z, lower.tail = identical(alternative, "less"))
}

# A test's p-value for every count: binom.test() or prop.test().
one_proportion_p <- function(test) {
  switch(test,
    binom_test = function(x, n, p0, alternative) binom_test_p(x, n, p0, alternative),
    z_test = function(x, n, p0, alternative) prop_test_p(x, n, p0, alternative, correct = FALSE),
    z_test_corrected = function(x, n, p0, alternative) prop_test_p(x, n, p0, alternative, correct = TRUE)
  )
}

# Power of the test at alpha for n people when the true proportion is p.
binom_test_power <- function(n, p, p0, alpha, alternative = "two.sided", test = "binom_test") {
  x <- 0:n
  sum(stats::dbinom(x, n, p)[one_proportion_p(test)(x, n, p0, alternative) <= alpha])
}

# The one-proportion tests run by summing over the counts.
summed_proportion_tests <- c("binom_test", "z_test", "z_test_corrected")

binom_test_method <- function(spec) {
  identical(spec$template, "one_proportion") && isTRUE(spec$target_test$method %in% summed_proportion_tests)
}

# How the backend and the script name each test.
one_proportion_call <- function(test, alternative) {
  side <- if (identical(alternative, "two.sided")) "" else sprintf("alternative = \"%s\"", alternative)
  switch(test,
    binom_test = sprintf("stats::binom.test(%s)", side),
    z_test = sprintf("stats::prop.test(%s)", paste(c(if (nzchar(side)) side, "correct = FALSE"), collapse = ", ")),
    z_test_corrected = sprintf("stats::prop.test(%s)", paste(c(if (nzchar(side)) side, "correct = TRUE"), collapse = ", "))
  )
}

binom_test_backend <- function(spec, seed = NULL) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  alternative <- switch(spec$target_test$alternative %||% "two_sided", less = "less", greater = "greater", "two.sided")
  test <- spec$target_test$method
  power_with <- function(s, n) binom_test_power(n, s$population$p, s$population$p0, alpha, alternative, test)
  power_at <- function(n) power_with(spec, n)
  list(
    name = "stats",
    packages = "stats",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sprintf("exact sum over every possible count of %s", one_proportion_call(test, alternative))),
    n_step = 1,
    exact_min_n = max(minimum_n(spec), 2),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    # The smallest detectable proportion, searched with this power as the
    # pwrss route searches its own (pwrss_search_plan(), the same grid).
    sensitivity = function(n, target) {
      plan <- pwrss_search_plan(spec)
      at <- function(x) power_with(plan$set(spec, x), n)
      found <- pwrss_search_root(at, plan$grid, target)
      if (is.na(found)) {
        abort_run("No effect in the range Powerkit searches reaches the target power at this sample size: try a larger sample or a lower target power.")
      }
      list(effect = plan$effect(found), effect_name = plan$effect_name, effect_description = sprintf("the %s", plan$what),
        power = at(found), searched = TRUE)
    },
    sawtooth = TRUE,
    check_run = function() data.frame(parameter = character(), specified = numeric(), recovered = numeric(), ok = logical())
  )
}

# The standalone script: binom.test()'s p-value for every count, written out
# so the script needs only base R, then the goal as for other exact tests of
# counts.
binom_test_script <- function(spec, result) {
  backend <- binom_test_backend(spec)
  define <- function(name) c(paste(name, "<-", paste(deparse(get(name, mode = "function"), width.cutoff = 100L), collapse = "\n")), "")
  alternative <- switch(spec$target_test$alternative %||% "two_sided", less = "less", greater = "greater", "two.sided")
  test <- spec$target_test$method
  about <- if (identical(test, "binom_test")) c(
    "# Power is the probability of every possible count times whether R's",
    "# binom.test() rejects on it, summed: no simulation, so no random error.",
    "# binom_test_p() gives binom.test()'s p-value for every count at once; on",
    "# any one count it is the same as binom.test(x, n, p0)$p.value. Two-sided,",
    "# binom.test() adds up every count no more likely than the one observed,",
    "# rather than putting alpha / 2 in each tail."
  ) else c(
    "# Power is the probability of every possible count times whether R's",
    "# prop.test() (the z test of one proportion) rejects on it, summed: no",
    "# simulation, so no random error, and no normal approximation to power.",
    sprintf("# prop_test_p() gives prop.test(x, n, p0, correct = %s)$p.value for", if (identical(test, "z_test_corrected")) "TRUE" else "FALSE"),
    "# every count at once."
  )
  c(
    script_header(spec, result, "stats", backend$functions[["exact"]]),
    about,
    "",
    define("binom_test_p"), define("prop_test_p"), define("one_proportion_p"), define("binom_test_power"),
    goal_inputs(spec, result),
    sprintf("p <- %s # expected proportion", r_code(spec$population$p %||% spec$population$p0)),
    sprintf("p0 <- %s # the fixed value it is compared with (the null hypothesis)", r_code(spec$population$p0)),
    sprintf("alternative <- \"%s\" # the test's alternative", alternative),
    sprintf("test <- \"%s\" # %s", test, one_proportion_call(test, alternative)),
    "power_at <- function(n) binom_test_power(n, p, p0, alpha, alternative, test)",
    "",
    switch(spec$goal$type,
      sample_size = sawtooth_goal_section(spec, result),
      sensitivity = search_section(result, pwrss_search_plan(spec),
        sprintf("# %s gives a p-value, not the effect, so powerkit", if (identical(test, "binom_test")) "binom.test()" else "prop.test()")),
      pwr_goal_section(spec, result)),
    comparison_section()
  )
}
