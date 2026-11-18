# Replication sample sizes corrected for publication bias and uncertainty,
# from BUCSS (Anderson, Kelley & Maxwell, 2017; Anderson & Kelley, 2024;
# references from citation("BUCSS"), in refs.bib).
#
# A published effect is selected for significance and estimated with
# error, so planning from it as if it were the true effect asks for too
# few people. BUCSS truncates the likelihood of the original's test
# statistic at its significance threshold (the publication bias) and takes
# a lower quantile of the corrected noncentrality parameter (the
# uncertainty): the quantile's complement is the "assurance", the chance
# that the planned power is reached (Anderson, Kelley & Maxwell, 2017).
# Every number here is BUCSS's own: powerkit chooses the function for the
# design and passes the original's statistic, sample size and levels.
#
# BUCSS covers the designs a replication plan's other goals can't: an
# original reported as an F from a between-subjects, within-subjects or
# mixed ANOVA, whose effect has several degrees of freedom or comes with
# no one-number estimate (decisions.md, 17 November 2026). For the t-test
# and correlation originals the plan's other goals already cover, it adds
# the bias-corrected sample size for a significant result beside them.
#
# A partial eta-squared is moved to its F with the error degrees of
# freedom the paper reports: partial eta-squared = F df1 / (F df1 + df2)
# (Lakens, 2013, refs.bib Lakens2013_effectsizes), so F = eta / (1 - eta)
# * df2 / df1, with df1 the effect's degrees of freedom in the design.

replication_bucss_designs <- c("two_groups", "one_sample", "paired", "correlation",
  "anova_between", "anova_within", "anova_mixed")

# The effect's numerator degrees of freedom in the design.
replication_bucss_df_effect <- function(design, levels_a, levels_b, effect) {
  a <- levels_a - 1
  b <- if (is.null(levels_b)) NA_real_ else levels_b - 1
  if (identical(design, "anova_mixed")) {
    return(switch(effect, between = a, within = b, interaction = a * b))
  }
  switch(effect, factor_a = a, factor_b = b, interaction = a * b)
}

