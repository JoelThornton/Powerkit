# Scoped warning: this is an unresolved approximation discrepancy, not a
# statement that every corrected repeated-measures design has the same bias.
gg_planning_note <- function(spec) {
  if (!identical(spec$design, "factorial_anova") ||
      !isTRUE(spec$target_test$correction %in% c("GG", "HF")) ||
      is_rank_test(spec) || is_bayes_test(spec) || is_pairwise(spec)) return(NULL)
  paste("Corrected repeated-measures planning needs an extra check.",
    "In a recorded mixed-design Greenhouse-Geisser case, Superpower's exact-data calculation gave higher power than independent simulated studies (.231 versus .218).",
    "The reason is unresolved; this is not a general error bound, and changing to Huynh-Feldt has not been verified as a remedy.",
    "Check the proposed sample size by simulation using the same population and corrected analysis before relying on it.")
}

# A sensitivity result is a proposal for a fixed-N simulation, not a
# simulation-confirmed target. Keep all other form answers and require
# the usual check action rather than starting a potentially long job.
interaction_verification_values <- function(calc, values) {
  if (!identical(calc$status, "ok") ||
      !identical(calc$spec$design, "regression_interaction") ||
      !identical(calc$spec$template, "two_way") ||
      !identical(calc$spec$population$metric, "correlation") ||
      !isTRUE(calc$result$sensitivity$approximation)) return(NULL)
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
  paste("This sample size is estimated from a smooth curve fitted to simulated studies.",
    "Corrected count tests are discrete: actual power at the returned integer N can fall below the target, and the fitted interval does not cover every approximation error.",
    "Check power at the proposed N with more simulations; compare nearby valid sample sizes before choosing your final sample.")
}
