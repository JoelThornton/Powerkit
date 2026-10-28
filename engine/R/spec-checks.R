# Checks that need more than the JSON schema: the variables and paths fit
# the template, the implied population is possible, and the goal can be met.
# Each check takes a schema-valid spec and returns a character vector of
# plain-English problems (empty when all is well).

population_problems <- function(spec) {
  design_check <- switch(
    spec$design,
    basic_test = check_basic_test,
    factorial_anova = check_factorial_anova,
    multiple_regression = check_multiple_regression,
    logistic_regression = check_single_predictor_x,
    poisson_regression = check_single_predictor_x,
    cluster_trial = check_cluster_trial,
    sem = check_sem,
    regression_interaction = check_regression_interaction,
    mediation = check_path_model,
    moderated_mediation = check_path_model,
    generic_test = function(spec) character(),
    equivalence_test = check_equivalence_test
  )
  design_problems <- design_check(spec)
  c(
    check_labels(spec),
    check_reliability_allowed(spec),
    check_allocation_allowed(spec),
    check_method_allowed(spec),
    check_proportions_formula_allowed(spec),
    check_direction_allowed(spec),
    check_weights_allowed(spec),
    design_problems,
    # The target effect can only be computed once the design itself is sound.
    check_goal(spec, check_effect = length(design_problems) == 0)
  )
}

# Advice that does not make a spec invalid. Returned as messages and issued
# as warnings by validate_spec().
spec_advice <- function(spec) {
  advice <- character()
  if (identical(spec$effect_justification$type, "pilot_study") && is.null(spec$effect_justification$safeguard)) {
    advice <- c(advice, paste0(
      "The effect size comes from a pilot study. Pilot estimates are very ",
      "imprecise, so a sample size based on one can be far too small or too ",
      "large. Consider a smallest effect of interest instead, or adjust the ",
      "pilot estimate and say how in 'effect_justification > adjustment'."
    ))
  }
  # Observed power: allowed, with a warning (judgement call 3.1, decided
  # 22 October 2026). Source: Rubin (2025), refs.bib RubinMikael2025_power.
  if (identical(spec$effect_justification$type, "own_study_result")) {
    advice <- c(advice, paste0(
      "The effect size is the one a finished study found, so this is ",
      "'observed power'. It is widely discouraged: \"post hoc power analyses ",
      "are useless at best, misleading at worst\" (Rubin, 2025, p. 14, citing ",
      "Dziak et al., 2020). Reviewers sometimes ask for it (same page); if you ",
      "report it, say how it was calculated. To plan a new study, use a ",
      "smallest effect of interest instead."
    ))
  }
  nrep <- spec$options$nrep
  if (!is.null(nrep) && nrep < 1000 && uses_simulation(spec)) {
    advice <- c(advice, sprintf(
      paste0(
        "'options > nrep' is %s. With fewer than 1,000 replications a power ",
        "estimate of 80%% is only accurate to about +/- %s; use 1,000 or more ",
        "for a final report."
      ),
      format_number(nrep), format_number(round(1.96 * sqrt(0.8 * 0.2 / nrep), 3))
    ))
  }
  attrition <- spec$options$attrition
  if (!is.null(attrition) && attrition > 0.5) {
    advice <- c(advice, sprintf(
      paste0(
        "'options > attrition' is %s, so more than half of those recruited ",
        "would not be analysed. Check this is right."
      ),
      format_number(attrition)
    ))
  }
  advice
}

# 2x2 ANOVA designs and the basic tests pwr covers are computed exactly
# unless simulation is requested; every other design is simulated.
uses_simulation <- function(spec) {
  # Welch's t-test is simulated unless the formula is requested.
  default <- if (exact_available(spec) && !identical(spec$target_test$method, "welch_t")) "exact" else "simulation"
  identical(spec$options$method %||% default, "simulation")
}

# Designs with an exact method: factorial ANOVA (Superpower's
# ANOVA_exact()), the basic tests pwr covers, and the tests pwrss covers
# (one proportion, McNemar, R-squared, Fisher's exact test, goodness of
# fit, two correlations, ANCOVA, contrasts, logistic and Poisson
# regression, and Welch's t-test on request).
exact_available <- function(spec) {
  spec$design %in% c("factorial_anova", "multiple_regression", "generic_test", "equivalence_test") ||
    pwr_covers(spec) ||
    pwrss_only(spec) ||
    identical(spec$target_test$method, "welch_t")
}

# Tests with no simulation in powerkit yet: they are computed by formula
# only (pwrss).
simulation_available <- function(spec) {
  !(spec$design %in% c("multiple_regression", "generic_test", "equivalence_test") || pwrss_only(spec))
}

# Basic tests powerkit computes by simulation only: neither pwr nor pwrss
# has a formula for them. G*Power computes the variance tests by formula,
# but no package powerkit is built on does, and powerkit doesn't write the
# maths itself (CLAUDE.md), so these are simulated with Spower.
spower_only <- function(spec) {
  spec$template %in% c("one_variance", "two_variances")
}

# Tests powerkit computes with pwrss's formulas only (and clustered
# designs, with powertools' formulas only).
pwrss_only <- function(spec) {
  spec$design %in% c("logistic_regression", "poisson_regression", "cluster_trial", "sem") ||
    spec$template %in% c("one_proportion", "mcnemar", "chi_square_gof", "two_correlations",
                         "oneway_ancova", "oneway_contrast") ||
    spec$template %in% dependent_correlation_templates() ||
    identical(spec$target_test$method, "fisher_exact")
}

# Variables -----------------------------------------------------------------

var_label <- function(spec, role) {
  label <- spec$variables[[role]]$label
  if (is.null(label)) role else sprintf("%s (%s)", label, role)
}

check_labels <- function(spec) {
  labels <- vapply(spec$variables, function(v) v$label, character(1))
  dups <- unique(labels[duplicated(labels)])
  vapply(dups, function(label) {
    roles <- names(labels)[labels == label]
    sprintf(
      "Variables %s have the same label, '%s'. Give each variable its own name so the diagram and write-up are clear.",
      quote_list(roles, "and"), label
    )
  }, character(1), USE.NAMES = FALSE)
}

