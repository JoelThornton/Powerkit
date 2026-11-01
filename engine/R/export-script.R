#' Write an R script that reproduces a result
#'
#' Writes a standalone R script that reproduces a [run_spec()] result by
#' calling the package that computed it (pwr, stats, pwrss, Spower, Superpower,
#' InteractionPoweR or power4mome) directly, with the design's values
#' filled in and a comment on each argument. powerkit is not needed to run
#' the script.
#'
#' The script repeats what powerkit did, so it gives the same numbers with
#' the same package versions:
#' * simulations use powerkit's seeds and its split of the replications
#'   into batches (one per core, or for power4mome batches of at most
#'   `provenance$batch_size` replications), each an ordinary call to the
#'   backend with its own seed;
#' * for a sample-size goal it simulates every sample size powerkit
#'   simulated and fits the same probit curve to find the required n and
#'   its 95% interval (powerkit's quicker first pass, which only chose
#'   those sizes, is not repeated);
#' * exact 2x2 results use `ANOVA_exact()` under the run's seed;
#' * exact basic-test results call pwr's formula, or for two proportions
#'   `power.prop.test()` (equal groups) or pwrss (unequal groups) (for a sample-size goal, at
#'   the sizes powerkit computed, around the required n).
#'
#' When the spec gives `options > attrition`, the script also works out the
#' number to recruit, as [run_spec()] does. It ends by comparing its numbers
#' with powerkit's and printing `sessionInfo()`. It doesn't repeat the check
#' run.
#'
#' @param spec The spec the result was run from: a list, a JSON string or a
#'   path to a JSON file.
#' @param result The `powerkit_result` returned by [run_spec()] for `spec`.
#' @param file Path to write the script to (UTF-8), or `NULL` to only
#'   return it.
#'
#' @return The script as a single string; invisibly if `file` is given.
#' @seealso [export_citations()]
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' result <- run_spec(spec)
#' cat(export_script(spec, result))
#' }
export_script <- function(spec, result, file = NULL) {
  spec <- spec_for_export(spec, result)
  lines <- if (justified_alpha_goal(spec)) justified_alpha_script(spec, result) else if (precision_goal(spec)) {
    precision_script(spec, result)
  } else switch(
    result$provenance$backend,
    pwr = ,
    stats = if (variance_formula_test(spec)) {
      variance_script(spec, result)
    } else if (hotelling_formula_test(spec)) {
      hotelling_script(spec, result)
    } else {
      pwr_script(spec, result)
    },
    pwrss = if (spec$design == "generic_test") {
      generic_script(spec, result)
    } else if (startsWith(spec$template, "noninf_")) {
      noninf_script(spec, result)
    } else if (minimum_effect_test(spec)) {
      met_script(spec, result)
    } else if (pwrss_covers(spec)) {
      pwrss_script(spec, result)
    } else {
      pwr_script(spec, result)
    },
    Spower = if (meta_subgroups(spec)) meta_subgroups_script(spec, result) else
      if (identical(spec$design, "meta_analysis")) meta_hk_script(spec, result) else spower_script(spec, result),
    Superpower = superpower_script(spec, result),
    InteractionPoweR = interactionpower_script(spec, result),
    power4mome = if (identical(spec$design, "dyadic")) apim_script(spec, result) else power4mome_script(spec, result),
    TOSTER = toster_script(spec, result),
    bfpwr = bfpwr_script(spec, result),
    metapower = if (meta_subgroups(spec)) meta_subgroups_script(spec, result) else metapower_script(spec, result),
    powertools = powertools_script(spec, result),
    semPower = sempower_script(spec, result),
    simr = switch(spec$template, two_level = two_level_script(spec, result), three_level = three_level_script(spec, result),
      item_predictor = item_predictor_script(spec, result),
      crossed_conditions = crossed_conditions_script(spec, result), simr_script(spec, result)),
    abort_export(sprintf(
      "Script export isn't available for results from %s.", result$provenance$backend
    ))
  )
  lines <- add_recruitment_section(lines, spec, result)
  lines <- c(lines, simulated_data_section(spec, simulated_data_n(spec, result), result$provenance$seed))
  text <- paste(c(lines, ""), collapse = "\n")
  if (is.null(file)) {
    return(text)
  }
  write_utf8(text, file)
  invisible(text)
}

