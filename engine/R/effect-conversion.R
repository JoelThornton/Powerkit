# Effect-size conversion: a published effect in another form (a t or F
# statistic, r, d or an odds ratio) turned into the effect size the card
# uses, with the effectsize package (Ben-Shachar, Lüdecke & Makowski,
# 2020), except t and F into d or d_z, which use psych's t2d(): the exact
# relation, d = t / sqrt(n) for one group or pairs and
# d = t sqrt(1 / n1 + 1 / n2) for two groups (Lakens, 2013, equations 7
# and 2; refs.bib Lakens2013_effectsizes; effectsize's t_to_d() puts
# the error df in place of n, and assumes equal groups; conventions.md,
# "Effect-size conversion"). The spec records what was converted in
# 'effect_justification > conversion'; validate_spec() puts the converted
# value in the population before the schema is checked, and records it as
# 'conversion > result'.

# For each template: the population field the conversion fills, its name,
# and each form it can be converted from, with the effectsize call.
conversion_templates <- list(
  independent_t = list(effect = "d", name = "Cohen's d", from = c("t", "F", "r", "odds_ratio")),
  one_sample_t = list(effect = "d", name = "Cohen's d", from = "t"),
  paired_t = list(effect = "dz", name = "d_z", from = c("t", "F")),
  correlation = list(effect = "r", name = "r", from = c("t", "F", "d", "odds_ratio")),
  # Between-participants ANOVA given by partial eta-squared (population >
  # metric "eta_squared"): a published F with its two dfs, or Cohen's f.
  oneway_between = list(effect = "eta_squared", name = "partial eta-squared", from = c("F", "f")),
  "2x2_between" = list(effect = "eta_squared", name = "partial eta-squared", from = c("F", "f")),
  factorial_between = list(effect = "eta_squared", name = "partial eta-squared", from = c("F", "f")),
  # Repeated-measures and mixed ANOVA: a published F only, whose partial
  # eta-squared already reflects the correlation between measurements
  # (population > eta_source "published").
  oneway_within = list(effect = "eta_squared", name = "partial eta-squared", from = "F"),
  "2x2_mixed" = list(effect = "eta_squared", name = "partial eta-squared", from = "F"),
  mixed = list(effect = "eta_squared", name = "partial eta-squared", from = "F")
)

conversion_from_names <- c(
  t = "a t statistic", F = "an F statistic", r = "r", d = "Cohen's d", odds_ratio = "an odds ratio",
  f = "Cohen's f"
)

or_list <- function(x) if (length(x) < 2) x else paste(paste(x[-length(x)], collapse = ", "), "or", x[length(x)])

