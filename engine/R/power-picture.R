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


# Shared input checks for the pictures below.
picture_check <- function(alpha) {
  if (!is.numeric(alpha) || length(alpha) != 1 || is.na(alpha) || alpha <= 0 || alpha >= 0.5) {
    abort_run("'alpha' should be between 0 and 0.5.")
  }
}

# The paired-samples t-test (Labs): the central and noncentral t with
# n - 1 df, the noncentrality d_z sqrt(n), as pwr.t.test(type = "paired")
# computes power; the smallest significant d_z is the critical t over
# sqrt(n), since a paired t is the mean difference over its standard
# error, SD / sqrt(n), so t = d_z sqrt(n).

#' The picture of power for a paired-samples t-test
#'
#' What the Labs picture of power draws for a paired-samples (or
#' one-sample) t-test: the t distribution when there is no effect and when
#' the effect is `dz`, the critical values, and the numbers behind them.
#'
#' @param n The number of participants (pairs), at least 3.
#' @param dz Cohen's d_z, the mean difference over the SD of the
#'   differences (0 or more).
#' @param alpha The significance level of the two-sided test.
#' @param points How many points of each curve to return.
#' @return A list: `n`, `dz`, `alpha`, `power` (pwr's `pwr.t.test()`,
#'   `type = "paired"`), `beta`, `df` (n - 1), `ncp` (d_z sqrt(n)),
#'   `t_crit`, `dz_crit` (the smallest observed d_z that would be
#'   significant), `curves` (a data frame of `t`, `null` and `alternative`
#'   densities), `function_used` and `package`.
#' @export
#' @examples
#' picture <- power_picture_paired(34, 0.5)
#' picture$power
power_picture_paired <- function(n, dz, alpha = 0.05, points = 401) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 3 || n %% 1 != 0) {
    abort_run("'n' should be a whole number of participants, at least 3.")
  }
  if (!is.numeric(dz) || length(dz) != 1 || is.na(dz) || dz < 0) {
    abort_run("'dz' should be a Cohen's d_z of 0 or more.")
  }
  picture_check(alpha)
  df <- n - 1
  ncp <- dz * sqrt(n)
  power <- pwr::pwr.t.test(n = n, d = dz, sig.level = alpha, type = "paired", alternative = "two.sided")$power
  t_crit <- stats::qt(1 - alpha / 2, df)
  from <- min(-4, -t_crit - 1)
  to <- max(4, t_crit + 1, ncp + 4)
  t <- seq(from, to, length.out = points)
  list(
    design = "paired", n = n, dz = dz, alpha = alpha, power = power, beta = 1 - power, df = df, ncp = ncp, t_crit = t_crit,
    dz_crit = t_crit / sqrt(n),
    curves = data.frame(t = t, null = stats::dt(t, df), alternative = stats::dt(t, df, ncp = ncp)),
    function_used = sprintf("pwr::pwr.t.test(n = %s, d = %s, sig.level = %s, type = \"paired\")", format(n), format(dz), format(alpha)),
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}

# The one-way ANOVA (Labs): the central and noncentral F with k - 1 and
# n - k df, the noncentrality lambda = f^2 n, as pwr.anova.test()
# computes power (pwr 1.3-0's source: lambda = k n f^2 with n per group);
# the test is one-sided (large F). The smallest significant Cohen's f: F
# is (SS_effect / df1) / (SS_error / df2) and Cohen's f^2 is SS_effect /
# SS_error (eta^2 / (1 - eta^2)), so the observed f is sqrt(F df1 / df2).