# The validated spec, after checking that `result` was run from it.
spec_for_export <- function(spec, result) {
  if (!inherits(result, "powerkit_result")) {
    abort_export("'result' should be the result of run_spec() (a powerkit result).")
  }
  spec <- withCallingHandlers(
    validate_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
  if (!identical(spec_hash(spec), result$provenance$spec_hash)) {
    abort_export(
      "This result wasn't produced from this spec (their spec hashes differ). Export the spec and the result from the same run."
    )
  }
  if (identical(result$provenance$method, "simulation") && !is.data.frame(result$provenance$simulations)) {
    abort_export(
      "This result doesn't record the seed of each simulated sample size, which the script needs. It may come from an older version of powerkit; run the spec again."
    )
  }
  spec
}

abort_export <- function(message) {
  abort_run(message, class = "powerkit_export_error")
}

write_utf8 <- function(text, file) {
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(text, con, sep = "")
}

# R code for a value: numbers to 15 significant digits (17 if needed to
# give back exactly the same number), strings quoted, vectors in c().
r_code <- function(x) {
  one <- function(v) {
    if (is.character(v)) {
      return(encodeString(v, quote = "\""))
    }
    if (is.logical(v)) {
      return(if (is.na(v)) "NA" else as.character(v))
    }
    if (is.na(v)) {
      return("NA")
    }
    short <- format(v, digits = 15, scientific = FALSE, trim = TRUE)
    if (as.numeric(short) == v) short else sprintf("%.17g", v)
  }
  x <- unlist(x, use.names = FALSE)
  values <- vapply(x, one, character(1), USE.NAMES = FALSE)
  if (length(values) == 1) values else paste0("c(", paste(values, collapse = ", "), ")")
}

# A label or level for use in a comment, on one line.
comment_text <- function(x) gsub("[\r\n]+", " ", as.character(x))

# Lines of a string built from one line per element, as R code.
r_multiline_string <- function(name, lines, comment) {
  c(
    comment,
    sprintf("%s <- paste(", name),
    paste0("  ", vapply(lines, encodeString, character(1), quote = "\"", USE.NAMES = FALSE), ","),
    "  sep = \"\\n\"",
    ")"
  )
}

# Script sections shared by every backend ------------------------------------

script_header <- function(spec, result, package, call_description) {
  p <- result$provenance
  versions <- p$packages[names(p$packages) != "powerkit"]
  c(
    sprintf("# Reproduces a powerkit power analysis by calling %s directly.", package),
    "# powerkit itself is not needed to run this script.",
    "#",
    sprintf("# Generated by powerkit %s on %s.", p$packages[["powerkit"]], format(Sys.Date(), "%d %B %Y")),
    sprintf("# Design specification hash (SHA-256): %s", p$spec_hash),
    sprintf("# powerkit's run used %s and %s.", p$r_version, paste(names(versions), versions, collapse = ", ")),
    "# Other versions of these packages may give slightly different numbers.",
    "#",
    sprintf("# Design: %s", design_description(spec)),
    sprintf("# Goal: %s", goal_description(spec)),
    sprintf("# Method: %s", method_description(result)),
    sprintf("# Calculation: %s", call_description),
    "#",
    sprintf("# %s did this calculation. Please cite it: run citation(\"%s\"),", package, package),
    "# and see powerkit's citations export for its method paper.",
    ""
  )
}

design_description <- function(spec) {
  v <- spec$variables
  factor_kind <- function(role) if (identical(v[[role]]$type, "within_factor")) "within" else "between participants"
  label <- function(role) comment_text(v[[role]]$label)
  levels <- function(role) paste(comment_text(unlist(v[[role]]$levels)), collapse = ", ")
  if (rank_test(spec)) {
    return(rank_design_description(spec, label, levels))
  }
  if (bayes_factor_test(spec)) {
    return(bayes_design_description(spec, label, levels))
  }
  if (minimum_effect_test(spec)) {
    base <- spec
    base$target_test$method <- if (identical(spec$template, "independent_t")) "student_t" else "t_test"
    return(sprintf("minimum-effect test (smallest effect of interest %s = %s): %s",
      if (identical(spec$template, "paired_t")) "d_z" else "d", format_number(spec$population$margin), design_description(base)))
  }
  if (meta_subgroups(spec)) {
    return(sprintf("%s meta-analysis of %s: does the average effect differ between %d kinds of study (%s = %s), %s, studies of %s participants with I-squared %s",
      if (identical(spec$target_test$model, "fixed")) "fixed-effect" else "random-effects", label("Y"),
      length(unlist(spec$population$effects)), if (identical(spec$population$metric, "r")) "r" else "Cohen's d",
      paste(format_number(as.numeric(unlist(spec$population$effects))), collapse = ", "),
      if (hartung_knapp_test(spec)) "Hartung-Knapp test" else "Q test", format_number(spec$population$study_size), format_number(spec$population$i2)))
  }
  if (identical(spec$design, "meta_analysis")) {
    return(meta_design_description(spec, label))
  }
  if (identical(spec$design, "dyadic")) {
    members <- unlist(spec$population$members %||% list("member 1", "member 2"))
    effect <- switch(spec$target_test$effect, actor = "the actor effect", partner = "the partner effect",
      actor_1 = sprintf("the actor effect for %s", members[1]), actor_2 = sprintf("the actor effect for %s", members[2]),
      partner_12 = sprintf("the partner effect of %s on %s", members[1], members[2]),
      partner_21 = sprintf("the partner effect of %s on %s", members[2], members[1]))
    return(sprintf("actor-partner interdependence model for %s dyads: %s predicting %s; effect tested: %s",
      if (isTRUE(spec$population$distinguishable)) "distinguishable" else "indistinguishable", label("X"), label("Y"), effect))
  }
  switch(
    paste(spec$design, spec$template, sep = "/"),
    "basic_test/one_sample_t" = sprintf("one-sample t-test of %s", label("Y")),
    "basic_test/independent_t" = sprintf(
      "independent-samples t-test (%s) of %s between the groups of %s (%s)",
      if (spec$target_test$method == "welch_t") "Welch's" else "Student's",
      label("Y"), label("X"), levels("X")
    ),
    "basic_test/paired_t" = sprintf(
      "paired-samples t-test of %s between the conditions of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "basic_test/correlation" = sprintf(
      "%s of %s with %s",
      switch(spec$target_test$method %||% "pearson", spearman = "Spearman's rank correlation (rho)", kendall = "Kendall's rank correlation (tau)", "Pearson correlation"),
      label("X"), label("Y")
    ),
    "basic_test/two_proportions" = sprintf(
      "%s of two proportions: %s between the groups of %s (%s)",
      if (identical(spec$target_test$method, "fisher_exact")) "Fisher's exact test" else "z test",
      label("Y"), label("X"), levels("X")
    ),
    "basic_test/two_correlations" = sprintf(
      "comparison of two correlations (Fisher's z test): %s with %s, between the groups of %s (%s)",
      label("X"), label("Y"), label("G"), levels("G")
    ),
    "basic_test/overlapping_correlations" = sprintf(
      "comparison of two dependent correlations (Steiger's z test), same people: %s with %s against %s with %s",
      label("X"), label("Y"), label("X"), label("Z")
    ),
    "basic_test/nonoverlapping_correlations" = sprintf(
      "comparison of two dependent correlations (Steiger's z test), same people: %s with %s against %s with %s",
      label("X1"), label("Y1"), label("X2"), label("Y2")
    ),
    "basic_test/chi_square_gof" = if (chisq_by_w(spec)) {
      sprintf("chi-square goodness-of-fit test of %s (%s), from Cohen's w", label("Y"), levels("Y"))
    } else {
      sprintf(
        "chi-square goodness-of-fit test of %s (%s) against %s proportions",
        label("Y"), levels("Y"), if (is.null(spec$population$null_probabilities)) "equal" else "fixed"
      )
    },
    "factorial_anova/oneway_ancova" = sprintf(
      "one-way ANCOVA of %s across the %d groups of %s (%s), adjusting for %s covariate%s; omnibus F test",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A"),
      spec$population$covariates, if (spec$population$covariates == 1) "" else "s"
    ),
    "factorial_anova/factorial_ancova" = sprintf(
      "two-way ANCOVA of %s: %s (%s) by %s (%s), adjusting for %s covariate%s; effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"),
      spec$population$covariates, if (spec$population$covariates == 1) "" else "s", anova_effect_name(spec)
    ),
    "factorial_anova/oneway_contrast" = sprintf(
      "planned comparison of %s across the %d groups of %s (%s), with weights %s; t test of the contrast",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A"),
      paste(format_number(as.numeric(unlist(spec$target_test$weights))), collapse = ", ")
    ),
    "basic_test/one_variance" = sprintf(
      "chi-square test of one variance: is the variance of %s different from a fixed value?",
      label("Y")
    ),
    "basic_test/proportion_trend" = sprintf(
      "Cochran-Armitage test of a linear trend in %s = %s across the %d groups of %s in order (%s), scores %s",
      label("Y"), comment_text(unlist(v$Y$levels)[2] %||% "yes"), length(unlist(v$X$levels)), label("X"), levels("X"),
      paste(format_number(trend_scores(spec)), collapse = ", ")
    ),
    "basic_test/two_variances" = sprintf(
      "F test of two variances: does the variance of %s differ between the groups of %s (%s)?",
      label("Y"), label("G"), levels("G")
    ),
    "basic_test/manova" = if (is.null(v$B)) {
      sprintf(
        "one-way MANOVA of %s across the %d groups of %s (%s); Pillai's trace%s",
        paste(vapply(manova_outcomes(spec), label, character(1)), collapse = ", "), length(unlist(v$A$levels)), label("A"), levels("A"),
        if (length(unlist(v$A$levels)) == 2) " (with two groups, Hotelling's T-squared)" else ""
      )
    } else {
      sprintf(
        "two-way MANOVA of %s by %s (%s) and %s (%s); Pillai's trace of %s",
        paste(vapply(manova_outcomes(spec), label, character(1)), collapse = ", "), label("A"), levels("A"), label("B"), levels("B"),
        switch(spec$target_test$effect, main_effect_A = label("A"), main_effect_B = label("B"), interaction = "their interaction")
      )
    },
    "basic_test/hotelling_one" = sprintf(
      "one-sample Hotelling's T-squared: do the means of %s differ from the fixed values (%s)?",
      paste(vapply(manova_outcomes(spec), label, character(1)), collapse = ", "),
      paste(format_number(as.numeric(unlist(spec$population$mu0))), collapse = ", ")
    ),
    "basic_test/paired_variances" = sprintf(
      "Pitman-Morgan test of two paired variances: does the variance of %s differ between %s (%s), in the same people?",
      label("Y"), label("X"), levels("X")
    ),
    "basic_test/one_proportion" = sprintf(
      "exact binomial test of one proportion: %s = %s, compared with a fixed value",
      label("Y"), comment_text(unlist(v$Y$levels)[2])
    ),
    "basic_test/mcnemar" = sprintf(
      "McNemar's exact test: %s = %s, compared between the conditions of %s (%s), same people",
      label("Y"), comment_text(unlist(v$Y$levels)[2]), label("X"), levels("X")
    ),
    "factorial_anova/oneway_between" = sprintf(
      "one-way between-participants ANOVA of %s across the %d groups of %s (%s); %s",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A"),
      if (welch_anova(spec)) "Welch's F test (variances not assumed equal)" else "omnibus F test"
    ),
    "factorial_anova/oneway_within" = sprintf(
      "one-way repeated-measures ANOVA of %s across the %d conditions of %s (%s), the same people in every condition; omnibus F test, %s",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A"), sphericity_words(spec)
    ),
    "ordinal_regression/ordinal_two_groups" = sprintf(
      "ordinal outcome: %s (%s, in order) compared between the groups of %s (%s), proportional odds",
      label("Y"), levels("Y"), label("X"), levels("X")
    ),
    "logistic_regression/factorial" = sprintf(
      "logistic regression of %s (%s) on %s (%s) by %s (%s), different people in every cell; effect tested: %s",
      label("Y"), levels("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "logistic_regression/single_predictor" = sprintf(
      "logistic regression of %s (%s) on %s%s: Wald z test of %s",
      label("Y"), levels("Y"), label("X"),
      if (identical(v$X$type, "binary")) sprintf(" (%s)", levels("X")) else "",
      if (isTRUE((spec$population$r2_other_predictors %||% 0) > 0)) "its coefficient, adjusting for other predictors" else "its coefficient"
    ),
    "poisson_regression/single_predictor_count" = sprintf(
      "Poisson regression of %s (a count) on %s%s: Wald z test of %s",
      label("Y"), label("X"),
      if (identical(v$X$type, "binary")) sprintf(" (%s)", levels("X")) else "",
      if (isTRUE((spec$population$r2_other_predictors %||% 0) > 0)) "its coefficient, adjusting for other predictors" else "its coefficient"
    ),
    "multiple_regression/r2_zero" = sprintf(
      "multiple regression of %s on %s predictors: is R-squared greater than 0? (F test)",
      label("Y"), spec$population$predictors
    ),
    "multiple_regression/r2_increase" = sprintf(
      "multiple regression of %s: does adding %s predictors to %s others increase R-squared? (F test)",
      label("Y"), spec$population$predictors_tested,
      spec$population$predictors_total - spec$population$predictors_tested
    ),
    "equivalence_test/tost_independent" = sprintf(
      "equivalence test (two one-sided t-tests, TOST) of %s between the groups of %s (%s)",
      label("Y"), label("X"), levels("X")
    ),
    "equivalence_test/tost_paired" = sprintf(
      "equivalence test (two one-sided paired t-tests, TOST) of %s between %s (%s)",
      label("Y"), label("X"), levels("X")
    ),
    "equivalence_test/tost_one_sample" = sprintf(
      "equivalence test (two one-sided one-sample t-tests, TOST) of %s against a fixed value", label("Y")
    ),
    "equivalence_test/noninf_independent" = sprintf(
      "non-inferiority test (one-sided t-test against the margin) of %s between the groups of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "equivalence_test/noninf_paired" = sprintf(
      "non-inferiority test (one-sided paired t-test against the margin) of %s between %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "equivalence_test/noninf_one_sample" = sprintf(
      "non-inferiority test (one-sided one-sample t-test against the margin) of %s against a reference value", label("Y")
    ),
    "equivalence_test/noninf_two_proportions" = sprintf(
      "non-inferiority test (one-sided z test against the margin) of %s between the groups of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "equivalence_test/tost_correlation" = sprintf(
      "equivalence test (two one-sided z tests on Fisher's z, TOST) of the correlation between %s and %s", label("X"), label("Y")
    ),
    "equivalence_test/tost_two_proportions" = sprintf(
      "equivalence test (two one-sided z tests, TOST) of the difference in %s between the groups of %s (%s)",
      label("Y"), label("X"), levels("X")
    ),
    "cluster_trial/cluster_randomised" = sprintf(
      "cluster-randomised trial: %s compared between the conditions of %s (%s), whole groups of %s assigned to each; %s",
      label("Y"), label("X"), levels("X"), spec$population$cluster_size, cluster_test_words(spec, "t test of the difference")
    ),
    "cluster_trial/multisite" = sprintf(
      "multisite trial: %s compared between the conditions of %s (%s), people randomised within each group of %s; %s",
      label("Y"), label("X"), levels("X"), spec$population$cluster_size, cluster_test_words(spec, "t test of the average difference")
    ),
    "cluster_trial/group_treatment" = sprintf(
      "group treatment trial: %s compared between the conditions of %s (%s), people randomised one by one and the second condition delivered in groups of %s; %s",
      label("Y"), label("X"), levels("X"), spec$population$cluster_size,
      if (identical(spec$population$metric, "proportion")) "yes/no outcome, z test of the difference in proportions" else "t test with Satterthwaite degrees of freedom"
    ),
    "sem/model_fit" = sprintf(
      "structural equation model: chi-square test of exact fit, power to reject a model with RMSEA %s on %s degrees of freedom",
      spec$population$rmsea, sem_df(spec)
    ),
    "sem/invariance" = sprintf(
      "measurement invariance across two groups: chi-square difference test of %s invariance, one factor of %s items (loading %s), %s of them %s in the second group",
      spec$population$level, spec$population$indicators, spec$population$loading, spec$population$noninvariant,
      if (identical(spec$population$level, "metric")) sprintf("with loading %s", spec$population$loading_group2)
      else sprintf("with intercepts shifted by %s SD", spec$population$intercept_difference)
    ),
    "sem/factor_correlation" = sprintf(
      "correlation between two factors (%s and %s items, loadings %s and %s): chi-square difference test of r = %s against 0",
      spec$population$indicators[[1]], spec$population$indicators[[2]], spec$population$loadings[[1]],
      spec$population$loadings[[2]], spec$population$r
    ),
    "sem/latent_regression" = sprintf(
      "latent regression: chi-square difference test of slope %s (%s) against 0, %s latent predictor%s, %s items per factor (loading %s)",
      spec$population$tested %||% 1L, spec$population$slopes[[spec$population$tested %||% 1L]],
      length(spec$population$slopes), if (length(spec$population$slopes) == 1) "" else "s",
      spec$population$indicators, spec$population$loading
    ),
    "precision/two_groups" = sprintf("confidence interval for Cohen's d of %s (%s) between %s (expected d = %s; two equal groups)",
      label("Y"), "noncentral t", levels("X"), spec$population$d),
    "precision/one_group" = sprintf("confidence interval for the standardised mean of %s (expected %s; noncentral t)", label("Y"), spec$population$d),
    "precision/paired" = sprintf("confidence interval for d_z, the paired difference in %s between %s (expected d_z = %s; noncentral t)",
      label("Y"), levels("X"), spec$population$dz),
    "precision/correlation" = sprintf("confidence interval for the %s correlation of %s and %s (expected r = %s)",
      spec$target_test$method, label("X"), label("Y"), spec$population$r),
    "precision/mean_difference" = sprintf("confidence interval for the difference in mean %s (expected %s, SD %s; two equal groups)",
      label("Y"), format_number(spec$population$difference), format_number(spec$population$sd)),
    "precision/odds_ratio" = sprintf("confidence interval for the odds ratio of %s (expected proportions %s and %s; two equal groups)",
      label("Y"), format_number(spec$population$p1), format_number(spec$population$p2)),
    "precision/icc" = sprintf("confidence interval for the ICC of %s (expected %s, %s ratings per subject)",
      label("Y"), format_number(spec$population$icc), format_number(spec$population$raters)),
    "precision/regression_coefficient" = sprintf("confidence interval for the standardised coefficient of %s on %s (expected %s; %s predictors, R-squared %s)",
      label("Y"), label("X"), format_number(spec$population$b), format_number(spec$population$predictors), format_number(spec$population$r2)),
    "precision/proportion" = sprintf("confidence interval for the proportion %s (expected %s; %s interval)",
      label("Y"), spec$population$p, switch(spec$target_test$method, wilson = "Wilson", agresti_coull = "Agresti-Coull", exact = "exact (Clopper-Pearson)", wald = "Wald")),
    "generic_test/t" = sprintf("generic t test with %s degrees of freedom", spec$population$df),
    "generic_test/f" = sprintf("generic F test with %s and %s degrees of freedom", spec$population$df1, spec$population$df2),
    "generic_test/chi_square" = sprintf("generic chi-square test with %s degrees of freedom", spec$population$df),
    "generic_test/z" = "generic z test (SD 1 under both hypotheses)",
    "basic_test/chi_square_independence" = sprintf(
      "chi-square test of independence of %s (%s) and %s (%s)", label("X"), levels("X"), label("Y"), levels("Y")
    ),
    "factorial_anova/2x2_between" = sprintf(
      "2 x 2 between-participants ANOVA of %s: %s (%s) by %s (%s); effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "factorial_anova/mixed" = sprintf(
      "mixed ANOVA of %s: %s (%s, between participants) by %s (%s, within); effect tested: %s; %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec), sphericity_words(spec)
    ),
    "factorial_anova/factorial_between" = sprintf(
      "two-factor between-participants ANOVA of %s: %s (%s) by %s (%s); effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "factorial_anova/factorial_within" = sprintf(
      "two-factor within-participants ANOVA of %s: %s (%s) by %s (%s), everyone in every condition; effect tested: %s; %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec), sphericity_words(spec)
    ),
    "factorial_anova/factorial_three" = sprintf(
      "three-factor ANOVA of %s: %s (%s, %s) by %s (%s, %s) by %s (%s, %s); effect tested: %s%s",
      label("Y"),
      label("A"), levels("A"), factor_kind("A"),
      label("B"), levels("B"), factor_kind("B"),
      label("C"), levels("C"), factor_kind("C"),
      anova_effect_name(spec),
      if (any(three_factor_within(spec))) "; sphericity assumed" else ""
    ),
    "factorial_anova/2x2_mixed" = sprintf(
      "2 x 2 mixed ANOVA of %s: %s (%s, between participants) by %s (%s, within); effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "mixed_model/crossed_conditions" = sprintf(
      "participants responding to %s items in %d conditions of %s (%s, %s participants); effect tested: %s",
      format_number(spec$population$items), length(spec$variables$X$levels), label("X"), levels("X"),
      if (identical(spec$variables$X$type, "between_factor")) "between" else "within",
      if (identical(spec$target_test$effect, "pairwise")) {
        sprintf("%s against %s (%s adjustment for all the pairs)", spec$target_test$comparison[[1]],
          spec$target_test$comparison[[2]], spec$target_test$p_adjust %||% "holm")
      } else {
        "any difference between the conditions"
      }
    ),
    "mixed_model/item_predictor" = sprintf(
      "participants responding to %s items that differ on %s (measured on each item, per SD); outcome %s%s",
      format_number(spec$population$items), label("X"), label("Y"),
      if (identical(spec$variables$Y$type, "binary")) " (yes/no, a logistic mixed model)" else ""
    ),
    "mixed_model/three_level" = sprintf(
      "three levels, people in groups of %s in sites of %s groups; %s (%s) assigned to %s; outcome %s",
      format_number(spec$population$group_size), format_number(spec$population$groups_per_site), label("X"), levels("X"),
      switch(spec$population$assignment, site = "whole sites", group = "groups within each site", person = "people within each group"),
      label("Y")
    ),
    "mixed_model/two_level" = sprintf(
      "people in groups of %s: %s (measured on each person, centred within groups) and %s (measured on each group) predicting %s; effect tested: %s",
      format_number(spec$population$cluster_size), label("X"), label("W"), label("Y"),
      switch(spec$target_test$effect, within_effect = sprintf("%s within groups", label("X")),
        between_effect = sprintf("%s between groups", label("W")), cross_level_interaction = "the cross-level interaction")
    ),
    "regression_interaction/three_way" = sprintf(
      "three-way regression interaction: does the interaction of %s (X) and %s (W) on %s (Y) depend on %s (Z)?",
      label("X"), label("W"), label("Y"), label("Z")
    ),
    "regression_interaction/two_way" = sprintf(
      "regression interaction: does the effect of %s (X) on %s (Y) depend on %s (W)?",
      label("X"), label("Y"), label("W")
    ),
    "mediation/process_4" = sprintf(
      "%s mediation (PROCESS model 4); indirect effect tested: %s",
      if (length(path_model(spec)$mediators) > 1) "parallel" else "simple", spec$target_test$path
    ),
    "mediation/process_6" = sprintf(
      "serial mediation (PROCESS model 6); indirect effect tested: %s", spec$target_test$path
    ),
    "moderated_mediation/process_7" = sprintf(
      "first-stage moderated mediation (PROCESS model 7): %s (W) moderates %s (X) -> %s; index of moderated mediation for Y = %s%s",
      label("W"), label("X"), mediator_words(spec, label), label("Y"), tested_mediator_words(spec, label)
    ),
    "moderated_mediation/process_14" = sprintf(
      "second-stage moderated mediation (PROCESS model 14): %s (W) moderates %s -> %s (Y); index of moderated mediation for X = %s%s",
      label("W"), mediator_words(spec, label), label("Y"), label("X"), tested_mediator_words(spec, label)
    )
  )
}

# The mediator, or each parallel mediator, as "Label (M1)".
mediator_words <- function(spec, label) {
  ms <- path_model(spec)$mediators
  words <- vapply(ms, function(m) sprintf("%s (%s)", label(m), m), character(1))
  if (length(ms) == 1) {
    return(words)
  }
  paste("each of", paste(utils::head(words, -1), collapse = ", "), "and", words[length(words)])
}

tested_mediator_words <- function(spec, label) {
  if (length(path_model(spec)$mediators) < 2) {
    return("")
  }
  m <- modmed_mediator(spec)
  sprintf(", through %s (%s)", label(m), m)
}

rank_design_description <- function(spec, label, levels) {
  v <- spec$variables
  test <- switch(
    spec$template,
    one_sample_t = sprintf("one-sample Wilcoxon signed-rank test of %s", label("Y")),
    paired_t = sprintf(
      "Wilcoxon signed-rank test of %s between the conditions of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    independent_t = sprintf(
      "Mann-Whitney (Wilcoxon rank-sum) test of %s between the groups of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    oneway_between = sprintf(
      "%s test of %s across the %d groups of %s (%s)%s",
      if (jonckheere_test(spec)) "Jonckheere-Terpstra" else "Kruskal-Wallis",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A"),
      if (jonckheere_test(spec)) ", a trend in the order given" else ""
    ),
    oneway_within = sprintf(
      "Friedman's test of %s across the %d conditions of %s (%s), everyone in every condition",
      label("Y"), length(unlist(v$A$levels)), label("A"), levels("A")
    )
  )
  sprintf("%s, simulated with %s", test, score_shape_words(spec$population$score_shape))
}

anova_effect_name <- function(spec) {
  v <- spec$variables
  switch(
    spec$target_test$effect,
    main_effect_A = sprintf("main effect of %s", comment_text(v$A$label)),
    main_effect_B = sprintf("main effect of %s", comment_text(v$B$label)),
    interaction = sprintf("%s x %s interaction", comment_text(v$A$label), comment_text(v$B$label)),
    main_effect_C = sprintf("main effect of %s", comment_text(v$C$label)),
    interaction_AB = sprintf("%s x %s interaction", comment_text(v$A$label), comment_text(v$B$label)),
    interaction_AC = sprintf("%s x %s interaction", comment_text(v$A$label), comment_text(v$C$label)),
    interaction_BC = sprintf("%s x %s interaction", comment_text(v$B$label), comment_text(v$C$label)),
    interaction_ABC = sprintf(
      "%s x %s x %s interaction", comment_text(v$A$label), comment_text(v$B$label), comment_text(v$C$label)
    )
  )
}

goal_description <- function(spec) {
  goal <- spec$goal
  if (bayes_factor_test(spec)) {
    return(switch(
      goal$type,
      power = sprintf("the probability of strong evidence (BF10 at least %s) at a total sample size of %s", bfpwr_inputs(spec)$threshold, goal$n),
      sample_size = sprintf("the smallest total sample size with a probability of at least %s of strong evidence (BF10 at least %s)", goal$power, bfpwr_inputs(spec)$threshold)
    ))
  }
  if (precision_goal(spec)) {
    level <- sprintf("%s%%", format(100 * (1 - spec$target_test$alpha)))
    return(if (!is.null(goal$width)) {
      sprintf("the smallest total sample size whose %s confidence interval is %s no wider than %s", level,
        if (is.null(goal$assurance)) "expected to be" else sprintf("with a %s chance", format(goal$assurance)), format(goal$width))
    } else {
      sprintf("the width of the %s confidence interval expected with a total sample size of %s", level, goal$n)
    })
  }
  if (spec$design == "generic_test") {
    return(switch(
      goal$type,
      power = sprintf("power for a noncentrality of %s, alpha = %s", spec$population$ncp, spec$target_test$alpha),
      sensitivity = sprintf("the noncentrality needed for power %s, alpha = %s", goal$power, spec$target_test$alpha)
    ))
  }
  switch(
    goal$type,
    power = sprintf("power at a total sample size of %s, alpha = %s", goal$n, spec$target_test$alpha),
    sample_size = sprintf(
      "the smallest total sample size with power of at least %s, alpha = %s", goal$power, spec$target_test$alpha
    ),
    sensitivity = sprintf(
      "the smallest effect (of the specified pattern) with power %s at a total sample size of %s, alpha = %s",
      goal$power, goal$n, spec$target_test$alpha
    )
  )
}

method_description <- function(result) {
  p <- result$provenance
  if (p$method == "exact") {
    return("exact (no simulation)")
  }
  if (p$method == "analytic") {
    return("fixed-model formula (no simulation)")
  }
  sprintf("simulation, %s replications per sample size, seed %s", p$nrep, p$seed)
}

# Inputs every script has: alpha, the goal and, for simulation, the
# replications and seed.
goal_inputs <- function(spec, result) {
  goal <- spec$goal
  p <- result$provenance
  c(
    sprintf("alpha <- %s # significance level", r_code(spec$target_test$alpha)),
    if (goal$type != "sample_size") {
      sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(goal$n))
    },
    if (goal$type != "power") {
      sprintf("target_power <- %s", r_code(goal$power))
    },
    if (p$method == "simulation") {
      c(
        sprintf("replications <- %s # simulated data sets per sample size", r_code(p$nrep)),
        sprintf("seed <- %s # powerkit's seed for this run", r_code(p$seed))
      )
    } else if (p$backend %in% c("pwr", "stats", "pwrss", "TOSTER", "powertools", "semPower") || p$method == "analytic") {
      sprintf(
        "# powerkit recorded seed %s for this run; %s's formulas draw no random numbers, so it isn't used.",
        p$seed, p$backend
      )
    } else {
      sprintf("seed <- %s # powerkit's seed for this run (see below)", r_code(p$seed))
    }
  )
}