check_reliability_allowed <- function(spec) {
  if (spec$design %in% c("regression_interaction", "mediation", "moderated_mediation")) {
    return(character())
  }
  has_rel <- vapply(spec$variables, function(v) !is.null(v$reliability), logical(1))
  vapply(names(has_rel)[has_rel], function(role) {
    sprintf(
      "'variables > %s > reliability' can't be used with %s designs yet; remove it.",
      role, gsub("_", " ", spec$design)
    )
  }, character(1), USE.NAMES = FALSE)
}

check_allocation_allowed <- function(spec) {
  if (is.null(spec$options$allocation_ratio)) {
    return(character())
  }
  # The two-variance test has two groups, but Spower can only simulate
  # equal ones: gen_var.test() builds a data frame of the wrong length when
  # the group sizes differ (docs/upstream-questions.md).
  if (identical(spec$template, "two_variances")) {
    return(paste0(
      "'options > allocation_ratio' isn't available for the two-variance ",
      "test yet: the simulation it uses can only draw groups of the same ",
      "size. Remove it, or plan for two equal groups."
    ))
  }
  if (spec$template %in% c("independent_t", "two_proportions", "two_correlations", "tost_independent")) {
    return(character())
  }
  paste0(
    "'options > allocation_ratio' only applies to two-group designs ",
    "(independent t-test, two proportions, two correlations, equivalence of ",
    "two groups); remove it."
  )
}

check_method_allowed <- function(spec) {
  if (identical(spec$options$method, "simulation") && !simulation_available(spec)) {
    return(paste0(
      "'options > method' 'simulation' isn't available for this test yet; ",
      "its power is calculated by formula. Remove 'options > method'."
    ))
  }
  if (!identical(spec$options$method, "exact") || exact_available(spec)) {
    return(character())
  }
  if (spower_only(spec)) {
    return(paste0(
      "'options > method' 'exact' isn't available for this test: none of the ",
      "packages powerkit uses has a formula for it, so its power is ",
      "simulated. Remove 'options > method'."
    ))
  }
  paste0(
    "'options > method' 'exact' is only available for 2x2 ANOVA designs and ",
    "basic tests; remove it or use 'simulation'."
  )
}

# The formula choice for two proportions (z test or arcsine) applies only
# to that test, and only when power is calculated by formula.
check_proportions_formula_allowed <- function(spec) {
  if (is.null(spec$options$proportions_formula)) {
    return(character())
  }
  if (spec$template != "two_proportions") {
    return("'options > proportions_formula' only applies to the two-proportions test; remove it.")
  }
  if (identical(spec$options$method, "simulation")) {
    return(paste0(
      "'options > proportions_formula' only applies when power is calculated by formula; ",
      "remove it or remove 'options > method' 'simulation'."
    ))
  }
  character()
}

# pwrss's one-sided tests (one proportion, McNemar, Fisher's exact test,
# two correlations, dependent correlations, logistic and Poisson
# regression, Welch's t-test by formula) run in the direction of the
# specified effect, so a one-sided test pointing the
# other way can't be computed with them.
check_direction_allowed <- function(spec) {
  alternative <- spec$target_test$alternative %||% "two_sided"
  one_sided <- c("one_proportion", "mcnemar", "independent_t", "two_proportions", "two_correlations",
                 dependent_correlation_templates(), "single_predictor",
                 "single_predictor_count", "one_variance", "two_variances",
                 "cluster_randomised", "multisite", "t", "z")
  if (alternative == "two_sided" || !spec$template %in% one_sided) {
    return(character())
  }
  pop <- spec$population
  # Generic tests: only the power for a given noncentrality has a direction
  # to check; the noncentrality needed is solved in the direction asked.
  if (identical(spec$design, "generic_test") && spec$goal$type != "power") {
    return(character())
  }
  diff <- switch(
    spec$template,
    t = ,
    z = pop$ncp,
    one_proportion = pop$p - pop$p0,
    mcnemar = pop$p_second_only - pop$p_first_only,
    two_correlations = pop$r2 - pop$r1,
    overlapping_correlations = ,
    nonoverlapping_correlations = dependent_correlation_difference(spec),
    # "greater" means the odds go up with X (odds ratio above 1).
    single_predictor = log(pop$odds_ratio),
    # "greater" means the event rate goes up with X (rate ratio above 1).
    single_predictor_count = log(pop$rate_ratio),
    # "greater" means the variance is the larger one: Y's against the fixed
    # value, or the first group's against the second.
    one_variance = pop$var - pop$var0,
    two_variances = pop$var1 - pop$var2,
    # "greater" means the second condition's mean is higher.
    cluster_randomised = ,
    multisite = pop$d,
    two_proportions = if (identical(spec$target_test$method, "fisher_exact")) pop$p2 - pop$p1,
    independent_t = if (identical(spec$target_test$method, "welch_t") &&
      identical(spec$options$method, "exact")) pop$d
  )
  if (is.null(diff) || diff == 0 || (alternative == "greater") == (diff > 0)) {
    return(character())
  }
  sprintf(
    paste0(
      "'target_test > alternative' is '%s', but the effect you specified goes ",
      "the other way. A one-sided test against the expected direction can't be ",
      "calculated for this test; use 'two_sided', or check the population values."
    ),
    alternative
  )
}

# Logistic and Poisson regression ----------------------------------------------

# 'x_prob' (the proportion in X's second level) only means something for a
# yes/no X.
check_single_predictor_x <- function(spec) {
  if (!is.null(spec$population$x_prob) && !identical(spec$variables$X$type, "binary")) {
    return(sprintf(
      "'population > x_prob' is the proportion in the second group of a yes/no X, but %s is a score; remove 'x_prob', or make X binary.",
      var_label(spec, "X")
    ))
  }
  character()
}

