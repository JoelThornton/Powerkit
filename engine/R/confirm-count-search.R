# A smooth power curve cannot capture the jumps of a corrected count test.
# Use it only to propose N, then run fresh studies at each proposed integer N.
# stats::binom.test supplies a one-sided Clopper-Pearson lower bound. Allocate
# a total .01 error budget over at most ten checks (Bonferroni/union bound),
# including checks that were not needed. No minimum-N or universal assurance
# is implied: this deliberately trades some sample efficiency for protection
# against Monte Carlo selection of an underpowered N under the given model.
confirm_count_search <- function(spec, backend, found, nrep, seed, cores,
                                 max_checks = 10L, error_budget = .01) {
  target <- spec$goal$power
  step <- backend$n_step
  cap <- step * floor((backend$n_max %||% 1e5) / step)
  n <- found$n_required$n
  checks <- found$simulations[FALSE, ]
  confirmation_nrep <- max(10000L, nrep)
  confidence <- 1 - error_budget / max_checks
  for (i in seq_len(max_checks)) {
    if (!is.finite(n) || n > cap) break
    check_seed <- offset_seed(seed, 10007 * (nrow(found$simulations) + i))
    fresh <- power_at_n(backend, n, TRUE, confirmation_nrep, check_seed, cores)
    record <- fresh$simulations
    record$fitted <- FALSE
    checks <- rbind(checks, record)
    lower <- unname(stats::binom.test(record$rejections, record$nrep,
      alternative = "greater", conf.level = confidence)$conf.int[1])
    if (lower >= target) {
      original <- found$n_required
      found$n_required <- list(n = n, lower = NA_real_, upper = NA_real_,
        power = fresh$curve$power, power_lower = lower, power_upper = 1,
        search_estimate = original,
        verification = list(type = "fresh_count_simulation", target = target,
          nrep = confirmation_nrep, max_checks = max_checks,
          error_budget = error_budget, confidence_per_check = confidence,
          checks = nrow(checks), lower = lower))
      found$simulations$stage <- "search"
      checks$stage <- "confirmation"
      found$simulations <- rbind(found$simulations, checks)
      return(found)
    }
    # Do not assume monotonicity or interpolate between discrete tests.
    # Only a sample size actually checked can be returned.
    n <- n + step * max(1, ceiling(.05 * n / step))
  }
  abort_run(paste("The corrected count-test search could not confirm the target power within its checking limit.",
    "No sample size is recommended. Check power at larger specified sample sizes, or reconsider your assumptions."))
}