# simulate_power(n_total, seed): rejections and analysable replications at
# n_total, from run_batch() over powerkit's batches (simulate_in_chunks()).
batch_section <- function(result, function_name) {
  p <- result$provenance
  batched <- !is.na(p$batch_size)
  c(
    "# powerkit splits the replications at each sample size into batches, as",
    "# equal in size as possible. Each batch is one call with its own seed",
    "# (seed, seed + 1, ...), and only its counts are kept. This is powerkit's",
    "# split, so the script simulates exactly the same data sets.",
    if (batched) {
      c(
        sprintf("# Batches hold at most %s replications: %s keeps every", p$batch_size, function_name),
        "# replication's data and fit until it returns, so batches bound memory use.",
        sprintf("batch_size <- %s", r_code(p$batch_size)),
        "batch_sizes <- function(replications) {",
        "  batches <- max(1, min(ceiling(replications / batch_size), replications))"
      )
    } else {
      c(
        sprintf(
          "# powerkit ran on %s %s, with one batch per core.", p$cores, if (p$cores == 1) "core" else "cores"
        ),
        "batch_sizes <- function(replications) {",
        sprintf("  batches <- max(1, min(%s, replications))", r_code(p$cores))
      )
    },
    "  replications %/% batches +",
    "    c(rep(1, replications %% batches), rep(0, batches - replications %% batches))",
    "}",
    "",
    "simulate_power <- function(n_total, seed) {",
    "  sizes <- batch_sizes(replications)",
    "  counts <- vapply(seq_along(sizes), function(i) {",
    "    batch_seed <- (seed + i - 2) %% 2147483646 + 1 # seed + i - 1, kept within R's range of seeds",
    "    run_batch(n_total, sizes[i], batch_seed)",
    "  }, numeric(2))",
    "  c(rejections = sum(counts[1, ]), valid = sum(counts[2, ]))",
    "}",
    ""
  )
}

# The goal, for a simulated result.
simulation_goal_section <- function(spec, result, n_step) {
  sims <- result$provenance$simulations
  if (spec$goal$type == "power") {
    return(c(
      "# Power at n_total ----",
      "counts <- simulate_power(n_total, seed)",
      "power <- counts[[\"rejections\"]] / counts[[\"valid\"]]",
      "mcse <- sqrt(power * (1 - power) / counts[[\"valid\"]]) # Monte Carlo standard error",
      "cat(sprintf(\"Power with n = %s: %.4f (Monte Carlo SE %.4f)\\n\", n_total, power, mcse))",
      "",
      "reproduced <- list(power = power)",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)),
      ""
    ))
  }
  est <- result$n_required
  c(
    "# Required n ----",
    "# powerkit simulated power at these total sample sizes, each with its own",
    "# seed (it chose them with a quicker first pass, not repeated here).",
    "# `fitted` marks the sizes its power curve was fitted to: those within 20%",
    "# of its first estimate of the required n.",
    "simulated <- data.frame(",
    sprintf("  n = %s,", r_code(sims$n)),
    sprintf("  seed = %s,", r_code(sims$seed)),
    sprintf("  fitted = %s", r_code(sims$fitted)),
    ")",
    "counts <- t(vapply(seq_len(nrow(simulated)), function(i) {",
    "  simulate_power(simulated$n[i], simulated$seed[i])",
    "}, numeric(2)))",
    "simulated$rejections <- counts[, 1]",
    "simulated$valid <- counts[, 2]",
    "simulated$power <- simulated$rejections / simulated$valid",
    "print(simulated)",
    "",
    "# powerkit smooths the simulated power with a probit regression of the",
    "# rejections on sqrt(n): for roughly normal test statistics, power is close",
    "# to pnorm(a + b * sqrt(n)). The required n is the smallest valid n whose",
    "# fitted power reaches the target; its 95% interval runs from the smallest n",
    "# whose upper confidence limit reaches the target to the smallest n whose",
    "# lower limit does.",
    "fitted_points <- simulated[simulated$fitted, ]",
    "fit <- suppressWarnings(glm(",
    "  cbind(rejections, valid - rejections) ~ sqrt(n),",
    "  family = binomial(link = \"probit\"),",
    "  data = fitted_points",
    "))",
    sprintf("n_step <- %s # valid total sample sizes are multiples of this", r_code(n_step)),
    "candidates <- data.frame(n = seq(min(fitted_points$n), max(fitted_points$n), by = n_step))",
    "link <- predict(fit, candidates, se.fit = TRUE)",
    "z <- qnorm(0.975)",
    "first_reaching <- function(p) candidates$n[which(p >= target_power)[1]]",
    "n_required <- first_reaching(pnorm(link$fit))",
    "n_lower <- first_reaching(pnorm(link$fit + z * link$se.fit))",
    "n_upper <- first_reaching(pnorm(link$fit - z * link$se.fit))",
    "cat(sprintf(\"Required n: %s (95%% interval %s to %s)\\n\", n_required, n_lower, n_upper))",
    "",
    "reproduced <- list(n = n_required, lower = n_lower, upper = n_upper, power = simulated$power)",
    "powerkit_result <- list(",
    sprintf("  n = %s, lower = %s, upper = %s,", r_code(est$n), r_code(est$lower), r_code(est$upper)),
    sprintf("  power = %s", r_code(result$curve$power)),
    ")",
    ""
  )
}

# Participants to recruit (run_spec()'s `recruitment`), placed before the
# comparison with powerkit's result and compared with it too. Nothing is
# added when the spec gives no attrition.
add_recruitment_section <- function(lines, spec, result) {
  r <- result$recruitment
  if (!is.list(r)) {
    return(lines)
  }
  at <- match("# Compare with powerkit's result ----", lines)
  analysed <- if (identical(spec$goal$type, "sample_size")) "n_required" else "n_total"
  split <- switch(
    spec$template,
    independent_t = ,
    two_proportions = ,
    two_correlations = ,
    ordinal_two_groups = ,
    tost_independent = c(
      sprintf("ratio <- %s # size of group 2 relative to group 1", r_code(spec$options$allocation_ratio %||% 1)),
      "groups_analysed <- c(round(n_analysed / (1 + ratio)), n_analysed - round(n_analysed / (1 + ratio)))"
    ),
    two_variances = ,
    tost_two_proportions = "groups_analysed <- rep(n_analysed / 2, 2) # two equal groups",
    cluster_randomised = ,
    multisite = c(
      sprintf("cluster_size <- %s # participants analysed in each group", r_code(spec$population$cluster_size)),
      "groups_analysed <- rep(cluster_size, n_analysed / cluster_size) # each group's analysed size"
    ),
    group_treatment = c(
      sprintf("cluster_size <- %s # participants analysed in each group of the grouped condition", r_code(spec$population$cluster_size)),
      "groups_analysed <- c(rep(cluster_size, n_analysed / cluster_size / 2), n_analysed / 2) # its groups, then the other condition"
    ),
    "2x2_between" = if (unequal_cells(spec)) {
      sprintf("groups_analysed <- n_analysed * %1$s / sum(%1$s) # the four cells, in the ratio given", r_code(cell_ratio_vector(spec)))
    } else {
      "groups_analysed <- rep(n_analysed / 4, 4) # four equal cells"
    },
    factorial_between = ,
    factorial = ,
    factorial_ancova = sprintf(
      "groups_analysed <- rep(n_analysed / %1$d, %1$d) # %1$d equal cells",
      length(spec$variables$A$levels) * length(spec$variables$B$levels)
    ),
    "2x2_mixed" = "groups_analysed <- rep(n_analysed / 2, 2) # two equal groups",
    oneway_between = if (jonckheere_test(spec)) "groups_analysed <- n_analysed * group_ratio / sum(group_ratio) # each group's share" else sprintf(
      "groups_analysed <- rep(n_analysed / %1$d, %1$d) # %1$d equal groups", length(spec$variables$A$levels)
    ),
    oneway_contrast = ,
    mixed = ,
    oneway_ancova = sprintf(
      "groups_analysed <- rep(n_analysed / %1$d, %1$d) # %1$d equal groups", length(spec$variables$A$levels)
    ),
    proportion_trend = "groups_analysed <- n_analysed * group_ratio / sum(group_ratio) # each group's share",
    "groups_analysed <- n_analysed # one group"
  )
  section <- c(
    "# Participants to recruit ----",
    "# n is the number analysed. To allow for attrition, each group's analysed",
    "# size is divided by (1 - attrition) and rounded up. This is a common but",
    "# crude heuristic: it ignores how missing data will be handled (Rubin, M.,",
    "# 2025, International Journal of Psychology, doi:10.1002/ijop.70017).",
    sprintf("attrition <- %s # proportion of those recruited who won't be analysed", r_code(r$attrition)),
    sprintf("n_analysed <- %s", analysed),
    split,
    "groups_recruit <- ceiling(groups_analysed / (1 - attrition) - 1e-9)",
    "n_recruit <- sum(groups_recruit)",
    "cat(sprintf(\"Analysed: %s. To recruit: %s (%s), allowing for %s%% attrition.\\n\",",
    "  n_analysed, n_recruit, paste(groups_recruit, collapse = \" + \"), 100 * attrition))",
    "",
    "reproduced$n_recruit <- n_recruit",
    sprintf("powerkit_result$n_recruit <- %s", r_code(r$n_recruit)),
    ""
  )
  c(lines[seq_len(at - 1)], section, lines[at:length(lines)])
}

comparison_section <- function() {
  c(
    "# Compare with powerkit's result ----",
    "if (isTRUE(all.equal(reproduced, powerkit_result, tolerance = 1e-10))) {",
    "  cat(\"Reproduced powerkit's result.\\n\")",
    "} else {",
    "  cat(\"These numbers differ from powerkit's result. Check that the package\\n\")",
    "  cat(\"versions match those listed at the top of this script.\\n\")",
    "  str(list(reproduced = reproduced, powerkit = powerkit_result))",
    "}",
    "",
    "sessionInfo()"
  )
}

# The variance tests by formula (backend-variance.R) ------------------------------

