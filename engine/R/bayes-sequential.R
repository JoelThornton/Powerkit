# Sequential Bayes factor designs (Labs): the Bayes factor is checked as the
# data come in, and the study stops at the first look where it passes the
# threshold for an effect or for no effect, or at the maximum sample size.
# This is the design Schonbrodt, Wagenmakers, Zehetleitner and Perugini
# (2017, refs.bib Schonbrodt2017_sequential) call the Sequential Bayes
# Factor, with the maximum sample size of Schonbrodt and Wagenmakers (2018,
# refs.bib SchonbrodtWagenmakers2018_bfda), and it is planned as they plan
# it: by Monte Carlo simulation, with the true effect drawn from the design
# prior in every simulated study, and again with no effect.
#
# The Bayes factor is bfpwr's tbf01() (the JZS Bayes factor, a Cauchy
# analysis prior; bfpwr has no sequential functions). It depends on the data
# only through the t statistic and the sample size, and it grows with t (with
# |t| for a two-sided test), so at each look the two thresholds are two
# values of t, found once with tbf01() and uniroot(). A simulated study then
# stops when its t passes one of them. This gives the same decisions as
# computing tbf01() at every look of every study (test-bayes-sequential.R
# checks it), in a fraction of the time. No new maths: the Bayes factor is
# bfpwr's, the procedure is the published one, and the simulated data are
# normal scores.