# Equivalence tests -------------------------------------------------------------

# An equivalence test shows that the true difference lies between -bound
# and +bound. If the expected difference is beyond the bound, TOSTER
# doesn't calculate power (power_t_TOST(): "True mean difference greater
# than bounds"), and it would be below alpha anyway. At the bound itself
# power is about alpha, however many people take part, so no sample size
# reaches a target power.
check_equivalence_test <- function(spec) {
  pop <- spec$population
  effect <- if (identical(spec$template, "tost_paired")) pop$dz else pop$d
  if (is.null(effect) || is.null(pop$bound)) {
    return(character())
  }
  outside <- abs(effect) > pop$bound + 1e-12
  at_bound <- abs(effect) >= pop$bound - 1e-12
  if (!outside && !(at_bound && identical(spec$goal$type, "sample_size"))) {
    return(character())
  }
  paste0(
    "The difference you expect is ", if (outside) "larger than" else "as large as",
    " the equivalence bound, so the study would be unlikely to show ",
    "equivalence however many people took part. Check the expected ",
    "difference and the bound: the expected difference has to lie inside the ",
    "bounds (0 means no difference)."
  )
}

# Clustered designs --------------------------------------------------------------

# Group sizes that vary: powertools' adjustment (its relative efficiency,
# re.clustsize.cont()) is an approximation that breaks down when they vary
# a lot, giving a value of 0 or below.
check_cluster_trial <- function(spec) {
  pop <- spec$population
  m_sd <- pop$cluster_size_sd %||% 0
  if (m_sd <= 0) {
    return(character())
  }
  # A multisite trial's adjustment uses the ICC of the effect (icc1).
  icc <- if (identical(spec$template, "multisite")) pop$icc_effect else pop$icc
  re <- quietly(powertools::re.clustsize.cont(m = pop$cluster_size, m.sd = m_sd, icc = icc))
  if (re > 0) {
    return(character())
  }
  sprintf(
    paste0(
      "'population > cluster_size_sd' (%s) is too large for an average group ",
      "size of %s: the adjustment for groups of different sizes isn't valid when ",
      "their sizes vary this much. Check the values, or plan with a smaller spread."
    ),
    format_number(m_sd), format_number(pop$cluster_size)
  )
}

# Structural equation models -----------------------------------------------------

# Model fit: the model is given either by its df or by the number of items
# and factors of a CFA, not both; each factor needs two items, and the
# model needs at least one degree of freedom to be tested.
check_sem <- function(spec) {
  pop <- spec$population
  shape <- !is.null(pop$indicators) || !is.null(pop$factors)
  if (!is.null(pop$df) && shape) {
    return(paste0(
      "Give either 'population > df' or 'population > indicators' and ",
      "'population > factors', not both."
    ))
  }
  if (!is.null(pop$df)) {
    return(character())
  }
  if (is.null(pop$indicators) || is.null(pop$factors)) {
    return(paste0(
      "Give the model's degrees of freedom ('population > df'), or both the number of ",
      "items ('population > indicators') and of factors ('population > factors')."
    ))
  }
  if (pop$indicators < 2 * pop$factors) {
    return(sprintf(
      "%s items can't measure %s factors: each factor needs at least two items (three for a model with one factor).",
      format_number(pop$indicators), format_number(pop$factors)
    ))
  }
  df <- sem_df(spec)
  if (df < 1) {
    return(sprintf(
      paste0(
        "A model with %s items on %s factor%s has %s degrees of freedom, so its fit can't be ",
        "tested. Add items: a single factor needs at least four."
      ),
      format_number(pop$indicators), format_number(pop$factors),
      if (pop$factors == 1) "" else "s", format_number(df)
    ))
  }
  character()
}

# Basic tests ----------------------------------------------------------------

check_basic_test <- function(spec) {
  switch(
    spec$template,
    chi_square_independence = check_probability_table(spec),
    chi_square_gof = check_gof_probabilities(spec),
    mcnemar = check_discordant_proportions(spec),
    overlapping_correlations = ,
    nonoverlapping_correlations = check_dependent_correlations(spec),
    character()
  )
}

# Dependent correlations (one group): X with Y against X with Z
# (overlapping), or X1 with Y1 against X2 with Y2 (non-overlapping).
dependent_correlation_templates <- function() {
  c("overlapping_correlations", "nonoverlapping_correlations")
}

# The correlation matrix of the variables, in pwrss's order (X, Y, Z; or
# X1, Y1, X2, Y2).
dependent_correlation_matrix <- function(spec) {
  pop <- spec$population
  if (spec$template == "overlapping_correlations") {
    r <- matrix(c(
      1, pop$r_X_Y, pop$r_X_Z,
      pop$r_X_Y, 1, pop$r_Y_Z,
      pop$r_X_Z, pop$r_Y_Z, 1
    ), nrow = 3)
    dimnames(r) <- list(c("X", "Y", "Z"), c("X", "Y", "Z"))
    return(r)
  }
  r <- matrix(c(
    1, pop$r_X1_Y1, pop$r_X1_X2, pop$r_X1_Y2,
    pop$r_X1_Y1, 1, pop$r_Y1_X2, pop$r_Y1_Y2,
    pop$r_X1_X2, pop$r_Y1_X2, 1, pop$r_X2_Y2,
    pop$r_X1_Y2, pop$r_Y1_Y2, pop$r_X2_Y2, 1
  ), nrow = 4)
  dimnames(r) <- list(c("X1", "Y1", "X2", "Y2"), c("X1", "Y1", "X2", "Y2"))
  r
}

# The second compared correlation minus the first: r_X_Z - r_X_Y, or
# r_X2_Y2 - r_X1_Y1 ("greater" means the second is larger).
dependent_correlation_difference <- function(spec) {
  pop <- spec$population
  if (spec$template == "overlapping_correlations") pop$r_X_Z - pop$r_X_Y else pop$r_X2_Y2 - pop$r_X1_Y1
}

