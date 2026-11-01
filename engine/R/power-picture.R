# The picture of power (Labs): for a two-group t-test, the central t
# distribution (no effect) and the noncentral t (the effect), with the
# numbers behind the picture. Power is pwr's (pwr.t.test()); the curves are
# base R's t densities (stats::dt()); the smallest significant d is the
# critical t times sqrt(1 / n1 + 1 / n2) (Lakens, 2013, equation 2; refs.bib
# Lakens2013_effectsizes). The app only draws what this returns.

#' The picture of power for a two-group t-test
#'
#' What the Labs picture of power draws: the t distribution when there is
#' no effect and when the effect is `d`, the critical values, and the
#' numbers behind them, for two equal groups.
#'
#' @param n The total number of participants, split into two equal groups
#'   (an even number, at least 4).
#' @param d Cohen's d, the effect in the population (0 or more).
#' @param alpha The significance level of the two-sided test.
#' @param points How many points of each curve to return.
#' @return A list: `n`, `d`, `alpha`, `power` (pwr's `pwr.t.test()`),
#'   `beta` (1 - power), `df`, `ncp` (the noncentrality, d sqrt(n / 4)),
#'   `t_crit` (the two-sided critical t), `d_crit` (the smallest observed d
#'   that would be significant), `curves` (a data frame of `t`, `null` and
#'   `alternative` densities), `function_used` and `package`.
#' @export
#' @examples
#' picture <- power_picture(64, 0.5)
#' picture$power
power_picture <- function(n, d, alpha = 0.05, points = 401) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 4 || n %% 2 != 0) {
    abort_run("'n' should be an even number of participants, at least 4, split into two equal groups.")
  }
  if (!is.numeric(d) || length(d) != 1 || is.na(d) || d < 0) {
    abort_run("'d' should be a Cohen's d of 0 or more.")
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || is.na(alpha) || alpha <= 0 || alpha >= 0.5) {
    abort_run("'alpha' should be between 0 and 0.5.")
  }
  n_group <- n / 2
  df <- n - 2
  ncp <- d * sqrt(n_group / 2)
  power <- pwr::pwr.t.test(n = n_group, d = d, sig.level = alpha, type = "two.sample", alternative = "two.sided")$power
  t_crit <- stats::qt(1 - alpha / 2, df)
  # The curves cover both critical values and most of the alternative.
  from <- min(-4, -t_crit - 1)
  to <- max(4, t_crit + 1, ncp + 4)
  t <- seq(from, to, length.out = points)
  list(
    n = n, d = d, alpha = alpha, power = power, beta = 1 - power, df = df, ncp = ncp, t_crit = t_crit,
    d_crit = t_crit * sqrt(1 / n_group + 1 / n_group),
    curves = data.frame(t = t, null = stats::dt(t, df), alternative = stats::dt(t, df, ncp = ncp)),
    function_used = sprintf("pwr::pwr.t.test(n = %s, d = %s, sig.level = %s)", format(n_group), format(d), format(alpha)),
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}


# The correlation (Labs): on the scale of Fisher's z, the sampling
# distribution of the observed correlation when there is none and when it
# is r, as pwr.r.test() computes power: each normal with SD 1 / sqrt(n -
# 3), centred on 0 and on atanh(r) + r / (2 (n - 1)), with the critical
# value atanh(r_crit), where r_crit = t_crit / sqrt(t_crit^2 + n - 2) is
# the critical correlation of the t test with n - 2 df (pwr 1.3-0's
# source for pwr.r.test()). Power is pwr's; the curves are base R's
# normal densities (stats::dnorm()).

#' The picture of power for a correlation
#'
#' What the Labs picture of power draws for a Pearson correlation: the
#' sampling distribution of the observed correlation, on the scale of
#' Fisher's z, when there is no correlation and when it is `r`, with the
#' critical values and the numbers behind them, as pwr's `pwr.r.test()`
#' computes power (two-sided).
#'
#' @param n The number of participants (at least 4).
#' @param r The correlation in the population (0 or more, below 1).
#' @param alpha The significance level of the two-sided test.
#' @param points How many points of each curve to return.
#' @return A list: `n`, `r`, `alpha`, `power` (pwr's `pwr.r.test()`),
#'   `beta` (1 - power), `df` (n - 2), `se` (1 / sqrt(n - 3)), `z_r` (the
#'   centre of the alternative, atanh(r) + r / (2 (n - 1))), `t_crit` (the
#'   two-sided critical t), `r_crit` (the smallest observed r that would be
#'   significant), `z_crit` (atanh(r_crit)), `curves` (a data frame of `z`,
#'   `null` and `alternative` densities), `function_used` and `package`.
#' @export
#' @examples
#' picture <- power_picture_r(84, 0.3)
#' picture$power
power_picture_r <- function(n, r, alpha = 0.05, points = 401) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 4 || n %% 1 != 0) {
    abort_run("'n' should be a whole number of participants, at least 4.")
  }
  if (!is.numeric(r) || length(r) != 1 || is.na(r) || r < 0 || r >= 1) {
    abort_run("'r' should be a correlation of 0 or more, below 1.")
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || is.na(alpha) || alpha <= 0 || alpha >= 0.5) {
    abort_run("'alpha' should be between 0 and 0.5.")
  }
  df <- n - 2
  se <- 1 / sqrt(n - 3)
  power <- pwr::pwr.r.test(n = n, r = r, sig.level = alpha, alternative = "two.sided")$power
  t_crit <- stats::qt(1 - alpha / 2, df)
  r_crit <- t_crit / sqrt(t_crit^2 + df)
  z_crit <- atanh(r_crit)
  z_r <- atanh(r) + r / (2 * (n - 1))
  from <- min(-4 * se, -z_crit - se)
  to <- max(4 * se, z_crit + se, z_r + 4 * se)
  z <- seq(from, to, length.out = points)
  list(
    n = n, r = r, alpha = alpha, power = power, beta = 1 - power, df = df, se = se, z_r = z_r,
    t_crit = t_crit, r_crit = r_crit, z_crit = z_crit,
    curves = data.frame(z = z, null = stats::dnorm(z, 0, se), alternative = stats::dnorm(z, z_r, se)),
    function_used = sprintf("pwr::pwr.r.test(n = %s, r = %s, sig.level = %s)", format(n), format(r), format(alpha)),
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}