#' Plan a sequential Bayes factor t-test
#'
#' What the Labs sequential Bayesian planning tool shows: a Bayes factor
#' t-test checked after every `step` participants (in each group, for two
#' groups) from `n_min` on, stopping when the Bayes factor reaches
#' `threshold` for an effect or `threshold_null` for no effect, or at
#' `n_max`. The chances of each ending and the sample size at the stop are
#' simulated under the planner's belief about the effect (a normal design
#' prior, drawn afresh for every simulated study) and with no effect, as in
#' Schonbrodt and Wagenmakers (2018). Every Bayes factor is bfpwr's
#' `tbf01()`.
#'
#' @param n_min The sample size at the first look (in each group, for two
#'   groups). A whole number, at least 3 (at least 2 in each group).
#' @param n_max The largest sample size: the study stops here whatever the
#'   Bayes factor. At least `n_min`, at most 10,000.
#' @param step How many participants (in each group, for two groups) are
#'   added between looks. 1 checks after every participant.
#' @param type `"two.sample"`, `"one.sample"` or `"paired"`.
#' @param effect,effect_sd The design prior: the standardised effect the
#'   planner expects (d, or d_z for paired data) and their uncertainty about
#'   it (an SD; 0 for exactly `effect`).
#' @param prior_scale The scale of the Cauchy analysis prior (bfpwr's
#'   `pscale`).
#' @param threshold The BF10 that counts as strong evidence for an effect.
#' @param threshold_null The BF01 that counts as strong evidence for no
#'   effect (the same as `threshold` unless set).
#' @param alternative `"two.sided"`, `"greater"` or `"less"`.
#' @param nsim How many studies are simulated under the belief, and again
#'   with no effect.
#' @param seed The random seed, recorded with the result.
#' @return A list: the inputs; `looks`, a data frame of each look's sample
#'   size `n` with the t statistics at which the Bayes factor passes each
#'   threshold (`t_effect`, `t_null`; in the direction of the hypothesis,
#'   and as |t| for a two-sided test; `NA` where a threshold can't be
#'   reached at that look); `outcomes`, a data frame with one row for the
#'   belief and one for no effect, giving the chance the study stops with
#'   strong evidence for an effect (`for_effect`), for no effect
#'   (`for_null`) or at the maximum (`at_max`), the chances at the maximum
#'   that the final BF10 is above 3 (`at_max_toward_effect`), below 1/3
#'   (`at_max_toward_null`) or between, the mean, median and 80th
#'   percentile of the sample size at the stop, and the Monte Carlo
#'   standard error of `for_effect`; `stops`, the number of simulated
#'   studies stopping at each look; `fixed`, bfpwr's chances for a single
#'   test at `n_max` (`ptbf01()`), for comparison; `nsim`, `seed`;
#'   `priors`, the two priors' densities as [bayes_planning()] gives them;
#'   `method`, `function_used` and `package`.
#' @export
#' @examples
#' \donttest{
#' plan <- bayes_sequential(n_min = 20, n_max = 100, effect = 0.5, effect_sd = 0.1, nsim = 500)
#' plan$outcomes
#' }
bayes_sequential <- function(n_min = 20, n_max = 200, step = 1, type = "two.sample", effect = 0.5, effect_sd = 0,
                             prior_scale = 1 / sqrt(2), threshold = 10, threshold_null = threshold,
                             alternative = "two.sided", nsim = 2000, seed = 1) {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x) one_number(x) && x == round(x)
  if (!is.character(type) || length(type) != 1 || !type %in% c("two.sample", "one.sample", "paired")) {
    abort_run("'type' should be \"two.sample\", \"one.sample\" or \"paired\".")
  }
  if (!whole(n_min) || n_min < 3 || n_min > 10000) {
    abort_run("'n_min' (the first look) should be a whole number of participants between 3 and 10,000.")
  }
  if (!whole(n_max) || n_max < n_min || n_max > 10000) {
    abort_run("'n_max' (the largest sample size) should be a whole number, at least the first look and at most 10,000.")
  }
  if (!whole(step) || step < 1) abort_run("'step' (participants between looks) should be a whole number, at least 1.")
  looks <- unique(c(seq(n_min, n_max, by = step), n_max))
  if (length(looks) > 2000) {
    abort_run(sprintf("'step' (participants between looks) gives %s looks; powerkit checks at most 2,000. Look less often, or lower the largest sample size.",
      format(length(looks), big.mark = ",")))
  }
  if (!one_number(effect) || abs(effect) > 5) abort_run("'effect' should be a standardised effect between -5 and 5.")
  if (!one_number(effect_sd) || effect_sd < 0 || effect_sd > 5) {
    abort_run("'effect_sd' (the uncertainty about the effect) should be 0 or more, and at most 5.")
  }
  if (!one_number(prior_scale) || prior_scale <= 0 || prior_scale > 5) {
    abort_run("'prior_scale' should be more than 0, and at most 5.")
  }
  if (!one_number(threshold) || threshold <= 1 || threshold > 1000) {
    abort_run("'threshold' should be a Bayes factor above 1, and at most 1,000.")
  }
  if (!one_number(threshold_null) || threshold_null <= 1 || threshold_null > 1000) {
    abort_run("'threshold_null' (the threshold for no effect) should be a Bayes factor above 1, and at most 1,000.")
  }
  if (!is.character(alternative) || length(alternative) != 1 || !alternative %in% c("two.sided", "greater", "less")) {
    abort_run("'alternative' should be \"two.sided\", \"greater\" or \"less\".")
  }
  if (!whole(nsim) || nsim < 100 || nsim > 1e5) abort_run("'nsim' (simulated studies) should be a whole number between 100 and 100,000.")
  if (!whole(seed)) abort_run("'seed' should be a whole number.")

  bounds <- call_backend("bfpwr", sequential_bounds(looks, type, alternative, prior_scale,
    c(effect = log(threshold), null = -log(threshold_null), toward_effect = log(3), toward_null = -log(3))))

  sim <- with_seed(seed, list(
    belief = simulate_sequential(nsim, looks, bounds, type, alternative, effect, effect_sd),
    null = simulate_sequential(nsim, looks, bounds, type, alternative, 0, 0)
  ))
  summarise <- function(s, truth) {
    at_max <- s$outcome == "max"
    split <- threshold > 3 && threshold_null > 3
    data.frame(
      truth = truth,
      for_effect = mean(s$outcome == "effect"), for_null = mean(s$outcome == "null"), at_max = mean(at_max),
      at_max_toward_effect = if (split) mean(at_max & s$last == "toward_effect") else NA_real_,
      at_max_toward_null = if (split) mean(at_max & s$last == "toward_null") else NA_real_,
      at_max_neither = if (split) mean(at_max & s$last == "neither") else NA_real_,
      n_mean = mean(s$n), n_median = stats::median(s$n), n_80 = unname(stats::quantile(s$n, 0.8, type = 1)),
      mcse_for_effect = sqrt(mean(s$outcome == "effect") * (1 - mean(s$outcome == "effect")) / nsim)
    )
  }
  outcomes <- rbind(summarise(sim$belief, "belief"), summarise(sim$null, "null"))
  stops <- rbind(
    data.frame(truth = "belief", n = looks, count = tabulate(match(sim$belief$n, looks), length(looks))),
    data.frame(truth = "null", n = looks, count = tabulate(match(sim$null$n, looks), length(looks)))
  )

  # One test at n_max, for comparison: bfpwr's own closed form.
  fixed_args <- list(n = n_max, plocation = 0, pscale = prior_scale, pdf = 1, type = type, alternative = alternative)
  fixed_chance <- function(k, dpm, dpsd, lower) {
    call_backend("bfpwr", quietly(do.call(bfpwr::ptbf01, c(fixed_args, list(k = k, dpm = dpm, dpsd = dpsd, lower.tail = lower)))))
  }
  fixed <- data.frame(
    truth = c("belief", "null"),
    for_effect = c(fixed_chance(1 / threshold, effect, effect_sd, TRUE), fixed_chance(1 / threshold, 0, 0, TRUE)),
    for_null = c(fixed_chance(threshold_null, effect, effect_sd, FALSE), fixed_chance(threshold_null, 0, 0, FALSE))
  )

  list(
    n_min = n_min, n_max = n_max, step = step, type = type, effect = effect, effect_sd = effect_sd,
    prior_scale = prior_scale, threshold = threshold, threshold_null = threshold_null, alternative = alternative,
    looks = data.frame(n = looks, t_effect = bounds$effect, t_null = bounds$null),
    outcomes = outcomes, stops = stops, fixed = fixed, nsim = nsim, seed = seed,
    priors = bayes_prior_densities(effect, effect_sd, prior_scale, alternative),
    method = paste(
      "Monte Carlo simulation of the Sequential Bayes Factor design with a maximum sample size (Schonbrodt et al., 2017;",
      "Schonbrodt & Wagenmakers, 2018): normal scores, the true effect drawn from the design prior for each simulated study,",
      "and the JZS Bayes factor from bfpwr::tbf01() at every look."
    ),
    function_used = sprintf(
      "powerkit::bayes_sequential(n_min = %s, n_max = %s, step = %s, type = \"%s\", effect = %s, effect_sd = %s, prior_scale = %s, threshold = %s, threshold_null = %s, alternative = \"%s\", nsim = %s, seed = %s)",
      format(n_min), format(n_max), format(step), type, format(effect), format(effect_sd), format(signif(prior_scale, 4)),
      format(threshold), format(threshold_null), alternative, format(nsim), format(seed)
    ),
    package = list(name = "bfpwr", version = as.character(utils::packageVersion("bfpwr")))
  )
}