check_dependent_correlations <- function(spec) {
  r <- dependent_correlation_matrix(spec)
  if (min(eigen(r, symmetric = TRUE, only.values = TRUE)$values) <= 1e-8) {
    return(paste0(
      "These correlations are impossible together: no population could have all of them at once. ",
      "Change one or more of them (the correlations that aren't compared are often the ones to check)."
    ))
  }
  # pwrss's Steiger test has no power for two equal correlations with a
  # two-sided test (there is no difference to detect).
  if (identical(spec$goal$type, "power") && abs(dependent_correlation_difference(spec)) < 1e-12 &&
    identical(spec$target_test$alternative %||% "two_sided", "two_sided")) {
    compared <- if (spec$template == "overlapping_correlations") "r_X_Y and r_X_Z" else "r_X1_Y1 and r_X2_Y2"
    return(sprintf(
      "The two correlations compared (%s) are equal, so a two-sided test has no difference to detect and its power can't be calculated. Give them different values (for a Type I error check, use a one-sided test).",
      compared
    ))
  }
  character()
}

# The two discordant proportions are parts of one population, so together
# they can't exceed 1.
check_discordant_proportions <- function(spec) {
  pop <- spec$population
  total <- pop$p_first_only + pop$p_second_only
  if (total > 1) {
    return(sprintf(
      "'population > p_first_only' and 'p_second_only' add up to %s, but together they can't be more than 1 (they are proportions of the same people).",
      format_number(total)
    ))
  }
  character()
}

# Goodness of fit: one proportion per level of Y, adding up to 1, and the
# same for the fixed proportions if given.
check_gof_probabilities <- function(spec) {
  pop <- spec$population
  k <- length(spec$variables$Y$levels)
  problems <- character()
  for (name in c("probabilities", "null_probabilities")) {
    p <- as.numeric(unlist(pop[[name]]))
    if (length(p) == 0) next
    if (length(p) != k) {
      problems <- c(problems, sprintf(
        "'population > %s' has %d values, but %s has %d levels. Give one proportion for each level, in the same order.",
        name, length(p), var_label(spec, "Y"), k
      ))
    } else if (abs(sum(p) - 1) > 1e-6) {
      problems <- c(problems, sprintf(
        "'population > %s' must add up to 1, but they add up to %s.",
        name, format_number(round(sum(p), 6))
      ))
    }
  }
  problems
}

check_probability_table <- function(spec) {
  rows <- spec$population$probabilities
  widths <- lengths(rows)
  if (length(unique(widths)) != 1) {
    return(paste0(
      "'population > probabilities' must be a table: every row needs the same ",
      "number of entries (one per level of Y). The rows have ",
      paste(widths, collapse = ", "), " entries."
    ))
  }
  p <- matrix(as.numeric(unlist(rows)), nrow = length(rows), byrow = TRUE)
  problems <- character()
  n_x <- length(spec$variables$X$levels)
  n_y <- length(spec$variables$Y$levels)
  if (nrow(p) != n_x || ncol(p) != n_y) {
    problems <- c(problems, sprintf(
      "'population > probabilities' is %d x %d, but %s has %d levels (rows) and %s has %d levels (columns).",
      nrow(p), ncol(p), var_label(spec, "X"), n_x, var_label(spec, "Y"), n_y
    ))
  }
  total <- sum(p)
  if (abs(total - 1) > 1e-6) {
    problems <- c(problems, sprintf(
      "'population > probabilities' must add up to 1, but they add up to %s. Each cell is the proportion of the population with that combination of X and Y.",
      format_number(round(total, 6))
    ))
  }
  if (any(rowSums(p) == 0) || any(colSums(p) == 0)) {
    problems <- c(problems, paste0(
      "'population > probabilities' has a row or column that is all zero, so ",
      "that level never occurs. Remove the level or give it some probability."
    ))
  }
  problems
}

# Factorial ANOVA ------------------------------------------------------------

check_factorial_anova <- function(spec) {
  pop <- spec$population
  if (identical(pop$metric, "standardised") && any(unlist(pop$sd) != 1)) {
    return(paste0(
      "With metric 'standardised' the means are in SD units, so ",
      "'population > sd' must be 1. To use your own units, set metric to 'raw'."
    ))
  }
  if (spec$template %in% c("oneway_between", "oneway_within", "oneway_ancova", "oneway_contrast")) {
    k <- length(spec$variables$A$levels)
    if (length(pop$means) != k) {
      return(sprintf(
        "'population > means' has %d values, but %s has %d levels. Give one mean for each level, in the same order.",
        length(pop$means), var_label(spec, "A"), k
      ))
    }
  }
  if (identical(spec$template, "oneway_contrast")) {
    return(check_contrast_weights(spec))
  }
  character()
}

# 'weights' say which combination of means a contrast tests, so they mean
# nothing for any other test.
check_weights_allowed <- function(spec) {
  if (is.null(spec$target_test$weights) || identical(spec$template, "oneway_contrast")) {
    return(character())
  }
  "'target_test > weights' are the weights of a planned comparison, which only the 'oneway_contrast' template tests. Remove them, or use that template."
}

# A contrast's weights: one per level, adding up to 0, and not all 0. The
# scale doesn't matter, so (-3, -1, 1, 3) and (-1.5, -0.5, 0.5, 1.5) are the
# same contrast.
check_contrast_weights <- function(spec) {
  weights <- as.numeric(unlist(spec$target_test$weights))
  k <- length(spec$variables$A$levels)
  if (length(weights) != k) {
    return(sprintf(
      "'target_test > weights' has %d values, but %s has %d levels. Give one weight for each level, in the same order.",
      length(weights), var_label(spec, "A"), k
    ))
  }
  if (all(weights == 0)) {
    return("'target_test > weights' are all 0, so they don't compare anything. Give negative weights to the levels on one side of the comparison and positive weights to the other.")
  }
  # The same tolerance as the whole-number checks elsewhere in this file.
  if (abs(sum(weights)) > 1e-9) {
    return(sprintf(
      "'target_test > weights' add up to %s, but a contrast's weights must add up to 0. For example, to compare the first two levels with the last two, use -0.5, -0.5, 0.5, 0.5.",
      format_number(sum(weights))
    ))
  }
  character()
}