#' Plan a replication with BUCSS: sample sizes corrected for publication
#' bias and uncertainty
#'
#' The sample size a replication needs for a significant result with the
#' chosen power, after correcting the original study's effect for
#' publication bias and uncertainty (Anderson, Kelley & Maxwell, 2017), at
#' each level of assurance. Calculated with BUCSS. Used by the replication
#' plan for originals reported as an F from an ANOVA, and beside the other
#' goals for t-test and correlation originals.
#'
#' @param design `"two_groups"`, `"one_sample"`, `"paired"` or
#'   `"correlation"` (a t-test or correlation original); or
#'   `"anova_between"`, `"anova_within"` or `"anova_mixed"` (an ANOVA
#'   original reported as an F or a partial eta-squared).
#' @param original_statistic The original's test statistic: t for a
#'   t-test (its sign is ignored), r for a correlation, F for an ANOVA.
#' @param original_n The original's total sample size (people, or pairs
#'   for `"paired"`).
#' @param levels_a,levels_b The levels of the ANOVA's factors:
#'   `levels_a` the first (the between-subjects factor in a mixed design),
#'   `levels_b` the second (the within-subjects factor in a mixed design;
#'   `NULL` for a one-factor between or within design).
#' @param effect The ANOVA effect the replication tests: `"factor_a"`,
#'   `"factor_b"` or `"interaction"` for a between or within design;
#'   `"between"`, `"within"` or `"interaction"` for a mixed design.
#' @param epsilon For within and mixed designs, the sphericity correction
#'   (1 assumes sphericity), as BUCSS takes it.
#' @param original_partial_eta,original_df_error In place of an F for an
#'   ANOVA: the partial eta-squared and the error degrees of freedom of
#'   the original's F test.
#' @param original_alpha The significance level the original's literature
#'   published at (BUCSS's `alpha_prior`): the publication threshold the
#'   correction undoes.
#' @param publication_filter Whether the original was published because
#'   it was significant. `TRUE` (BUCSS's default) corrects for publication
#'   bias at `original_alpha`; `FALSE`, for an original that would have
#'   been published whatever it found (a Registered Report, say), passes
#'   BUCSS `alpha_prior = 1`, which leaves only the correction for
#'   uncertainty (Anderson, Kelley & Maxwell, 2017, p. 1552).
#' @param alpha The replication's significance level, two-sided.
#' @param power The power the replication aims for.
#' @param assurance The levels of assurance: the chance the planned power
#'   is reached, from 0.5 (BUCSS's recommended floor) to below 1.
#' @param alternative `"two.sided"` or, for a t-test or correlation,
#'   `"one.sided"` in the original's direction, planned as BUCSS's
#'   two-sided test at `2 * alpha`.
#' @return A list: `inputs`; `design_label` and `unit` (BUCSS's names for
#'   the design and its sample-size unit); `df_effect`; `f` (the F used,
#'   for an ANOVA); `sizes`, a data frame of `assurance`, `n` (total),
#'   `per_unit` (per group or cell, `NA` when the unit is the total),
#'   `actual_power` and `reason` (`NA`; `"not_plannable"` when the
#'   corrected effect is zero at that assurance; or `"not_significant"`
#'   when the original wasn't significant at `original_alpha`, so there
#'   was no publication threshold to correct for); `assurance_ceiling`;
#'   `function_used`; `packages`; and `script`, an R script that
#'   repeats the calculation.
#' @export
#' @examples
#' if (requireNamespace("BUCSS", quietly = TRUE)) {
#'   # Shnabel et al. (2009), Study 1: a 2 x 2 mixed-design interaction
#'   replication_bucss("anova_mixed", 15.38, 120, levels_a = 2, levels_b = 2,
#'     effect = "interaction", power = 0.9)$sizes
#' }
replication_bucss <- function(design, original_statistic = NULL, original_n, levels_a = NULL, levels_b = NULL,
                              effect = NULL, epsilon = 1, original_partial_eta = NULL, original_df_error = NULL,
                              original_alpha = 0.05, alpha = 0.05, power = 0.8, assurance = c(0.5, 0.8),
                              alternative = "two.sided", publication_filter = TRUE) {
  need_packages("BUCSS")
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x, low) one_number(x) && x == round(x) && x >= low && x <= 1e6
  if (!is.character(design) || length(design) != 1 || !design %in% replication_bucss_designs) {
    abort_run(sprintf("'design' should be one of %s.", paste0("\"", replication_bucss_designs, "\"", collapse = ", ")))
  }
  anova <- startsWith(design, "anova_")
  mixed <- identical(design, "anova_mixed")
  correlation <- identical(design, "correlation")
  if (!is.character(alternative) || length(alternative) != 1 || !alternative %in% c("two.sided", "one.sided")) {
    abort_run("'alternative' should be \"two.sided\" or \"one.sided\".")
  }
  if (!is.logical(publication_filter) || length(publication_filter) != 1 || is.na(publication_filter)) {
    abort_run("'publication_filter' should be TRUE (published because it was significant) or FALSE (published whatever it found).")
  }
  if (anova && identical(alternative, "one.sided")) {
    abort_run("An ANOVA's F test has no direction, so the replication's test is planned as the F test at its significance level.")
  }
  for (level in list(list(original_alpha, "original study's"), list(alpha, "replication's"))) {
    if (!one_number(level[[1]]) || level[[1]] <= 0 || level[[1]] >= 0.5) {
      abort_run(sprintf("The %s significance level should be between 0 and 0.5, for example 0.05.", level[[2]]))
    }
  }
  if (!one_number(power) || power <= alpha || power >= 1) {
    abort_run("The power to aim for should be between the significance level and 1, for example 0.8.")
  }
  if (!is.numeric(assurance) || !length(assurance) || anyNA(assurance) || any(assurance < 0.5 | assurance >= 1)) {
    abort_run("Each level of assurance should be at least 0.5 (BUCSS's recommended floor) and below 1, for example 0.8.")
  }
  df_effect <- NA_real_
  f_used <- NULL
  if (anova) {
    if (!whole(levels_a, 2)) abort_run("The first factor's number of levels should be a whole number, at least 2.")
    if (!is.null(levels_b) && !whole(levels_b, 2)) abort_run("The second factor's number of levels should be a whole number, at least 2.")
    if (mixed && is.null(levels_b)) abort_run("A mixed design needs the levels of its between-subjects and its within-subjects factor.")
    effects <- if (mixed) c("between", "within", "interaction") else if (is.null(levels_b)) "factor_a" else c("factor_a", "factor_b", "interaction")
    if (is.null(effect) && length(effects) == 1) effect <- effects
    if (!is.character(effect) || length(effect) != 1 || !effect %in% effects) {
      abort_run(sprintf("The effect should be one of %s for this design.", paste0("\"", effects, "\"", collapse = ", ")))
    }
    if (!design %in% "anova_between" && (!one_number(epsilon) || epsilon <= 0 || epsilon > 1)) {
      abort_run("The sphericity correction (epsilon) should be above 0 and at most 1; 1 assumes sphericity.")
    }
    df_effect <- replication_bucss_df_effect(design, levels_a, levels_b, effect)
    cells <- if (identical(design, "anova_between")) levels_a * (levels_b %||% 1) else if (mixed) levels_a else 1
    if (!whole(original_n, cells + 1)) {
      abort_run(sprintf("The original study's total sample size should be a whole number, more than %s.",
        if (cells > 1) sprintf("its %s groups", cells) else "1"))
    }
    if (!is.null(original_partial_eta)) {
      if (!is.null(original_statistic)) abort_run("Give the original's F or its partial eta-squared, not both.")
      if (!one_number(original_partial_eta) || original_partial_eta <= 0 || original_partial_eta >= 1) {
        abort_run("The original's partial eta-squared should be between 0 and 1.")
      }
      if (!one_number(original_df_error) || original_df_error <= 0) {
        abort_run("A partial eta-squared needs the error degrees of freedom of its F test, the second number in F(df1, df2).")
      }
      original_statistic <- original_partial_eta / (1 - original_partial_eta) * original_df_error / df_effect
    }
    if (!one_number(original_statistic) || original_statistic <= 0) {
      abort_run("The original's F statistic should be a number above 0.")
    }
    f_used <- original_statistic
  } else {
    if (!whole(original_n, if (correlation) 4 else if (identical(design, "two_groups")) 4 else 2)) {
      abort_run(sprintf("The original study's %s should be a whole number, at least %s.",
        if (identical(design, "paired")) "number of pairs" else "total sample size",
        if (correlation || identical(design, "two_groups")) 4 else 2))
    }
    if (!one_number(original_statistic) || original_statistic == 0 || (correlation && abs(original_statistic) >= 1)) {
      abort_run(if (correlation) "The original correlation should be between -1 and 1, and not 0." else
        "The original's t statistic should be a number, and not 0.")
    }
  }
  alpha_planned <- if (identical(alternative, "one.sided")) 2 * alpha else alpha
  stat <- abs(original_statistic)
  b_effect <- if (anova) c(factor_a = "factor_A", factor_b = "factor_B", interaction = "interaction",
    between = "between", within = "within")[[effect]]
  call_for <- function(a) {
    # No publication filter: alpha_prior = 1 truncates nothing.
    common <- list(alpha_prior = if (publication_filter) original_alpha else 1, alpha_planned = alpha_planned, assurance = a, desired_power = power)
    spec <- switch(design,
      two_groups = list(fun = "ss_buc_independent_t", args = c(list(t_observed = stat, N = original_n), common)),
      one_sample = list(fun = "ss_buc_one_sample_t", args = c(list(t_observed = stat, N = original_n), common)),
      paired = list(fun = "ss_buc_paired_t", args = c(list(t_observed = stat, N = original_n), common)),
      correlation = list(fun = "ss_buc_correlation", args = c(list(r_observed = stat, N = original_n), common)),
      anova_between = if (is.null(levels_b)) {
        list(fun = "ss_buc_one_way_anova", args = c(list(F_observed = stat, N = original_n, levels_A = levels_a), common))
      } else {
        list(fun = "ss_buc_factorial_anova", args = c(list(F_observed = stat, N = original_n, levels_A = levels_a,
          levels_B = levels_b, effect = b_effect), common))
      },
      anova_within = list(fun = "ss_buc_rm_anova", args = c(list(F_observed = stat, N = original_n, levels_A = levels_a,
        levels_B = levels_b, effect = b_effect), common, list(epsilon = epsilon))),
      anova_mixed = list(fun = "ss_buc_mixed_anova", args = c(list(F_observed = stat, N = original_n,
        levels_between = levels_a, levels_within = levels_b, effect = b_effect), common, list(epsilon = epsilon))))
    # A one-factor within design has no second factor: left out, not NULL.
    spec$args <- Filter(Negate(is.null), spec$args)
    spec
  }
  label <- unit <- NA_character_
  ceiling_value <- NA_real_
  rows <- lapply(sort(unique(assurance)), function(a) {
    spec <- call_for(a)
    out <- tryCatch(do.call(getExportedValue("BUCSS", spec$fun), spec$args), error = function(e) e)
    if (inherits(out, "error")) {
      return(data.frame(assurance = a, n = NA_real_, per_unit = NA_real_, actual_power = NA_real_,
        reason = if (inherits(out, "bucss_nonsignificant")) "not_significant" else "not_plannable"))
    }
    value <- stats::setNames(out$value, out$term)
    label <<- attr(out, "design") %||% label
    unit <<- attr(out, "sample_size_unit") %||% unit
    ceiling_value <<- attr(out, "assurance_ceiling") %||% ceiling_value
    per <- grep("^necessary_n_per", names(value), value = TRUE)
    total <- if ("total_N" %in% names(value)) value[["total_N"]] else value[["necessary_N"]]
    data.frame(assurance = a, n = total, per_unit = if (length(per)) value[[per[[1]]]] else NA_real_,
      actual_power = value[["actual_power"]], reason = NA_character_)
  })
  spec <- call_for(max(assurance))
  args_text <- vapply(names(spec$args), function(k) {
    v <- spec$args[[k]]
    if (identical(k, "assurance")) return("assurance = a")
    sprintf("%s = %s", k, if (is.character(v)) sprintf("\"%s\"", v) else format(signif(v, 8)))
  }, character(1))
  res <- list(
    inputs = list(design = design, original_statistic = original_statistic, original_n = original_n,
      levels_a = levels_a, levels_b = levels_b, effect = effect, epsilon = if (anova && !identical(design, "anova_between")) epsilon,
      original_partial_eta = original_partial_eta, original_df_error = original_df_error,
      original_alpha = original_alpha, alpha = alpha, power = power, assurance = sort(unique(assurance)),
      alternative = alternative, publication_filter = publication_filter),
    design_label = label,
    unit = unit,
    df_effect = df_effect,
    f = f_used,
    sizes = do.call(rbind, rows),
    assurance_ceiling = ceiling_value,
    function_used = sprintf("BUCSS::%s(%s)", spec$fun, paste(args_text, collapse = ", ")),
    packages = list(list(name = "BUCSS", version = as.character(utils::packageVersion("BUCSS"))))
  )
  res$script <- paste(replication_bucss_script(res), collapse = "\n")
  res
}