# The chi-square or F distribution, in base R: no package to load.
variance_script <- function(spec, result) {
  inputs <- variance_inputs(spec)
  one <- identical(spec$template, "one_variance")
  ratio <- spec$options$allocation_ratio %||% 1
  tails <- switch(
    inputs$alternative,
    two_sided = c(
      "  # Two-sided: alpha / 2 in each tail.",
      sprintf("  lower <- %s(alpha / 2, %s)", if (one) "qchisq" else "qf", if (one) "df" else "df[1], df[2]"),
      sprintf("  upper <- %s(1 - alpha / 2, %s)", if (one) "qchisq" else "qf", if (one) "df" else "df[1], df[2]"),
      sprintf("  %s(lower / ratio, %s) + %s(upper / ratio, %s, lower.tail = FALSE)",
        if (one) "pchisq" else "pf", if (one) "df" else "df[1], df[2]", if (one) "pchisq" else "pf", if (one) "df" else "df[1], df[2]")
    ),
    greater = c(
      "  # One-sided: the first variance is the larger.",
      sprintf("  upper <- %s(1 - alpha, %s)", if (one) "qchisq" else "qf", if (one) "df" else "df[1], df[2]"),
      sprintf("  %s(upper / ratio, %s, lower.tail = FALSE)", if (one) "pchisq" else "pf", if (one) "df" else "df[1], df[2]")
    ),
    less = c(
      "  # One-sided: the first variance is the smaller.",
      sprintf("  lower <- %s(alpha, %s)", if (one) "qchisq" else "qf", if (one) "df" else "df[1], df[2]"),
      sprintf("  %s(lower / ratio, %s)", if (one) "pchisq" else "pf", if (one) "df" else "df[1], df[2]")
    )
  )
  c(
    script_header(spec, result, "base R's stats package", inputs$description),
    "# Inputs ----",
    spower_script_inputs(spec),
    if (!one) {
      sprintf("allocation_ratio <- %s # size of group 2 relative to group 1", r_code(ratio))
    },
    goal_inputs(spec, result),
    "",
    if (one) {
      c(
        "# Under H0, (n - 1) s^2 / variance_null follows the chi-square distribution",
        "# with n - 1 df; under H1, the same distribution times the variance ratio",
        "# (G*Power 3.1 manual, section 26.5)."
      )
    } else {
      c(
        "# Under H0, s1^2 / s2^2 follows the F distribution with n1 - 1 and n2 - 1",
        "# df; under H1, the same distribution times the variance ratio (G*Power",
        "# 3.1 manual, section 15.5)."
      )
    },
    if (one) "ratio <- variance / variance_null" else "ratio <- variances[1] / variances[2]",
    "power_at <- function(n_total) {",
    if (one) {
      "  df <- n_total - 1"
    } else {
      c(
        "  n_group1 <- round(n_total / (1 + allocation_ratio))",
        "  df <- c(n_group1 - 1, n_total - n_group1 - 1)"
      )
    },
    tails,
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# Hotelling's T-squared (one group against fixed values, or two groups) by
# its noncentral F distribution, in base R (backend-hotelling.R).
hotelling_script <- function(spec, result) {
  inputs <- hotelling_inputs(spec)
  two <- inputs$groups == 2
  c(
    script_header(spec, result, "base R's stats package", inputs$description),
    "# Inputs ----",
    spower_script_inputs(spec),
    goal_inputs(spec, result),
    "",
    if (two) {
      c(
        "# With two equal groups, T^2 (N - p - 1) / ((N - 2) p) follows the noncentral",
        "# F distribution with p and N - p - 1 df and noncentrality N1 N2 / N = N / 4",
        "# times the squared Mahalanobis distance between the groups' means",
        "# (Anderson, 2003, An Introduction to Multivariate Statistical Analysis,",
        "# 3rd ed., sections 5.3.4 and 5.4)."
      )
    } else {
      c(
        "# (T^2 / (n - 1)) (n - p) / p follows the noncentral F distribution with p",
        "# and n - p df and noncentrality n times the squared Mahalanobis distance",
        "# of the means from the fixed values (Anderson, 2003, An Introduction to",
        "# Multivariate Statistical Analysis, 3rd ed., section 5.4)."
      )
    },
    "p <- length(sds)",
    "sigma <- matrix(r, p, p)",
    "diag(sigma) <- 1",
    "sigma <- sigma * outer(sds, sds) # covariance matrix of the outcomes",
    if (two) "difference <- means[2, ] - means[1, ]" else "difference <- means - mu0",
    "distance2 <- as.numeric(t(difference) %*% solve(sigma, difference))",
    "power_at <- function(n_total) {",
    if (two) {
      c(
        "  df2 <- n_total - p - 1",
        "  ncp <- n_total / 4 * distance2"
      )
    } else {
      c(
        "  df2 <- n_total - p",
        "  ncp <- n_total * distance2"
      )
    },
    "  critical <- qf(1 - alpha, p, df2)",
    "  pf(critical, p, df2, ncp = ncp, lower.tail = FALSE)",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# pwr -----------------------------------------------------------------------------

pwr_script <- function(spec, result) {
  inputs <- pwr_inputs(spec)
  c(
    script_header(spec, result, inputs$package, inputs$description),
    switch(
      inputs$package,
      stats = c("# power.prop.test() is in base R's stats package.", ""),
      c(sprintf("library(%s)", inputs$package), "")
    ),
    "# Inputs ----",
    spower_script_inputs(spec),
    goal_inputs(spec, result),
    "",
    sprintf("# Power at a total sample size, from %s's formula.", inputs$package),
    "power_at <- function(n_total) {",
    pwr_script_call_lines(spec, inputs),
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# The body of power_at(): group sizes if needed, then the pwr call with a
# comment on each argument. powerkit passes the same values (pwr_inputs()).
pwr_script_call_lines <- function(spec, inputs) {
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  alt <- sprintf("alternative = %s # %s", r_code(alternative), switch(
    alternative,
    two.sided = "two-sided test",
    greater = "one-sided: the effect is positive",
    less = "one-sided: the effect is negative"
  ))
  groups <- c(
    "  n_group1 <- round(n_total / (1 + allocation_ratio))",
    "  n_group2 <- n_total - n_group1"
  )
  ratio <- spec$options$allocation_ratio %||% 1
  if (inputs$fun %in% c("power.prop.test", "power.z.twoprops")) {
    return(prop_test_script_lines(spec, inputs))
  }
  call <- switch(
    spec$template,
    one_sample_t = list(head = "pwr.t.test(", args = c(
      "n = n_total", "d = d", "sig.level = alpha", "type = \"one.sample\"", alt
    )),
    independent_t = if (isTRUE(all.equal(ratio, 1))) {
      list(head = "pwr.t.test(", args = c(
        "n = n_total / 2 # pwr's n is the size of each group",
        "d = d # group 2 minus group 1; pwr's \"greater\" means d > 0",
        "sig.level = alpha",
        "type = \"two.sample\" # Student's t-test (equal variances)",
        alt
      ))
    } else {
      list(pre = groups, head = "pwr.t2n.test(", args = c(
        "n1 = n_group1", "n2 = n_group2",
        "d = d # group 2 minus group 1; pwr's \"greater\" means d > 0",
        "sig.level = alpha", alt
      ))
    },
    paired_t = list(head = "pwr.t.test(", args = c(
      "n = n_total # number of pairs", "d = dz # for a paired test, pwr's d is d_z",
      "sig.level = alpha", "type = \"paired\"", alt
    )),
    correlation = list(head = "pwr.r.test( # Fisher's z approximation", args = c(
      "n = n_total", "r = r", "sig.level = alpha", alt
    )),
    two_proportions = list(
      pre = groups,
      head = "pwr.2p2n.test( # Cohen's h (arcsine approximation), no continuity correction",
      args = c(
        "h = ES.h(proportions[2], proportions[1]) # positive when group 2's proportion is higher",
        "n1 = n_group1", "n2 = n_group2", "sig.level = alpha", alt
      )
    ),
    chi_square_independence = list(head = "pwr.chisq.test(", args = c(
      if (chisq_by_w(spec)) "w = w" else "w = ES.w2(probabilities) # Cohen's w for the table of proportions",
      "N = n_total",
      "df = df",
      "sig.level = alpha"
    ))
  )
  c(call$pre, paste0("  ", call$head), paste0("    ", ensure_commas(call$args)), "  )$power")
}

# The body of power_at() for two proportions by the z test with pooled
# variance under the null, as G*Power does: stats::power.prop.test() for
# equal groups (both tails counted, strict = TRUE), pwrss's
# power.z.twoprops() for unequal groups. A one-sided test against the
# specified direction is the two-sided power at 2 x alpha minus the
# one-sided power (pwr_power()).
prop_test_script_lines <- function(spec, inputs) {
  args <- inputs$args(2)
  pwrss <- identical(inputs$package, "pwrss")
  call <- function(alternative, sig) {
    if (pwrss) {
      return(c(
        "  n_group1 <- round(n_total / (1 + allocation_ratio))",
        "  n_group2 <- n_total - n_group1",
        "  power.z.twoprops(",
        paste0("    ", ensure_commas(c(
          "prob1 = proportions[1]", "prob2 = proportions[2]",
          "n2 = n_group2",
          "n.ratio = n_group1 / n_group2 # pwrss's n.ratio is n1 / n2",
          sprintf("alpha = %s", sig),
          sprintf("alternative = %s", r_code(alternative)),
          "std.error = \"pooled\" # pooled variance under the null, as G*Power",
          "verbose = FALSE"
        ))),
        "  )$power"
      ))
    }
    c(
      "  power.prop.test(",
      paste0("    ", ensure_commas(c(
        "n = n_total / 2 # power.prop.test()'s n is the size of each group (equal groups)",
        "p1 = proportions[1]", "p2 = proportions[2]",
        sprintf("sig.level = %s", sig),
        sprintf("alternative = %s", r_code(alternative)),
        if (alternative == "two.sided") {
          "strict = TRUE # count rejections in both tails, as G*Power does"
        } else {
          "strict = TRUE # no effect on a one-sided test"
        }
      ))),
      "  )$power"
    )
  }
  if (!isTRUE(inputs$against_effect)) {
    note <- if (args$alternative == "one.sided") {
      "  # One-sided, in the direction of the specified difference."
    }
    return(c(note, call(args$alternative, "alpha")))
  }
  c(
    sprintf("  # One-sided, against the specified difference: %s() uses", inputs$fun),
    "  # |p1 - p2|, so the power is the two-sided power at 2 x alpha minus the",
    "  # one-sided power at alpha (the tail away from the difference).",
    sub("^  power", "  both_tails <- power", call("two.sided", "2 * alpha")),
    sub("^  power", "  toward_effect <- power", call("one.sided", "alpha")),
    "  both_tails - toward_effect"
  )
}

pwr_goal_section <- function(spec, result) {
  switch(
    spec$goal$type,
    power = c(
      "# Power at n_total ----",
      "power <- power_at(n_total)",
      "cat(sprintf(\"Power with n = %s: %.4f\\n\", n_total, power))",
      "",
      "reproduced <- list(power = power)",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)),
      ""
    ),
    sample_size = c(
      "# Required n ----",
      "# Power at the required n that powerkit found and at three valid sizes",
      sprintf("# either side (valid sizes are multiples of %s). Power rises with n, so", valid_n_step(spec)),
      "# the required n is the first of these that reaches the target power: the",
      "# size before it doesn't.",
      sprintf("sizes <- %s", r_code(result$curve$n)),
      "power <- vapply(sizes, power_at, numeric(1))",
      "n_required <- sizes[which(power >= target_power)[1]]",
      "print(data.frame(n = sizes, power = power))",
      "cat(sprintf(\"Required n: %s\\n\", n_required))",
      "",
      "reproduced <- list(n = n_required, power = power)",
      sprintf(
        "powerkit_result <- list(n = %s, power = %s)",
        r_code(result$n_required$n), r_code(result$curve$power)
      ),
      ""
    ),
    sensitivity = pwr_sensitivity_section(spec, result)
  )
}

# The smallest detectable effect for a basic test, found the way powerkit
# finds it (pwr_sensitivity()): pwr solves for the effect when it is left
# NULL; for two proportions, p2 is searched with power_at().
pwr_sensitivity_section <- function(spec, result) {
  s <- result$sensitivity
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  two_sided <- alternative == "two.sided"
  ratio <- spec$options$allocation_ratio %||% 1
  solve <- function(variable, call, field) {
    c(
      "# pwr finds the effect itself when it is left NULL (see the help for",
      "# the function below: exactly one parameter is passed as NULL).",
      sprintf("found <- %s$%s", call, field),
      if (two_sided) {
        c(
          "# For a two-sided test pwr returns a positive effect; keep the sign",
          "# of the effect you specified (positive if you gave none).",
          sprintf("%s <- if (%s < 0) -abs(found) else found", variable, variable)
        )
      } else {
        sprintf("%s <- found", variable)
      }
    )
  }
  alt <- sprintf("alternative = %s", r_code(alternative))
  find <- switch(
    spec$template,
    one_sample_t = solve("d", sprintf(
      "pwr.t.test(n = n_total, d = NULL, sig.level = alpha, power = target_power, type = \"one.sample\", %s)", alt
    ), "d"),
    independent_t = if (isTRUE(all.equal(ratio, 1))) {
      solve("d", sprintf(
        "pwr.t.test(n = n_total / 2, d = NULL, sig.level = alpha, power = target_power, type = \"two.sample\", %s)", alt
      ), "d")
    } else {
      c(
        "n_group1 <- round(n_total / (1 + allocation_ratio))",
        solve("d", sprintf(
          "pwr.t2n.test(n1 = n_group1, n2 = n_total - n_group1, d = NULL, sig.level = alpha, power = target_power, %s)", alt
        ), "d")
      )
    },
    paired_t = solve("dz", sprintf(
      "pwr.t.test(n = n_total, d = NULL, sig.level = alpha, power = target_power, type = \"paired\", %s)", alt
    ), "d"),
    correlation = solve("r", sprintf(
      "pwr.r.test(n = n_total, r = NULL, sig.level = alpha, power = target_power, %s)", alt
    ), "r"),
    chi_square_independence = c(
      "w <- pwr.chisq.test(N = n_total, w = NULL, df = df, sig.level = alpha, power = target_power)$w",
      "# The power at that w, with the same pwr call as for power.",
      "power_at <- function(n_total) {",
      "  pwr.chisq.test(w = w, N = n_total, df = df, sig.level = alpha)$power",
      "}"
    ),
    two_proportions = c(
      "# Keep group 1's proportion and move group 2's away from it, in the",
      "# direction you specified (up if you gave none), until power reaches",
      "# the target.",
      "p1 <- proportions[1]",
      "limit <- if (proportions[2] >= p1) 1 - 1e-9 else 1e-9",
      "power_with_p2 <- function(p2) {",
      "  proportions[2] <<- p2",
      "  power_at(n_total)",
      "}",
      "p2 <- uniroot(function(p) power_with_p2(p) - target_power,",
      "  lower = min(p1, limit), upper = max(p1, limit), tol = 1e-10)$root",
      "proportions[2] <- p2"
    )
  )
  effect <- switch(
    spec$template,
    independent_t = "d", one_sample_t = "d", paired_t = "dz",
    correlation = "r", chi_square_independence = "w", two_proportions = "p2"
  )
  c(
    "# Smallest detectable effect ----",
    find,
    "power <- power_at(n_total)",
    sprintf(
      "cat(sprintf(\"Smallest detectable effect: %s = %%.4g (power %%.4f)\\n\", %s, power))",
      gsub("%", "%%", gsub("\"", "'", comment_text(s$effect_description)), fixed = TRUE), effect
    ),
    "",
    sprintf("reproduced <- list(effect = %s, power = power)", effect),
    sprintf("powerkit_result <- list(effect = %s, power = %s)", r_code(s$effect), r_code(s$power)),
    ""
  )
}

# Spower -------------------------------------------------------------------------

spower_script <- function(spec, result) {
  inputs <- spower_inputs(spec)
  one_sided <- inputs$alternative != "two_sided"
  c(
    script_header(spec, result, "Spower", inputs$description),
    "library(Spower)",
    "",
    "# Inputs ----",
    spower_script_inputs(spec),
    goal_inputs(spec, result),
    "",
    # Spower reads its experiment unevaluated, so values computed from the
    # inputs are given to it by name.
    if (length(spower_derived_lines(spec)) > 0) c(spower_derived_lines(spec), ""),
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    spower_group_size_lines(spec),
    "  set.seed(batch_seed) # Spower draws its own seeds from R's random-number generator",
    "  result <- Spower(",
    paste0("    ", spower_experiment_lines(spec, inputs, one_sided)),
    "    sig.level = alpha,",
    "    replications = batch_replications,",
    "    parallel = FALSE,",
    "    verbose = FALSE",
    "  )",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec)),
    comparison_section()
  )
}

# The user's values, in the spec's terms.
spower_script_inputs <- function(spec) {
  if (rank_test(spec)) {
    return(rank_script_inputs(spec))
  }
  pop <- spec$population
  v <- spec$variables
  lv <- function(role, i) comment_text(unlist(v[[role]]$levels)[i])
  ratio <- spec$options$allocation_ratio %||% 1
  ratio_line <- sprintf(
    "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
    r_code(ratio), lv("X", 2), lv("X", 1)
  )
  if (welch_anova(spec)) {
    groups <- paste(comment_text(unlist(v$A$levels)), collapse = ", ")
    return(c(
      sprintf("means <- %s # mean of %s in each group (%s)", r_code(as.numeric(unlist(pop$means))), comment_text(v$Y$label), groups),
      sprintf("sds <- %s # SD in each group, in the same units", r_code(welch_sds(spec)))
    ))
  }
  switch(
    spec$template,
    one_sample_t = sprintf(
      "d <- %s # Cohen's d: (expected mean of %s minus the fixed value) / SD", r_code(pop$d), comment_text(v$Y$label)
    ),
    independent_t = c(
      sprintf("d <- %s # Cohen's d: (mean of %s minus mean of %s) / pooled SD", r_code(pop$d), lv("X", 2), lv("X", 1)),
      ratio_line
    ),
    paired_t = sprintf(
      "dz <- %s # d_z: mean of the differences (%s minus %s) / SD of the differences",
      r_code(pop$dz), lv("X", 2), lv("X", 1)
    ),
    correlation = c(
      sprintf("r <- %s # population correlation (Pearson's r of the scores)", r_code(pop$r)),
      if (shaped_rank_correlation(spec)) sprintf("score_shape <- %s # the shape of both scores: %s",
        r_code(pop$score_shape), score_shape_words(pop$score_shape))
    ),
    manova = c(
      sprintf("# Mean of each outcome (columns: %s) in each group (rows: %s).",
        paste(vapply(manova_outcomes(spec), function(y) comment_text(v[[y]]$label), character(1)), collapse = ", "),
        if (is.null(v$B)) {
          paste(comment_text(unlist(v$A$levels)), collapse = ", ")
        } else {
          paste(apply(expand.grid(b = comment_text(unlist(v$B$levels)), a = comment_text(unlist(v$A$levels)))[, 2:1], 1,
            paste, collapse = " with "), collapse = ", ")
        }),
      if (!is.null(v$B)) c(
        sprintf("b <- %d # levels of %s; the rows are %s's levels by %s's, %s's fastest",
          length(unlist(v$B$levels)), comment_text(v$B$label), comment_text(v$A$label), comment_text(v$B$label), comment_text(v$B$label)),
        sprintf("term <- %s # the effect tested", r_code(manova_term(spec)))
      ),
      sprintf("means <- matrix(%s, nrow = %d, byrow = TRUE)", r_code(as.numeric(t(manova_means(spec)))), length(pop$means)),
      sprintf("sds <- %s # SD of each outcome within the groups", r_code(as.numeric(unlist(pop$sds)))),
      sprintf("r <- %s # correlation between every pair of outcomes", r_code(pop$r))
    ),
    hotelling_one = c(
      sprintf("# Outcomes, in order: %s.",
        paste(vapply(manova_outcomes(spec), function(y) comment_text(v[[y]]$label), character(1)), collapse = ", ")),
      sprintf("means <- %s # expected mean of each outcome", r_code(as.numeric(unlist(pop$means)))),
      sprintf("mu0 <- %s # the fixed value each mean is compared with", r_code(as.numeric(unlist(pop$mu0)))),
      sprintf("sds <- %s # SD of each outcome", r_code(as.numeric(unlist(pop$sds)))),
      sprintf("r <- %s # correlation between every pair of outcomes", r_code(pop$r))
    ),
    paired_variances = c(
      sprintf("var1 <- %s # variance of %s in %s", r_code(pop$var1), comment_text(v$Y$label), lv("X", 1)),
      sprintf("var2 <- %s # variance of %s in %s", r_code(pop$var2), comment_text(v$Y$label), lv("X", 2)),
      sprintf("rho12 <- %s # correlation between the two measurements", r_code(pop$r))
    ),
    two_proportions = c(
      sprintf(
        "proportions <- %s # proportion with %s = %s in %s, then in %s",
        r_code(c(pop$p1, pop$p2)), comment_text(v$Y$label), lv("Y", 2), lv("X", 1), lv("X", 2)
      ),
      ratio_line
    ),
    one_variance = c(
      sprintf("variance <- %s # expected variance of %s", r_code(pop$var), comment_text(v$Y$label)),
      sprintf("variance_null <- %s # the fixed variance it is compared with", r_code(pop$var0))
    ),
    two_variances = sprintf(
      "variances <- %s # variance of %s in %s, then in %s",
      r_code(c(pop$var1, pop$var2)), comment_text(v$Y$label),
      comment_text(unlist(v$G$levels)[1]), comment_text(unlist(v$G$levels)[2])
    ),
    factorial = c(
      sprintf(
        "# Proportion with %s = %s in each cell: rows are %s (%s), columns %s (%s).",
        comment_text(v$Y$label), lv("Y", 2),
        comment_text(v$A$label), paste(comment_text(unlist(v$A$levels)), collapse = ", "),
        comment_text(v$B$label), paste(comment_text(unlist(v$B$levels)), collapse = ", ")
      ),
      sprintf(
        "probabilities <- matrix(%s, nrow = %d, byrow = TRUE)",
        r_code(t(logistic_factorial_probabilities(spec))), nrow(logistic_factorial_probabilities(spec))
      )
    ),
    proportion_trend = c(
      sprintf(
        "proportions <- %s # proportion with %s = %s in each group, in order (%s)",
        r_code(as.numeric(unlist(pop$proportions))), comment_text(v$Y$label), lv("Y", 2),
        paste(comment_text(unlist(v$X$levels)), collapse = ", ")
      ),
      sprintf("scores <- %s # each group's score in the trend test%s", r_code(trend_scores(spec)),
        if (is.null(pop$scores)) " (1, 2, 3, ...: equally spaced, prop.trend.test()'s default)" else ""),
      group_ratio_line(spec)
    ),
    chi_square_independence = if (chisq_by_w(spec)) {
      c(
        sprintf("w <- %s # Cohen's w for the association of %s and %s, taken as the population value (as in G*Power)",
          r_code(spec$population$w), comment_text(v$X$label), comment_text(v$Y$label)),
        sprintf("df <- %d # degrees of freedom: (%d categories - 1) x (%d categories - 1)", as.integer(chisq_df(spec)),
          length(v$X$levels), length(v$Y$levels))
      )
    } else {
      c(
        sprintf(
          "# Probability of each combination: rows are %s (%s), columns %s (%s).",
          comment_text(v$X$label), paste(comment_text(unlist(v$X$levels)), collapse = ", "),
          comment_text(v$Y$label), paste(comment_text(unlist(v$Y$levels)), collapse = ", ")
        ),
        sprintf(
          "probabilities <- matrix(%s, nrow = %d, byrow = TRUE)",
          r_code(t(probability_matrix(spec))), nrow(probability_matrix(spec))
        ),
        "df <- (nrow(probabilities) - 1) * (ncol(probabilities) - 1) # degrees of freedom"
      )
    }
  )
}

spower_group_size_lines <- function(spec) {
  if (jonckheere_test(spec) || spec$template == "proportion_trend") {
    return(c(
      "  # The experiment's n is one share of the total: each group has n times",
      "  # its share in group_ratio.",
      "  n_share <- batch_n / sum(group_ratio)"
    ))
  }
  if (spec$template == "oneway_between") {
    return(c(
      "  # Spower's n is the size of each group; the groups are equal.",
      "  n_group <- batch_n / length(means)"
    ))
  }
  if (spec$template == "manova") {
    return(c(
      "  # The experiment's n is the size of each group; the groups are equal.",
      "  n_group <- batch_n / nrow(means)"
    ))
  }
  if (spec$template %in% c("independent_t", "two_proportions")) {
    return(c(
      "  # Spower's n is the size of group 1; group 2 has allocation_ratio times as many.",
      "  n_group1 <- round(batch_n / (1 + allocation_ratio))"
    ))
  }
  if (spec$template == "two_variances") {
    return(c(
      "  # Spower's n is the size of one group; the two groups are equal.",
      "  n_group1 <- round(batch_n / 2)"
    ))
  }
  if (spec$template == "factorial") {
    return(c(
      "  # p_glm() takes the design itself: the same number of people in every cell.",
      "  X <- cells[rep(seq_len(nrow(cells)), each = batch_n / nrow(cells)), ]"
    ))
  }
  character()
}

# The arguments of Spower's experiment function, one per line, with a
# comment on each. powerkit passes the same values (spower_inputs()).
spower_experiment_lines <- function(spec, inputs, one_sided) {
  if (rank_test(spec)) {
    return(rank_experiment_lines(spec, inputs, one_sided))
  }
  welch <- identical(spec$target_test$method, "welch_t")
  args <- switch(
    spec$template,
    oneway_between = c(
      "n = n_group, # size of each group",
      "k = length(means), # number of groups",
      "means = means,",
      "sds = sds,",
      "var.equal = FALSE # Welch's F test (stats::oneway.test())"
    ),
    one_sample_t = c(
      "n = batch_n, # sample size",
      "d = d, # Cohen's d",
      "type = \"one.sample\""
    ),
    independent_t = c(
      "n = n_group1, # size of group 1",
      "d = d_spower, # -d (see above)",
      "type = \"two.sample\",",
      "n2_n1 = allocation_ratio, # size of group 2 relative to group 1",
      sprintf("var.equal = %s # %s", if (welch) "FALSE" else "TRUE", if (welch) "FALSE: Welch's t-test" else "TRUE: Student's t-test")
    ),
    paired_t = c(
      "n = batch_n, # number of participants (pairs)",
      "d = d_spower, # -sqrt(2) * d_z (see above)",
      "type = \"paired\""
    ),
    correlation = c(
      "n = batch_n, # sample size",
      "r = r, # population correlation",
      if (rank_correlation(spec)) sprintf("method = \"%s\" # %s", spec$target_test$method,
        if (identical(spec$target_test$method, "spearman")) "Spearman's rho" else "Kendall's tau"),
      if (shaped_rank_correlation(spec)) c("gen_fun = shaped_pair, # scores of the chosen shape (above)", "shape = score_shape")
    ),
    paired_variances = c(
      "n = batch_n, # number of people",
      "r = 0, # p_r()'s own argument; the generator below ignores it",
      "gen_fun = pitman_morgan_scores, # the sum and difference of the paired scores",
      "var1 = var1,",
      "var2 = var2,",
      "rho12 = rho12"
    ),
    two_proportions = c(
      "n = n_group1, # size of group 1",
      "prop = proportions, # proportion in group 1, then group 2",
      "n.ratios = group_ratios, # group sizes relative to group 1",
      "correct = FALSE # no continuity correction (Spower's default is TRUE; powerkit's Departure 5)"
    ),
    one_variance = c(
      "n = batch_n, # sample size",
      "vars = variance, # one variance: p_var.test() then runs the chi-square test",
      "sigma2 = variance_null # the fixed variance under the null"
    ),
    two_variances = c(
      "n = n_group1, # size of each group",
      "vars = variances # two variances: p_var.test() then runs the F test (var.test)"
    ),
    manova = c(
      "n = n_group, # size of each group",
      "means = means,",
      "sds = sds,",
      if (is.null(spec$variables$B)) "r = r" else c("r = r,", "b = b,", "term = term")
    ),
    hotelling_one = c(
      "n = batch_n, # the number of people",
      "means = means,",
      "mu0 = mu0,",
      "sds = sds,",
      "r = r"
    ),
    factorial = c(
      "formula = y ~ A * B, # both factors and their interaction",
      "X = X, # the design (above)",
      "betas = betas, # coefficients that give each cell's proportion (above)",
      sprintf("test = test, # %s", logistic_factorial_effect_words(spec)),
      "family = binomial() # logistic regression"
    ),
    chi_square_independence = c(
      "n = batch_n, # total sample size",
      "P = probabilities, # probability of each combination",
      "correct = FALSE # no continuity correction (Spower's default is TRUE; powerkit's Departure 5)"
    ),
    proportion_trend = c(
      "n = n_share, # one share of the total",
      "proportions = proportions,",
      "scores = scores,",
      "n.ratios = group_ratio # each group's share"
    )
  )
  if (one_sided) {
    args <- c(args, spower_alternative_line(spec, inputs))
  }
  args <- ensure_commas(args)
  c(sprintf("%s(", inputs$experiment), paste0("  ", args), "),")
}

# A one-sided test: Spower's `alternative` (Spower 0.7 and later), in
# Spower's orientation (powerkit's spower_alternative()).
spower_alternative_line <- function(spec, inputs) {
  alternative <- spower_alternative(spec$template, inputs$alternative)
  positive <- inputs$alternative == "greater"
  why <- switch(
    spec$template,
    independent_t = sprintf(
      "your test expects group 2's mean to be %s; Spower tests group 1 minus group 2",
      if (positive) "higher" else "lower"
    ),
    paired_t = sprintf(
      "your test expects the second condition to be %s; Spower tests first minus second",
      if (positive) "higher" else "lower"
    ),
    two_proportions = sprintf(
      "your test expects p2 to be %s than p1; Spower tests p1 minus p2",
      if (positive) "higher" else "lower"
    ),
    one_variance = sprintf(
      "your test expects the variance to be %s than the fixed value",
      if (positive) "larger" else "smaller"
    ),
    two_variances = sprintf(
      "your test expects group 1's variance to be %s than group 2's",
      if (positive) "larger" else "smaller"
    ),
    paired_variances = sprintf(
      "your test expects the first measurement's variance to be %s than the second's (the sum and difference correlate %s)",
      if (positive) "larger" else "smaller", if (positive) "positively" else "negatively"
    ),
    oneway_between = sprintf("your test expects the scores to %s across the groups in order", if (positive) "rise" else "fall"),
    proportion_trend = sprintf("your test expects the proportion to %s with the scores", if (positive) "rise" else "fall"),
    sprintf("one-sided: the effect is expected to be %s", if (positive) "positive" else "negative")
  )
  sprintf("alternative = %s # %s", r_code(alternative), why)
}

# A trend test's relative group sizes (options > group_ratio; 1 each for
# equal groups).
group_ratio_line <- function(spec) {
  levels <- unlist(if (proportion_trend(spec)) spec$variables$X$levels else spec$variables$A$levels)
  sprintf("group_ratio <- %s # relative size of each group (%s)%s", r_code(trend_group_shares(spec)),
    paste(comment_text(levels), collapse = ", "), if (unequal_groups(spec)) "" else ": equal groups")
}

# How a repeated-measures design treats sphericity: with one SD and one
# correlation it holds; otherwise the covariances may break it, and the F
# test is corrected only if asked (target_test > correction).
sphericity_words <- function(spec) {
  pop <- spec$population
  if (length(unlist(pop$sd)) == 1 && length(unlist(pop$r)) == 1) {
    return("sphericity assumed")
  }
  switch(spec$target_test$correction %||% "none",
    none = "SDs and correlations as given, F test not corrected for sphericity",
    GG = "SDs and correlations as given, Greenhouse-Geisser correction",
    HF = "SDs and correlations as given, Huynh-Feldt correction")
}

# Put a comma after every argument but the last, before any comment.
ensure_commas <- function(args) {
  code <- sub(" #.*$", "", args)
  comment <- ifelse(grepl(" #", args), sub("^.*?( #.*)$", "\\1", args, perl = TRUE), "")
  code <- sub(",$", "", code)
  last <- length(code)
  code[-last] <- paste0(code[-last], ",")
  paste0(code, comment)
}

# Spower's values computed from the user's (powerkit's spower_inputs()).
spower_derived_lines <- function(spec) {
  if (rank_test(spec)) {
    return(rank_derived_lines(spec))
  }
  if (shaped_rank_correlation(spec)) {
    return(c(
      "# Two scores of the chosen shape (mean 0, SD 1) with Pearson's correlation r:",
      "# the second is r times the first plus sqrt(1 - r^2) times another draw.",
      "shaped_pair <- function(n, r, shape, ...) {",
      "  draw <- function(n) switch(shape,",
      "    skewed = (rchisq(n, df = 10) - 10) / sqrt(20), # standardised chi-square, 10 df",
      "    heavy_tailed = rt(n, df = 3) / sqrt(3) # t with 3 df, rescaled to SD 1",
      "  )",
      "  x <- draw(n)",
      "  data.frame(x = x, y = r * x + sqrt(1 - r^2) * draw(n))",
      "}"
    ))
  }
  switch(
    spec$template,
    independent_t = "d_spower <- -d # Spower puts the effect in group 1, so d (group 2 minus group 1) changes sign",
    paired_t = c(
      "# Spower's paired generator draws the two time points with SD 1 and the",
      "# effect in the first, so the differences have SD sqrt(2): Spower's d is",
      "# -sqrt(2) * d_z.",
      "d_spower <- -sqrt(2) * dz"
    ),
    two_proportions = "group_ratios <- c(1, allocation_ratio) # group sizes relative to group 1",
    proportion_trend = c(
      "# The experiment, as powerkit runs it: each group's count of yes out of n,",
      "# drawn from its proportion, and the p-value of the Cochran-Armitage test",
      "# of a linear trend along the scores (prop.trend.test(), chi-square, 1 df).",
      "# prop.trend.test() is two-sided; a one-sided test halves its p-value when",
      "# the observed trend goes the way predicted (\"greater\": the proportion",
      "# rises with the scores), and otherwise gives 1 minus half of it.",
      "p_cochran_armitage <- function(n, proportions, scores, n.ratios = rep(1, length(proportions)),",
      "                               alternative = \"two.sided\") {",
      "  sizes <- n * n.ratios",
      "  yes <- rbinom(length(proportions), sizes, proportions)",
      "  p <- prop.trend.test(yes, sizes, score = scores)$p.value",
      "  if (alternative == \"two.sided\") return(p)",
      "  rising <- sum(yes * (scores - sum(sizes * scores) / sum(sizes))) > 0",
      "  if (rising == (alternative == \"greater\")) p / 2 else 1 - p / 2",
      "}"
    ),
    factorial = c(
      "# The cells, with sum-to-zero (effect) coding, so that each factor's",
      "# coefficients are its main effect averaged over the other factor.",
      "cells <- expand.grid(A = factor(seq_len(nrow(probabilities))), B = factor(seq_len(ncol(probabilities))))",
      "contrasts(cells$A) <- contr.sum(nrow(probabilities))",
      "contrasts(cells$B) <- contr.sum(ncol(probabilities))",
      "# The logistic model's coefficients that give each cell's proportion exactly",
      "# (all terms, solved on the log-odds scale).",
      "model <- model.matrix(~ A * B, cells)",
      "betas <- drop(solve(model, qlogis(probabilities[cbind(as.integer(cells$A), as.integer(cells$B))])))",
      sprintf("# The Wald test of %s: all of its coefficients are 0.", logistic_factorial_effect_words(spec)),
      sprintf("test <- %s", r_code(logistic_factorial_design(spec)$test))
    ),
    manova = c(
      "# The experiment, as powerkit runs it: multivariate normal scores for each",
      "# group, then the p-value of Pillai's trace from stats::manova().",
      "manova_scores <- function(n, means, sds, r) {",
      "  p <- ncol(means)",
      "  correlation <- matrix(r, p, p)",
      "  diag(correlation) <- 1",
      "  sigma <- diag(sds, p) %*% correlation %*% diag(sds, p)",
      "  y <- do.call(rbind, lapply(seq_len(nrow(means)), function(g) SimDesign::rmvnorm(n, means[g, ], sigma)))",
      "  colnames(y) <- paste0(\"Y\", seq_len(p))",
      "  data.frame(group = factor(rep(seq_len(nrow(means)), each = n)), y)",
      "}",
      if (is.null(spec$variables$B)) c(
        "p_manova <- function(n, means, sds, r) {",
        "  data <- manova_scores(n, means, sds, r)",
        "  fit <- stats::manova(as.matrix(data[, -1]) ~ data$group)",
        "  summary(fit, test = \"Pillai\")$stats[1, \"Pr(>F)\"]",
        "}"
      ) else c(
        "# Two factors: the groups are A's levels by B's (B fastest); the model is",
        "# A * B, and the groups are equal, so the sequential test is the adjusted one.",
        "p_manova <- function(n, means, sds, r, b, term) {",
        "  data <- manova_scores(n, means, sds, r)",
        "  group <- as.integer(data$group)",
        "  A <- factor((group - 1) %/% b + 1)",
        "  B <- factor((group - 1) %% b + 1)",
        "  fit <- stats::manova(as.matrix(data[, -1]) ~ A * B)",
        "  summary(fit, test = \"Pillai\")$stats[term, \"Pr(>F)\"]",
        "}"
      )
    ),
    hotelling_one = c(
      "# The experiment, as powerkit runs it: one group's multivariate normal",
      "# scores, then the p-value of one-sample Hotelling's T-squared, the test of",
      "# the intercept of lm(scores - mu0 ~ 1) (exact with one group).",
      "hotelling_one_scores <- function(n, means, sds, r) {",
      "  p <- length(means)",
      "  correlation <- matrix(r, p, p)",
      "  diag(correlation) <- 1",
      "  sigma <- diag(sds, p) %*% correlation %*% diag(sds, p)",
      "  SimDesign::rmvnorm(n, means, sigma)",
      "}",
      "p_hotelling_one <- function(n, means, mu0, sds, r) {",
      "  differences <- sweep(hotelling_one_scores(n, means, sds, r), 2, mu0)",
      "  stats::anova(stats::lm(differences ~ 1), test = \"Pillai\")[1, \"Pr(>F)\"]",
      "}"
    ),
    paired_variances = c(
      "# The Pitman-Morgan test: two paired variances are equal exactly when the",
      "# sum and the difference of the two measurements are uncorrelated, so",
      "# p_r() tests that correlation on paired normal scores.",
      "pitman_morgan_scores <- function(n, r, var1, var2, rho12, ...) {",
      "  z1 <- rnorm(n)",
      "  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * rnorm(n)",
      "  x <- sqrt(var1) * z1",
      "  y <- sqrt(var2) * z2",
      "  data.frame(x = x + y, y = x - y)",
      "}"
    ),
    character()
  )
}

# Rank tests (Spower's p_wilcox.test() and p_kruskal.test()) -------------------

rank_script_inputs <- function(spec) {
  pop <- spec$population
  v <- spec$variables
  lv <- function(role, i) comment_text(unlist(v[[role]]$levels)[i])
  shape <- sprintf(
    "score_shape <- %s # the shape of the scores: %s",
    r_code(pop$score_shape %||% "normal"), score_shape_words(pop$score_shape)
  )
  effect <- switch(
    spec$template,
    one_sample_t = sprintf(
      "d <- %s # Cohen's d: (expected mean of %s minus the fixed value) / SD", r_code(pop$d), comment_text(v$Y$label)
    ),
    paired_t = sprintf(
      "dz <- %s # d_z: mean of the differences (%s minus %s) / SD of the differences",
      r_code(pop$dz), lv("X", 2), lv("X", 1)
    ),
    independent_t = c(
      sprintf("d <- %s # Cohen's d: (mean of %s minus mean of %s) / SD", r_code(pop$d), lv("X", 2), lv("X", 1)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(spec$options$allocation_ratio %||% 1), lv("X", 2), lv("X", 1)
      )
    ),
    oneway_between = c(
      sprintf(
        "means <- %s / %s # group means (%s) in SD units: the means over the SD",
        r_code(as.numeric(unlist(pop$means))), r_code(pop$sd),
        paste(comment_text(unlist(v$A$levels)), collapse = ", ")
      ),
      if (jonckheere_test(spec)) group_ratio_line(spec)
    ),
    oneway_within = c(
      sprintf(
        "means <- %s / %s # condition means (%s) in SD units: the means over the SD",
        r_code(as.numeric(unlist(pop$means))), r_code(pop$sd),
        paste(comment_text(unlist(v$A$levels)), collapse = ", ")
      ),
      sprintf("r <- %s # correlation between any two conditions, within a participant", r_code(pop$r))
    )
  )
  c(effect, shape)
}

# The score generators powerkit uses (score_shape_sampler(), and the
# parents in rank_test_inputs()).
rank_derived_lines <- function(spec) {
  draw <- c(
    "# Scores with mean 0 and SD 1 in the chosen shape.",
    "draw_scores <- function(n) {",
    "  switch(score_shape,",
    "    normal = rnorm(n),",
    "    skewed = (rchisq(n, df = 10) - 10) / sqrt(20), # standardised chi-square, 10 df (as in Spower's examples)",
    "    heavy_tailed = rt(n, df = 3) / sqrt(3) # t with 3 df, rescaled to SD 1",
    "  )",
    "}"
  )
  rest <- switch(
    spec$template,
    one_sample_t = c(
      "shifted <- function(n, d) d + draw_scores(n) # scores shifted by d"
    ),
    paired_t = c(
      "# The signed-rank test ranks the within-person differences, so the",
      "# differences are drawn directly: first minus second condition, shifted",
      "# by -d_z, against a second sample of 0.",
      "shifted <- function(n, d) d + draw_scores(n)",
      "zero <- function(n, d) rep(0, n)",
      "d_spower <- -dz"
    ),
    independent_t = c(
      "shifted <- function(n, d) d + draw_scores(n) # group 1, shifted by d",
      "unshifted <- function(n, d) draw_scores(n) # group 2",
      "d_spower <- -d # Spower compares group 1 with group 2, so d (group 2 minus group 1) changes sign"
    ),
    oneway_between = c(
      "# Each group's scores: its mean plus scores in the chosen shape.",
      "gen_groups <- function(n, k, n.ratios, means, ...) {",
      "  lapply(seq_len(k), function(g) means[g] + draw_scores(n * n.ratios[g]))",
      "}",
      if (jonckheere_test(spec)) c(
        "# The experiment, as powerkit runs it: the groups in the order of their",
        "# levels, and the p-value of PMCMRplus's Jonckheere-Terpstra test (its",
        "# default: the normal approximation, no continuity correction; \"greater\"",
        "# is a rise across the groups). The scores and their groups go in as x and",
        "# g: given a list of groups, jonckheereTest() ignores `alternative`.",
        "p_jonckheere <- function(n, k, means, gen_fun, n.ratios = rep(1, k), alternative = \"two.sided\") {",
        "  groups <- gen_fun(n, k, n.ratios, means)",
        "  g <- factor(rep(seq_len(k), lengths(groups)))",
        "  unname(PMCMRplus::jonckheereTest(unlist(groups), g, alternative = alternative)$p.value)",
        "}"
      )
    ),
    oneway_within = c(
      "# The experiment, as powerkit runs it: each score is the condition's mean,",
      "# the person's own level (normal, variance r) and a deviation in the chosen",
      "# shape (variance 1 - r), so every score has SD 1 and two conditions",
      "# correlate r. The people's levels are drawn first, then each condition's",
      "# deviations in turn. Then the p-value of Friedman's test.",
      "p_friedman <- function(n, means, r) {",
      "  person <- sqrt(r) * rnorm(n)",
      "  y <- vapply(seq_along(means), function(j) means[j] + person + sqrt(1 - r) * draw_scores(n), numeric(n))",
      "  friedman.test(matrix(y, nrow = n))$p.value",
      "}"
    )
  )
  c(draw, "", rest)
}

rank_experiment_lines <- function(spec, inputs, one_sided) {
  args <- switch(
    spec$template,
    one_sample_t = c(
      "n = batch_n, # sample size",
      "d = d, # Cohen's d",
      "type = \"one.sample\",",
      "parent1 = shifted"
    ),
    paired_t = c(
      "n = batch_n, # number of participants (pairs)",
      "d = d_spower, # -d_z (see above)",
      "type = \"paired\",",
      "parent1 = shifted,",
      "parent2 = zero"
    ),
    independent_t = c(
      "n = n_group1, # size of group 1",
      "d = d_spower, # -d (see above)",
      "type = \"two.sample\",",
      "n2_n1 = allocation_ratio, # size of group 2 relative to group 1",
      "parent1 = shifted,",
      "parent2 = unshifted"
    ),
    oneway_between = if (jonckheere_test(spec)) c(
      "n = n_share, # one share of the total",
      "k = length(means), # number of groups",
      "means = means, # group means in SD units",
      "gen_fun = gen_groups,",
      "n.ratios = group_ratio # each group's share"
    ) else c(
      "n = n_group, # size of each group",
      "k = length(means), # number of groups",
      "means = means, # group means in SD units",
      "gen_fun = gen_groups"
    ),
    oneway_within = c(
      "n = batch_n, # number of participants",
      "means = means, # condition means in SD units",
      "r = r"
    )
  )
  if (one_sided) {
    args <- c(args, spower_alternative_line(spec, inputs))
  }
  args <- ensure_commas(args)
  c(sprintf("%s(", inputs$experiment), paste0("  ", args), "),")
}

# Superpower ----------------------------------------------------------------------

superpower_script <- function(spec, result) {
  inputs <- superpower_inputs(spec)
  p <- result$provenance
  call_description <- if (p$method == "exact") {
    "Superpower::ANOVA_exact()"
  } else {
    "Superpower::ANOVA_power()"
  }
  c(
    script_header(spec, result, "Superpower", call_description),
    "library(Superpower)",
    "",
    "# Inputs ----",
    superpower_script_inputs(spec, inputs),
    goal_inputs(spec, result),
    "",
    "# Superpower's design. ANOVA_design() draws random numbers, so powerkit",
    "# builds it under the run's seed.",
    "build_design <- function(n_total, means = mu) {",
    "  set.seed(seed)",
    "  ANOVA_design(",
    "    design = design_string,",
    if (is.null(inputs$cell_ratio)) {
      "    n = n_total / groups, # Superpower's n is per between-participants group"
    } else {
      "    n = n_total * cell_ratio / sum(cell_ratio), # Superpower's n for each cell: unequal cells"
    },
    "    mu = means,",
    "    sd = cell_sd,",
    "    r = r,",
    "    plot = FALSE",
    "  )",
    "}",
    "",
    if (p$method == "exact") {
      superpower_exact_sections(spec, result, inputs)
    } else {
      c(
        "# One batch of simulated data sets: rejections and analysable data sets.",
        "# The design is built before ANOVA_power() is called, as in powerkit.",
        "run_batch <- function(batch_n, batch_replications, batch_seed) {",
        "  design <- build_design(batch_n)",
        "  result <- ANOVA_power(",
        "    design,",
        "    alpha_level = alpha,",
        if (spec$template %in% c("oneway_within", "mixed", "factorial_within")) "    correction = correction, # sphericity correction of the F test",
        if (!is.null(inputs$pairwise_row)) "    p_adjust = p_adjust, # adjusts the p-values of all the pairwise t-tests",
        "    nsims = batch_replications,",
        "    seed = batch_seed,",
        "    verbose = FALSE",
        "  )",
        if (is.null(inputs$pairwise_row)) {
          "  power <- result$main_results[paste0(\"anova_\", effect_row), \"power\"] / 100"
        } else {
          "  power <- result$pc_results[pairwise_row, \"power\"] / 100 # the chosen pair's t-test"
        },
        "  c(round(power * batch_replications), batch_replications)",
        "}",
        "",
        batch_section(result, "ANOVA_power()"),
        simulation_goal_section(spec, result, inputs$groups)
      )
    },
    comparison_section()
  )
}

# Pairwise comparisons: the chosen pair's row of pc_results and the
# adjustment, or nothing.
superpower_pairwise_lines <- function(inputs) {
  if (is.null(inputs$pairwise_row)) {
    return(character())
  }
  c(
    sprintf("pairwise_row <- %s # Superpower's row of pc_results for the pair compared", r_code(inputs$pairwise_row)),
    sprintf("p_adjust <- %s # adjustment across all the pairwise comparisons (stats::p.adjust())", r_code(inputs$p_adjust))
  )
}

superpower_script_inputs <- function(spec, inputs) {
  v <- spec$variables
  factor_line <- function(role, letter) {
    lv <- comment_text(unlist(v[[role]]$levels))
    sprintf(
      "#   %s = %s: %s1 = %s, %s2 = %s", letter, comment_text(v[[role]]$label), letter, lv[1], letter, lv[2]
    )
  }
  if (spec$template == "oneway_between") {
    lv <- comment_text(unlist(v$A$levels))
    return(c(
      sprintf("# Superpower names the factor a and its levels a1 to a%d:", length(lv)),
      sprintf("#   a = %s: %s", comment_text(v$A$label), paste(sprintf("a%d = %s", seq_along(lv), lv), collapse = ", ")),
      sprintf("design_string <- %s # one between-participants factor with %d levels", r_code(inputs$design), length(lv)),
      sprintf("mu <- %s # mean of %s in each group, a1 to a%d", r_code(inputs$mu), comment_text(v$Y$label), length(lv)),
      sprintf("cell_sd <- %s # SD in every group", r_code(inputs$sd)),
      "r <- 0 # correlation between repeated measures (none in a between design)",
      sprintf("groups <- %s # groups: the total n is split equally across them", inputs$groups),
      "effect_row <- \"a\" # Superpower's row for the factor's main effect (the omnibus F test)",
      superpower_pairwise_lines(inputs)
    ))
  }
  if (spec$template == "oneway_within") {
    lv <- comment_text(unlist(v$A$levels))
    return(c(
      sprintf("# Superpower names the factor a and its levels a1 to a%d:", length(lv)),
      sprintf("#   a = %s: %s", comment_text(v$A$label), paste(sprintf("a%d = %s", seq_along(lv), lv), collapse = ", ")),
      sprintf("design_string <- %s # one within-participants factor with %d levels", r_code(inputs$design), length(lv)),
      sprintf("mu <- %s # mean of %s in each condition, a1 to a%d", r_code(inputs$mu), comment_text(v$Y$label), length(lv)),
      sprintf("cell_sd <- %s # %s", r_code(inputs$sd), if (length(inputs$sd) == 1) "SD in every condition" else sprintf("SD in each condition, a1 to a%d", length(lv))),
      sprintf("r <- %s # %s", r_code(inputs$r), if (length(inputs$r) == 1) {
        "correlation between any two conditions, within a participant"
      } else {
        "correlation between each pair of conditions: (a1, a2), (a1, a3), ..., (a2, a3), ..."
      }),
      sprintf("correction <- %s # sphericity correction of the F test (none, GG or HF)", r_code(inputs$correction)),
      "groups <- 1 # one group: everyone is in every condition",
      "effect_row <- \"a\" # Superpower's row for the factor's main effect (the omnibus F test)",
      superpower_pairwise_lines(inputs)
    ))
  }
  if (spec$template == "factorial_three") {
    level_line <- function(role, letter) {
      lv <- comment_text(unlist(v[[role]]$levels))
      sprintf("#   %s = %s (%s): %s", letter, comment_text(v[[role]]$label),
              if (identical(v[[role]]$type, "within_factor")) "within participants" else "between participants",
              paste(sprintf("%s%d = %s", letter, seq_along(lv), lv), collapse = ", "))
    }
    return(c(
      "# Superpower names the factors a, b and c and their levels a1, a2, ..., b1, ..., c1, ...:",
      level_line("A", "a"),
      level_line("B", "b"),
      level_line("C", "c"),
      sprintf("design_string <- %s # b: between participants, w: within", r_code(inputs$design)),
      sprintf(
        "mu <- %s # cell means of %s, in Superpower's order a1_b1_c1, a1_b1_c2, ..., a1_b2_c1, ...",
        r_code(inputs$mu), comment_text(v$Y$label)
      ),
      sprintf("cell_sd <- %s # SD in every cell", r_code(inputs$sd)),
      sprintf("r <- %s # %s", r_code(inputs$r), if (any(three_factor_within(spec))) {
        "correlation between any two cells, within a participant"
      } else {
        "no repeated measures: every cell is different people"
      }),
      sprintf("groups <- %s # %s", inputs$groups, if (inputs$groups == 1) {
        "one group: everyone is in every cell"
      } else {
        "between-participants groups: the total n is split equally across them"
      }),
      sprintf("effect_row <- %s # Superpower's row for the effect tested (\"a\", \"a:b\", \"a:b:c\", ...)", r_code(inputs$effect))
    ))
  }
  if (spec$template %in% c("mixed", "factorial_between", "factorial_within")) {
    level_line <- function(role, letter) {
      lv <- comment_text(unlist(v[[role]]$levels))
      sprintf("#   %s = %s: %s", letter, comment_text(v[[role]]$label),
              paste(sprintf("%s%d = %s", letter, seq_along(lv), lv), collapse = ", "))
    }
    k <- length(unlist(v$A$levels))
    m <- length(unlist(v$B$levels))
    return(c(
      "# Superpower names the factors a and b and their levels a1, a2, ..., b1, b2, ...:",
      level_line("A", "a"),
      level_line("B", "b"),
      sprintf("design_string <- %s # %s", r_code(inputs$design), switch(
        spec$template,
        mixed = sprintf("a between participants (%d levels), b within (%d levels)", k, m),
        factorial_between = sprintf("a (%d levels) and b (%d levels), both between participants", k, m),
        factorial_within = sprintf("a (%d levels) and b (%d levels), both within participants", k, m)
      )),
      sprintf(
        "mu <- %s # cell means of %s, in Superpower's order a1_b1, a1_b2, ..., a2_b1, ...",
        r_code(inputs$mu), comment_text(v$Y$label)
      ),
      sprintf("cell_sd <- %s # %s", r_code(inputs$sd), if (length(inputs$sd) == 1) "SD in every cell" else "SD of each cell, in the same order"),
      sprintf("r <- %s # %s", r_code(inputs$r), switch(
        spec$template,
        mixed = if (length(inputs$r) == 1) "correlation between any two levels of b, within a participant" else
          "correlations: the upper triangle of the cells' correlation matrix, row by row (0 between different groups)",
        factorial_between = "no repeated measures: every cell is different people",
        factorial_within = if (length(inputs$r) == 1) "correlation between any two cells, within a participant" else
          "correlation between each pair of cells: (a1_b1, a1_b2), (a1_b1, a1_b3), ..., (a1_b2, a1_b3), ..."
      )),
      if (spec$template != "factorial_between") sprintf(
        "correction <- %s # sphericity correction of the within-participants F tests (none, GG or HF)", r_code(inputs$correction)
      ),
      sprintf("groups <- %s # %s", inputs$groups, if (inputs$groups == 1) {
        "one group: everyone is in every cell"
      } else {
        "between-participants groups: the total n is split equally across them"
      }),
      sprintf("effect_row <- %s # Superpower's row for the effect tested (\"a\", \"b\" or \"a:b\")", r_code(inputs$effect))
    ))
  }
  between <- spec$template == "2x2_between"
  c(
    "# Superpower names the factors a and b and their levels a1, a2, b1, b2:",
    factor_line("A", "a"),
    factor_line("B", "b"),
    sprintf(
      "design_string <- %s # %s",
      r_code(inputs$design),
      if (between) "two between-participants factors" else "a between participants, b within"
    ),
    sprintf(
      "mu <- %s # cell means of %s, in Superpower's order a1_b1, a1_b2, a2_b1, a2_b2",
      r_code(inputs$mu), comment_text(v$Y$label)
    ),
    sprintf(
      "cell_sd <- %s # %s", r_code(inputs$sd),
      if (length(inputs$sd) == 1) "SD in every cell" else "SD of each cell, in the same order"
    ),
    sprintf(
      "r <- %s # %s", r_code(inputs$r),
      if (between) "correlation between repeated measures (none in a between design)" else if (length(inputs$r) == 1)
        "correlation between the two measurements of b" else
        "correlations: the upper triangle of the cells' correlation matrix, row by row (one per group, 0 between groups)"
    ),
    sprintf(
      "groups <- %s # between-participants groups: %s", inputs$groups,
      if (is.null(inputs$cell_ratio)) "the total n is split equally across them" else "the total n is split in the ratio below"
    ),
    if (!is.null(inputs$cell_ratio)) sprintf(
      "cell_ratio <- %s # relative cell sizes, in the same order (ANOVA_exact() takes equal cells only, so power is simulated)",
      r_code(inputs$cell_ratio)
    ),
    sprintf(
      "effect_row <- %s # Superpower's row for the effect tested (\"a\", \"b\" or \"a:b\")", r_code(inputs$effect)
    )
  )
}

superpower_exact_sections <- function(spec, result, inputs) {
  exact <- c(
    "# Exact power for the effect tested, and Superpower's Cohen's f.",
    "# ANOVA_exact() also draws random numbers (its results vary around the",
    "# 15th decimal place), so powerkit runs it under the run's seed too.",
    if (spec$template == "2x2_mixed") {
      c(
        "# powerkit uses ANOVA_exact() rather than ANOVA_exact2() for mixed",
        "# designs: it reproduces G*Power's values (powerkit's Departure 2)."
      )
    },
    "exact_result <- function(n_total, means = mu) {",
    "  design <- build_design(n_total, means)",
    "  set.seed(seed)",
    if (spec$template %in% c("oneway_within", "mixed", "factorial_within")) {
      "  result <- ANOVA_exact(design, alpha_level = alpha, correction = correction, verbose = FALSE)"
    } else {
      "  result <- ANOVA_exact(design, alpha_level = alpha, verbose = FALSE)"
    },
    "  row <- result$main_results[effect_row, ]",
    "  list(power = row$power / 100, cohen_f = row$cohen_f)",
    "}",
    "exact_power <- function(n_total, means = mu) exact_result(n_total, means)$power",
    ""
  )
  goal <- switch(
    spec$goal$type,
    power = c(
      "# Power at n_total ----",
      "power <- exact_power(n_total)",
      "cat(sprintf(\"Power with n = %s: %.4f\\n\", n_total, power))",
      "",
      "reproduced <- list(power = power)",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)),
      ""
    ),
    sample_size = c(
      "# Required n ----",
      "# Exact power at the required n that powerkit found and at three valid",
      sprintf(
        "# sizes either side (valid sizes are multiples of %s). Power rises with n,", inputs$groups
      ),
      "# so the required n is the first of these that reaches the target power:",
      "# the size before it doesn't.",
      sprintf("sizes <- %s", r_code(result$curve$n)),
      "power <- vapply(sizes, exact_power, numeric(1))",
      "n_required <- sizes[which(power >= target_power)[1]]",
      "print(data.frame(n = sizes, power = power))",
      "cat(sprintf(\"Required n: %s\\n\", n_required))",
      "",
      "reproduced <- list(n = n_required, power = power)",
      sprintf(
        "powerkit_result <- list(n = %s, power = %s)",
        r_code(result$n_required$n), r_code(result$curve$power)
      ),
      ""
    ),
    sensitivity = superpower_sensitivity_section(spec, result)
  )
  c(exact, goal)
}