anova_contrast <- function(spec) {
  if (identical(spec$template, "oneway_contrast")) {
    # The contrast itself: zero when the weighted means cancel out, which
    # includes every mean being equal.
    weights <- as.numeric(unlist(spec$target_test$weights))
    return(sum(weights * as.numeric(unlist(spec$population$means))))
  }
  if (spec$template %in% c("oneway_between", "oneway_within", "oneway_ancova")) {
    # Largest difference between group means: zero only if all are equal.
    means <- as.numeric(unlist(spec$population$means))
    return(max(means) - min(means))
  }
  m <- matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
  switch(
    spec$target_test$effect,
    main_effect_A = sum(m[1, ]) - sum(m[2, ]),
    main_effect_B = sum(m[, 1]) - sum(m[, 2]),
    interaction = m[1, 1] - m[1, 2] - m[2, 1] + m[2, 2]
  )
}

# Multiple regression ---------------------------------------------------------

check_multiple_regression <- function(spec) {
  pop <- spec$population
  if (spec$template != "r2_increase") {
    return(character())
  }
  problems <- character()
  if (pop$predictors_tested > pop$predictors_total) {
    problems <- c(problems, sprintf(
      "'population > predictors_tested' (%s) can't be more than 'predictors_total' (%s): the tested set is part of the full model.",
      format_number(pop$predictors_tested), format_number(pop$predictors_total)
    ))
  }
  if (pop$r2_reduced > pop$r2_full) {
    problems <- c(problems, sprintf(
      "'population > r2_reduced' (%s) can't be more than 'r2_full' (%s): adding predictors can't lower R-squared.",
      format_number(pop$r2_reduced), format_number(pop$r2_full)
    ))
  }
  if (pop$predictors_tested == pop$predictors_total && pop$r2_reduced > 0) {
    problems <- c(problems, paste0(
      "The tested set is every predictor, so the reduced model has none and ",
      "'population > r2_reduced' must be 0. To test R-squared against 0, you ",
      "can also use template 'r2_zero'."
    ))
  }
  problems
}

# Regression interaction -----------------------------------------------------

check_regression_interaction <- function(spec) {
  pop <- spec$population
  # Correlations among X, W and their product, assuming X and W are centred
  # and jointly normal (as InteractionPoweR does): XW is uncorrelated with
  # X and W.
  predictors <- matrix(
    c(1, pop$r_X_W, 0, pop$r_X_W, 1, 0, 0, 0, 1),
    nrow = 3,
    dimnames = list(c("X", "W", "XW"), c("X", "W", "XW"))
  )
  with_y <- c(pop$r_X_Y, pop$r_W_Y, pop$r_XW_Y)
  r2 <- drop(t(with_y) %*% solve(predictors, with_y))
  if (r2 < 1 - 1e-8) {
    return(character())
  }
  sprintf(
    paste0(
      "These correlations are impossible together: they imply that %s, %s ",
      "and their interaction explain %s%% of the variance in %s (R-squared = %s), ",
      "but R-squared must be below 1. Make one or more of r_X_Y, r_W_Y and ",
      "r_XW_Y smaller, or change r_X_W."
    ),
    var_label(spec, "X"), var_label(spec, "W"), format_number(round(100 * r2, 1)),
    var_label(spec, "Y"), format_number(round(r2, 3))
  )
}

# Mediation and moderated mediation -------------------------------------------

# The structure of each PROCESS template: which variable is regressed on
# which, which product terms exist, and the order in which to build them.
path_model <- function(spec) {
  roles <- names(spec$variables)
  mediators <- sort(grep("^M[1-9]?$", roles, value = TRUE))
  switch(
    spec$template,
    process_4 = list(
      exogenous = "X",
      mediators = mediators,
      products = list(),
      equations = c(
        stats::setNames(rep(list("X"), length(mediators)), mediators),
        list(Y = c("X", mediators))
      )
    ),
    process_6 = list(
      exogenous = "X",
      mediators = mediators,
      serial = TRUE,
      products = list(),
      equations = c(
        stats::setNames(
          lapply(seq_along(mediators), function(i) c("X", mediators[seq_len(i - 1)])),
          mediators
        ),
        list(Y = c("X", mediators))
      )
    ),
    process_7 = list(
      exogenous = c("X", "W"),
      mediators = "M",
      products = list(XW = c("X", "W")),
      equations = list(M = c("X", "W", "XW"), Y = c("X", "M"))
    ),
    process_14 = list(
      exogenous = c("X", "W"),
      mediators = "M",
      products = list(MW = c("M", "W")),
      equations = list(M = "X", Y = c("X", "M", "W", "MW"))
    )
  )
}

model_paths <- function(model) {
  unlist(lapply(names(model$equations), function(outcome) {
    paste0(model$equations[[outcome]], "->", outcome)
  }), use.names = FALSE)
}

check_path_model <- function(spec) {
  model <- path_model(spec)
  problems <- check_mediator_names(spec, model)
  if (length(problems) > 0) {
    return(problems)
  }
  problems <- c(
    check_path_names(spec, model),
    check_correlation_names(spec, model),
    check_target_path(spec, model)
  )
  if (length(problems) > 0) {
    return(problems)
  }
  check_implied_variances(spec, model)
}

check_mediator_names <- function(spec, model) {
  mediators <- model$mediators
  numbered <- paste0("M", seq_along(mediators))
  ok <- switch(
    spec$template,
    process_4 = identical(mediators, "M") ||
      (length(mediators) >= 2 && setequal(mediators, numbered)),
    process_6 = length(mediators) >= 2 && setequal(mediators, numbered),
    TRUE
  )
  if (ok) {
    return(character())
  }
  advice <- if (spec$template == "process_4") {
    "Name a single mediator 'M', or several mediators M1, M2, M3, ... with no gaps"
  } else {
    "Name the mediators M1, M2, ... in causal order, with no gaps"
  }
  sprintf("%s. The mediators are currently named %s.", advice, quote_list(mediators, "and"))
}

