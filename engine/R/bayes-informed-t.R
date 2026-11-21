# Bayes factor t-tests with an informed analysis prior: the chance that the
# Bayes factor reaches a threshold, worked out exactly.
#
# The Bayes factor is bfpwr's own tbf01() (Pawel & Held, 2025, the package's
# citation()), a t analysis prior with a location, a scale and degrees of
# freedom (tbf01()'s help: "implemented as in equation (5) in Gronau et al.
# (2020)"). bfpwr's power function, powertbf01(), gives wrong answers for an
# informed prior at small samples (docs/upstream-questions.md, bfpwr question
# 2): power 1 at n = 3 and 5 and 0 at n = 10 where Bayes factors computed
# with tbf01() on simulated t statistics give about 0, 0.7% and 5%. So for
# an informed prior powerkit keeps bfpwr's Bayes factor and works out the
# chance itself:
#
#   1. The Bayes factor depends on the data only through the t statistic.
#      BF01(t) rises to one peak and falls on either side (checked over a
#      fine grid in test-bayes-informed-t.R; tbf01()'s numerical
#      integration wobbles only where BF10 is beyond about e^10, far past
#      any evidence threshold), so each threshold is crossed at most twice. The crossings are found by root-finding on tbf01().
#   2. The t statistic of a study whose true standardised effect is d has a
#      noncentral t distribution: n - 1 degrees of freedom and
#      noncentrality d * sqrt(n) for one sample or pairs (n pairs), 2n - 2
#      and d * sqrt(n / 2) for two groups of n. So the chance of each region
#      is a difference of stats::pt() values.
#   3. With a normal design prior N(dpm, dpsd^2) on d, the chance is
#      averaged over d by stats::integrate().
#
# Nothing is simulated and nothing is approximated beyond numerical
# integration, so the answer has no random error. With the default JZS
# prior (location 0, Cauchy) powerkit still calls powertbf01(), the
# package's own method (bfpwr_power()).

# TRUE when the analysis prior isn't bfpwr's default JZS prior.
bft_informed <- function(inputs) {
  !isTRUE((inputs$prior_location %||% 0) == 0 && (inputs$prior_df %||% 1) == 1)
}

# The t statistic's degrees of freedom and the factor that turns d into its
# noncentrality, at bfpwr's n (per group for two groups).
bft_df <- function(type, n) if (identical(type, "two.sample")) 2 * n - 2 else n - 1
bft_ncp_factor <- function(type, n) if (identical(type, "two.sample")) sqrt(n / 2) else sqrt(n)

# log BF01 at t, by bfpwr::tbf01().
bft_log_bf01 <- function(t, n, inputs) {
  quietly(suppressWarnings(bfpwr::tbf01(
    t = t, n = n, plocation = inputs$prior_location %||% 0, pscale = inputs$prior_scale,
    pdf = inputs$prior_df %||% 1, type = inputs$type, alternative = inputs$alternative, log = TRUE
  )))
}

# Where log BF01 crosses log(level): the peak of BF01 and the crossing on
# each side of it (NA where BF01 doesn't reach the level on that side
# before |t| = 4096, beyond which no study of any size has a measurable
# chance of falling).
bft_crossings <- function(n, inputs, level) {
  f <- function(t) bft_log_bf01(t, n, inputs) - log(level)
  # A one-sided prior can give log BF01 = -Inf far on the wrong side;
  # optimize() then warns and uses a large negative number, which is right.
  peak <- suppressWarnings(stats::optimize(f, c(-50, 50), maximum = TRUE, tol = 1e-8))
  top <- peak$maximum
  above <- peak$objective >= 0
  side <- function(direction) {
    if (!above) {
      return(NA_real_)
    }
    inner <- top
    for (step in 2^(0:12)) {
      outer <- top + direction * step
      if (f(outer) < 0) {
        return(stats::uniroot(f, sort(c(inner, outer)), tol = 1e-10)$root)
      }
      inner <- outer
    }
    NA_real_
  }
  list(peak = top, above = above, lower = side(-1), upper = side(1))
}

# The chance that a study of bfpwr's size n gives BF01 <= level (for_effect,
# BF10 at least 1 / level) or BF01 >= level, when its true effect is d.
bft_region_chance <- function(crossings, df, ncp, for_effect) {
  below <- function(x) if (is.na(x)) 0 else suppressWarnings(stats::pt(x, df, ncp))
  above <- function(x) if (is.na(x)) 0 else suppressWarnings(stats::pt(x, df, ncp, lower.tail = FALSE))
  if (!crossings$above) {
    # BF01 stays below the level everywhere.
    return(if (for_effect) 1 else 0)
  }
  outside <- below(crossings$lower) + above(crossings$upper)
  if (for_effect) outside else 1 - outside
}

