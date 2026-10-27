# Safeguard power (Perugini, Gallucci & Costantini, 2014; refs.bib
# Perugini2014_safeguard): when the effect size is one earlier study's
# estimate, plan with the lower bound of a two-sided confidence interval
# around it instead of the estimate itself. The lower end of the 60%
# interval gives 80% protection against the estimate being too large; the
# lower end of the 90% interval gives 95%. The intervals come from psych:
# cohen.d.ci() (noncentral t) for d and d_z, r.con() (Fisher's z) for r.

# Which population field holds the effect, for each template safeguard
# power covers, and which sample sizes the earlier study needs.
safeguard_templates <- list(
  one_sample_t = list(effect = "d", sizes = "n"),
  paired_t = list(effect = "dz", sizes = "n"),
  independent_t = list(effect = "d", sizes = c("n1", "n2")),
  correlation = list(effect = "r", sizes = "n")
)

#' The safeguard effect size
#'
#' The lower bound (towards zero) of a two-sided confidence interval around
#' an earlier study's effect size, for planning with safeguard power
#' (Perugini, Gallucci & Costantini, 2014). With `protection = 0.8` the
#' interval is the 60% one; with 0.95, the 90% one.
#'
#' @param estimate The earlier study's effect size: Cohen's d, d_z or r.
#' @param template `"one_sample_t"`, `"paired_t"`, `"independent_t"` or
#'   `"correlation"`.
#' @param n The earlier study's number of participants (one-sample, paired
#'   and correlation).
#' @param n1,n2 The earlier study's group sizes (independent groups).
#' @param protection The chance that the true effect is at least the
#'   safeguard effect, if the earlier estimate is unbiased: 0.8 by default.
#' @return A list: `estimate`, `lower` (the safeguard effect, with the
#'   estimate's sign), `conf_level`, `protection`, `function_used` and
#'   `package` (name and version).
#' @export
#' @examples
#' safeguard_effect(0.5, "independent_t", n1 = 20, n2 = 20)
safeguard_effect <- function(estimate, template, n = NULL, n1 = NULL, n2 = NULL, protection = 0.8) {
  conf_level <- 2 * protection - 1
  size <- abs(estimate)
  if (identical(template, "correlation")) {
    lower <- psych::r.con(size, n, p = conf_level)[1]
    used <- sprintf("psych::r.con(%s, %s, p = %s)", format(size), n, format(conf_level))
  } else {
    if (identical(template, "independent_t")) {
      ci <- psych::cohen.d.ci(size, n1 = n1, n2 = n2, alpha = 1 - conf_level)
      used <- sprintf("psych::cohen.d.ci(%s, n1 = %s, n2 = %s, alpha = %s)", format(size), n1, n2, format(1 - conf_level))
    } else {
      ci <- psych::cohen.d.ci(size, n1 = n, alpha = 1 - conf_level)
      used <- sprintf("psych::cohen.d.ci(%s, n1 = %s, alpha = %s)", format(size), n, format(1 - conf_level))
    }
    lower <- unname(ci[1, "lower"])
  }
  list(estimate = estimate, lower = sign(estimate) * lower, conf_level = conf_level, protection = protection,
       function_used = used, package = list(name = "psych", version = as.character(utils::packageVersion("psych"))))
}

# In validate_spec(): when the effect justification asks for safeguard
# power, put the safeguard effect in the population and keep the earlier
# study's estimate in the justification. Applied once: a spec that already
# records the estimate is left as it is, so validating twice gives the same
# spec and the same hash. Returns list(spec, problems).
apply_safeguard <- function(spec) {
  sg <- spec$effect_justification$safeguard
  if (is.null(sg) || !is.null(sg$estimate)) return(list(spec = spec, problems = character()))
  rule <- safeguard_templates[[spec$template %||% ""]]
  if (!identical(spec$design, "basic_test") || is.null(rule)) {
    return(list(spec = spec, problems = paste0(
      "Safeguard power ('effect_justification > safeguard') is available for the one-sample, paired and ",
      "independent t-tests and the correlation, not for this design.")))
  }
  missing <- setdiff(rule$sizes, names(sg))
  if (length(missing)) {
    return(list(spec = spec, problems = sprintf(
      "Safeguard power needs the earlier study's %s ('effect_justification > safeguard > %s').",
      if (identical(rule$sizes, "n")) "number of participants" else "group sizes", missing[1])))
  }
  estimate <- spec$population[[rule$effect]]
  if (is.null(estimate) || estimate == 0) {
    return(list(spec = spec, problems = "Safeguard power needs the earlier study's effect size, and it can't be zero."))
  }
  out <- safeguard_effect(estimate, spec$template, n = sg$n, n1 = sg$n1, n2 = sg$n2, protection = sg$protection %||% 0.8)
  if (is.na(out$lower) || sign(out$lower) != sign(estimate) || out$lower == 0) {
    return(list(spec = spec, problems = sprintf(paste0(
      "The safeguard effect is zero or in the other direction: the %d%% confidence interval around the earlier ",
      "study's estimate (%s) includes zero, so that study can't tell you how large the effect is. ",
      "Plan from the smallest effect that would matter instead."), round(100 * out$conf_level), format(estimate))))
  }
  spec$effect_justification$safeguard$estimate <- estimate
  spec$effect_justification$safeguard$protection <- out$protection
  spec$population[[rule$effect]] <- out$lower
  list(spec = spec, problems = character())
}

# For the result: what the safeguard did, or NULL.
safeguard_record <- function(spec) {
  sg <- spec$effect_justification$safeguard
  if (is.null(sg$estimate)) return(NULL)
  rule <- safeguard_templates[[spec$template]]
  out <- safeguard_effect(sg$estimate, spec$template, n = sg$n, n1 = sg$n1, n2 = sg$n2, protection = sg$protection)
  out$lower <- spec$population[[rule$effect]]
  out$effect_name <- switch(rule$effect, d = "Cohen's d", dz = "d_z", r = "r")
  out$n <- sg$n
  out$n1 <- sg$n1
  out$n2 <- sg$n2
  out
}