# At each look, the t statistics at which log BF10 reaches each target (in
# the hypothesis's direction; |t| when two-sided). log BF10 grows with that t,
# so each root is bracketed by stepping from a start (the previous look's
# root, which moves little) and then found with uniroot(). The study stops
# for an effect when its t is at or above the effect root, and for no effect
# at or below the null root. `NA` when a target can't be reached: within
# |t| <= 12, or before tbf01()'s numerical integration stops growing (far in
# the wrong direction of a one-sided test, where BF01 is already huge), or
# for no effect in a two-sided test when even t = 0 doesn't give it.
sequential_bounds <- function(looks, type, alternative, prior_scale, targets) {
  sgn <- if (identical(alternative, "less")) -1 else 1
  lower <- if (identical(alternative, "two.sided")) 0 else -12
  log_bf10 <- function(t, n) {
    -quietly(suppressWarnings(bfpwr::tbf01(t = sgn * t, n = n, plocation = 0, pscale = prior_scale, pdf = 1,
      type = type, alternative = alternative, log = TRUE)))
  }
  root <- function(n, target, start) {
    f <- function(t) log_bf10(t, n) - target
    a <- max(lower, start)
    fa <- f(a)
    if (!is.finite(fa)) return(NA_real_)
    dir <- if (fa < 0) 1 else -1
    repeat {
      b <- a + dir * 0.25
      if (b > 12) return(NA_real_)
      if (b < lower) {
        # Past the target even at the lowest t: an effect is always found
        # (two-sided, t = 0 already enough), no effect never is.
        return(if (target >= 0 && identical(lower, 0)) 0 else NA_real_)
      }
      fb <- f(b)
      if (!is.finite(fb) || (fb - fa) * dir < 0) return(NA_real_)
      if ((fb >= 0) != (fa >= 0)) {
        ends <- if (a < b) c(a, b) else c(b, a)
        values <- if (a < b) c(fa, fb) else c(fb, fa)
        return(stats::uniroot(f, ends, f.lower = values[1], f.upper = values[2], tol = 1e-7)$root)
      }
      a <- b
      fa <- fb
    }
  }
  out <- lapply(targets, function(target) {
    previous <- 0
    vapply(looks, function(n) {
      r <- root(n, target, previous)
      if (!is.na(r)) previous <<- r
      r
    }, 0)
  })
  as.data.frame(out)
}

