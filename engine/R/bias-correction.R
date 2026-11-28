# A published effect corrected for publication bias and uncertainty, on the
# ANOVA input screens: BUCSS (Anderson, Kelley & Maxwell, 2017; refs.bib),
# from the earlier study's F, its degrees of freedom and its total sample
# size. A partial eta-squared from one published study is the most inflated
# number powerkit takes: studies were more often published when their F
# came out large, and one study's estimate is uncertain. BUCSS gives the
# sample size that reaches the planned power with a chosen assurance after
# correcting for both. Every number is BUCSS's own, through
# replication_bucss(); this file only maps a design spec onto its
# arguments. The plan's own result still uses the published estimate as it
# stands, and the corrected sizes are shown beside it.

# The ANOVA templates BUCSS covers, and how their factors map onto its
# designs. The ANCOVAs are left out: BUCSS has no design with covariates.
bias_correction_templates <- c("oneway_between", "2x2_between", "factorial_between", "factorial_three",
                               "oneway_within", "2x2_mixed", "mixed")

# The arguments for replication_bucss(), or a character string saying why
# the spec can't be corrected this way.
bias_correction_args <- function(spec) {
  bc <- spec$effect_justification$bias_correction
  if (!isTRUE(spec$template %in% bias_correction_templates)) {
    return(paste0("The correction for publication bias and uncertainty ('effect_justification > bias_correction') ",
      "is available for the ANOVAs without covariates, not for this design."))
  }
  conv <- spec$effect_justification$conversion
  if (!identical(conv$from, "F") || is.null(conv[["df"]]) || is.null(conv$df_error)) {
    return(paste0("The correction for publication bias and uncertainty needs the earlier study's F with both its ",
      "degrees of freedom ('effect_justification > conversion' from \"F\", with 'df' and 'df_error')."))
  }
  if (is.null(bc$n)) {
    return("The correction for publication bias and uncertainty needs the earlier study's total sample size ('effect_justification > bias_correction > n').")
  }
  vars <- spec$variables
  levels_of <- function(name) length(vars[[name]]$levels)
  within <- function(name) identical(vars[[name]]$type, "within_factor")
  factors <- intersect(c("A", "B", "C"), names(vars))
  kinds <- vapply(factors, within, logical(1))
  design <- if (!any(kinds)) "anova_between" else if (all(kinds)) "anova_within" else "anova_mixed"
  effect_names <- c(main_effect_A = "factor_a", main_effect_B = "factor_b", main_effect_C = "factor_c",
    interaction = "interaction", interaction_AB = "a_by_b", interaction_AC = "a_by_c", interaction_BC = "b_by_c",
    interaction_ABC = "a_by_b_by_c")
  effect <- spec$target_test$effect %||% "main_effect_A"
  three <- length(factors) == 3
  if (identical(design, "anova_mixed")) {
    # BUCSS's mixed designs take the between-subjects factors first.
    between <- sum(!kinds)
    if (any(kinds[seq_len(between)])) {
      return("The correction for publication bias and uncertainty needs the between-participants factors listed before the within-participants ones.")
    }
    if (!three) effect <- c(main_effect_A = "between", main_effect_B = "within", interaction = "interaction")[[effect]]
  }
  if (!three && !identical(design, "anova_mixed")) {
    effect <- if (identical(effect, "interaction_AB")) "interaction" else effect_names[[effect]]
  } else if (three) {
    effect <- effect_names[[effect]]
  }
  if (is.null(effect) || is.na(effect)) return("The correction for publication bias and uncertainty doesn't cover this effect.")
  args <- list(design = design, original_statistic = conv$value, original_n = bc$n,
    levels_a = levels_of(factors[1]), levels_b = if (length(factors) >= 2) levels_of(factors[2]),
    levels_c = if (three) levels_of(factors[3]),
    between_factors = if (three && identical(design, "anova_mixed")) sum(!kinds),
    effect = effect, original_alpha = bc$original_alpha %||% 0.05, alpha = spec$target_test$alpha %||% 0.05,
    power = spec$goal$power, assurance = c(0.5, 0.8),
    publication_filter = !identical(bc$published, "any"))
  if (!identical(design, "anova_between")) args$epsilon <- 1
  args
}

# In validate_spec(): a correction asked for where it can't be made.
bias_correction_problems <- function(spec) {
  if (is.null(spec$effect_justification$bias_correction)) return(character())
  args <- bias_correction_args(spec)
  if (is.character(args)) return(args)
  df_effect <- if (is.null(args$levels_c)) {
    replication_bucss_df_effect(args$design, args$levels_a, args$levels_b, args$effect)
  } else {
    replication_bucss_effect_three(args$design, args$levels_a, args$levels_b, args$levels_c, args$between_factors, args$effect)$df_effect
  }
  df <- spec$effect_justification$conversion[["df"]]
  if (!isTRUE(all.equal(as.numeric(df), as.numeric(df_effect)))) {
    return(sprintf(paste0("The earlier study's F has %s degrees of freedom for the effect, but this design's effect has %s. ",
      "The correction assumes the earlier study had the same design; give an F from a study with the same factors and levels."),
      format(df), format(df_effect)))
  }
  character()
}

#' The sample size corrected for publication bias and uncertainty, for a
#' plan on an ANOVA screen
#'
#' For a design spec whose effect comes from one earlier study's F (and
#' whose justification asks for `bias_correction`), the sample sizes BUCSS
#' gives at 50% and 80% assurance (Anderson, Kelley & Maxwell, 2017),
#' through [replication_bucss()]. `NULL` when the spec doesn't ask for it,
#' or its goal isn't a sample size.
#'
#' @param spec A validated design spec.
#' @return `NULL`, or [replication_bucss()]'s list.
#' @keywords internal
bias_correction_record <- function(spec) {
  # BUCSS gives a sample size: for another goal (a curve or comparison
  # worked out from the same plan, say) there is nothing to add.
  if (is.null(spec$effect_justification$bias_correction) || !identical(spec$goal$type, "sample_size")) return(NULL)
  args <- bias_correction_args(spec)
  if (is.character(args)) return(NULL)
  do.call(replication_bucss, args)
}