# The R script for a BUCSS plan: the same call, at each assurance.
replication_bucss_script <- function(res, header = TRUE) {
  c(
    if (header) c(
      "# Replication plan, from powerkit's replication plan:",
      if (isFALSE(res$inputs$publication_filter)) "# the sample size for a significant result, corrected for uncertainty (no publication filter: alpha_prior = 1),"
        else "# the sample size for a significant result, corrected for publication bias and uncertainty,",
      "# with BUCSS (Anderson, Kelley & Maxwell, 2017).",
      sprintf("# Written by powerkit %s on %s.", as.character(utils::packageVersion("powerkit")), format(Sys.Date())),
      ""),
    if (!is.null(res$inputs$original_partial_eta)) sprintf(
      "# The original's partial eta-squared (%s) with F(%s, %s), as its F (Lakens, 2013): %s",
      format(signif(res$inputs$original_partial_eta, 6)), format(res$df_effect), format(res$inputs$original_df_error),
      format(signif(res$f, 8))),
    "library(BUCSS)",
    sprintf("for (a in c(%s)) {", paste(format(res$inputs$assurance), collapse = ", ")),
    sprintf("  plan <- tryCatch(%s,", sub("^BUCSS::", "", res$function_used)),
    "    error = function(e) conditionMessage(e))  # BUCSS explains when the original is too weak to plan from",
    "  print(plan)",
    "}"
  )
}
