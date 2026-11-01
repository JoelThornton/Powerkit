# Bayesian planning (Labs): for a Bayes factor t-test at a fixed sample
# size, the chance of each outcome (strong evidence for an effect, strong
# evidence for no effect, neither) when the effect is what the planner
# believes and when there is none, with the two priors drawn.
#
# Every probability is bfpwr's (Pawel & Held, 2025, refs.bib bfpwr_method):
# ptbf01() is the distribution function of BF01 under a normal design prior
# N(dpm, dpsd^2) on the true standardised effect, powertbf01() its sample
# size search and tbf01() the Bayes factor itself. bfpwr keeps the analysis
# prior (the one the Bayes factor is computed with: a t prior with location
# `plocation`, scale `pscale` and `pdf` degrees of freedom, so pdf = 1 is
# the Cauchy prior of the JZS Bayes factor) apart from the design prior
# (what the planner believes now), as its vignette "using-bfpwr" explains.
# BF10 = 1 / BF01, so with a threshold k on BF10:
#   strong evidence for an effect   P(BF01 <= 1/k) = ptbf01(1/k)
#   strong evidence for no effect   P(BF01 >= k)   = ptbf01(k, lower.tail = FALSE)
#   neither                         the rest
# The app only draws what this returns.

#' Plan a Bayes factor t-test at a fixed sample size
#'
#' What the Labs Bayesian planning tool shows: for a Bayes factor t-test
#' (the JZS Bayes factor with a Cauchy analysis prior), the chance of strong
#' evidence for an effect, of strong evidence for no effect and of neither,
#' under the planner's belief about the effect (the design prior) and with
#' no effect, all from bfpwr.
#'
#' @param n The sample size: people in each group for two groups, otherwise
#'   people (or pairs). A whole number, at least 3.
#' @param type `"two.sample"`, `"one.sample"` or `"paired"`.
#' @param effect The design prior's centre: the standardised effect (d, or
#'   d_z for paired data) the planner expects.
#' @param effect_sd The design prior's SD: the planner's uncertainty about
#'   the effect (0 plans for exactly `effect`).
#' @param prior_scale The scale of the Cauchy analysis prior (bfpwr's
#'   `pscale`; 1 / sqrt(2) by default, as in bfpwr).
#' @param threshold The Bayes factor counted as strong evidence, either way
#'   (BF10 at least this for an effect, BF01 at least this for none).
#' @param alternative `"two.sided"`, `"greater"` or `"less"`; a one-sided
#'   hypothesis truncates the analysis prior to that direction (bfpwr's
#'   `alternative`).
#' @param target The chance of strong evidence for an effect that the sample
#'   size search aims for.
#' @param grid How many sample sizes the curves are computed at.
#' @return A list: the inputs; `outcomes`, a data frame with one row for
#'   the design prior (`"belief"`) and one for no effect (`"null"`), giving
#'   `for_effect`, `for_null` and `neither`; `largest_bf01`, the most
#'   evidence for no effect the study could give (the BF01 when t = 0; `NA`
#'   for a one-sided test, whose BF01 has no largest value); `n_needed`, the
#'   sample size for `target` (`NA` if over 10,000); `curves`, a data frame
#'   of `n`, `for_effect` (under the design prior) and `for_null` (with no
#'   effect); `priors`, a data frame of effect values `x` with the analysis
#'   prior's and the design prior's densities; `function_used` and
#'   `package`.
#' @export
#' @examples
#' plan <- bayes_planning(120, effect = 0.5, effect_sd = 0.15)
#' plan$outcomes
bayes_planning <- function(n, type = "two.sample", effect = 0.5, effect_sd = 0, prior_scale = 1 / sqrt(2),
                           threshold = 10, alternative = "two.sided", target = 0.8, grid = 30) {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  if (!one_number(n) || n < 3 || n != round(n) || n > 10000) {
    abort_run("'n' should be a whole number of participants between 3 and 10,000.")
  }
  if (!is.character(type) || length(type) != 1 || !type %in% c("two.sample", "one.sample", "paired")) {
    abort_run("'type' should be \"two.sample\", \"one.sample\" or \"paired\".")
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
  if (!is.character(alternative) || length(alternative) != 1 || !alternative %in% c("two.sided", "greater", "less")) {
    abort_run("'alternative' should be \"two.sided\", \"greater\" or \"less\".")
  }
  if (!one_number(target) || target <= 0 || target >= 1) abort_run("'target' should be a chance between 0 and 1.")

  fixed <- list(plocation = 0, pscale = prior_scale, pdf = 1, type = type, alternative = alternative)
  outcome_row <- function(at_n, dpm, dpsd) {
    args <- c(fixed, list(n = at_n, dpm = dpm, dpsd = dpsd))
    for_effect <- call_backend("bfpwr", quietly(do.call(bfpwr::ptbf01, c(list(k = 1 / threshold), args))))
    for_null <- call_backend("bfpwr", quietly(do.call(bfpwr::ptbf01, c(list(k = threshold, lower.tail = FALSE), args))))
    c(for_effect = for_effect, for_null = for_null)
  }
  belief <- outcome_row(n, effect, effect_sd)
  null <- outcome_row(n, 0, 0)
  outcomes <- data.frame(
    truth = c("belief", "null"),
    for_effect = c(belief[["for_effect"]], null[["for_effect"]]),
    for_null = c(belief[["for_null"]], null[["for_null"]])
  )
  outcomes$neither <- pmax(0, 1 - outcomes$for_effect - outcomes$for_null)

  largest <- if (identical(alternative, "two.sided")) {
    call_backend("bfpwr", quietly(do.call(bfpwr::tbf01, c(list(t = 0, n = n), fixed))))
  } else {
    NA_real_
  }
  search <- call_backend("bfpwr", quietly(suppressWarnings(do.call(bfpwr::powertbf01,
    c(list(power = target, k = 1 / threshold, dpm = effect, dpsd = effect_sd, nrange = c(3, 10000)), fixed)))))
  n_needed <- if (is.finite(search$n %||% NA_real_)) ceiling(search$n) else NA_integer_

  top <- max(2 * n, if (is.na(n_needed)) 0 else n_needed, 50)
  sizes <- unique(round(seq(3, top, length.out = grid)))
  chance <- function(m, k, dpm, dpsd, lower) {
    call_backend("bfpwr", quietly(do.call(bfpwr::ptbf01,
      c(fixed, list(k = k, n = m, dpm = dpm, dpsd = dpsd, lower.tail = lower)))))
  }
  curves <- data.frame(
    n = sizes,
    for_effect = vapply(sizes, chance, 0, k = 1 / threshold, dpm = effect, dpsd = effect_sd, lower = TRUE),
    for_null = vapply(sizes, chance, 0, k = threshold, dpm = 0, dpsd = 0, lower = FALSE)
  )

  # The analysis prior is a Cauchy (a t with 1 df) with scale prior_scale,
  # truncated to one side for a one-sided test; the design prior is normal.
  reach <- max(3 * prior_scale, abs(effect) + 3 * effect_sd, 1)
  x <- seq(-reach, reach, length.out = 401)
  analysis <- stats::dt(x / prior_scale, df = 1) / prior_scale
  if (!identical(alternative, "two.sided")) {
    keep <- if (identical(alternative, "greater")) x >= 0 else x <= 0
    analysis <- ifelse(keep, 2 * analysis, 0)
  }
  design <- if (effect_sd > 0) stats::dnorm(x, effect, effect_sd) else rep(NA_real_, length(x))

  list(
    n = n, type = type, effect = effect, effect_sd = effect_sd, prior_scale = prior_scale,
    threshold = threshold, alternative = alternative, target = target,
    outcomes = outcomes, largest_bf01 = largest, n_needed = n_needed, curves = curves,
    priors = data.frame(x = x, analysis = analysis, design = design),
    function_used = sprintf(
      "bfpwr::ptbf01(k = %s and %s, n = %s, pscale = %s, dpm = %s, dpsd = %s, type = \"%s\", alternative = \"%s\")",
      format(signif(1 / threshold, 4)), format(threshold), format(n), format(signif(prior_scale, 4)),
      format(effect), format(effect_sd), type, alternative
    ),
    package = list(name = "bfpwr", version = as.character(utils::packageVersion("bfpwr")))
  )
}