check_path_names <- function(spec, model) {
  required <- model_paths(model)
  given <- names(spec$population$paths)
  problems <- character()
  missing <- setdiff(required, given)
  if (length(missing) > 0) {
    problems <- c(problems, sprintf(
      "'population > paths' is missing %s. Give every path in the model a value (use 0 for no effect).",
      quote_list(missing, "and")
    ))
  }
  for (extra in setdiff(given, required)) {
    hint <- if (spec$template == "process_4" && grepl("^M[0-9]->M[0-9]$", extra)) {
      " Paths between mediators belong in serial mediation (template 'process_6')."
    } else {
      suggestion(extra, missing)
    }
    problems <- c(problems, sprintf(
      "'population > paths' has '%s', which is not a path in %s.%s",
      extra, template_name(spec$template), hint
    ))
  }
  problems
}

template_name <- function(template) {
  sprintf("PROCESS model %s", sub("process_", "", template, fixed = TRUE))
}

check_correlation_names <- function(spec, model) {
  field <- if (spec$design == "mediation") "residual_correlations" else "correlations"
  correlations <- spec$population[[field]]
  if (length(correlations) == 0) {
    return(character())
  }
  allowed_vars <- if (spec$design == "mediation") model$mediators else c("X", "W")
  if (spec$design == "mediation" && length(model$mediators) < 2) {
    return(sprintf(
      "'population > %s' is only used when there are two or more mediators; remove it.",
      field
    ))
  }
  problems <- character()
  pairs <- character()
  for (key in names(correlations)) {
    ends <- trimws(strsplit(key, "<->", fixed = TRUE)[[1]])
    if (length(ends) != 2 || !all(ends %in% allowed_vars) || ends[1] == ends[2]) {
      problems <- c(problems, sprintf(
        "'population > %s > %s' isn't a valid pair. Write pairs as 'A<->B' using %s.",
        field, key, quote_list(allowed_vars)
      ))
      next
    }
    pair <- paste(sort(ends), collapse = "<->")
    if (pair %in% pairs) {
      problems <- c(problems, sprintf(
        "'population > %s' gives the correlation %s twice; keep only one.",
        field, pair
      ))
    }
    pairs <- c(pairs, pair)
  }
  problems
}

indirect_paths <- function(model) {
  mediators <- model$mediators
  if (!isTRUE(model$serial)) {
    return(paste0("X->", mediators, "->Y"))
  }
  # Serial mediation: every ordered subset of the mediators is a path.
  chains <- lapply(seq_along(mediators), function(k) {
    vapply(
      utils::combn(mediators, k, simplify = FALSE),
      function(m) paste(c("X", m, "Y"), collapse = "->"),
      character(1)
    )
  })
  unlist(chains)
}

check_target_path <- function(spec, model) {
  path <- spec$target_test$path
  if (is.null(path)) {
    return(character())
  }
  normalised <- paste(trimws(strsplit(path, "->", fixed = TRUE)[[1]]), collapse = "->")
  valid <- indirect_paths(model)
  if (normalised %in% valid) {
    return(character())
  }
  sprintf(
    "'target_test > path' is '%s', which isn't an indirect path in this model. Choose one of %s.",
    path, quote_list(valid)
  )
}

# Build the model-implied covariance matrix one variable at a time, with all
# observed variables standardised. Exogenous variables are standardised and
# correlated as given; a product term of two standardised, jointly normal
# variables with correlation r has variance 1 + r^2 and is uncorrelated with
# every other variable. Each endogenous variable's explained variance is
# b' S b; its residual variance (1 - R-squared) must be positive. Stops at
# the first variable where it is not.
implied_r_squared <- function(spec, model) {
  paths <- spec$population$paths
  correlations <- correlation_lookup(spec)
  order <- c(model$exogenous, endogenous_order(model))
  s <- matrix(0, 0, 0)
  r_squared <- c()
  residual_var <- c()
  for (v in order) {
    if (v %in% model$exogenous) {
      covs <- vapply(rownames(s), function(u) correlations(u, v), numeric(1))
      s <- grow_cov(s, v, covs, 1)
    } else if (v %in% names(model$products)) {
      parts <- model$products[[v]]
      s <- grow_cov(s, v, rep(0, nrow(s)), 1 + s[parts[1], parts[2]]^2)
    } else {
      preds <- model$equations[[v]]
      b <- vapply(preds, function(p) as.numeric(paths[[paste0(p, "->", v)]]), numeric(1))
      explained <- drop(t(b) %*% s[preds, preds, drop = FALSE] %*% b)
      r_squared[v] <- explained
      if (explained >= 1 - 1e-8) {
        # Later variables would be built on an impossible covariance matrix.
        break
      }
      residual_var[v] <- 1 - explained
      covs <- drop(t(b) %*% s[preds, , drop = FALSE])
      # Correlated residuals between parallel mediators.
      for (u in intersect(names(residual_var), rownames(s))) {
        rho <- correlations(u, v, residual = TRUE)
        if (rho != 0 && residual_var[u] > 0 && residual_var[v] > 0) {
          covs[u] <- covs[u] + rho * sqrt(residual_var[u] * residual_var[v])
        }
      }
      s <- grow_cov(s, v, covs, 1)
    }
  }
  list(r_squared = r_squared, cov = s)
}

endogenous_order <- function(model) {
  products <- names(model$products)
  steps <- character()
  for (v in names(model$equations)) {
    # Add any product term as soon as both its parts exist.
    for (p in setdiff(products, steps)) {
      if (all(model$products[[p]] %in% c(model$exogenous, steps)) && p %in% model$equations[[v]]) {
        steps <- c(steps, p)
      }
    }
    steps <- c(steps, v)
  }
  steps
}

