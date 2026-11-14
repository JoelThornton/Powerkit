# A corrected F test of a within-participants effect whose SDs or
# correlations differ, so sphericity can fail (the F test, not a rank test,
# a Bayes factor or pairwise comparisons).
corrected_nonspherical_test <- function(spec) {
  identical(spec$design, "factorial_anova") && sphericity_can_fail(spec) &&
    isTRUE(spec$target_test$correction %in% c("GG", "HF")) &&
    !is_rank_test(spec) && !is_bayes_test(spec) && !is_pairwise(spec)
}

# Whether such a test is worked out with Superpower's exact data set: on
# request, or for the smallest detectable effect, which the engine finds
# with it (Departure 27 makes simulation the default otherwise).
gg_exact_route <- function(spec) {
  corrected_nonspherical_test(spec) &&
    (identical(spec$options$method, "exact") || isTRUE(spec$goal$type %in% c("sensitivity", "sensitivity_curve")))
}

# The exact data set applies the correction by scaling the test's
# noncentrality and degrees of freedom by epsilon, an approximation that
# missed simulated power by up to about 3 points in either direction
# (docs/validation-log.md, 14 November 2026; Departure 27).
gg_planning_note <- function(spec) {
  if (!gg_exact_route(spec)) return(NULL)
  smallest <- isTRUE(spec$goal$type %in% c("sensitivity", "sensitivity_curve"))
  paste(
    if (smallest) {
      "The smallest detectable effect is found with Superpower's exact dataset, which applies the sphericity correction approximately, by scaling the test's degrees of freedom by epsilon."
    } else {
      "You chose Superpower's exact dataset, which applies the sphericity correction approximately, by scaling the test's degrees of freedom by epsilon."
    },
    "In powerkit's checks this was up to about 3 percentage points too high or too low compared with simulated studies of the corrected test.",
    if (smallest) {
      "Before relying on it, enter means of that size and check their power by simulation."
    } else {
      "Check the power at this sample size by simulation before relying on it."
    })
}

# A sensitivity result is a proposal for a fixed-N simulation, not a
# simulation-confirmed target. Keep all other form answers and require
# the usual check action rather than starting a potentially long job.
interaction_verification_values <- function(calc, values) {
  if (!identical(calc$status, "ok") ||
      !identical(calc$spec$design, "regression_interaction") ||
      !identical(calc$spec$template, "two_way") ||
      !identical(calc$spec$population$metric, "correlation") ||
      # Only a smallest-effect result has a list here; a sample size or
      # power result can hold a bare value, and `$` on it is an error.
      !is.list(calc$result$sensitivity) || !isTRUE(calc$result$sensitivity$approximation)) return(NULL)
  values$goal <- "power"
  values$n <- as.character(calc$spec$goal$n)
  values$r_XW_Y <- as.character(calc$result$sensitivity$effect)
  values
}

corrected_anova_verification_values <- function(calc, values) {
  if (!identical(calc$status, "ok") || is.null(gg_planning_note(calc$spec)) ||
      !identical(calc$result$provenance$method, "exact") ||
      identical(calc$result$goal_type, "sensitivity")) return(NULL)
  values$goal <- "power"
  values$n <- as.character(n_analysed(calc$result))
  values$method <- "simulation"
  values$gg_method <- "simulation"
  values
}

corrected_count_verification_values <- function(calc, values) {
  if (!identical(calc$status, "ok") || !is_corrected_count_test(calc$spec) ||
      !identical(calc$result$goal_type, "sample_size")) return(NULL)
  values$goal <- "power"
  values$n <- as.character(n_analysed(calc$result))
  values
}
corrected_count_search_note <- function(spec, result) {
  if (!is_corrected_count_test(spec) || !identical(result$goal_type, "sample_size")) return(NULL)
  checked <- result$n_required$verification
  if (!is.null(checked)) return(paste(
    sprintf("This sample size passed a fresh simulation check: estimated power %.1f%%, with a one-sided lower bound of %.1f%%.",
      100 * result$n_required$power, 100 * checked$lower),
    sprintf("Each check used %s new simulated studies; the 99%% Monte Carlo protection accounts for up to ten candidate checks.",
      format(checked$nrep, big.mark = ",")),
    "This may recommend more participants than the minimum. It checks only the population and analysis you specified; it does not protect against an optimistic effect size or wrong assumptions."))
  paste("This sample size is estimated from a smooth curve fitted to simulated studies.",
    "Corrected count tests are discrete: actual power at the returned integer N can fall below the target, and the fitted interval does not cover every approximation error.",
    "Check power at the proposed N with more simulations; compare nearby valid sample sizes before choosing your final sample.")
}

attrition_planning_note <- function(spec) {
  if (!isTRUE((spec$options$attrition %||% 0) > 0)) return(NULL)
  paste("The attrition percentage only adds a recruitment buffer for the analysed sample.",
    "It does not model which observations are missing or how they will be analysed.",
    "Missingness can change power or bias results; this buffer alone does not establish that your planned missing-data analysis reaches the target.")
}

# Cross-lagged panel (E74) with no measurement error assumed: real scores
# contain error, which lowers power and attenuates the lagged effects
# (specialist maths review, M-14), so the result says the power is optimistic.
riclpm_reliability_note <- function(spec) {
  if (!identical(spec$template, "riclpm") || !isTRUE((spec$population$reliability %||% 1) >= 1)) return(NULL)
  paste("This power assumes the scores have no measurement error, which almost no measure achieves, so it is optimistic:",
    "measurement error lowers power and makes the lagged effects look smaller.",
    "Enter the measures' reliability (for example their alpha or omega) for a realistic answer.")
}

# These limitations stay visible with explanations off and precede the answer.
planning_warning_notes <- function(spec, result = NULL) unique(c(
  gg_planning_note(spec), uncorrected_f_note(spec), binary_x_modmed_note(spec), attrition_planning_note(spec),
  riclpm_reliability_note(spec),
  if (!is.null(result)) corrected_count_search_note(spec, result)
))
planning_warnings_ui <- function(spec, result = NULL) {
  notes <- planning_warning_notes(spec, result)
  if (!length(notes)) return(NULL)
  div(class = "alert alert-warning selected-method-warning planning-critical", role = "status",
    tags$strong("Important limitation for this analysis"),
    tags$ul(lapply(notes, tags$li)),
    if (identical(spec$design, "moderated_mediation") &&
        identical(spec$variables$X$type, "binary")) p(
      "Choose the analysis you will actually report. If that is ordinary regression with a percentile bootstrap, select the PROCESS-style option. Its evidence covers only recorded settings; switching methods alone does not validate your plan."))
}
