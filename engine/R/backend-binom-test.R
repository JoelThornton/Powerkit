# The exact binomial test of one proportion with R's binom.test() p-value,
# worked out exactly: power is the probability of every possible count
# times whether binom.test() rejects on it, summed over all counts.
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

# Power of binom.test() at alpha for n people when the true proportion is p.
binom_test_power <- function(n, p, p0, alpha, alternative = "two.sided") {
  x <- 0:n
  sum(stats::dbinom(x, n, p)[binom_test_p(x, n, p0, alternative) <= alpha])
}

binom_test_method <- function(spec) {
  identical(spec$template, "one_proportion") && identical(spec$target_test$method, "binom_test")
}

binom_test_backend <- function(spec, seed = NULL) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  alternative <- switch(spec$target_test$alternative %||% "two_sided", less = "less", greater = "greater", "two.sided")
  power_with <- function(s, n) binom_test_power(n, s$population$p, s$population$p0, alpha, alternative)
  power_at <- function(n) power_with(spec, n)
  list(
    name = "stats",
    packages = "stats",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sprintf("exact sum over every possible count of stats::binom.test(%s)",
      if (identical(alternative, "two.sided")) "" else sprintf("alternative = \"%s\"", alternative))),
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
  c(
    script_header(spec, result, "stats", backend$functions[["exact"]]),
    "# Power is the probability of every possible count times whether R's",
    "# binom.test() rejects on it, summed: no simulation, so no random error.",
    "# binom_test_p() gives binom.test()'s p-value for every count at once; on",
    "# any one count it is the same as binom.test(x, n, p0)$p.value. Two-sided,",
    "# binom.test() adds up every count no more likely than the one observed,",
    "# rather than putting alpha / 2 in each tail.",
    "",
    define("binom_test_p"), define("binom_test_power"),
    goal_inputs(spec, result),
    sprintf("p <- %s # expected proportion", r_code(spec$population$p %||% spec$population$p0)),
    sprintf("p0 <- %s # the fixed value it is compared with (the null hypothesis)", r_code(spec$population$p0)),
    sprintf("alternative <- \"%s\" # binom.test()'s alternative", alternative),
    "power_at <- function(n) binom_test_power(n, p, p0, alpha, alternative)",
    "",
    switch(spec$goal$type,
      sample_size = sawtooth_goal_section(spec, result),
      sensitivity = search_section(result, pwrss_search_plan(spec),
        "# binom.test() gives a p-value, not the effect, so powerkit"),
      pwr_goal_section(spec, result)),
    comparison_section()
  )
}