grow_cov <- function(s, name, covs, variance) {
  k <- nrow(s)
  out <- matrix(0, k + 1, k + 1, dimnames = list(c(rownames(s), name), c(rownames(s), name)))
  if (k > 0) {
    out[seq_len(k), seq_len(k)] <- s
    out[k + 1, seq_len(k)] <- covs
    out[seq_len(k), k + 1] <- covs
  }
  out[k + 1, k + 1] <- variance
  out
}

correlation_lookup <- function(spec) {
  exo <- spec$population$correlations
  resid <- spec$population$residual_correlations
  lookup <- function(values, a, b) {
    for (key in names(values)) {
      ends <- trimws(strsplit(key, "<->", fixed = TRUE)[[1]])
      if (setequal(ends, c(a, b))) {
        return(as.numeric(values[[key]]))
      }
    }
    0
  }
  function(a, b, residual = FALSE) {
    lookup(if (residual) resid else exo, a, b)
  }
}

check_implied_variances <- function(spec, model) {
  problems <- check_residual_correlation_matrix(spec, model)
  if (length(problems) > 0) {
    return(problems)
  }
  r2 <- implied_r_squared(spec, model)$r_squared
  for (v in names(r2)) {
    if (r2[[v]] >= 1 - 1e-8) {
      preds <- model$equations[[v]]
      problems <- c(problems, sprintf(
        paste0(
          "The paths into %s are impossible together: they would explain %s%% ",
          "of its variance (R-squared = %s), but R-squared must be below 1. ",
          "Make one or more of these paths smaller: %s."
        ),
        var_label(spec, v), format_number(round(100 * r2[[v]], 1)),
        format_number(round(r2[[v]], 3)), quote_list(paste0(preds, "->", v))
      ))
    }
  }
  problems
}

check_residual_correlation_matrix <- function(spec, model) {
  mediators <- model$mediators
  if (spec$design != "mediation" || length(mediators) < 3 ||
    length(spec$population$residual_correlations) == 0) {
    return(character())
  }
  lookup <- correlation_lookup(spec)
  r <- outer(mediators, mediators, Vectorize(function(a, b) {
    if (a == b) 1 else lookup(a, b, residual = TRUE)
  }))
  if (min(eigen(r, symmetric = TRUE, only.values = TRUE)$values) > 1e-8) {
    return(character())
  }
  paste0(
    "The residual correlations between the mediators are impossible together ",
    "(no population could have all of them at once). Make some of them closer to 0."
  )
}

# Goal --------------------------------------------------------------------------

check_goal <- function(spec, check_effect = TRUE) {
  goal <- spec$goal
  alpha <- spec$target_test$alpha
  problems <- character()
  if (!is.null(goal$power) && goal$power <= alpha) {
    problems <- c(problems, sprintf(
      paste0(
        "'goal > power' (%s) must be greater than alpha (%s): even with no ",
        "real effect, a test is significant alpha of the time."
      ),
      format_number(goal$power), format_number(alpha)
    ))
  }
  if (!is.null(goal$n)) {
    problems <- c(problems, check_n(spec, goal$n))
  }
  # For the basic tests, the smallest detectable effect needs no effect
  # size: pwr solves for it directly (for two proportions, a search keeps
  # group 1's proportion), so a zero effect (no effect size given) is
  # allowed and the result is positive (an increase in group 2).
  needs_effect <- goal$type == "sample_size" || !(
    identical(spec$design, "basic_test") &&
      spec$template %in% c(
        "one_sample_t", "independent_t", "paired_t", "correlation",
        "two_proportions", "chi_square_independence"
      )
  ) && !identical(spec$design, "generic_test") && !identical(spec$design, "cluster_trial")
  if (check_effect && goal$type %in% c("sample_size", "sensitivity") &&
    needs_effect && target_effect_is_zero(spec)) {
    consequence <- if (goal$type == "sample_size") {
      "no sample size can reach the target power"
    } else {
      "there is no effect pattern to scale for a sensitivity analysis"
    }
    problems <- c(problems, paste0(
      "The effect you want to detect is zero in this population, so ",
      consequence, ". Check the population values, or use goal type 'power' ",
      "to check the Type I error rate."
    ))
  }
  problems
}

check_n <- function(spec, n) {
  minimum <- minimum_n(spec)
  if (n < minimum) {
    return(sprintf(
      "'goal > n' is %s, but this design needs at least %s participants.",
      format_number(n), format_number(minimum)
    ))
  }
  groups <- group_split(spec)
  if (is.null(groups)) {
    return(character())
  }
  if (groups$valid(n)) {
    return(character())
  }
  below <- if (n > minimum) seq(max(minimum, n - 1000), n - 1) else numeric()
  nearby <- c(
    utils::tail(Filter(groups$valid, below), 1),
    utils::head(Filter(groups$valid, seq(n + 1, n + 1000)), 1)
  )
  if (length(nearby) == 0) {
    return(sprintf(
      "'options > allocation_ratio' (%s) can't split any nearby n into whole groups. Use a simple ratio such as 2 or 1.5.",
      format_number(spec$options$allocation_ratio)
    ))
  }
  sprintf(
    "'goal > n' must %s; %s doesn't. The nearest that do: %s.",
    groups$rule, format_number(n), paste(nearby, collapse = " and ")
  )
}