#' The chance of a Bayes factor t-test's evidence with an informed prior
#'
#' Exact calculation for a t analysis prior with any location, scale and
#' degrees of freedom: bfpwr's Bayes factor (`bfpwr::tbf01()`), the
#' noncentral t distribution of the t statistic, and a normal design prior
#' on the true effect.
#'
#' @param inputs As `bfpwr_inputs()` gives: `type`, `alternative`,
#'   `threshold`, `prior_location`, `prior_scale`, `prior_df`, `size`.
#' @param n powerkit's total sample size.
#' @param for_effect TRUE for the chance that BF10 reaches the threshold,
#'   FALSE for the chance that BF01 does.
#' @param dpm,dpsd The design prior's mean and SD (dpsd = 0: exactly dpm).
#' @return A probability.
#' @noRd
bft_chance_exact <- function(inputs, n, for_effect = TRUE, dpm = inputs$effect, dpsd = inputs$effect_sd) {
  size <- inputs$size(n)
  level <- if (for_effect) 1 / inputs$threshold else inputs$threshold
  crossings <- bft_crossings(size, inputs, level)
  df <- bft_df(inputs$type, size)
  factor <- bft_ncp_factor(inputs$type, size)
  at <- function(d) bft_region_chance(crossings, df, d * factor, for_effect)
  if (!isTRUE(dpsd > 0)) {
    return(at(dpm))
  }
  integrand <- function(d) vapply(d, at, numeric(1)) * stats::dnorm(d, dpm, dpsd)
  value <- stats::integrate(integrand, dpm - 10 * dpsd, dpm + 10 * dpsd, rel.tol = 1e-8, subdivisions = 200L)$value
  min(max(value, 0), 1)
}

# The R script for a Bayes factor t-test with an informed prior: the same
# exact calculation, written out around bfpwr::tbf01() (export_script()).
bft_script <- function(spec, result, inputs) {
  effect_name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  size_line <- if (identical(inputs$type, "two.sample")) {
    "  n <- n_total / 2 # bfpwr takes the size of each group (equal groups)"
  } else {
    "  n <- n_total"
  }
  c(
    script_header(spec, result, "bfpwr", "bfpwr::tbf01"),
    "library(bfpwr)",
    "",
    "# Inputs ----",
    sprintf("effect <- %s # the expected effect, as %s", r_code(inputs$effect), effect_name),
    sprintf("effect_sd <- %s # uncertainty about it (SD of the normal design prior; 0 = exactly this effect)", r_code(inputs$effect_sd)),
    sprintf("threshold <- %s # evidence threshold: BF10 at least this (BF01 at most 1 / threshold)", r_code(inputs$threshold)),
    sprintf("prior_location <- %s # location of the t analysis prior", r_code(inputs$prior_location)),
    sprintf("prior_scale <- %s # scale of the t analysis prior", r_code(inputs$prior_scale)),
    sprintf("prior_df <- %s # degrees of freedom of the t analysis prior (1 = Cauchy)", r_code(inputs$prior_df)),
    sprintf("type <- %s", r_code(inputs$type)),
    sprintf("alternative <- %s", r_code(inputs$alternative)),
    bayes_goal_inputs(spec),
    "",
    "# bfpwr::powertbf01() is unreliable for an informed prior at small",
    "# samples, so the chance is worked out from bfpwr's own Bayes factor:",
    "# find where BF01 crosses 1 / threshold (it rises to one peak and falls",
    "# on either side), then add up the noncentral t distribution's chance of",
    "# falling beyond those points, averaged over the design prior.",
    "log_bf01 <- function(t, n) {",
    "  tbf01(t = t, n = n, plocation = prior_location, pscale = prior_scale, pdf = prior_df,",
    "    type = type, alternative = alternative, log = TRUE)",
    "}",
    "power_at <- function(n_total) {",
    size_line,
    "  f <- function(t) log_bf01(t, n) - log(1 / threshold)",
    "  peak <- suppressWarnings(optimize(f, c(-50, 50), maximum = TRUE, tol = 1e-8))",
    "  if (peak$objective < 0) return(1) # every study gives BF10 above the threshold",
    "  crossing <- function(direction) {",
    "    inner <- peak$maximum",
    "    for (step in 2^(0:12)) {",
    "      outer <- peak$maximum + direction * step",
    "      if (f(outer) < 0) return(uniroot(f, sort(c(inner, outer)), tol = 1e-10)$root)",
    "      inner <- outer",
    "    }",
    "    NA",
    "  }",
    "  lower <- crossing(-1)",
    "  upper <- crossing(1)",
    "  df <- if (type == \"two.sample\") 2 * n - 2 else n - 1",
    "  m <- if (type == \"two.sample\") sqrt(n / 2) else sqrt(n)",
    "  at <- function(d) {",
    "    (if (is.na(lower)) 0 else pt(lower, df, d * m)) +",
    "      (if (is.na(upper)) 0 else pt(upper, df, d * m, lower.tail = FALSE))",
    "  }",
    "  if (effect_sd == 0) return(at(effect))",
    "  integrate(function(d) vapply(d, at, numeric(1)) * dnorm(d, effect, effect_sd),",
    "    effect - 10 * effect_sd, effect + 10 * effect_sd, rel.tol = 1e-8, subdivisions = 200L)$value",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
