# ANOVA originals in a replication plan (queue item 28; decisions.md,
# 18 November 2026).
#
# An ANOVA effect with one numerator degree of freedom is a comparison of
# two means, and its F is the square of that comparison's t statistic,
# F(1, df) = t^2 (Lakens, 2013, refs.bib Lakens2013_effectsizes). So the
# replication plan takes it through the same goals as a t-test original:
# the effect is moved to a two-group or paired comparison, t = sqrt(F),
# and replication_planning() plans it with its t statistic, converted to d
# as for any t-test original (Lakens, 2013). Which comparison an effect is:
#   between-subjects, a factor with two levels: two groups, the factor's
#     two marginal means (N / 2 in each), d in the within-cell SD
#   between-subjects 2 x 2 interaction: two groups, d being half the
#     difference between the two simple effects, in the within-cell SD
#     (its standard error with N / 4 people a cell is 2 / sqrt(N), as for
#     two groups of N / 2)
#   within-subjects, a factor with two levels, or a 2 x 2 interaction:
#     pairs (each person's difference, or difference of differences), d_z
#   mixed, the between-subjects factor with two groups: two groups compared
#     on each person's mean over the conditions
#   mixed, the within-subjects factor with two conditions: pairs, each
#     person's change (the ANOVA's error df is N - groups, the paired t's
#     N - 1: the same with two groups' worth of difference at most)
#   mixed 2 x 2 interaction: two groups compared on each person's change
# The goals judged against the original's effect work on the estimate and
# its standard error, so the ANOVA's error degrees of freedom only enter
# small telescopes and the Bayes factor t-test, through the t-test's
# degrees of freedom; the difference is recorded with the plan
# (`df_error` against `df_t`). BUCSS's correction is the ANOVA's own
# function, so its number is the design's.
#
# An effect with several degrees of freedom has no one number to plan
# from. Its replication is planned from BUCSS's corrected original, or
# from the smallest effect that would matter to the researcher (a partial
# eta-squared, no default), through the F test of the matching ANOVA card
# (pwrss's power.f.ancova() or power.f.mixed.anova(), as run_spec() runs
# those cards from a partial eta-squared): replication_anova_smallest().

replication_anova_designs <- c("anova_between", "anova_within", "anova_mixed")

# The effect's two-mean comparison, for an effect with one degree of
# freedom; NULL for one with several.
replication_anova_comparison <- function(design, levels_a, levels_b, effect) {
  b <- levels_b %||% NA_real_
  two <- function(x) isTRUE(x == 2)
  mixed <- identical(design, "anova_mixed")
  one_df <- switch(effect,
    factor_a = , between = two(levels_a),
    factor_b = , within = two(b),
    interaction = two(levels_a) && two(b),
    FALSE)
  if (!one_df) return(NULL)
  if (identical(design, "anova_between")) {
    return(list(design = "two_groups", words = switch(effect,
      interaction = "half the difference between the two simple effects, in the within-group SD (d)",
      if (is.na(b)) "the difference between the two groups, in the within-group SD (d)" else
        "the difference between the factor's two levels, averaged over the other factor, in the within-group SD (d)")))
  }
  if (identical(design, "anova_within")) {
    return(list(design = "paired", words = switch(effect,
      interaction = "each person's difference between the two simple effects, in its own SD (d_z)",
      if (is.na(b)) "each person's difference between the two conditions, in its own SD (d_z)" else
        "each person's difference between the factor's two levels, averaged over the other factor, in its own SD (d_z)")))
  }
  if (mixed) {
    return(switch(effect,
      between = list(design = "two_groups", words = "the difference between the two groups in each person's mean over the conditions, in its SD (d)"),
      within = list(design = "paired", words = "each person's change between the two conditions, in its own SD (d_z)"),
      interaction = list(design = "two_groups", words = "the difference between the two groups in each person's change, in the SD of the change (d)")))
  }
  NULL
}