superpower_sensitivity_section <- function(spec, result) {
  s <- result$sensitivity
  contrast <- switch(
    spec$target_test$effect,
    main_effect_A = "mean(means[1, ]) - mean(means[2, ])",
    main_effect_B = "mean(means[, 1]) - mean(means[, 2])",
    interaction = "(means[1, 1] - means[1, 2]) - (means[2, 1] - means[2, 2])"
  )
  c(
    "# Smallest detectable effect ----",
    "# powerkit keeps the shape of your pattern of means and scales its size",
    "# (each cell mean's distance from the grand mean) until the effect tested",
    "# reaches the target power at n_total. Scale 1 is the pattern as given;",
    "# scale 0 makes all means equal.",
    "grand_mean <- mean(mu)",
    "means_at <- function(scale) grand_mean + scale * (mu - grand_mean)",
    "power_at <- function(scale) exact_power(n_total, means_at(scale))",
    "upper <- 1",
    "while (power_at(upper) < target_power) upper <- upper * 2",
    "scale <- uniroot(function(k) power_at(k) - target_power, lower = 0, upper = upper, tol = 1e-10)$root",
    "at_scale <- exact_result(n_total, means_at(scale))",
    "means <- matrix(means_at(scale), nrow = 2, byrow = TRUE) # rows: a1, a2; columns: b1, b2",
    sprintf("effect <- %s # %s", contrast, comment_text(s$effect_description)),
    "print(means)",
    "cat(sprintf(\"Smallest detectable effect: %.4g (Cohen's f = %.3f, power %.4f)\\n\",",
    "  effect, at_scale$cohen_f, at_scale$power))",
    "",
    "reproduced <- list(scale = scale, effect = effect, cohen_f = at_scale$cohen_f, power = at_scale$power)",
    "powerkit_result <- list(",
    sprintf("  scale = %s, effect = %s,", r_code(s$scale), r_code(s$effect)),
    sprintf("  cohen_f = %s, power = %s", r_code(s$cohen_f), r_code(s$power)),
    ")",
    ""
  )
}