#' The picture of power for a one-way ANOVA
#'
#' What the Labs picture of power draws for a one-way between-participants
#' ANOVA with equal groups: the F distribution when there is no effect and
#' when the effect is Cohen's `f`, the critical value, and the numbers
#' behind them.
#'
#' @param n The total number of participants, split into `k` equal groups.
#' @param f Cohen's f in the population (0 or more).
#' @param k The number of groups (2 to 10).
#' @param alpha The significance level.
#' @param points How many points of each curve to return.
#' @return A list: `n`, `f`, `k`, `alpha`, `power` (pwr's
#'   `pwr.anova.test()`), `beta`, `df1`, `df2`, `ncp` (f^2 n), `f_crit`
#'   (the critical F), `effect_crit` (the smallest observed f that would be
#'   significant), `curves` (a data frame of `F`, `null` and `alternative`
#'   densities), `function_used` and `package`.
#' @export
#' @examples
#' picture <- power_picture_anova(156, 0.25, k = 3)
#' picture$power
power_picture_anova <- function(n, f, k = 3, alpha = 0.05, points = 401) {
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k > 10 || k %% 1 != 0) {
    abort_run("'k' should be a whole number of groups, from 2 to 10.")
  }
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n %% k != 0 || n / k < 2) {
    abort_run(sprintf("'n' should split into %d equal groups of at least 2 participants.", k))
  }
  if (!is.numeric(f) || length(f) != 1 || is.na(f) || f < 0) {
    abort_run("'f' should be a Cohen's f of 0 or more.")
  }
  picture_check(alpha)
  df1 <- k - 1
  df2 <- n - k
  ncp <- f^2 * n
  power <- pwr::pwr.anova.test(k = k, n = n / k, f = f, sig.level = alpha)$power
  f_crit <- stats::qf(1 - alpha, df1, df2)
  # The F axis covers the critical value and most of the alternative.
  to <- max(f_crit * 2, stats::qf(0.995, df1, df2, ncp = ncp))
  values <- seq(0, to, length.out = points)
  # The F density with one numerator df is infinite at 0: start just above.
  values[1] <- to / (points * 20)
  list(
    design = "anova", n = n, f = f, k = k, alpha = alpha, power = power, beta = 1 - power, df1 = df1, df2 = df2, ncp = ncp,
    f_crit = f_crit, effect_crit = sqrt(f_crit * df1 / df2),
    curves = data.frame(F = values, null = stats::df(values, df1, df2), alternative = stats::df(values, df1, df2, ncp = ncp)),
    function_used = sprintf("pwr::pwr.anova.test(k = %s, n = %s, f = %s, sig.level = %s)", format(k), format(n / k), format(f), format(alpha)),
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}

# Two proportions (Labs): as pwr.2p.test() computes power, the test
# statistic is normal with SD 1, centred on 0 with no effect and on
# h sqrt(n / 2) (n per group) for Cohen's h = 2 asin(sqrt(p2)) -
# 2 asin(sqrt(p1)) (pwr 1.3-0's source for pwr.2p.test() and ES.h()); the
# smallest significant h is the critical z times sqrt(2 / n).

#' The picture of power for two proportions
#'
#' What the Labs picture of power draws for comparing two groups'
#' proportions with Cohen's h (pwr's arcsine approximation, two equal
#' groups): the test statistic's distribution when the groups don't differ
#' and when they do, the critical values, and the numbers behind them.
#'
#' @param n The total number of participants, split into two equal groups
#'   (an even number, at least 4).
#' @param p1,p2 The proportion of 'yes' in each group (between 0 and 1).
#' @param alpha The significance level of the two-sided test.
#' @param points How many points of each curve to return.
#' @return A list: `n`, `p1`, `p2`, `h` (Cohen's h, from pwr's `ES.h()`,
#'   as p2 against p1), `alpha`, `power` (pwr's `pwr.2p.test()`), `beta`,
#'   `centre` (|h| sqrt(n per group / 2)), `z_crit`, `h_crit` (the
#'   smallest observed |h| that would be significant), `curves` (a data
#'   frame of `z`, `null` and `alternative` densities), `function_used`
#'   and `package`.
#' @export
#' @examples
#' picture <- power_picture_2p(194, 0.4, 0.6)
#' picture$power
power_picture_2p <- function(n, p1, p2, alpha = 0.05, points = 401) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 4 || n %% 2 != 0) {
    abort_run("'n' should be an even number of participants, at least 4, split into two equal groups.")
  }
  for (p in list(p1, p2)) {
    if (!is.numeric(p) || length(p) != 1 || is.na(p) || p <= 0 || p >= 1) {
      abort_run("Each proportion should be between 0 and 1.")
    }
  }
  picture_check(alpha)
  n_group <- n / 2
  h <- pwr::ES.h(p2, p1)
  centre <- abs(h) * sqrt(n_group / 2)
  power <- pwr::pwr.2p.test(h = abs(h), n = n_group, sig.level = alpha, alternative = "two.sided")$power
  z_crit <- stats::qnorm(1 - alpha / 2)
  from <- min(-4, -z_crit - 1)
  to <- max(4, z_crit + 1, centre + 4)
  z <- seq(from, to, length.out = points)
  list(
    design = "two_proportions", n = n, p1 = p1, p2 = p2, h = h, alpha = alpha, power = power, beta = 1 - power,
    centre = centre, z_crit = z_crit, h_crit = z_crit * sqrt(2 / n_group),
    curves = data.frame(z = z, null = stats::dnorm(z), alternative = stats::dnorm(z, centre)),
    function_used = sprintf("pwr::pwr.2p.test(h = ES.h(%s, %s), n = %s, sig.level = %s)", format(p2), format(p1), format(n_group), format(alpha)),
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}