#' Convert a published effect size into the one a design uses
#'
#' Turns an effect reported in another form into the effect size a
#' powerkit design takes, with the effectsize package (psych's `t2d()` for
#' a t or F statistic into Cohen's d or d_z, with the sample size df + 1
#' for one group or pairs and df + 2, or the two group sizes, for two
#' groups): a t statistic, an F
#' statistic with one numerator degree of freedom, r, Cohen's d or an odds
#' ratio, into Cohen's d (one-sample and independent t-tests), d_z (paired
#' t-test) or r (correlation); and an F statistic (with both its degrees of
#' freedom) or Cohen's f into the partial eta-squared of a
#' between-participants ANOVA (`"oneway_between"`, `"2x2_between"`,
#' `"factorial_between"`).
#'
#' @param from The form of the published effect: `"t"`, `"F"`, `"r"`,
#'   `"d"`, `"odds_ratio"` or `"f"`.
#' @param value The published value.
#' @param template The design's template: `"independent_t"`,
#'   `"one_sample_t"`, `"paired_t"`, `"correlation"`, `"oneway_between"`,
#'   `"2x2_between"` or `"factorial_between"`.
#' @param df_error The error (denominator) degrees of freedom, for t and F.
#' @param n1,n2 Optional group sizes, for the independent t-test and the
#'   correlation (t, F, r or d with two groups of unequal size); equal
#'   groups are assumed without them. With a t or F statistic, the error df
#'   can't exceed n1 + n2 - 2.
#' @param df The numerator degrees of freedom, for an F statistic converted
#'   into an ANOVA's partial eta-squared.
#'
#' @return A list: `effect_name` and `value` (the converted effect),
#'   `function_used` (the call) and `package` (name and version).
#' @export
#' @examples
#' convert_effect("t", 2.5, "independent_t", df_error = 58)
convert_effect <- function(from, value, template, df_error = NULL, n1 = NULL, n2 = NULL, df = NULL) {
  rule <- conversion_templates[[template]]
  if (is.null(rule)) {
    abort_spec(sprintf("Converting an effect size isn't available for the '%s' design yet.", template))
  }
  if (!from %in% rule$from) {
    abort_spec(sprintf("For this design, an effect size can be converted from %s, not from %s.",
      or_list(conversion_from_names[rule$from]), conversion_from_names[[from]] %||% from))
  }
  if (from %in% c("t", "F") && is.null(df_error)) {
    abort_spec(sprintf("Converting %s needs its error degrees of freedom ('df_error').", conversion_from_names[[from]]))
  }
  anova <- identical(rule$effect, "eta_squared")
  if (anova && identical(from, "F") && is.null(df)) {
    abort_spec("Converting an F statistic for an ANOVA needs its numerator degrees of freedom ('df') as well as 'df_error'.")
  }
  paired <- template %in% c("one_sample_t", "paired_t")
  if (xor(is.null(n1), is.null(n2))) {
    abort_spec("Give both group sizes ('effect_justification > conversion > n1' and 'effect_justification > conversion > n2'), or neither for equal groups.")
  }
  if (!is.null(n1) && !template %in% c("independent_t", "correlation")) {
    abort_spec("Group sizes ('effect_justification > conversion > n1' and 'effect_justification > conversion > n2') are only used for two groups: the independent t-test or the correlation.")
  }
  if (!is.null(n1) && from %in% c("t", "F") && !is.null(df_error) && df_error > n1 + n2 - 2) {
    abort_spec(sprintf(
      "With groups of %s and %s, a t or F statistic has at most %s error degrees of freedom, not %s. Check the group sizes and the df.",
      n1, n2, n1 + n2 - 2, df_error))
  }
  sizes <- if (!is.null(n1) && !is.null(n2)) sprintf(", n1 = %s, n2 = %s", n1, n2) else ""
  # psych's t2d(): one group or pairs of n = df + 1 (n1 = n); two groups of
  # their own sizes, or two equal groups of n = df + 2 in all.
  t2d <- function(t) {
    if (paired) {
      list(value = psych::t2d(t, n1 = df_error + 1), used = sprintf("psych::t2d(t = %s, n1 = %s)", signif(t, 7), df_error + 1))
    } else if (!is.null(n1)) {
      list(value = psych::t2d(t, n1 = n1, n2 = n2), used = sprintf("psych::t2d(t = %s, n1 = %s, n2 = %s)", signif(t, 7), n1, n2))
    } else {
      list(value = psych::t2d(t, n = df_error + 2), used = sprintf("psych::t2d(t = %s, n = %s)", signif(t, 7), df_error + 2))
    }
  }
  call <- switch(
    paste(rule$effect, from),
    "eta_squared F" = list(
      value = effectsize::F_to_eta2(value, df, df_error)[[1]],
      used = sprintf("effectsize::F_to_eta2(f = %s, df = %s, df_error = %s)", value, df, df_error)),
    "eta_squared f" = list(
      value = effectsize::f_to_eta2(value),
      used = sprintf("effectsize::f_to_eta2(f = %s)", value)),
    "d t" = , "dz t" = t2d(value),
    # F with one numerator df is t squared: t = sqrt(F), positive, as F
    # carries no direction.
    "d F" = , "dz F" = t2d(sqrt(value)),
    "d r" = list(
      value = if (nzchar(sizes)) effectsize::r_to_d(value, n1, n2) else effectsize::r_to_d(value),
      used = sprintf("effectsize::r_to_d(r = %s%s)", value, sizes)),
    "d odds_ratio" = list(
      value = effectsize::oddsratio_to_d(value),
      used = sprintf("effectsize::oddsratio_to_d(OR = %s)", value)),
    "r t" = list(
      value = effectsize::t_to_r(value, df_error)[[1]],
      used = sprintf("effectsize::t_to_r(t = %s, df_error = %s)", value, df_error)),
    "r F" = list(
      value = effectsize::F_to_r(value, 1, df_error)[[1]],
      used = sprintf("effectsize::F_to_r(f = %s, df = 1, df_error = %s)", value, df_error)),
    "r d" = list(
      value = if (nzchar(sizes)) effectsize::d_to_r(value, n1, n2) else effectsize::d_to_r(value),
      used = sprintf("effectsize::d_to_r(d = %s%s)", value, sizes)),
    "r odds_ratio" = list(
      value = effectsize::oddsratio_to_r(value),
      used = sprintf("effectsize::oddsratio_to_r(OR = %s)", value))
  )
  package <- conversion_package(from, rule)
  list(effect_name = rule$name, value = unname(call$value), function_used = call$used,
       package = list(name = package, version = as.character(utils::packageVersion(package))))
}