# InteractionPoweR -----------------------------------------------------------------

interactionpower_script <- function(spec, result) {
  if (identical(spec$template, "three_way")) {
    return(interactionpower_3way_script(spec, result))
  }
  inputs <- interactionpower_inputs(spec)
  v <- spec$variables
  label <- function(role) comment_text(v[[role]]$label)
  c(
    script_header(spec, result, "InteractionPoweR", paste0(result$provenance$backend_function, "()")),
    "library(InteractionPoweR)",
    "",
    "# Inputs ----",
    sprintf("# InteractionPoweR's x1 is X (%s), x2 is W (%s, the moderator), y is Y (%s);", label("X"), label("W"), label("Y")),
    "# x1x2 is their product. Correlations are among the true scores.",
    sprintf("r_x1_y <- %s # X with Y", r_code(inputs$r.x1.y)),
    sprintf("r_x2_y <- %s # W with Y", r_code(inputs$r.x2.y)),
    sprintf("r_x1x2_y <- %s # the interaction XW with Y", r_code(inputs$r.x1x2.y)),
    sprintf("r_x1_x2 <- %s # X with W", r_code(inputs$r.x1.x2)),
    sprintf("rel_x1 <- %s # reliability of X (1 = no measurement error)", r_code(inputs$rel.x1)),
    sprintf("rel_x2 <- %s # reliability of W", r_code(inputs$rel.x2)),
    sprintf("rel_y <- %s # reliability of Y", r_code(inputs$rel.y)),
    if (inputs$k.x1 > 0 || inputs$k.x2 > 0) c(
      sprintf("k_x1 <- %s # %s", inputs$k.x1, if (inputs$k.x1 > 0) "X is yes/no: two levels, split 50/50" else "X is a score"),
      sprintf("k_x2 <- %s # %s", inputs$k.x2, if (inputs$k.x2 > 0) "W is yes/no: two levels, split 50/50" else "W is a score"),
      "# With a yes/no variable, its correlations are those of the observed 0/1",
      "# data (point-biserial with Y): adjust.correlations = TRUE, the default."
    ),
    goal_inputs(spec, result),
    "",
    if (spec$goal$type == "sensitivity") interactionpower_sensitivity_section(result) else interactionpower_simulation_lines(spec, result)
  )
}

