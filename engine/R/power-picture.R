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
