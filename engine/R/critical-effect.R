# The critical effect size (refs.bib Perugini2025_critical, Lakens2022_justification):
# the smallest observed effect that would be statistically significant at the
# n analysed, the alpha and the test, whatever the true effect. It describes
# the data a study will produce, not the population effect assumed for power.
# No CRAN package computes it (the authors' criticalESvalue is on GitHub only),
# so it is the closed form Perugini et al. (2025) give in their Table 1, from
# the critical t of the test (stats::qt()):
#   one-sample t        d_c   = t_c sqrt(1 / n),               df = n - 1
#   paired t            d_z,c = t_c sqrt(1 / n),               df = n - 1
#   two-sample t        d_c   = t_c sqrt(1 / n1 + 1 / n2),     df = n1 + n2 - 2
#                       (Student's t, pooled SD, any group sizes)
#   correlation (t)     r_c   = t_c / sqrt(n - 2 + t_c^2),     df = n - 2
# Two-sided tests have t_c = qt(1 - alpha / 2, df) and a critical value on
# each side; one-sided tests t_c = qt(1 - alpha, df) on the side tested.
# Checked against simulated studies in test-validation-critical-effect.R.
# Only for the designs pwr computes (pwr_covers()): Student's t-tests and
# Pearson's correlation, not Welch's t, the minimum-effect, rank or Bayes
# factor versions.

critical_effect_templates <- c("one_sample_t", "paired_t", "independent_t", "correlation")

critical_effect <- function(spec, n) {
  if (!isTRUE(spec$template %in% critical_effect_templates) || !isTRUE(pwr_covers(spec))) return(NULL)
  if (!is.numeric(n) || length(n) != 1 || is.na(n)) return(NULL)
  alpha <- spec$target_test$alpha %||% 0.05
  alternative <- spec$target_test$alternative %||% "two_sided"
  tails <- if (identical(alternative, "two_sided")) 2 else 1
  groups <- if (identical(spec$template, "independent_t")) critical_effect_groups(spec, n)
  df <- switch(spec$template,
    one_sample_t = , paired_t = n - 1,
    independent_t = sum(groups) - 2,
    correlation = n - 2
  )
  if (df < 1) return(NULL)
  t_critical <- stats::qt(1 - alpha / tails, df)
  value <- switch(spec$template,
    one_sample_t = , paired_t = t_critical * sqrt(1 / n),
    independent_t = t_critical * sqrt(sum(1 / groups)),
    correlation = t_critical / sqrt(n - 2 + t_critical^2)
  )
  list(
    effect_name = switch(spec$template, paired_t = "d_z", correlation = "r", "d"),
    value = value,
    alternative = alternative,
    alpha = alpha,
    n = n,
    groups = groups,
    df = df,
    t_critical = t_critical,
    source = "Perugini et al. (2025)"
  )
}

# The two groups' sizes at total n, as the power calculation splits them
# (pwr_inputs(): the allocation ratio is n2 / n1).
critical_effect_groups <- function(spec, n) {
  ratio <- spec$options$allocation_ratio %||% 1
  if (isTRUE(all.equal(ratio, 1))) return(c(n / 2, n / 2))
  n1 <- round(n / (1 + ratio))
  c(n1, n - n1)
}

# Technical details for Pearson's correlation, which pwr's pwr.r.test()
# doesn't return: the t test's df (n - 2) and critical t, the same critical
# t (and critical r) pwr.r.test() uses internally, from Perugini et al.'s
# closed form. pwr then takes power from Fisher's z of the expected r
# against the critical r, so there is no noncentrality parameter to give.
critical_effect_details <- function(ce) {
  if (is.null(ce) || !identical(ce$effect_name, "r")) return(NULL)
  t_c <- ce$t_critical
  list(
    statistic = "t",
    df = ce$df,
    critical = switch(ce$alternative, two_sided = c(-t_c, t_c), greater = t_c, less = -t_c),
    ncp = NA_real_,
    actual_alpha = NA_real_,
    source = "Perugini et al.'s (2025) formula, with the critical t pwr's pwr.r.test() also uses",
    note = sprintf(paste("The critical r is %s. pwr's power for a correlation compares Fisher's z of the expected r with that",
      "critical r, so there is no noncentrality parameter."),
      switch(ce$alternative, two_sided = sprintf("\u00b1%s", formatC(ce$value, digits = 3, format = "f")),
        greater = formatC(ce$value, digits = 3, format = "f"), less = formatC(-ce$value, digits = 3, format = "f")))
  )
}