# An ANOVA original with one degree of freedom as a t-test original: the
# comparison, its t statistic and its sample sizes.
replication_anova_one_df <- function(design, original_n, levels_a, levels_b = NULL, effect = NULL,
                                     original_f = NULL, original_partial_eta = NULL, original_df_error = NULL) {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x, low) one_number(x) && x == round(x) && x >= low && x <= 1e6
  mixed <- identical(design, "anova_mixed")
  if (!whole(levels_a, 2)) abort_run("The first factor's number of levels should be a whole number, at least 2.")
  if (!is.null(levels_b) && !whole(levels_b, 2)) abort_run("The second factor's number of levels should be a whole number, at least 2.")
  if (mixed && is.null(levels_b)) abort_run("A mixed design needs the levels of its between-subjects and its within-subjects factor.")
  effects <- if (mixed) c("between", "within", "interaction") else if (is.null(levels_b)) "factor_a" else c("factor_a", "factor_b", "interaction")
  if (is.null(effect) && length(effects) == 1) effect <- effects
  if (!is.character(effect) || length(effect) != 1 || !effect %in% effects) {
    abort_run(sprintf("The effect should be one of %s for this design.", paste0("\"", effects, "\"", collapse = ", ")))
  }
  df_effect <- replication_bucss_df_effect(design, levels_a, levels_b, effect)
  comparison <- replication_anova_comparison(design, levels_a, levels_b, effect)
  if (is.null(comparison)) {
    abort_run(sprintf(paste("This effect has %s degrees of freedom, so it is not one comparison and has no one number to plan from.",
      "Plan it with BUCSS's correction of the original (replication_bucss()), or from the smallest effect that would matter (replication_anova_smallest())."),
      df_effect))
  }
  groups <- if (identical(design, "anova_between")) levels_a * (levels_b %||% 1) else if (mixed) levels_a else 1
  if (!whole(original_n, groups + 2)) {
    abort_run(sprintf("The original study's total sample size should be a whole number, at least %s.", groups + 2))
  }
  # The ANOVA's error degrees of freedom for this effect.
  df_error <- original_n - groups
  if (!is.null(original_partial_eta)) {
    if (!is.null(original_f)) abort_run("Give the original's F or its partial eta-squared, not both.")
    if (!one_number(original_partial_eta) || original_partial_eta <= 0 || original_partial_eta >= 1) {
      abort_run("The original's partial eta-squared should be between 0 and 1.")
    }
    if (!one_number(original_df_error) || original_df_error <= 0) {
      abort_run("A partial eta-squared needs the error degrees of freedom of its F test, the second number in F(df1, df2).")
    }
    # Partial eta-squared = F df1 / (F df1 + df2), with df1 = 1 (Lakens, 2013).
    original_f <- original_partial_eta / (1 - original_partial_eta) * original_df_error
  }
  if (!one_number(original_f) || original_f <= 0) abort_run("The original's F statistic should be a number above 0.")
  two <- identical(comparison$design, "two_groups")
  n1 <- if (two) floor(original_n / 2)
  list(design = comparison$design, effect = effect, effect_words = comparison$words, f = original_f, t = sqrt(original_f),
    n = if (!two) original_n, n1 = n1, n2 = if (two) original_n - n1, df_error = df_error,
    df_t = original_n - if (two) 2 else 1)
}