# The package a conversion uses: psych for a t or F statistic into d or
# d_z, effectsize otherwise.
conversion_package <- function(from, rule) {
  if (rule$effect %in% c("d", "dz") && from %in% c("t", "F")) "psych" else "effectsize"
}

# The package a spec's conversion uses, for the provenance (NULL without
# a conversion, or one validation will refuse).
spec_conversion_package <- function(spec) {
  conv <- spec$effect_justification$conversion
  rule <- conversion_templates[[spec$template %||% ""]]
  if (is.null(conv) || is.null(rule) || !is.character(conv$from)) return(NULL)
  conversion_package(conv$from, rule)
}

# In validate_spec(), before the schema is checked: when the justification
# gives a conversion, put the converted effect in the population (the
# schema needs it there) and record it in 'conversion > result'. A spec that
# already records the result keeps it, so validating twice gives the same
# spec and the same hash. Returns list(spec, problems); a malformed
# conversion is left for the schema to report.
apply_conversion <- function(spec) {
  conv <- spec$effect_justification$conversion
  none <- list(spec = spec, problems = character())
  if (!is.list(conv) || !is.null(conv$result)) return(none)
  if (!is.character(conv$from) || !is.numeric(conv$value)) return(none)
  rule <- conversion_templates[[spec$template %||% ""]]
  anova <- identical(spec$design, "factorial_anova") && identical(rule$effect, "eta_squared") &&
    identical(spec$population$metric, "eta_squared")
  if (is.null(rule) || !(identical(spec$design, "basic_test") || anova)) {
    return(list(spec = spec, problems = paste0(
      "Converting an effect size ('effect_justification > conversion') is available for the one-sample, paired and ",
      "independent t-tests, the correlation, and between-participants ANOVA given by partial eta-squared ",
      "('population > metric' \"eta_squared\"), not for this design yet.")))
  }
  if (spec$template %in% eta_squared_mixed_templates && !identical(spec$population$eta_source, "published")) {
    return(list(spec = spec, problems = paste0(
      "A published F from a repeated-measures or mixed ANOVA gives partial eta-squared as that analysis reports it, ",
      "which already reflects the correlation between measurements: set 'population > eta_source' to \"published\".")))
  }
  if (!is.null(spec$population[[rule$effect]])) {
    return(list(spec = spec, problems = sprintf(paste0(
      "The spec gives both an effect size ('population > %s') and a conversion ('effect_justification > conversion'). ",
      "Give one: the conversion fills in the effect size."), rule$effect)))
  }
  if (identical(spec$population$metric, "raw")) {
    return(list(spec = spec, problems = paste0(
      "An effect in the outcome's own units ('population > raw') can't also be converted from another form. Give one.")))
  }
  out <- tryCatch(
    convert_effect(conv$from, conv$value, spec$template, df_error = conv$df_error, n1 = conv$n1, n2 = conv$n2, df = conv[["df"]]),
    powerkit_spec_error = function(e) e
  )
  if (inherits(out, "powerkit_spec_error")) return(list(spec = spec, problems = out$problems %||% conditionMessage(out)))
  if (!is.finite(out$value)) {
    return(list(spec = spec, problems = "The converted effect size isn't a finite number. Check the value and its degrees of freedom."))
  }
  spec$population[[rule$effect]] <- out$value
  spec$effect_justification$conversion$result <- out$value
  list(spec = spec, problems = character())
}

# For the result: what the conversion did, or NULL. `value` is the
# published value, `converted` the effect the calculation used: the result
# the spec records. A plan saved by an earlier powerkit keeps its result
# even where this version converts differently; `earlier` is then TRUE and
# `now` is what this version's `function_used` gives.
conversion_record <- function(spec) {
  conv <- spec$effect_justification$conversion
  if (is.null(conv$result)) return(NULL)
  out <- convert_effect(conv$from, conv$value, spec$template, df_error = conv$df_error, n1 = conv$n1, n2 = conv$n2, df = conv[["df"]])
  earlier <- !isTRUE(all.equal(out$value, conv$result, tolerance = 1e-10))
  list(from = conv$from, from_name = conversion_from_names[[conv$from]], value = conv$value,
       df = conv[["df"]], df_error = conv$df_error, n1 = conv$n1, n2 = conv$n2, effect_name = out$effect_name,
       converted = conv$result, function_used = out$function_used, package = out$package,
       earlier = earlier, now = if (earlier) out$value)
}