# nsim studies, each followed from look to look: the t statistic at each look
# from running sums of normal scores (SD 1; the true effect added to the first
# group, or to every score for one group or pairs), stopping at the first look
# past a threshold. `last` places the final Bayes factor of a study stopping
# at the maximum: above 3, below 1/3, or between.
simulate_sequential <- function(nsim, looks, bounds, type, alternative, effect, effect_sd) {
  d <- stats::rnorm(nsim, effect, effect_sd)
  two_groups <- identical(type, "two.sample")
  s1 <- q1 <- s2 <- q2 <- numeric(nsim)
  outcome <- rep(NA_character_, nsim)
  stop_n <- rep(NA_real_, nsim)
  last <- rep(NA_character_, nsim)
  current <- 0
  orient <- function(t) if (identical(alternative, "two.sided")) abs(t) else if (identical(alternative, "less")) -t else t
  past <- function(u, limit, dir) if (is.na(limit)) rep(FALSE, length(u)) else if (dir > 0) u >= limit else u <= limit
  for (j in seq_along(looks)) {
    open <- which(is.na(outcome))
    if (!length(open)) break
    for (i in seq_len(looks[j] - current)) {
      x <- stats::rnorm(length(open), d[open])
      s1[open] <- s1[open] + x
      q1[open] <- q1[open] + x^2
      if (two_groups) {
        y <- stats::rnorm(length(open))
        s2[open] <- s2[open] + y
        q2[open] <- q2[open] + y^2
      }
    }
    current <- looks[j]
    n <- current
    m1 <- s1[open] / n
    t <- if (two_groups) {
      m2 <- s2[open] / n
      pooled <- ((q1[open] - n * m1^2) + (q2[open] - n * m2^2)) / (2 * n - 2)
      (m1 - m2) / sqrt(pooled * 2 / n)
    } else {
      m1 / sqrt((q1[open] - n * m1^2) / (n - 1) / n)
    }
    u <- orient(t)
    for_effect <- past(u, bounds$effect[j], 1)
    for_null <- !for_effect & past(u, bounds$null[j], -1)
    outcome[open[for_effect]] <- "effect"
    outcome[open[for_null]] <- "null"
    stop_n[open[for_effect | for_null]] <- n
    if (j == length(looks)) {
      rest <- !(for_effect | for_null)
      outcome[open[rest]] <- "max"
      stop_n[open[rest]] <- n
      last[open[rest]] <- ifelse(past(u[rest], bounds$toward_effect[j], 1), "toward_effect",
        ifelse(past(u[rest], bounds$toward_null[j], -1), "toward_null", "neither"))
    }
  }
  list(outcome = outcome, n = stop_n, last = last)
}