# Three-way interactions: InteractionPoweR's analytic
# power_interaction_3way_r2(), called with the spec's values.
interactionpower_3way_script <- function(spec, result) {
  inputs <- interactionpower_3way_inputs(spec)
  label <- function(role) comment_text(spec$variables[[role]]$label %||% role)
  line <- function(name, value, comment) sprintf("%s <- %s # %s", name, r_code(value), comment)
  c(
    script_header(spec, result, "InteractionPoweR", "InteractionPoweR::power_interaction_3way_r2()"),
    "library(InteractionPoweR)",
    "",
    "# Inputs ----",
    sprintf(
      "# InteractionPoweR's x1 is X (%s), x2 is W (%s), x3 is Z (%s), y is Y (%s).",
      label("X"), label("W"), label("Z"), label("Y")
    ),
    "# Correlations are among the true scores; the three-way effect is the",
    "# standardised regression coefficient of the product x1x2x3.",
    line("b_x1x2x3", inputs$b.x1x2x3, "the three-way interaction XWZ (standardised coefficient)"),
    line("r_x1_y", inputs$r.x1.y, "X with Y"),
    line("r_x2_y", inputs$r.x2.y, "W with Y"),
    line("r_x3_y", inputs$r.x3.y, "Z with Y"),
    line("r_x1x2_y", inputs$r.x1x2.y, "the product XW with Y"),
    line("r_x1x3_y", inputs$r.x1x3.y, "the product XZ with Y"),
    line("r_x2x3_y", inputs$r.x2x3.y, "the product WZ with Y"),
    line("r_x1_x2", inputs$r.x1.x2, "X with W"),
    line("r_x1_x3", inputs$r.x1.x3, "X with Z"),
    line("r_x2_x3", inputs$r.x2.x3, "W with Z"),
    line("rel_x1", inputs$rel.x1, "reliability of X (1 = no measurement error)"),
    line("rel_x2", inputs$rel.x2, "reliability of W"),
    line("rel_x3", inputs$rel.x3, "reliability of Z"),
    line("rel_y", inputs$rel.y, "reliability of Y"),
    goal_inputs(spec, result),
    "",
    "# Power of the test of the three-way coefficient at a total sample size:",
    "# InteractionPoweR's analytic formula (the change in R-squared when XWZ is",
    "# added to the model with every lower-order term).",
    "power_at <- function(n_total) {",
    "  power_interaction_3way_r2(",
    "    N = n_total, b.x1x2x3 = b_x1x2x3,",
    "    r.x1.y = r_x1_y, r.x2.y = r_x2_y, r.x3.y = r_x3_y,",
    "    r.x1x2.y = r_x1x2_y, r.x1x3.y = r_x1x3_y, r.x2x3.y = r_x2x3_y,",
    "    r.x1.x2 = r_x1_x2, r.x1.x3 = r_x1_x3, r.x2.x3 = r_x2_x3,",
    "    rel.x1 = rel_x1, rel.x2 = rel_x2, rel.x3 = rel_x3, rel.y = rel_y, alpha = alpha",
    "  )$pwr[1]",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# The smallest detectable interaction: the search powerkit ran, with
# InteractionPoweR's fixed-model power_interaction_r2().
interactionpower_sensitivity_section <- function(result) {
  s <- result$sensitivity
  c(
    "# Smallest detectable interaction ----",
    "# Keep the other correlations and the reliabilities, and move the",
    "# interaction's correlation with Y away from 0 (in the direction you gave;",
    "# positive if you gave none) until power reaches the target. This uses",
    "# InteractionPoweR's fixed-model formula, power_interaction_r2(), which",
    "# gives slightly higher power than simulation (powerkit's conventions,",
    "# Known difference 1), so the effect is slightly smaller than simulation",
    "# would give.",
    "direction <- if (r_x1x2_y < 0) -1 else 1",
    "power_with_r <- function(r) {",
    "  tryCatch(power_interaction_r2(",
    "    N = n_total, r.x1.y = r_x1_y, r.x2.y = r_x2_y, r.x1x2.y = direction * r, r.x1.x2 = r_x1_x2,",
    "    rel.x1 = rel_x1, rel.x2 = rel_x2, rel.y = rel_y, alpha = alpha",
    "  )$pwr[1], error = function(e) NA_real_) # NA: correlations impossible together",
    "}",
    "lower <- 0",
    "upper <- NA",
    "for (r in seq(0.01, 0.99, by = 0.01)) {",
    "  p <- power_with_r(r)",
    "  if (is.na(p)) break",
    "  if (p >= target_power) {",
    "    upper <- r",
    "    break",
    "  }",
    "  lower <- r",
    "}",
    "r <- uniroot(function(r) power_with_r(r) - target_power, lower = lower, upper = upper, tol = 1e-10)$root",
    "effect <- direction * r",
    "power <- power_with_r(r)",
    "cat(sprintf(\"Smallest detectable correlation of the interaction with Y: %.4g (power %.4f)\\n\", effect, power))",
    "",
    "reproduced <- list(effect = effect, power = power)",
    sprintf("powerkit_result <- list(effect = %s, power = %s)", r_code(s$effect), r_code(s$power)),
    "",
    comparison_section()
  )
}

interactionpower_simulation_lines <- function(spec, result) {
  c(
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "# Each data set is analysed with lm(y ~ x1 + x2 + x1x2), testing the",
    "# product of the observed X and W. powerkit reports this simulated power;",
    "# fixed-model calculations such as InteractionPoweR's power_interaction_r2()",
    "# give slightly higher power (powerkit's conventions, Known difference 1).",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed) # power_interaction() has no seed argument; on one core it uses R's generator",
    "  result <- power_interaction(",
    "    n.iter = batch_replications, # simulated data sets",
    "    N = batch_n, # sample size",
    "    r.x1.y = r_x1_y,",
    "    r.x2.y = r_x2_y,",
    "    r.x1x2.y = r_x1x2_y,",
    "    r.x1.x2 = r_x1_x2,",
    "    rel.x1 = rel_x1,",
    "    rel.x2 = rel_x2,",
    "    rel.y = rel_y,",
    if (spec$variables$X$type == "binary" || spec$variables$W$type == "binary") "    k.x1 = k_x1, k.x2 = k_x2,",
    "    alpha = alpha",
    "  )",
    "  c(round(result$pwr[1] * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "power_interaction()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}

# power4mome --------------------------------------------------------------------------

power4mome_script <- function(spec, result) {
  inputs <- power4mome_inputs(spec)
  args <- inputs$test_args
  monte_carlo <- inputs$ci_type == "mc"
  roles <- c("x", "m", "y", "w")
  roles <- roles[roles %in% names(args)]
  role_lines <- vapply(roles, function(r) sprintf("%s = %s,", r, r_code(args[[r]])), character(1))
  tested <- if (spec$design == "mediation") {
    sprintf("# the indirect effect tested: %s", spec$target_test$path)
  } else if (!is.null(spec$target_test$path)) {
    sprintf("# the index of moderated mediation through %s", modmed_mediator(spec))
  } else {
    "# the index of moderated mediation"
  }
  c(
    script_header(spec, result, "power4mome", result$provenance$backend_function),
    "library(power4mome)",
    "",
    "# Inputs ----",
    r_multiline_string(
      "model", strsplit(inputs$model, "\n", fixed = TRUE)[[1]],
      c(
        "# The model fitted to each data set, in lavaan syntax.",
        if (spec$design == "moderated_mediation") {
          "# A product such as X:W is the interaction of X and W."
        },
        "# power4mome fits it with lavaan (maximum likelihood). PROCESS uses OLS,",
        "# which gives the same estimates and slightly larger standard errors",
        "# (powerkit's Departure 6).",
        if (any(grepl("~~", strsplit(inputs$model, "\n", fixed = TRUE)[[1]]))) {
          c(
            "# The mediators' residuals are free to correlate, as in PROCESS",
            "# (powerkit's Departure 7)."
          )
        }
      )
    ),
    r_multiline_string(
      "pop_es", strsplit(inputs$pop_es, "\n", fixed = TRUE)[[1]],
      c(
        "# Population values, \"outcome ~ predictor: value\", all standardised.",
        power4mome_covariance_comment(spec)
      )
    ),
    sprintf(
      "ci_draws <- %s # %s per confidence interval (power4mome's R)",
      r_code(inputs$ci_draws), if (monte_carlo) "Monte Carlo draws" else "bootstrap resamples"
    ),
    goal_inputs(spec, result),
    "",
    "# Boos and Zhang's (2000) method off: powerkit always tests with the",
    "# confidence interval (powerkit's Departure 8). power4mome 0.2.1's test",
    "# functions don't read this option, so test_method = \"ci\" below asks for",
    "# the CI rule explicitly; power4mome's summaries do read it.",
    "options(power4mome.bz = FALSE)",
    "",
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  # iseed sets the simulated data sets. set.seed() as well, because for a",
    "  # model with a product term power4test() first standardises the",
    "  # population by Monte Carlo, using R's generator as it finds it.",
    "  set.seed(batch_seed)",
    "  result <- power4test(",
    "    nrep = as.integer(batch_replications), # simulated data sets",
    "    model = model,",
    "    pop_es = pop_es,",
    "    n = batch_n, # sample size",
    if (!is.null(inputs$x_prob)) sprintf(
      "    x_fun = list(X = list(rbinary_rs, p1 = %s)), # X is yes/no: %s in its second level, rescaled to SD 1",
      r_code(inputs$x_prob), r_code(inputs$x_prob)
    ),
    "    R = ci_draws,",
    sprintf(
      "    ci_type = %s, # %s", r_code(inputs$ci_type),
      if (monte_carlo) "Monte Carlo confidence intervals" else "percentile bootstrap confidence intervals"
    ),
    sprintf("    test_fun = %s,", inputs$test_name),
    "    test_args = list(",
    paste0("      ", role_lines[1], " ", tested),
    if (length(role_lines) > 1) paste0("      ", role_lines[-1]),
    sprintf("      mc_ci = %s,", r_code(args$mc_ci)),
    sprintf("      boot_ci = %s,", r_code(args$boot_ci)),
    "      level = 1 - alpha, # confidence level",
    "      test_method = \"ci\" # significant if the confidence interval excludes 0",
    "    ),",
    "    iseed = batch_seed,",
    "    parallel = FALSE,",
    "    progress = FALSE",
    "  )",
    "  rates <- rejection_rates(result)",
    "  # power4mome drops data sets whose model can't be fitted.",
    "  valid <- round(rates$pvalid[1] * batch_replications)",
    "  c(round(rates$reject[1] * valid), valid)",
    "}",
    "",
    batch_section(result, "power4test()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}

power4mome_covariance_comment <- function(spec) {
  model <- path_model(spec)
  if (spec$design == "mediation" && !isTRUE(model$serial) && length(model$mediators) > 1) {
    return(c(
      "# Between two mediators, \"~~\" is their residual covariance: each",
      "# residual correlation you gave, times the two residual SDs, sqrt(1 - R^2)."
    ))
  }
  if (spec$design == "moderated_mediation") {
    return("# \"X ~~ W\" is the correlation of X and W.")
  }
  character()
}

# The test of a clustered design, in words: the t test for a score, or the
# z test of the log odds ratio for a yes/no outcome.
cluster_test_words <- function(spec, score_words) {
  if (identical(spec$population$metric, "proportion")) {
    "yes/no outcome, z test of the log odds ratio (mixed-effects logistic model)"
  } else {
    score_words
  }
}

logistic_factorial_effect_words <- function(spec) {
  switch(
    spec$target_test$effect,
    main_effect_A = sprintf("the main effect of %s", comment_text(spec$variables$A$label)),
    main_effect_B = sprintf("the main effect of %s", comment_text(spec$variables$B$label)),
    interaction = "the interaction"
  )
}

# simr ----------------------------------------------------------------------------

# Participants responding to many items in two conditions (E33): simr's
# powerSim() on the model makeLmer() builds, testing the condition with
# lmerTest's Satterthwaite t test.
simr_script <- function(spec, result) {
  inputs <- simr_inputs(spec)
  pop <- spec$population
  v <- spec$variables
  levels <- comment_text(unlist(v$X$levels))
  item_slope <- length(inputs$VarCorr$item) > 1
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with fixed(\"cond\", \"%s\")", inputs$method)),
    "library(simr)",
    if (inputs$binary) "# A yes/no outcome: a logistic mixed model (glmer), every SD on the log-odds scale." else
      "library(lmerTest) # the Satterthwaite t test (simr's method \"sa\")",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, in its own units; cond is %s coded -0.5 (%s) and 0.5 (%s),", comment_text(v$Y$label), comment_text(v$X$label), levels[1], levels[2]),
    "# so its coefficient is the difference between the conditions.",
    if (inputs$binary) {
      sprintf("probabilities <- %s # the chance of 'yes' in %s and in %s, for a typical participant and item",
        r_code(as.numeric(unlist(pop$probabilities))), levels[1], levels[2])
    } else {
      sprintf("difference <- %s # mean in %s minus mean in %s", r_code(pop$difference), levels[2], levels[1])
    },
    sprintf("sd_participant <- %s # SD of participants' intercepts", r_code(pop$sd_participant)),
    if (!inputs$participants_between) c(
      sprintf("sd_participant_slope <- %s # SD of participants' condition slopes", r_code(pop$sd_participant_slope)),
      sprintf("r_participant <- %s # correlation of participants' intercepts and slopes", r_code(pop$r_participant %||% 0))
    ),
    sprintf("sd_item <- %s # SD of items' intercepts", r_code(pop$sd_item)),
    if (item_slope) sprintf("sd_item_slope <- %s # SD of items' condition slopes", r_code(pop$sd_item_slope)),
    if (!inputs$binary) sprintf("sd_residual <- %s # residual SD", r_code(pop$sd_residual)),
    if (isTRUE(inputs$vary_items)) {
      c(sprintf("participants <- %s # the participants, fixed: the sample size below is the number of items", r_code(pop$participants)),
        "items <- NA # set for each number of items tried")
    } else sprintf("items <- %s # number of items", r_code(pop$items)),
    sprintf("item_design <- %s # %s", r_code(if (inputs$within) "within" else "between"),
      if (inputs$within) "every item in both conditions" else "each item in one condition: the first half in the first"),
    sprintf("participant_design <- %s # %s", r_code(if (inputs$participants_between) "between" else "within"),
      if (inputs$participants_between) "each participant in one condition: the first half in the first" else "every participant in both conditions"),
    goal_inputs(spec, result),
    "",
    "# One data set's design: with the conditions within participants, every",
    "# participant responds to every item; between participants, each responds",
    "# to every item (items within) or to their own condition's half (between).",
    "design_for <- function(n_participants) {",
    "  if (participant_design == \"between\") {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items))",
    "    data$cond <- ifelse(data$participant <= n_participants / 2, -0.5, 0.5)",
    "    if (item_design == \"between\") data <- data[(data$item <= items / 2) == (data$cond < 0), ]",
    "  } else if (item_design == \"within\") {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items), cond = c(-0.5, 0.5))",
    "  } else {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items))",
    "    data$cond <- ifelse(data$item <= items / 2, -0.5, 0.5)",
    "  }",
    "  data$participant <- factor(data$participant)",
    "  data$item <- factor(data$item)",
    "  data",
    "}",
    "",
    "# The population model: fixed effects, random-effect variances and residual SD.",
    "model_for <- function(n_participants) {",
    if (inputs$participants_between) {
      "  participant <- sd_participant^2"
    } else {
      c("  participant <- matrix(c(sd_participant^2, r_participant * sd_participant * sd_participant_slope,",
        "    r_participant * sd_participant * sd_participant_slope, sd_participant_slope^2), nrow = 2)")
    },
    if (inputs$binary) {
      c(sprintf("  makeGlmer(%s, family = \"binomial\",", deparse1(inputs$formula)),
        "    fixef = c(mean(qlogis(probabilities)), diff(qlogis(probabilities))),",
        sprintf("    VarCorr = list(participant = participant, item = %s),", if (item_slope) "diag(c(sd_item^2, sd_item_slope^2))" else "sd_item^2"),
        "    data = design_for(n_participants))")
    } else {
      c(sprintf("  makeLmer(%s,", deparse1(inputs$formula)),
        "    fixef = c(0, difference),",
        sprintf("    VarCorr = list(participant = participant, item = %s),", if (item_slope) "diag(c(sd_item^2, sd_item_slope^2))" else "sd_item^2"),
        "    sigma = sd_residual, data = design_for(n_participants))")
    },
    "}",
    "",
    if (isTRUE(inputs$vary_items)) c(
      "# The sample size searched is the number of items, with the participants fixed.",
      "model_for_participants <- model_for",
      "model_for <- function(n_items) {",
      "  items <<- n_items",
      "  model_for_participants(participants)",
      "}",
      ""
    ),
    "# One batch of simulated data sets: significant results and data sets.",
    "# simr counts a data set whose fit or test fails as not significant.",
    if (!inputs$binary) c(
      "# powerkit tests with Satterthwaite's t test (\"sa\"), not simr's default",
      "# \"z\", an asymptotic approximation (powerkit's Departure 16)."
    ),
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(\"cond\", \"%s\"),", inputs$method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}
