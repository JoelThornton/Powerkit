#' Simulate repeated two-group studies for teaching
#'
#' Each study draws fresh independent normal scores, with SD 1 in both
#' groups and means 0 and `d`, then runs an actual two-sided pooled
#' [stats::t.test()]. Estimates are [effectsize::cohens_d()] with a pooled
#' SD. The p-value and estimate therefore come from the same observations.
#' This educational example does not model publication practices, missing
#' data, unequal variances, or uncertainty about the population effect.
#'
#' @param n Total participants, an even whole number from 6 to 2000.
#' @param d True population mean difference (group 2 minus group 1), in
#'   within-group SD units, between -3 and 3. Zero means no effect.
#' @param alpha Two-sided significance threshold, between 0 and 0.5.
#' @param seed Reproducible random seed, from 1 to 2147483646.
#' @param replications Number of independent studies, from 10 to 10000.
#' @return A list with `settings`, one row per study in `studies`, counts
#'   and conditional summaries in `summary`, and reproducible `provenance`.
#'   Exaggeration compares absolute effect magnitudes; a wrong direction
#'   is reported separately. Ratios to a true effect of zero are undefined.
#' @export
#' @examples
#' studies <- study_variation(n = 64, d = 0.3, replications = 10)
#' studies$summary$significant
study_variation <- function(n = 64L, d = 0.3, alpha = 0.05,
                            seed = 20261104L, replications = 1000L) {
  scalar <- function(x, lo, hi, integer = FALSE) {
    is.numeric(x) && length(x) == 1L && is.finite(x) &&
      x >= lo && x <= hi && (!integer || x == round(x))
  }
  if (!scalar(n, 6, 2000, TRUE) || n %% 2 != 0) {
    abort_run("Choose an even total sample size between 6 and 2,000, split equally between the groups.")
  }
  if (!scalar(d, -3, 3)) abort_run("Enter the population effect as Cohen's d between -3 and 3; use zero for no effect.")
  if (!scalar(alpha, 0, 0.5) || alpha <= 0 || alpha >= 0.5) abort_run("Choose a significance threshold between zero and 0.5.")
  if (!scalar(seed, 1, 2147483646, TRUE)) abort_run("Use a whole-number seed between 1 and 2,147,483,646.")
  if (!scalar(replications, 10, 10000, TRUE)) abort_run("Simulate between 10 and 10,000 whole studies.")
  settings <- list(n = as.integer(n), n_per_group = as.integer(n / 2), d = d,
    alpha = alpha, seed = as.integer(seed), replications = as.integer(replications),
    population = "Independent normal scores; group means 0 and d; both SDs 1",
    analysis = "Two-sided Student t-test, pooled variance; Cohen's d = group 2 minus group 1")
  observations <- with_seed(seed, {
    do.call(rbind, lapply(seq_len(replications), function(i) {
      group_1 <- stats::rnorm(n / 2)
      group_2 <- stats::rnorm(n / 2, mean = d)
      test <- stats::t.test(group_2, group_1, var.equal = TRUE, alternative = "two.sided")
      estimate <- effectsize::cohens_d(group_2, group_1, pooled_sd = TRUE, ci = NULL, verbose = FALSE)$Cohens_d
      data.frame(study = i, estimate = estimate, t = unname(test$statistic), p_value = test$p.value)
    }))
  })
  observations$significant <- observations$p_value < alpha
  observations$overestimates_magnitude <- if (d == 0) NA else abs(observations$estimate) > abs(d)
  observations$wrong_direction <- if (d == 0) NA else observations$estimate * d < 0
  selected <- observations[observations$significant, , drop = FALSE]
  count <- nrow(selected)
  interval <- stats::binom.test(count, replications)$conf.int
  summary <- list(attempted = as.integer(replications), valid = nrow(observations), failed = 0L,
    significant = count, proportion_significant = count / replications,
    simulation_interval = unname(interval),
    overestimated_significant = if (d == 0 || count == 0) NA_integer_ else sum(selected$overestimates_magnitude),
    wrong_direction_significant = if (d == 0 || count == 0) NA_integer_ else sum(selected$wrong_direction),
    mean_estimate = mean(observations$estimate),
    selected_mean_magnitude = if (count == 0) NA_real_ else mean(abs(selected$estimate)),
    selected_magnitude_ratio = if (d == 0 || count == 0) NA_real_ else mean(abs(selected$estimate)) / abs(d))
  list(settings = settings, studies = observations, summary = summary,
    provenance = list(spec_hash = spec_hash(settings), seed = as.integer(seed),
      backend = "stats + effectsize", backend_function = "stats::rnorm; stats::t.test; effectsize::cohens_d",
      method = "simulation", nrep = as.integer(replications), r_version = R.version.string,
      packages = package_versions(c("powerkit", "stats", "effectsize"))))
}