#' Plan an ANOVA replication from the smallest effect that would matter
#'
#' The sample size a replication of an ANOVA effect needs for its F test
#' to reach the chosen power if the true effect is the smallest that would
#' matter, given as a partial eta-squared. This is the route for an effect
#' with several degrees of freedom, which has no one number for the
#' replication plan's other goals; it runs the matching ANOVA card's F
#' test ([run_spec()] on a spec given by its partial eta-squared, so
#' pwrss's `power.f.ancova()` or `power.f.mixed.anova()`), so the number
#' is the card's. For within-subjects and mixed designs the partial
#' eta-squared is taken as those analyses report it (`eta_source`
#' `"published"`), so no correlation between measurements is needed.
#'
#' @param design `"anova_between"`, `"anova_within"` or `"anova_mixed"`.
#' @param levels_a,levels_b The levels of the factors, as for
#'   [replication_bucss()]: in a mixed design `levels_a` is the
#'   between-subjects factor and `levels_b` the within-subjects one.
#'   A within-subjects design with two factors has no card that takes a
#'   partial eta-squared, so it is refused.
#' @param effect `"factor_a"`, `"factor_b"` or `"interaction"`; for a
#'   mixed design `"between"`, `"within"` or `"interaction"`.
#' @param smallest_effect The smallest partial eta-squared that would
#'   matter, between 0 and 1. There is no default: it is the researcher's
#'   judgement.
#' @param alpha The significance level.
#' @param power The power to aim for.
#' @return A list: `inputs`, `n` (the total sample size), `per_unit` (per
#'   group or cell, `NA` for a within-subjects design), `power` (the power
#'   reached at `n`), `spec` (the card's spec, which [run_spec()] runs),
#'   `function_used` and `packages`.
#' @export
#' @examples
#' if (requireNamespace("pwrss", quietly = TRUE)) {
#'   replication_anova_smallest("anova_between", levels_a = 3, effect = "factor_a",
#'     smallest_effect = 0.06)$n
#' }
replication_anova_smallest <- function(design, levels_a, levels_b = NULL, effect = NULL, smallest_effect,
                                       alpha = 0.05, power = 0.8) {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x, low) one_number(x) && x == round(x) && x >= low && x <= 100
  if (!is.character(design) || length(design) != 1 || !design %in% replication_anova_designs) {
    abort_run("'design' should be \"anova_between\", \"anova_within\" or \"anova_mixed\".")
  }
  mixed <- identical(design, "anova_mixed")
  if (!whole(levels_a, 2)) abort_run("The first factor's number of levels should be a whole number, at least 2.")
  if (!is.null(levels_b) && !whole(levels_b, 2)) abort_run("The second factor's number of levels should be a whole number, at least 2.")
  if (mixed && is.null(levels_b)) abort_run("A mixed design needs the levels of its between-subjects and its within-subjects factor.")
  if (identical(design, "anova_within") && !is.null(levels_b)) {
    abort_run(paste("No ANOVA card plans a within-subjects design with two factors from a partial eta-squared:",
      "its card plans from the means in each condition. Plan the replication there, from the smallest pattern of means that would matter."))
  }
  effects <- if (mixed) c("between", "within", "interaction") else if (is.null(levels_b)) "factor_a" else c("factor_a", "factor_b", "interaction")
  if (is.null(effect) && length(effects) == 1) effect <- effects
  if (!is.character(effect) || length(effect) != 1 || !effect %in% effects) {
    abort_run(sprintf("The effect should be one of %s for this design.", paste0("\"", effects, "\"", collapse = ", ")))
  }
  if (!one_number(smallest_effect) || smallest_effect <= 0 || smallest_effect >= 1) {
    abort_run("The smallest effect that would matter should be a partial eta-squared between 0 and 1, such as 0.03.")
  }
  if (!one_number(alpha) || alpha <= 0 || alpha >= 0.5) abort_run("The significance level should be between 0 and 0.5, for example 0.05.")
  if (!one_number(power) || power <= alpha || power >= 1) abort_run("The power to aim for should be between the significance level and 1, for example 0.8.")
  factor <- function(type, k, name) list(type = type, label = name, levels = as.list(sprintf("%s%d", tolower(name), seq_len(k))))
  template <- if (mixed) "mixed" else if (identical(design, "anova_within")) "oneway_within" else if (is.null(levels_b)) "oneway_between" else "factorial_between"
  variables <- list(A = factor(if (identical(design, "anova_within")) "within_factor" else "between_factor", levels_a, "A"))
  if (!is.null(levels_b)) variables$B <- factor(if (mixed) "within_factor" else "between_factor", levels_b, "B")
  variables$Y <- list(type = "continuous", label = "Score")
  population <- list(metric = "eta_squared", eta_squared = smallest_effect)
  if (template %in% c("oneway_within", "mixed")) population$eta_source <- "published"
  spec <- list(spec_version = "0.1", design = "factorial_anova", template = template, variables = variables,
    population = population,
    effect_justification = list(type = "smallest_effect_of_interest",
      source = "The smallest effect that would matter to the replication's authors."),
    target_test = list(effect = c(factor_a = "main_effect_A", between = "main_effect_A", factor_b = "main_effect_B",
      within = "main_effect_B", interaction = "interaction")[[effect]], method = "anova_f", alpha = alpha),
    goal = list(type = "sample_size", power = power))
  result <- run_spec(spec)
  n <- result$n_required$n
  cells <- if (identical(design, "anova_within")) NA_real_ else levels_a * (if (mixed) 1 else levels_b %||% 1)
  list(
    inputs = list(design = design, levels_a = levels_a, levels_b = levels_b, effect = effect,
      smallest_effect = smallest_effect, alpha = alpha, power = power),
    n = n,
    per_unit = if (is.na(cells)) NA_real_ else n / cells,
    power = result$curve$power[match(n, result$curve$n)],
    spec = spec,
    function_used = result$provenance$backend_function,
    packages = result$provenance$packages
  )
}