minimum_n <- function(spec) {
  # A whole study (experimental): the smallest n its schema allows.
  if (identical(spec$kind, "whole_study")) {
    return(20)
  }
  switch(
    spec$design,
    basic_test = switch(
      spec$template,
      one_sample_t = 3,
      paired_t = 3,
      chi_square_independence = length(unlist(spec$population$probabilities)),
      chi_square_gof = length(unlist(spec$population$probabilities)),
      # Fisher's z needs more than 3 people in each group (its SE is
      # 1 / sqrt(n - 3)).
      two_correlations = 10,
      # Steiger's z, on Fisher's z scale too, needs more than 3 people;
      # pwrss's own search for n starts at 5.
      overlapping_correlations = ,
      nonoverlapping_correlations = 5,
      # One degree of freedom for the chi-square test of one variance; two
      # people per group for the F test of two.
      one_variance = 2,
      two_variances = 4,
      4
    ),
    # TOSTER's power_t_TOST() needs two people per group (one in a
    # one-sample or paired design); powerkit asks for one more, as for the
    # t-tests.
    equivalence_test = if (identical(spec$template, "tost_independent")) 4 else 3,
    factorial_anova = switch(
      spec$template,
      "2x2_between" = 8,
      "2x2_mixed" = 4,
      # Two participants per group, so the error df is at least the number
      # of groups.
      oneway_between = ,
      oneway_contrast = 2 * length(spec$variables$A$levels),
      # Everyone is in every condition: Superpower's exact data set needs at
      # least five participants (backend-superpower.R, exact_min_n).
      oneway_within = 5,
      # Two per group, plus one error df for each covariate.
      oneway_ancova = 2 * length(spec$variables$A$levels) + spec$population$covariates
    ),
    # The intercept, every predictor, and at least one residual df.
    multiple_regression = (spec$population$predictors %||% spec$population$predictors_total) + 2,
    # pwrss's own search for n starts at 2; at least the intercept and X's
    # coefficient, plus one.
    logistic_regression = ,
    poisson_regression = 3,
    # Two groups in each condition (cluster-randomised), or two groups
    # (multisite): the fewest powertools accepts.
    cluster_trial = (if (identical(spec$template, "multisite")) 2 else 4) * spec$population$cluster_size,
    regression_interaction = 6,
    # More participants than items, so that the sample covariance matrix
    # can be positive definite; 2 when only the df are known.
    sem = if (is.null(spec$population$indicators)) 2 else spec$population$indicators + 1,
    # Enough for the largest regression in the model plus two residual df.
    max(lengths(path_model(spec)$equations)) + 3
  )
}

group_split <- function(spec) {
  whole <- function(x) abs(x - round(x)) < 1e-9
  if (spec$template == "2x2_between") {
    return(list(rule = "split into 4 equal cells for a 2x2 between-participants design", valid = function(n) n %% 4 == 0))
  }
  if (spec$template == "2x2_mixed") {
    return(list(rule = "split into 2 equal groups for the between-participants factor", valid = function(n) n %% 2 == 0))
  }
  if (spec$template %in% c("oneway_between", "oneway_ancova", "oneway_contrast")) {
    k <- length(spec$variables$A$levels)
    return(list(rule = sprintf("split into %d equal groups", k), valid = function(n) n %% k == 0))
  }
  if (spec$template == "multisite") {
    m <- spec$population$cluster_size
    return(list(
      rule = sprintf("be a whole number of groups of %s", format_number(m)),
      valid = function(n) n %% m == 0
    ))
  }
  if (spec$template == "cluster_randomised") {
    m <- spec$population$cluster_size
    return(list(
      rule = sprintf("be a whole number of groups of %s, the same number of groups in each condition", format_number(m)),
      valid = function(n) n %% (2 * m) == 0
    ))
  }
  if (spec$template %in% c("independent_t", "two_proportions", "two_correlations", "two_variances", "tost_independent")) {
    ratio <- spec$options$allocation_ratio %||% 1
    return(list(
      rule = sprintf("split into two whole groups in the ratio 1 : %s", format_number(ratio)),
      valid = function(n) whole(n / (1 + ratio)) && whole(n * ratio / (1 + ratio))
    ))
  }
  NULL
}

target_effect_is_zero <- function(spec) {
  pop <- spec$population
  paths <- pop$paths
  value <- switch(
    spec$design,
    basic_test = switch(
      spec$template,
      one_sample_t = pop$d,
      independent_t = pop$d,
      paired_t = pop$dz,
      one_proportion = pop$p - pop$p0,
      mcnemar = pop$p_second_only - pop$p_first_only,
      correlation = pop$r,
      two_proportions = pop$p1 - pop$p2,
      two_correlations = pop$r1 - pop$r2,
      overlapping_correlations = ,
      nonoverlapping_correlations = dependent_correlation_difference(spec),
      one_variance = pop$var - pop$var0,
      two_variances = pop$var1 - pop$var2,
      chi_square_gof = {
        p <- as.numeric(unlist(pop$probabilities))
        p0 <- as.numeric(unlist(pop$null_probabilities %||% rep(1 / length(p), length(p))))
        max(abs(p - p0))
      },
      chi_square_independence = {
        p <- matrix(as.numeric(unlist(pop$probabilities)), nrow = length(pop$probabilities), byrow = TRUE)
        max(abs(p - outer(rowSums(p), colSums(p))))
      }
    ),
    factorial_anova = anova_contrast(spec),
    # An equivalence test has something to show whenever the bound is above
    # 0 (the schema requires it), whatever the expected difference.
    equivalence_test = pop$bound,
    multiple_regression = if (spec$template == "r2_zero") pop$r2 else pop$r2_full - pop$r2_reduced,
    logistic_regression = log(pop$odds_ratio),
    poisson_regression = log(pop$rate_ratio),
    cluster_trial = pop$d,
    # Never 0 in practice: the schema refuses it, as semPower does.
    sem = pop$rmsea,
    regression_interaction = pop$r_XW_Y,
    mediation = {
      nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
      prod(vapply(seq_len(length(nodes) - 1), function(i) {
        as.numeric(paths[[paste0(nodes[i], "->", nodes[i + 1])]])
      }, numeric(1)))
    },
    moderated_mediation = switch(
      spec$template,
      process_7 = paths[["XW->M"]] * paths[["M->Y"]],
      process_14 = paths[["X->M"]] * paths[["MW->Y"]]
    )
  )
  isTRUE(abs(value) < 1e-12)
}
