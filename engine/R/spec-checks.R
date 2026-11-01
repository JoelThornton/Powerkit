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
    logistic_regression = function(spec) {
      if (identical(spec$template, "factorial")) check_logistic_factorial(spec) else check_single_predictor_x(spec)
    },
    ordinal_regression = check_ordinal_two_groups,
    mixed_model = function(spec) {
      switch(spec$template, two_level = character(), crossed_conditions = check_crossed_conditions(spec),
        three_level = check_three_level(spec), item_predictor = check_item_predictor(spec),
        c(check_crossed_two_condition(spec), check_crossed_outcome(spec, conditions = FALSE)))
    },
    poisson_regression = check_single_predictor_x,
    cluster_trial = check_cluster_trial,
    sem = check_sem,
    regression_interaction = check_regression_interaction,
    mediation = function(spec) c(check_path_model(spec), check_single_predictor_x(spec)),
    moderated_mediation = check_path_model,
    generic_test = function(spec) character(),
    equivalence_test = check_equivalence_test,
    meta_analysis = check_meta_analysis,
    precision = function(spec) character(),
    dyadic = check_apim
  )
  # Precision planning has no test to check, only its interval and goal.
  if (identical(spec$design, "precision")) {
    return(c(check_labels(spec), check_precision(spec)))
  }
  design_problems <- design_check(spec)
  c(
    check_labels(spec),
    check_reliability_allowed(spec),
    check_allocation_allowed(spec),
    check_cell_ratio_allowed(spec),
    check_group_ratio_allowed(spec),
    check_method_allowed(spec),
    check_score_shape_allowed(spec),
    check_welch_sds(spec),
    check_bayes_factor(spec),
    check_minimum_effect(spec),
    check_justified_alpha(spec),
    check_precision(spec),
    check_proportions_formula_allowed(spec),
    check_direction_allowed(spec),
    check_weights_allowed(spec),
    check_pairwise(spec),
    check_friedman(spec),
    check_jonckheere(spec),
    check_within_covariance(spec),
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
  bayes_factor_test(spec) || minimum_effect_test(spec) || !rank_test(spec) && !welch_anova(spec) && !rank_correlation(spec) && !unequal_cells(spec) &&
    !pairwise_comparison(spec) &&
    !identical(spec$template, "paired_variances") && !proportion_trend(spec) && !(identical(spec$template, "manova") && !manova_two_groups(spec)) && (
    spec$design %in% c("factorial_anova", "multiple_regression", "generic_test", "equivalence_test") ||
      pwr_covers(spec) ||
      formula_test(spec) ||
      pwrss_only(spec) ||
      identical(spec$target_test$method, "welch_t")
  )
}

# A 2 x 2 between-participants ANOVA with unequal cells (options >
# cell_ratio): Superpower's ANOVA_exact() takes equal cells only, so these
# are simulated with ANOVA_power() (docs/conventions.md, "Superpower and
# unequal group sizes").
unequal_cells <- function(spec) {
  !is.null(spec$options$cell_ratio)
}

# The relative cell sizes in Superpower's order (a1_b1, a1_b2, a2_b1,
# a2_b2): the spec's rows read in turn.
cell_ratio_vector <- function(spec) {
  as.numeric(unlist(spec$options$cell_ratio))
}

check_cell_ratio_allowed <- function(spec) {
  if (!unequal_cells(spec)) {
    return(character())
  }
  if (!identical(spec$template, "2x2_between")) {
    return(paste0(
      "'options > cell_ratio' only applies to the 2 x 2 between-participants ",
      "ANOVA (template 2x2_between): Superpower can simulate unequal groups ",
      "only when every factor is between participants. Remove it."
    ))
  }
  if (identical(spec$goal$type, "sensitivity")) {
    return(paste0(
      "The smallest detectable effect isn't available with unequal cells: it ",
      "uses Superpower's exact method, which takes equal cells only. Use goal ",
      "type 'power' or 'sample_size'."
    ))
  }
  if (identical(spec$options$method, "exact")) {
    return(paste0(
      "'options > method' 'exact' isn't available with unequal cells: ",
      "Superpower's exact method takes equal cells only, so power is ",
      "simulated. Remove 'options > method'."
    ))
  }
  character()
}

# Tests with no simulation in powerkit yet: they are computed by formula
# only (pwrss).
simulation_available <- function(spec) {
  !(spec$design %in% c("multiple_regression", "generic_test", "equivalence_test") || pwrss_only(spec) || bayes_factor_test(spec) ||
    minimum_effect_test(spec))
}

# Basic tests powerkit computes by simulation only: no formula covers
# them (the Pitman-Morgan test, and MANOVA with three or more groups or
# two factors). The variance tests of one or two groups and Hotelling's
# T-squared (one group, or a MANOVA of two groups) have their own formula
# (backend-variance.R, backend-hotelling.R). The rank
# tests are simulated with Spower too (backend-spower.R).
spower_only <- function(spec) {
  identical(spec$template, "paired_variances") || identical(spec$template, "manova") && !manova_two_groups(spec) || rank_test(spec) || welch_anova(spec) ||
    rank_correlation(spec) || proportion_trend(spec)
}

# Rank-based tests: the Wilcoxon signed-rank test (one sample, paired), the
# Mann-Whitney test (two groups), the Kruskal-Wallis test (three or more
# groups), simulated with Spower's p_wilcox.test() and p_kruskal.test(),
# and the Jonckheere-Terpstra test (groups in order) and Friedman's test,
# simulated by powerkit's own experiments with Spower.
rank_test <- function(spec) {
  isTRUE(spec$target_test$method %in% c("wilcoxon_signed_rank", "mann_whitney", "kruskal_wallis", "friedman", "jonckheere_terpstra"))
}

# The Jonckheere-Terpstra test of a trend across groups in order (PMCMRplus's
# jonckheereTest()), on the one-way between-participants template.
jonckheere_test <- function(spec) identical(spec$target_test$method, "jonckheere_terpstra")

# The Cochran-Armitage test of a trend in proportions (stats::prop.trend.test()).
proportion_trend <- function(spec) identical(spec$template, "proportion_trend")

# Welch's one-way ANOVA (unequal variances), simulated with Spower's
# p_anova.test(var.equal = FALSE): no package powerkit uses has a formula.
welch_anova <- function(spec) identical(spec$target_test$method, "welch_f")

# Pairwise comparisons after a one-way ANOVA (target_test > effect
# "pairwise"): the t-test of one pair of levels, its p-value adjusted for
# all the pairwise comparisons, simulated with Superpower's ANOVA_power()
# (p_adjust), which adjusts across the pairwise t-tests only.
pairwise_comparison <- function(spec) identical(spec$target_test$effect, "pairwise")

# The chosen pair's positions among A's levels, in level order.
pairwise_levels <- function(spec) {
  sort(match(unlist(spec$target_test$comparison), unlist(spec$variables$A$levels)))
}

check_pairwise <- function(spec) {
  tt <- spec$target_test
  if (!pairwise_comparison(spec)) {
    problems <- character()
    if (!is.null(tt$comparison) || !is.null(tt$p_adjust)) {
      problems <- c(problems, paste0(
        "'target_test > comparison' and 'target_test > p_adjust' only apply to pairwise comparisons ",
        "('target_test > effect' \"pairwise\"); remove them."))
    }
    if (identical(tt$method, "t_test") && identical(spec$design, "factorial_anova")) {
      problems <- c(problems, "'target_test > method' \"t_test\" is for pairwise comparisons: set 'target_test > effect' to \"pairwise\".")
    }
    return(problems)
  }
  if (identical(spec$template, "crossed_conditions")) {
    # Checked with the design (check_crossed_conditions()).
    return(character())
  }
  if (!spec$template %in% c("oneway_between", "oneway_within")) {
    return("Pairwise comparisons are available after a one-way ANOVA (between or within participants) only, so far.")
  }
  problems <- character()
  if (!identical(tt$method, "t_test")) {
    problems <- c(problems, "Pairwise comparisons are t-tests: set 'target_test > method' to \"t_test\".")
  }
  # Partial eta-squared: check_eta_squared_anova() says the means are needed.
  levels <- unlist(spec$variables$A$levels)
  pair <- unlist(tt$comparison)
  if (length(pair) != 2 || length(unique(pair)) != 2) {
    problems <- c(problems, "'target_test > comparison' should name two different levels of A, the pair whose difference is tested.")
  } else if (!all(pair %in% levels)) {
    problems <- c(problems, sprintf(
      "'target_test > comparison' names %s, which %s not among A's levels (%s).",
      paste(sprintf("'%s'", setdiff(pair, levels)), collapse = " and "),
      if (length(setdiff(pair, levels)) == 1) "is" else "are", paste(levels, collapse = ", ")))
  }
  problems
}

# Friedman's test (one-way repeated measures, rank-based): the scores are
# each person's own level plus a deviation (friedman_scores()), so the
# correlation between conditions is the share of the variance that is the
# person's and must be at least 0 and below 1; the effect is given by the
# condition means.
check_friedman <- function(spec) {
  if (!identical(spec$target_test$method, "friedman")) {
    return(character())
  }
  problems <- character()
  if (!identical(spec$template, "oneway_within")) {
    problems <- c(problems, "Friedman's test is for one factor with every participant in every condition (template 'oneway_within').")
  }
  # Partial eta-squared: check_eta_squared_anova() says the means are needed.
  r <- spec$population$r
  if (is.numeric(r) && length(r) == 1 && (r < 0 || r >= 1)) {
    problems <- c(problems, paste0(
      "For Friedman's test, the correlation between conditions ('population > r') must be at least 0 and below 1: ",
      "powerkit draws each score as the person's own level plus a deviation, so the correlation is the share of ",
      "the variance that is the person's."))
  }
  problems
}

# One-way repeated measures with an SD per condition or a correlation per
# pair: one value per condition (k) and per pair (k(k - 1) / 2), a
# correlation matrix that is possible (positive definite), and the means
# themselves (partial eta-squared has no SDs). The sphericity correction
# belongs to this template alone.
check_within_covariance <- function(spec) {
  pop <- spec$population
  correction <- spec$target_test$correction
  problems <- character()
  if (spec$template %in% c("mixed", "factorial_within", "2x2_mixed")) {
    return(check_factorial_covariance(spec))
  }
  if (!identical(spec$template, "oneway_within")) {
    if (!is.null(correction)) {
      problems <- c(problems, paste0(
        "'target_test > correction' only applies to repeated-measures ANOVAs with a within-participants factor of ",
        "three or more levels (templates 'oneway_within', 'mixed' and 'factorial_within'); remove it."))
    }
    return(problems)
  }
  sds <- as.numeric(unlist(pop$sd))
  rs <- as.numeric(unlist(pop$r))
  k <- length(spec$variables$A$levels)
  several <- length(sds) > 1 || length(rs) > 1
  if (several && identical(pop$metric, "eta_squared")) {
    return("An SD per condition or a correlation per pair needs the condition means ('population > means'), not partial eta-squared.")
  }
  if (!is.null(correction) && !identical(correction, "none") && identical(pop$metric, "eta_squared")) {
    return(paste0("A sphericity correction ('target_test > correction') needs the condition means, SDs and correlations: ",
      "from partial eta-squared powerkit assumes sphericity (pwrss's epsilon = 1)."))
  }
  if (several && !spec$target_test$method %in% c("anova_f", "t_test")) {
    problems <- c(problems, "An SD per condition or a correlation per pair is available for the F test and pairwise comparisons; Friedman's test takes one of each.")
  }
  if (length(sds) > 1 && length(sds) != k) {
    problems <- c(problems, sprintf("'population > sd' should have one SD per condition (%d); it has %d.", k, length(sds)))
  }
  if (length(rs) > 1 && length(rs) != k * (k - 1) / 2) {
    problems <- c(problems, sprintf(
      "'population > r' should have one correlation per pair of conditions (%d, in the order (1, 2), (1, 3), ..., (2, 3), ...); it has %d.",
      k * (k - 1) / 2, length(rs)))
  } else if (length(rs) > 1) {
    correlation <- diag(k)
    correlation[upper.tri(correlation)] <- rs
    correlation[lower.tri(correlation)] <- t(correlation)[lower.tri(correlation)]
    if (min(eigen(correlation, symmetric = TRUE, only.values = TRUE)$values) <= 0) {
      problems <- c(problems, "These correlations can't all hold at once (the correlation matrix they make isn't possible): check them, for example pairs that are much higher or lower than the rest.")
    }
  } else if (length(rs) == 1 && k > 1 && rs <= -1 / (k - 1)) {
    problems <- c(problems, sprintf("With %d conditions, one correlation for every pair must be above %s.", k, format_number(round(-1 / (k - 1), 3))))
  }
  problems
}

# Two-factor designs with repeated measures: an SD per cell (one row per
# level of A, one SD per level of B, like the means), and a correlation per
# pair of B's levels (mixed, the same in every group), per group (2 x 2
# mixed, one pair) or per pair of cells (within). Each correlation matrix
# must be possible, the means must be given (partial eta-squared has no
# SDs), and a sphericity correction needs a within factor that can break
# sphericity (three or more levels).
check_factorial_covariance <- function(spec) {
  pop <- spec$population
  k <- length(spec$variables$A$levels)
  m <- length(spec$variables$B$levels)
  sds <- as.numeric(unlist(pop$sd))
  rs <- as.numeric(unlist(pop$r))
  correction <- spec$target_test$correction
  several <- length(sds) > 1 || length(rs) > 1
  if (several && identical(pop$metric, "eta_squared")) {
    return("An SD per cell or more than one correlation needs the cell means ('population > means'), not partial eta-squared.")
  }
  problems <- character()
  if (!is.null(correction) && !identical(correction, "none")) {
    if (identical(spec$template, "2x2_mixed")) {
      problems <- c(problems, "With two repeated measurements sphericity can't fail, so the 2 x 2 mixed ANOVA has no sphericity correction: remove 'target_test > correction'.")
    } else if (identical(pop$metric, "eta_squared")) {
      problems <- c(problems, paste0("A sphericity correction ('target_test > correction') needs the cell means, SDs and correlations: ",
        "from partial eta-squared powerkit assumes sphericity (pwrss's epsilon = 1)."))
    }
  }
  if (length(sds) > 1 && (!is.list(pop$sd) || length(pop$sd) != k || any(lengths(pop$sd) != m))) {
    problems <- c(problems, sprintf(
      "'population > sd' should have one SD per cell, as %d rows (levels of A) of %d SDs (levels of B), like the means.", k, m))
  }
  matrix_possible <- function(size, values) {
    r <- diag(size)
    r[upper.tri(r)] <- values
    r[lower.tri(r)] <- t(r)[lower.tri(r)]
    min(eigen(r, symmetric = TRUE, only.values = TRUE)$values) > 0
  }
  impossible <- "These correlations can't all hold at once (the correlation matrix they make isn't possible): check them, for example pairs that are much higher or lower than the rest."
  if (length(rs) > 1) {
    expected <- switch(spec$template, "2x2_mixed" = k, mixed = m * (m - 1) / 2, factorial_within = k * m * (k * m - 1) / 2)
    what <- switch(spec$template,
      "2x2_mixed" = "one correlation per group (levels of A, in order)",
      mixed = "one correlation per pair of B's levels, in the order (1, 2), (1, 3), ..., (2, 3), ..., the same in every group",
      factorial_within = "one correlation per pair of cells, the cells in the order A1 B1, A1 B2, ..., A2 B1, ... and the pairs in the order (1, 2), (1, 3), ..., (2, 3), ...")
    if (length(rs) != expected) {
      problems <- c(problems, sprintf("'population > r' should have %s: %d in all; it has %d.", what, expected, length(rs)))
    } else if (identical(spec$template, "mixed") && !matrix_possible(m, rs)) {
      problems <- c(problems, impossible)
    } else if (identical(spec$template, "factorial_within") && !matrix_possible(k * m, rs)) {
      problems <- c(problems, impossible)
    }
  } else if (length(rs) == 1 && identical(spec$template, "mixed")) {
    # (The within design's single correlation is checked with its shape.)
    size <- m
    if (size > 2 && rs <= -1 / (size - 1)) {
      problems <- c(problems, sprintf("With %d measurements per participant, one correlation for every pair must be above %s.",
        size, format_number(round(-1 / (size - 1), 3))))
    }
  }
  problems
}

# Spearman's rho and Kendall's tau, simulated with Spower's p_r(method =).
rank_correlation <- function(spec) isTRUE(spec$target_test$method %in% c("spearman", "kendall"))

# Bayes factor t-tests (bfpwr, backend-bfpwr.R): bfpwr takes equal groups
# only, and the uncertainty about the effect is an input to them alone.
check_bayes_factor <- function(spec) {
  if (!bayes_factor_test(spec)) {
    if (!is.null(spec$population$effect_sd)) {
      return(paste0(
        "'population > effect_sd' is only used by the Bayes factor t-tests; ",
        "remove it, or set 'target_test > method' to 'bayes_factor'."
      ))
    }
    if (!is.null(spec$population$p_sd)) {
      return(paste0(
        "'population > p_sd' is only used by the Bayes factor test of one proportion; ",
        "remove it, or set 'target_test > method' to 'bayes_factor'."
      ))
    }
    return(character())
  }
  if (bfbin_test(spec)) {
    return(check_bayes_binomial(spec))
  }
  if (!is.null(spec$target_test$prior_a) || !is.null(spec$target_test$prior_b) || !is.null(spec$target_test$one_sided_null)) {
    return(paste0(
      "'target_test > prior_a', 'prior_b' and 'one_sided_null' belong to the Bayes factor test of one proportion; ",
      "a Bayes factor t-test has a Cauchy prior, set by 'prior_scale'."))
  }
  ratio <- spec$options$allocation_ratio %||% 1
  if (!isTRUE(all.equal(ratio, 1))) {
    return(paste0(
      "The Bayes factor t-test for two groups is calculated for equal groups ",
      "only (bfpwr takes one group size), so 'options > allocation_ratio' ",
      "must be 1."
    ))
  }
  character()
}

# The binomial Bayes factor: a design prior SD the beta distribution can
# have, and the choice of null only for a one-sided test.
check_bayes_binomial <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  problems <- character()
  if (!is.null(tt$prior_scale) || !is.null(pop$effect_sd)) {
    problems <- c(problems, paste0(
      "The Bayes factor test of one proportion has a beta analysis prior ('target_test > prior_a' and 'prior_b') ",
      "and its uncertainty as 'population > p_sd'; 'prior_scale' and 'effect_sd' belong to the Bayes factor t-tests."))
  }
  p_sd <- pop$p_sd %||% 0
  if (is.numeric(pop$p) && is.numeric(p_sd) && p_sd > 0 && p_sd^2 >= pop$p * (1 - pop$p)) {
    problems <- c(problems, sprintf(paste0(
      "'population > p_sd' (%s) is too large for a proportion of %s: a beta distribution with that mean ",
      "has an SD below %s. Give a smaller uncertainty."), format(p_sd), format(pop$p), format(signif(sqrt(pop$p * (1 - pop$p)), 3))))
  }
  if (!is.null(tt$one_sided_null) && identical(tt$alternative %||% "two_sided", "two_sided")) {
    problems <- c(problems, "'target_test > one_sided_null' applies to a one-sided test only; remove it, or set 'target_test > alternative'.")
  }
  problems
}

# Each group's SD is an input to Welch's F only, and needs one per group.
check_welch_sds <- function(spec) {
  sds <- spec$population$sds
  if (welch_anova(spec) && identical(spec$population$metric, "standardised")) {
    return(paste0(
      "Welch's F is for groups whose SDs differ, so there is no single SD to put the means ",
      "in units of: give the means and each group's SD in the outcome's own units (metric 'raw')."
    ))
  }
  # MANOVA's sds are one per outcome (check_manova()).
  if (is.null(sds) || spec$template %in% c("manova", "hotelling_one")) {
    return(character())
  }
  if (!welch_anova(spec)) {
    return(paste0(
      "'population > sds' (an SD for each group) is only used by Welch's F ",
      "('target_test > method' 'welch_f'); the F test assumes the same SD in every group. ",
      "Remove it, or choose Welch's F."
    ))
  }
  k <- length(spec$variables$A$levels)
  if (length(sds) != k) {
    return(sprintf("'population > sds' has %d SDs, but there are %d groups: give one SD for each group, in the same order.", length(sds), k))
  }
  character()
}

# The shape of the scores is only an input to the rank tests: the t-tests
# and ANOVA powerkit computes assume normal scores.
check_score_shape_allowed <- function(spec) {
  if (is.null(spec$population$score_shape) || rank_test(spec) || rank_correlation(spec)) {
    return(character())
  }
  paste0(
    "'population > score_shape' is only used by the rank tests (Wilcoxon, ",
    "Mann-Whitney, Kruskal-Wallis, Jonckheere-Terpstra, Friedman) and the rank correlations (Spearman, ",
    "Kendall); the t-tests, ANOVA and Pearson's r assume normal scores. Remove it, ",
    "or choose a rank test in 'target_test > method'."
  )
}

# Tests powerkit computes with pwrss's formulas only (and clustered
# designs, with powertools' formulas only).
pwrss_only <- function(spec) {
  (spec$design %in% c("logistic_regression", "poisson_regression", "cluster_trial", "sem", "ordinal_regression") &&
    !identical(spec$template, "factorial")) ||
    spec$template %in% c("one_proportion", "mcnemar", "chi_square_gof", "two_correlations",
                         "oneway_ancova", "factorial_ancova", "oneway_contrast") ||
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
  if (identical(spec$template, "two_variances") && identical(spec$options$method, "simulation")) {
    return(paste0(
      "'options > allocation_ratio' isn't available for the simulated ",
      "two-variance test: the simulation can only draw groups of the same ",
      "size. Remove it, or use the formula (remove 'options > method')."
    ))
  }
  if (spec$template %in% c("independent_t", "two_proportions", "two_correlations", "two_variances", "tost_independent", "invariance",
                           "noninf_independent", "noninf_two_proportions", "ordinal_two_groups")) {
    return(character())
  }
  paste0(
    "'options > allocation_ratio' only applies to two-group designs ",
    "(independent t-test, two proportions, two correlations, equivalence of ",
    "two groups, measurement invariance); remove it."
  )
}

check_method_allowed <- function(spec) {
  if (identical(spec$options$method, "simulation") && !simulation_available(spec)) {
    return(paste0(
      "'options > method' 'simulation' isn't available for this test yet; ",
      "its power is calculated by formula. Remove 'options > method'."
    ))
  }
  # Unequal cells: check_cell_ratio_allowed() explains.
  if (!identical(spec$options$method, "exact") || exact_available(spec) || unequal_cells(spec)) {
    return(character())
  }
  if (pairwise_comparison(spec)) {
    return(paste0(
      "'options > method' 'exact' isn't available for pairwise comparisons: Superpower adjusts ",
      "the p-values for the number of comparisons only in its simulation (ANOVA_power()). ",
      "Remove 'options > method'."
    ))
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
                 "cluster_randomised", "multisite", "group_treatment", "t", "z")
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
    multisite = ,
    group_treatment = if (identical(pop$metric, "proportion")) pop$p2 - pop$p1 else pop$d,
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

# Participants and items in two conditions (mixed_model) ------------------------

# Items between conditions are split in half, so their number must be
# even; a by-item condition slope exists only when every item is in both
# conditions.
check_crossed_two_condition <- function(spec) {
  pop <- spec$population
  within <- identical(pop$item_design %||% "between", "within")
  problems <- character()
  if (!within && pop$items %% 2 == 1) {
    problems <- c(problems, sprintf(
      "'population > items' is %s, but with each item in one condition half the items go in each, so the number must be even.",
      format_number(pop$items)
    ))
  }
  if (!within && !is.null(pop$sd_item_slope)) {
    problems <- c(problems, paste0(
      "'population > sd_item_slope' only applies when every item appears in both conditions ",
      "('population > item_design' \"within\"); remove it, or set item_design to \"within\"."
    ))
  }
  # Conditions between participants: each participant is in one condition,
  # so there is no participant condition slope (nor its correlation).
  if (identical(spec$variables$X$type, "between_factor")) {
    for (key in c("sd_participant_slope", "r_participant")) {
      if (!is.null(pop[[key]])) {
        problems <- c(problems, sprintf(paste0(
          "'population > %s' only applies when every participant takes part in both conditions; ",
          "with the conditions between participants each has one condition, so remove it."), key))
      }
    }
  } else if (is.null(pop$sd_participant_slope)) {
    problems <- c(problems, paste0(
      "Give 'population > sd_participant_slope', how much the difference between conditions varies across participants ",
      "(0 if it doesn't), or make X a between factor if each participant is in one condition."))
  }
  problems
}

# A predictor measured on each item (E67): a score outcome takes a
# residual SD and Satterthwaite's test; a yes/no outcome a probability and
# glmer's tests.
check_item_predictor <- function(spec) {
  pop <- spec$population
  binary <- identical(spec$variables$Y$type, "binary")
  problems <- character()
  if (binary) {
    if (!identical(pop$metric, "probability") || is.null(pop$probability)) {
      problems <- c(problems, "With a yes/no outcome, set 'population > metric' to \"probability\" and give 'population > probability', the chance of 'yes' at the items' average X.")
    }
    if (!is.null(pop$sd_residual)) problems <- c(problems, "A yes/no outcome has no residual SD: remove 'population > sd_residual'.")
    allowed <- c("wald", "likelihood_ratio")
  } else {
    if (is.null(pop$sd_residual)) problems <- c(problems, "Give 'population > sd_residual'.")
    if (!is.null(pop$probability)) problems <- c(problems, "'population > probability' is for a yes/no outcome; remove it.")
    allowed <- "satterthwaite_t"
  }
  if (!spec$target_test$method %in% allowed) {
    problems <- c(problems, sprintf("'target_test > method' should be %s for this outcome.", paste(sprintf("\"%s\"", allowed), collapse = " or ")))
  }
  problems
}

# Three levels (E68): the shares of variance leave some within groups;
# half of what is assigned goes in each condition, so that number is even;
# an effect can vary only across the levels above the one assigned.
check_three_level <- function(spec) {
  pop <- spec$population
  problems <- character()
  if (pop$icc_site + pop$icc_group >= 1) {
    problems <- c(problems, sprintf("'population > icc_site' and 'icc_group' add up to %s, but together they must be below 1: some of the variance lies between people in the same group.",
      format_number(pop$icc_site + pop$icc_group)))
  }
  if (identical(pop$assignment, "group") && pop$groups_per_site %% 2 == 1) {
    problems <- c(problems, sprintf("With groups assigned within each site, half of each site's groups go in each condition, so 'population > groups_per_site' (%s) must be even.", format_number(pop$groups_per_site)))
  }
  if (identical(pop$assignment, "person") && pop$group_size %% 2 == 1) {
    problems <- c(problems, sprintf("With people assigned within each group, half of each group goes in each condition, so 'population > group_size' (%s) must be even.", format_number(pop$group_size)))
  }
  if (identical(pop$assignment, "site") && !is.null(pop$icc_effect_site)) {
    problems <- c(problems, "'population > icc_effect_site' is how much the effect varies between sites, which needs both conditions in every site: remove it when whole sites are assigned.")
  }
  if (!identical(pop$assignment, "person") && !is.null(pop$icc_effect_group)) {
    problems <- c(problems, "'population > icc_effect_group' is how much the effect varies between groups, which needs both conditions in every group: remove it unless people are assigned within groups.")
  }
  problems
}

# The outcome of the participants-and-items designs (E33, E63): a score,
# with means or a difference in its units, a residual SD and Satterthwaite's
# tests; or yes/no, with probabilities, no residual SD and glmer's tests.
check_crossed_outcome <- function(spec, conditions) {
  pop <- spec$population
  tt <- spec$target_test
  binary <- identical(spec$variables$Y$type, "binary")
  pairwise <- identical(tt$effect, "pairwise")
  k <- length(spec$variables$X$levels)
  problems <- character()
  score_values <- if (conditions) "means" else "difference"
  if (binary) {
    if (!identical(pop$metric, "probability")) {
      problems <- c(problems, "With a yes/no outcome, set 'population > metric' to \"probability\" and give the chance of 'yes' in each condition ('population > probabilities').")
    }
    if (length(unlist(pop$probabilities)) != k) {
      problems <- c(problems, sprintf("Give 'population > probabilities', the chance of 'yes' in each of the %d conditions for a typical participant and item.", k))
    }
    for (key in c(score_values, "sd_residual")) {
      if (!is.null(pop[[key]])) {
        problems <- c(problems, sprintf("'population > %s' is for a score outcome; with a yes/no outcome the conditions are given as probabilities and there is no residual SD, so remove it.", key))
      }
    }
    allowed <- c("wald", "likelihood_ratio")
  } else {
    if (!identical(pop$metric %||% "raw", "raw") || !is.null(pop$probabilities)) {
      problems <- c(problems, "'population > probabilities' and the metric \"probability\" are for a yes/no outcome; with a score, give the outcome's means and residual SD.")
    }
    for (key in c(score_values, "sd_residual")) {
      if (is.null(pop[[key]])) problems <- c(problems, sprintf("Give 'population > %s'.", key))
    }
    allowed <- if (pairwise || !conditions) "satterthwaite_t" else "satterthwaite_f"
  }
  if (!tt$method %in% allowed) {
    problems <- c(problems, sprintf("'target_test > method' should be %s for this outcome and test.",
      paste(sprintf("\"%s\"", allowed), collapse = " or ")))
  }
  problems
}

# Participants and items in three or more conditions (E63): a mean per
# condition, items split equally between the conditions (or every item in
# every condition, the only design with an item-by-condition SD), and for
# a pairwise comparison two of X's levels and the t test.
check_crossed_conditions <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  within <- identical(pop$item_design %||% "between", "within")
  problems <- character()
  if (!identical(spec$variables$Y$type, "binary") && length(unlist(pop$means)) != k) {
    problems <- c(problems, sprintf("'population > means' has %d values, but X has %d conditions: give one mean per condition, in the order of its levels.",
      length(unlist(pop$means)), k))
  }
  if (!within && pop$items %% k != 0) {
    problems <- c(problems, sprintf(
      "'population > items' is %s, but with each item in one condition the items are split equally between the %d conditions, so the number must be a multiple of %d.",
      format_number(pop$items), k, k))
  }
  if (!within && !is.null(pop$sd_item_condition)) {
    problems <- c(problems, paste0(
      "'population > sd_item_condition' only applies when every item appears in every condition ",
      "('population > item_design' \"within\"); remove it, or set item_design to \"within\"."))
  }
  if (identical(spec$variables$X$type, "between_factor")) {
    if (!is.null(pop$sd_participant_condition)) {
      problems <- c(problems, paste0("'population > sd_participant_condition' only applies when every participant takes part in every condition; ",
        "with the conditions between participants each has one condition, so remove it."))
    }
  } else if (is.null(pop$sd_participant_condition)) {
    problems <- c(problems, paste0("Give 'population > sd_participant_condition', how much participants' condition effects vary ",
      "(0 if they don't), or make X a between factor if each participant is in one condition."))
  }
  pairwise <- identical(tt$effect, "pairwise")
  problems <- c(problems, check_crossed_outcome(spec, conditions = TRUE))
  if (!pairwise && (!is.null(tt$comparison) || !is.null(tt$p_adjust))) {
    problems <- c(problems, paste0("'target_test > comparison' and 'target_test > p_adjust' only apply to a pairwise comparison ",
      "('target_test > effect' \"pairwise\"); remove them."))
  }
  if (pairwise) {
    pair <- unlist(tt$comparison)
    if (length(pair) != 2 || length(unique(pair)) != 2 || !all(pair %in% levels)) {
      problems <- c(problems, sprintf("'target_test > comparison' should name two different conditions of X (%s), the pair whose difference is tested.",
        paste(levels, collapse = ", ")))
    }
  }
  problems
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
  if (startsWith(spec$template, "noninf_")) {
    return(check_noninferiority(spec))
  }
  effect <- switch(
    spec$template,
    tost_paired = pop$dz,
    tost_correlation = pop$r,
    tost_two_proportions = if (!is.null(pop$p1) && !is.null(pop$p2)) pop$p2 - pop$p1,
    pop$d
  )
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

# Non-inferiority: the expected effect has to be better than the margin
# (beyond it, the new condition is expected to be worse than allowed, and
# no study would show non-inferiority; pwrss would also test the wrong
# side). At the margin itself, power is about alpha.
check_noninferiority <- function(spec) {
  effect <- noninf_effect(spec)
  margin <- spec$population$margin
  if (is.null(effect) || length(effect) == 0 || is.null(margin)) {
    return(character())
  }
  beyond <- effect < -margin - 1e-12
  at <- effect <= -margin + 1e-12
  if (!beyond && !at) {
    return(character())
  }
  paste0(
    "The difference you expect is ", if (beyond) "worse than" else "exactly at",
    " the non-inferiority margin, so the study ", if (beyond) "couldn't" else "would be unlikely to",
    " show non-inferiority however many people took part. The expected difference has to be ",
    "better than minus the margin (0, no difference, is common); check its direction and ",
    "whether higher or lower values are better ('population > better')."
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
  # Yes/no outcome: multisite.bin() has no adjustment for groups of
  # different sizes, and crt.parallel.bin()'s (re.clustsize.bin()) is an
  # open question upstream (docs/upstream-questions.md), so groups of equal
  # size only.
  if (identical(pop$metric, "proportion")) {
    return(paste0(
      "For a yes/no outcome, powerkit plans for groups of the same size only: ",
      "remove 'population > cluster_size_sd' or set it to 0, and give the average group size."
    ))
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
  if (identical(spec$template, "invariance")) {
    return(check_sem_invariance(spec))
  }
  if (identical(spec$template, "latent_regression")) {
    return(check_sem_latent_regression(spec))
  }
  if (identical(spec$template, "factor_correlation")) {
    return(character())
  }
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

# Invariance: the values that set the difference belong to the level
# tested, and at least one item must stay invariant (if every item
# differed alike, the difference would be one in the factor itself).
check_sem_invariance <- function(spec) {
  pop <- spec$population
  metric <- identical(pop$level, "metric")
  over_time <- identical(pop$over, "occasions")
  if (over_time && is.null(pop$stability)) {
    return(paste0(
      "Invariance over two occasions needs the factor's correlation between them ",
      "('population > stability'): how stable people's standing is from one occasion to the next."
    ))
  }
  if (!over_time && !is.null(pop$stability)) {
    return("'population > stability' is only used for invariance over occasions ('population > over' 'occasions'); remove it.")
  }
  if (over_time && !is.null(spec$options$allocation_ratio)) {
    return("Invariance over occasions measures the same people twice, so there are no groups to split: remove 'options > allocation_ratio'.")
  }
  if (metric && (is.null(pop$loading_group2) || !is.null(pop$intercept_difference))) {
    return(paste0(
      "Metric invariance is about loadings: give the loading of the items that differ in ",
      "the second group ('population > loading_group2'), and no 'intercept_difference'."
    ))
  }
  if (!metric && (is.null(pop$intercept_difference) || !is.null(pop$loading_group2))) {
    return(paste0(
      "Scalar invariance is about intercepts: give how far the intercepts of the items that ",
      "differ are shifted in the second group ('population > intercept_difference'), and no 'loading_group2'."
    ))
  }
  if (pop$noninvariant >= pop$indicators) {
    return(sprintf(
      paste0(
        "%s of %s items differ between the groups. At least one item must be the same in both ",
        "groups: if every item differed alike, the difference would be one in the factor itself, ",
        "which invariance testing can't tell apart."
      ),
      format_number(pop$noninvariant), format_number(pop$indicators)
    ))
  }
  character()
}

# Latent regression: the slope tested exists, and the slopes and the
# predictors' correlation describe a possible population (the explained
# variance of the outcome below 1, the correlations a valid matrix).
check_sem_latent_regression <- function(spec) {
  pop <- spec$population
  slopes <- unlist(pop$slopes)
  k <- length(slopes)
  tested <- pop$tested %||% 1L
  if (tested > k) {
    return(sprintf(
      "'population > tested' is %s, but there %s only %s slope%s.",
      format_number(tested), if (k == 1) "is" else "are", format_number(k), if (k == 1) "" else "s"
    ))
  }
  r <- pop$predictor_correlation %||% 0
  if (k > 1) {
    rxx <- sem_predictor_correlations(k, r)
    if (min(eigen(rxx, symmetric = TRUE, only.values = TRUE)$values) <= 0) {
      return(sprintf(
        "%s predictors can't all correlate %s with each other: below %s, the correlations contradict each other.",
        format_number(k), format_number(r), format_number(round(-1 / (k - 1), 3))
      ))
    }
  } else {
    rxx <- matrix(1)
  }
  r2 <- as.numeric(t(slopes) %*% rxx %*% slopes)
  if (r2 >= 1) {
    return(sprintf(
      paste0(
        "These slopes and correlations would explain %s%% of the outcome's variance, which is ",
        "impossible. Lower the slopes, or the correlation between the predictors if they share ",
        "the same direction."
      ),
      format_number(round(100 * r2))
    ))
  }
  character()
}

# Basic tests ----------------------------------------------------------------

# A chi-square test given by Cohen's w: worked out by formula, as in
# G*Power; a simulation needs the proportions to draw from.
check_chisq_w <- function(spec) {
  if (identical(spec$options$method, "simulation")) {
    return("With Cohen's w, power is worked out by formula; a simulation needs the proportions ('population > metric' \"proportion\").")
  }
  character()
}

check_basic_test <- function(spec) {
  switch(
    spec$template,
    chi_square_independence = if (chisq_by_w(spec)) check_chisq_w(spec) else check_probability_table(spec),
    chi_square_gof = if (chisq_by_w(spec)) check_chisq_w(spec) else check_gof_probabilities(spec),
    mcnemar = check_discordant_proportions(spec),
    manova = check_manova(spec),
    hotelling_one = check_hotelling_one(spec),
    overlapping_correlations = ,
    nonoverlapping_correlations = check_dependent_correlations(spec),
    proportion_trend = check_proportion_trend(spec),
    character()
  )
}

# The Cochran-Armitage test: one proportion and (if given) one score per
# group, in the order of the groups; the scores must not all be the same,
# or there is no trend to test.
check_proportion_trend <- function(spec) {
  k <- length(spec$variables$X$levels)
  pop <- spec$population
  problems <- character()
  if (length(pop$proportions) != k) {
    problems <- c(problems, sprintf(
      "'population > proportions' should have one proportion per group: X has %d levels, and %d proportions were given.",
      k, length(pop$proportions)))
  }
  if (!is.null(pop$scores)) {
    scores <- as.numeric(unlist(pop$scores))
    if (length(scores) != k) {
      problems <- c(problems, sprintf(
        "'population > scores' should have one score per group: X has %d levels, and %d scores were given.", k, length(scores)))
    } else if (length(unique(scores)) < 2) {
      problems <- c(problems, "'population > scores' are all the same, so there is no order to test a trend along: give each group its score (for example its dose).")
    }
  }
  if (identical(spec$options$method, "exact")) {
    problems <- c(problems, "'options > method' 'exact' isn't available for the Cochran-Armitage test: it is simulated. Remove 'options > method'.")
  }
  problems
}

# Unequal groups in a trend test (options > group_ratio): the
# Jonckheere-Terpstra and Cochran-Armitage tests only, one whole number per
# group in the groups' order.
unequal_groups <- function(spec) {
  !is.null(spec$options$group_ratio) && (jonckheere_test(spec) || proportion_trend(spec))
}

group_ratio_vector <- function(spec) as.numeric(unlist(spec$options$group_ratio))

check_group_ratio_allowed <- function(spec) {
  ratio <- spec$options$group_ratio
  if (is.null(ratio)) {
    return(character())
  }
  if (!jonckheere_test(spec) && !proportion_trend(spec)) {
    return(paste0(
      "'options > group_ratio' only applies to the trend tests (the Jonckheere-Terpstra ",
      "and Cochran-Armitage tests). Remove it."
    ))
  }
  k <- length(if (proportion_trend(spec)) spec$variables$X$levels else spec$variables$A$levels)
  if (length(ratio) != k) {
    return(sprintf(
      "'options > group_ratio' should have one number per group: there are %d groups, and %d numbers were given.",
      k, length(ratio)
    ))
  }
  character()
}

# The scores of a trend in proportions: those given, or 1, 2, ..., k
# (prop.trend.test()'s default).
trend_scores <- function(spec) {
  scores <- spec$population$scores
  if (is.null(scores)) seq_along(spec$population$proportions) else as.numeric(unlist(scores))
}

# The Jonckheere-Terpstra test is for groups in order: the one-way
# between-participants template, with its means (not eta-squared).
check_jonckheere <- function(spec) {
  if (!jonckheere_test(spec)) {
    return(character())
  }
  if (!identical(spec$template, "oneway_between")) {
    return("The Jonckheere-Terpstra test is for three or more groups of different people in a set order (template 'oneway_between').")
  }
  if (identical(spec$target_test$effect, "pairwise")) {
    return("The Jonckheere-Terpstra test tests a trend across all the groups, not one pair: set 'target_test > effect' to \"main_effect_A\".")
  }
  character()
}

# MANOVA: one row of means per group and one mean per outcome, outcomes
# named Y1, Y2, ... in order, one SD per outcome, and a correlation that
# gives a valid covariance matrix (with the same correlation between every
# pair of p outcomes, it must be above -1 / (p - 1)).
manova_outcomes <- function(spec) {
  sort(grep("^Y[1-9]$", names(spec$variables), value = TRUE))
}

# The number of groups: A's levels, or with a second factor B every
# combination of A and B.
manova_groups <- function(spec) {
  length(spec$variables$A$levels) * if (is.null(spec$variables$B)) 1L else length(spec$variables$B$levels)
}

check_manova <- function(spec) {
  pop <- spec$population
  outcomes <- manova_outcomes(spec)
  p <- length(outcomes)
  k <- manova_groups(spec)
  two <- !is.null(spec$variables$B)
  problems <- character()
  if (!identical(outcomes, paste0("Y", seq_len(p)))) {
    problems <- c(problems, sprintf("The outcomes should be named Y1 to Y%d, with none missing.", p))
  }
  if (!two && !identical(spec$target_test$effect, "main_effect_A")) {
    problems <- c(problems, "With one factor the test is of A ('target_test > effect' \"main_effect_A\"); B's effect and the interaction need a second factor B.")
  }
  if (length(pop$means) != k) {
    problems <- c(problems, if (two) {
      sprintf("'population > means' should have one row per combination of A and B (%d), A's levels outer; it has %d.", k, length(pop$means))
    } else {
      sprintf("'population > means' should have one row per group of A (%d); it has %d.", k, length(pop$means))
    })
  }
  if (any(lengths(pop$means) != p)) {
    problems <- c(problems, sprintf("Each row of 'population > means' should have one mean per outcome (%d).", p))
  }
  if (length(pop$sds) != p) {
    problems <- c(problems, sprintf("'population > sds' should have one SD per outcome (%d); it has %d.", p, length(pop$sds)))
  }
  if (p > 1 && pop$r <= -1 / (p - 1)) {
    problems <- c(problems, sprintf(
      "With %d outcomes, the correlation between every pair can't be %s or lower (it must be above %s), or the outcomes couldn't all be correlated that way at once.",
      p, format_number(-1 / (p - 1)), format_number(round(-1 / (p - 1), 3))))
  }
  problems
}

# One-sample Hotelling's T-squared: one mean and one fixed value per
# outcome, outcomes Y1, Y2, ... in order, one SD per outcome, and a
# correlation that gives a valid covariance matrix (as for MANOVA).
check_hotelling_one <- function(spec) {
  pop <- spec$population
  outcomes <- manova_outcomes(spec)
  p <- length(outcomes)
  problems <- character()
  if (!identical(outcomes, paste0("Y", seq_len(p)))) {
    problems <- c(problems, sprintf("The outcomes should be named Y1 to Y%d, with none missing.", p))
  }
  for (field in c("means", "mu0", "sds")) {
    if (length(pop[[field]]) != p) {
      problems <- c(problems, sprintf("'population > %s' should have one value per outcome (%d); it has %d.", field, p, length(pop[[field]])))
    }
  }
  if (p > 1 && pop$r <= -1 / (p - 1)) {
    problems <- c(problems, sprintf(
      "With %d outcomes, the correlation between every pair can't be %s or lower (it must be above %s), or the outcomes couldn't all be correlated that way at once.",
      p, format_number(-1 / (p - 1)), format_number(round(-1 / (p - 1), 3))))
  }
  problems
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
  if (identical(pop$metric, "eta_squared")) {
    return(check_eta_squared_anova(spec))
  }
  if (identical(pop$metric, "standardised") && any(unlist(pop[["sd"]]) != 1)) {
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
  if (spec$template %in% c("mixed", "factorial_between", "factorial_within", "factorial_ancova")) {
    return(check_mixed_shape(spec))
  }
  if (spec$template == "factorial_three") {
    return(check_three_shape(spec))
  }
  character()
}

# Three factors: one array of means per level of A, one per level of B
# within it, one mean per level of C; a correlation exactly when a factor
# is within participants, above -1 / (cells - 1) for the cells a
# participant is measured in.
check_three_shape <- function(spec) {
  pop <- spec$population
  levels <- vapply(c("A", "B", "C"), function(v) length(spec$variables[[v]]$levels), integer(1))
  shape_ok <- length(pop$means) == levels[1] &&
    all(vapply(pop$means, function(a) length(a) == levels[2] && all(lengths(a) == levels[3]), logical(1)))
  if (!shape_ok) {
    return(sprintf(
      paste0(
        "'population > means' should have %d arrays (one per level of %s), each with %d arrays ",
        "(one per level of %s) of %d means (one per level of %s), in the same order as the levels."
      ),
      levels[1], var_label(spec, "A"), levels[2], var_label(spec, "B"), levels[3], var_label(spec, "C")
    ))
  }
  within <- vapply(c("A", "B", "C"), function(v) identical(spec$variables[[v]]$type, "within_factor"), logical(1))
  if (!any(within) && !is.null(pop$r)) {
    return("Every factor is between participants, so there are no repeated measurements to correlate: remove 'population > r'.")
  }
  if (any(within) && is.null(pop$r)) {
    return("At least one factor is within participants: give 'population > r', the correlation between a participant's scores in any two conditions.")
  }
  cells <- prod(levels[within])
  if (any(within) && pop$r <= -1 / (cells - 1)) {
    return(sprintf(
      "With %d conditions per participant, one correlation between every pair of them must be above %s. Check 'population > r'.",
      cells, format(round(-1 / (cells - 1), 3))
    ))
  }
  character()
}

# The larger mixed design: one row of means per level of A, each with one
# mean per level of B, and at least one factor with three or more levels
# (a 2 x 2 design has its own template).
check_mixed_shape <- function(spec) {
  k <- length(spec$variables$A$levels)
  m <- length(spec$variables$B$levels)
  if (k == 2 && m == 2 && spec$template == "mixed") {
    return("Both factors have two levels: use the template '2x2_mixed' for a 2 x 2 mixed design.")
  }
  if (k == 2 && m == 2 && spec$template == "factorial_between") {
    return("Both factors have two levels: use the template '2x2_between' for a 2 x 2 between-participants design.")
  }
  rows <- lengths(spec$population$means)
  if (length(rows) != k || any(rows != m)) {
    return(sprintf(
      "'population > means' should have %d rows (one per level of %s), each with %d means (one per level of %s), in the same order as the levels.",
      k, var_label(spec, "A"), m, var_label(spec, "B")
    ))
  }
  if (spec$template == "factorial_within" && length(unlist(spec$population$r)) == 1 && spec$population$r <= -1 / (k * m - 1)) {
    # The same correlation between every pair of the k x m cells is only
    # possible above -1 / (cells - 1).
    return(sprintf(
      "With %d conditions, one correlation between every pair of them must be above %s. Check 'population > r'.",
      k * m, format(round(-1 / (k * m - 1), 3))
    ))
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

# Three factors: the target effect's largest departure from no effect, from
# the ANOVA decomposition of the cell means (each effect's terms are the
# marginal means with the lower-order effects removed). Zero only when the
# effect is absent.
three_factor_effect_size <- function(spec) {
  levels <- vapply(c("A", "B", "C"), function(v) length(spec$variables[[v]]$levels), integer(1))
  m <- aperm(array(as.numeric(unlist(spec$population$means)), dim = rev(levels)), 3:1)
  centre <- function(x) x - mean(x)
  margin <- function(dims) apply(m, dims, mean)
  a <- centre(margin(1))
  b <- centre(margin(2))
  c <- centre(margin(3))
  ab <- margin(c(1, 2)) - outer(a, b, "+") - mean(m)
  ac <- margin(c(1, 3)) - outer(a, c, "+") - mean(m)
  bc <- margin(c(2, 3)) - outer(b, c, "+") - mean(m)
  abc <- m - mean(m) -
    outer(outer(a, rep(1, levels[2])), rep(1, levels[3])) -
    outer(outer(rep(1, levels[1]), b), rep(1, levels[3])) -
    outer(outer(rep(1, levels[1]), rep(1, levels[2])), c) -
    outer(ab, rep(1, levels[3])) -
    aperm(outer(ac, rep(1, levels[2])), c(1, 3, 2)) -
    aperm(outer(bc, rep(1, levels[1])), c(3, 1, 2))
  terms <- list(
    main_effect_A = a, main_effect_B = b, main_effect_C = c,
    interaction_AB = ab, interaction_AC = ac, interaction_BC = bc, interaction_ABC = abc
  )
  max(abs(terms[[spec$target_test$effect]]))
}

anova_contrast <- function(spec) {
  if (identical(spec$population$metric, "eta_squared")) {
    return(spec$population$eta_squared)
  }
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
  if (spec$template == "factorial_three") {
    return(three_factor_effect_size(spec))
  }
  if (spec$template %in% c("mixed", "factorial_between", "factorial_within", "factorial_ancova")) {
    # Each effect's largest departure from no effect: zero only when the
    # effect is absent.
    m <- do.call(rbind, lapply(spec$population$means, function(row) as.numeric(unlist(row))))
    residual <- m - outer(rowMeans(m), colMeans(m), "+") + mean(m)
    return(switch(
      spec$target_test$effect,
      main_effect_A = diff(range(rowMeans(m))),
      main_effect_B = diff(range(colMeans(m))),
      interaction = max(abs(residual))
    ))
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
  # Three-way interactions: InteractionPoweR builds the full correlation
  # matrix of the seven terms itself, and the backend refuses an impossible
  # one in plain English (interactionpower_3way_power()).
  if (identical(spec$template, "three_way")) {
    return(character())
  }
  # Given by its R-squared change (pwrss's F test, as in G*Power): no
  # correlations to check; the reliability adjustment and yes/no variables
  # need InteractionPoweR's correlations.
  if (identical(pop$metric, "r2_change")) {
    problems <- character()
    if ((pop$r2_main %||% 0) + pop$r2_change >= 1) {
      problems <- c(problems, "'population > r2_main' plus 'r2_change' must be below 1: together they are the model's R-squared.")
    }
    if (any(vapply(c("X", "W", "Y"), function(v) !is.null(spec$variables[[v]]$reliability), logical(1)))) {
      problems <- c(problems, paste0("Reliability is used with the correlations (InteractionPoweR); with the R-squared change ",
        "the measures are taken as measured. Remove 'reliability', or give the correlations instead."))
    }
    if (any(vapply(c("X", "W"), function(v) identical(spec$variables[[v]]$type, "binary"), logical(1)))) {
      problems <- c(problems, "The R-squared change route is for two scores; for a yes/no X or W, give the correlations.")
    }
    return(problems)
  }
  # A yes/no variable has no reliability to enter: misclassification in a
  # 0/1 variable is a different problem from unreliable scores (decided 16
  # October 2026; for E15, only the score's reliability is asked).
  binary_rel <- Filter(function(v) identical(spec$variables[[v]]$type, "binary") && !is.null(spec$variables[[v]]$reliability), c("X", "W"))
  if (length(binary_rel)) {
    return(sprintf(
      "'variables > %s > reliability' can't be used for a yes/no variable: misclassification isn't the same as unreliable scores. Remove it.",
      binary_rel[1]
    ))
  }
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
    # Moderated mediation with one mediator (M) or parallel mediators (M1,
    # M2, ...). Model 7: W moderates X -> each mediator. Model 14: W
    # moderates each mediator -> Y (the product of mediator Mk and W is
    # MkW, or MW for a single mediator).
    process_7 = list(
      exogenous = c("X", "W"),
      mediators = mediators,
      products = list(XW = c("X", "W")),
      equations = c(
        stats::setNames(rep(list(c("X", "W", "XW")), length(mediators)), mediators),
        list(Y = c("X", mediators))
      )
    ),
    process_14 = {
      products <- stats::setNames(lapply(mediators, function(m) c(m, "W")), paste0(mediators, "W"))
      list(
        exogenous = c("X", "W"),
        mediators = mediators,
        products = products,
        equations = c(
          stats::setNames(rep(list("X"), length(mediators)), mediators),
          list(Y = c("X", mediators, "W", names(products)))
        )
      )
    }
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
    process_4 = ,
    process_7 = ,
    process_14 = identical(mediators, "M") ||
      (length(mediators) >= 2 && setequal(mediators, numbered)),
    process_6 = length(mediators) >= 2 && setequal(mediators, numbered),
    TRUE
  )
  if (ok) {
    return(character())
  }
  advice <- if (spec$template != "process_6") {
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
  if (spec$design == "moderated_mediation") {
    return(c(
      check_correlation_field(spec, model, "correlations", c("X", "W")),
      check_correlation_field(spec, model, "residual_correlations", model$mediators)
    ))
  }
  check_correlation_field(spec, model, "residual_correlations", model$mediators)
}

# One map of correlations ('A<->B': r) among `allowed_vars`. Residual
# correlations are only for two or more (parallel) mediators.
check_correlation_field <- function(spec, model, field, allowed_vars) {
  correlations <- spec$population[[field]]
  if (length(correlations) == 0) {
    return(character())
  }
  if (field == "residual_correlations" && length(model$mediators) < 2) {
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
    if (spec$design == "moderated_mediation" && length(model$mediators) > 1) {
      return(sprintf(
        "With several mediators, say which mediator's index of moderated mediation to test in 'target_test > path': one of %s.",
        quote_list(indirect_paths(model))
      ))
    }
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
  if (length(mediators) < 3 ||
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
  if (!is.null(goal$power) && !is.null(alpha) && goal$power <= alpha) {
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
      # Two people in the smaller group (pwr.t2n.test() needs them): with
      # an allocation of 1 : 3, eight in all, not four.
      independent_t = {
        ratio <- spec$options$allocation_ratio %||% 1
        max(4, ceiling(2 * (1 + ratio) / min(1, ratio)))
      },
      chi_square_independence = length(spec$variables$X$levels) * length(spec$variables$Y$levels),
      chi_square_gof = length(spec$variables$Y$levels),
      # Two people in each group.
      proportion_trend = if (unequal_groups(spec)) {
        w <- group_ratio_vector(spec)
        ceiling(2 * sum(w) / min(w))
      } else {
        2 * length(spec$variables$X$levels)
      },
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
      # Pillai's trace needs more people than outcomes in the residual
      # degrees of freedom: at least p + 2 people in each group.
      manova = manova_groups(spec) * (length(manova_outcomes(spec)) + 2),
      # Hotelling's T-squared with one group has n - p denominator df: at
      # least p + 2 people, as each MANOVA group needs.
      hotelling_one = length(manova_outcomes(spec)) + 2,
      4
    ),
    # TOSTER's power_t_TOST() needs two people per group (one in a
    # one-sample or paired design); powerkit asks for one more, as for the
    # t-tests.
    equivalence_test = switch(
      spec$template,
      tost_independent = 4,
      # TOSTER's z test of a correlation uses Fisher's z, whose SE is
      # 1 / sqrt(n - 3).
      tost_correlation = 5,
      # TOSTER's power_twoprop() needs four people in each of the two
      # equal groups.
      tost_two_proportions = 8,
      # pwrss's t tests need at least 3 degrees of freedom.
      noninf_independent = 6,
      noninf_paired = ,
      noninf_one_sample = 5,
      noninf_two_proportions = 4,
      3
    ),
    factorial_anova = switch(
      spec$template,
      # Two participants in the smallest cell.
      "2x2_between" = if (unequal_cells(spec)) {
        w <- cell_ratio_vector(spec)
        ceiling(2 * sum(w) / min(w))
      } else {
        8
      },
      "2x2_mixed" = 4,
      # Two participants per between-participants group.
      mixed = 2 * length(spec$variables$A$levels),
      # Two participants per cell when every cell is different people;
      # Superpower's exact data set needs at least five people in a
      # within design (backend-superpower.R, exact_min_n).
      factorial_between = 2 * length(spec$variables$A$levels) * length(spec$variables$B$levels),
      factorial_within = 5,
      # Two participants per between-participants group (one group when
      # every factor is within); Superpower's exact data set needs at
      # least five participants per group (backend-superpower.R).
      factorial_three = 5 * prod(vapply(c("A", "B", "C"), function(v) {
        if (identical(spec$variables[[v]]$type, "within_factor")) 1L else length(spec$variables[[v]]$levels)
      }, integer(1))),
      # Two participants per group, so the error df is at least the number
      # of groups.
      oneway_between = if (unequal_groups(spec)) {
        w <- group_ratio_vector(spec)
        ceiling(2 * sum(w) / min(w))
      } else {
        2 * length(spec$variables$A$levels)
      },
      oneway_contrast = 2 * length(spec$variables$A$levels),
      # Everyone is in every condition: Superpower's exact data set needs at
      # least five participants (backend-superpower.R, exact_min_n).
      oneway_within = 5,
      # Two per group, plus one error df for each covariate.
      oneway_ancova = 2 * length(spec$variables$A$levels) + spec$population$covariates,
      # Two per cell, plus one error df for each covariate.
      factorial_ancova = 2 * length(spec$variables$A$levels) * length(spec$variables$B$levels) + spec$population$covariates
    ),
    # The intercept, every predictor, and at least one residual df.
    multiple_regression = (spec$population$predictors %||% spec$population$predictors_total) + 2,
    # pwrss's own search for n starts at 2; at least the intercept and X's
    # coefficient, plus one.
    # A logistic factorial design: ten in every cell, so that most simulated
    # data sets have both answers in each cell.
    logistic_regression = if (identical(spec$template, "factorial")) {
      10 * length(spec$variables$A$levels) * length(spec$variables$B$levels)
    } else {
      3
    },
    poisson_regression = 3,
    # powertools::propodds() needs at least 2 in group 1; 2 in each group.
    ordinal_regression = 4,
    # Enough participants to estimate a random intercept and slope.
    # Two-level: at least ten groups, for the groups' variances.
    mixed_model = if (identical(spec$template, "two_level")) 10 * spec$population$cluster_size else
      if (identical(spec$template, "three_level")) 6 * spec$population$group_size * spec$population$groups_per_site else 6,
    # A meta-analysis: n is the number of studies; metapower needs at
    # least two.
    # Subgroups: two studies of each kind, so the within-kind variance has
    # a degree of freedom.
    meta_analysis = if (identical(spec$template, "subgroups")) 2 * length(unlist(spec$population$effects)) else 2,
    # Dyads: enough pairs for lavaan to fit the APIM's 10 parameters.
    dyadic = 20,
    # Two groups in each condition (cluster-randomised), or two groups
    # (multisite), or two groups and as many people again (group
    # treatment): the fewest powertools accepts.
    cluster_trial = (if (identical(spec$template, "multisite")) 2 else 4) * spec$population$cluster_size,
    # The intercept and every term (3 for two-way, 7 for three-way), plus
    # at least two residual df.
    regression_interaction = if (identical(spec$template, "three_way")) 10 else 6,
    # More participants than items, so that the sample covariance matrix
    # can be positive definite; 2 when only the df are known.
    sem = switch(
      spec$template,
      model_fit = if (is.null(spec$population$indicators)) 2 else spec$population$indicators + 1,
      # Each group needs more people than items.
      invariance = (if (identical(spec$population$over, "occasions")) 1 else 2) * (spec$population$indicators + 1),
      factor_correlation = sum(unlist(spec$population$indicators)) + 1,
      latent_regression = spec$population$indicators * (length(spec$population$slopes) + 1) + 1
    ),
    # Enough for the largest regression in the model plus two residual df.
    max(lengths(path_model(spec)$equations)) + 3
  )
}

group_split <- function(spec) {
  whole <- function(x) abs(x - round(x)) < 1e-9
  if (identical(spec$design, "meta_analysis") && identical(spec$template, "subgroups")) {
    g <- length(unlist(spec$population$effects))
    return(list(rule = sprintf("split equally between the %d kinds of study", g), valid = function(n) n %% g == 0))
  }
  if (spec$template == "2x2_between" && unequal_cells(spec)) {
    w <- cell_ratio_vector(spec)
    return(list(
      rule = sprintf("split into 4 whole cells in the ratio %s", paste(format_number(w), collapse = " : ")),
      valid = function(n) all(whole(n * w / sum(w)))
    ))
  }
  if (spec$template == "2x2_between") {
    return(list(rule = "split into 4 equal cells for a 2x2 between-participants design", valid = function(n) n %% 4 == 0))
  }
  if (spec$template == "2x2_mixed") {
    return(list(rule = "split into 2 equal groups for the between-participants factor", valid = function(n) n %% 2 == 0))
  }
  if (spec$template == "tost_two_proportions") {
    return(list(rule = "split into 2 equal groups (TOSTER takes one group size)", valid = function(n) n %% 2 == 0))
  }
  if (identical(spec$template, "manova") && !is.null(spec$variables$B)) {
    cells <- manova_groups(spec)
    return(list(rule = sprintf("split into %d equal groups, one per combination of A and B", cells), valid = function(n) n %% cells == 0))
  }
  if (identical(spec$template, "crossed_two_condition") && identical(spec$variables$X$type, "between_factor")) {
    return(list(rule = "split into 2 equal groups, one per condition", valid = function(n) n %% 2 == 0))
  }
  if (identical(spec$template, "crossed_conditions") && identical(spec$variables$X$type, "between_factor")) {
    k <- length(spec$variables$X$levels)
    return(list(rule = sprintf("split into %d equal groups, one per condition", k), valid = function(n) n %% k == 0))
  }
  if (identical(spec$template, "three_level")) {
    site <- spec$population$group_size * spec$population$groups_per_site
    step <- if (identical(spec$population$assignment, "site")) 2 * site else site
    return(list(rule = sprintf("a whole number of sites of %d people%s", site,
      if (identical(spec$population$assignment, "site")) ", an even number of them" else ""), valid = function(n) n %% step == 0))
  }
  if (identical(spec$template, "two_level")) {
    m <- spec$population$cluster_size
    return(list(rule = sprintf("a whole number of groups of %d", m), valid = function(n) n %% m == 0))
  }
  if (unequal_groups(spec)) {
    w <- group_ratio_vector(spec)
    return(list(
      rule = sprintf("split into %d whole groups in the ratio %s", length(w), paste(format_number(w), collapse = " : ")),
      valid = function(n) all(whole(n * w / sum(w)))
    ))
  }
  if (spec$template %in% c("oneway_between", "oneway_ancova", "oneway_contrast", "mixed", "manova")) {
    k <- length(spec$variables$A$levels)
    return(list(rule = sprintf("split into %d equal groups", k), valid = function(n) n %% k == 0))
  }
  if (identical(spec$template, "proportion_trend")) {
    k <- length(spec$variables$X$levels)
    return(list(rule = sprintf("split into %d equal groups", k), valid = function(n) n %% k == 0))
  }
  if (spec$template %in% c("factorial_between", "factorial_ancova", "factorial")) {
    cells <- length(spec$variables$A$levels) * length(spec$variables$B$levels)
    return(list(rule = sprintf("split into %d equal groups, one per cell", cells), valid = function(n) n %% cells == 0))
  }
  if (spec$template == "factorial_three") {
    groups <- three_factor_groups(spec)
    if (groups == 1) {
      return(NULL)
    }
    return(list(
      rule = sprintf("split into %d equal groups, one per combination of the between-participants factors", groups),
      valid = function(n) n %% groups == 0
    ))
  }
  if (spec$template == "multisite") {
    m <- spec$population$cluster_size
    return(list(
      rule = sprintf("be a whole number of groups of %s", format_number(m)),
      valid = function(n) n %% m == 0
    ))
  }
  if (spec$template == "group_treatment") {
    m <- spec$population$cluster_size
    return(list(
      rule = sprintf("be a whole number of groups of %s in the grouped condition, with as many people again taking part individually", format_number(m)),
      valid = function(n) n %% (2 * m) == 0
    ))
  }
  if (spec$template == "cluster_randomised") {
    m <- spec$population$cluster_size
    return(list(
      rule = sprintf("be a whole number of groups of %s, the same number of groups in each condition", format_number(m)),
      valid = function(n) n %% (2 * m) == 0
    ))
  }
  if (spec$template %in% c("independent_t", "two_proportions", "two_correlations", "two_variances", "tost_independent",
                           "noninf_independent", "noninf_two_proportions") ||
      (identical(spec$template, "invariance") && !identical(spec$population$over, "occasions"))) {
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
      # No trend when every group has the same proportion.
      proportion_trend = diff(range(as.numeric(unlist(pop$proportions)))),
      two_variances = ,
      paired_variances = pop$var1 - pop$var2,
      # The largest difference between two groups on any outcome.
      manova = {
        means <- do.call(rbind, lapply(pop$means, as.numeric))
        if (is.null(spec$variables$B)) {
          max(apply(means, 2, function(x) diff(range(x))))
        } else {
          # Each outcome's cell means as an A by B table: the spread of the
          # effect tested (row means, column means, or what is left after
          # both, for the interaction).
          k <- length(spec$variables$A$levels)
          max(apply(means, 2, function(x) {
            cells <- matrix(x, nrow = k, byrow = TRUE)
            switch(spec$target_test$effect,
              main_effect_A = diff(range(rowMeans(cells))),
              main_effect_B = diff(range(colMeans(cells))),
              interaction = max(abs(cells - outer(rowMeans(cells), colMeans(cells), "+") + mean(cells))))
          }))
        }
      },
      # The largest difference between a mean and its fixed value.
      hotelling_one = max(abs(as.numeric(unlist(pop$means)) - as.numeric(unlist(pop$mu0)))),
      chi_square_gof = if (chisq_by_w(spec)) pop$w else {
        p <- as.numeric(unlist(pop$probabilities))
        p0 <- as.numeric(unlist(pop$null_probabilities %||% rep(1 / length(p), length(p))))
        max(abs(p - p0))
      },
      chi_square_independence = if (chisq_by_w(spec)) pop$w else {
        p <- matrix(as.numeric(unlist(pop$probabilities)), nrow = length(pop$probabilities), byrow = TRUE)
        max(abs(p - outer(rowSums(p), colSums(p))))
      }
    ),
    factorial_anova = if (pairwise_comparison(spec)) {
      # The chosen pair's difference (an unknown pair is reported by
      # check_pairwise()).
      pair <- pairwise_levels(spec)
      if (length(pair) == 2 && !anyNA(pair)) diff(as.numeric(unlist(pop$means))[pair]) else 1
    } else {
      anova_contrast(spec)
    },
    # An equivalence test has something to show whenever the bound is above
    # 0 (the schema requires it), whatever the expected difference.
    equivalence_test = pop$bound %||% pop$margin,
    multiple_regression = if (spec$template == "r2_zero") pop$r2 else pop$r2_full - pop$r2_reduced,
    logistic_regression = if (identical(spec$template, "factorial")) {
      design <- logistic_factorial_design(spec)
      max(abs(design$betas[design$tested]))
    } else {
      log(pop$odds_ratio)
    },
    ordinal_regression = log(pop$odds_ratio),
    mixed_model = if (identical(spec$template, "two_level")) {
      switch(spec$target_test$effect, within_effect = pop$b_X, between_effect = pop$b_W, cross_level_interaction = pop$b_XW)
    } else if (identical(spec$template, "three_level")) {
      pop$d
    } else if (identical(spec$template, "item_predictor")) {
      pop$slope
    } else if (identical(spec$template, "crossed_conditions")) {
      means <- as.numeric(unlist(pop$means %||% pop$probabilities))
      pair <- match(unlist(spec$target_test$comparison), unlist(spec$variables$X$levels))
      if (identical(spec$target_test$effect, "pairwise")) {
        if (length(pair) == 2 && !anyNA(pair)) diff(means[pair]) else 1
      } else {
        max(abs(means - mean(means)))
      }
    } else if (identical(spec$variables$Y$type, "binary")) {
      p <- as.numeric(unlist(pop$probabilities))
      if (length(p) == 2) diff(p) else 1
    } else {
      pop$difference
    },
    poisson_regression = log(pop$rate_ratio),
    cluster_trial = if (identical(pop$metric, "proportion")) pop$p2 - pop$p1 else pop$d,
    # Never 0 in practice for model fit: the schema refuses it, as
    # semPower does.
    sem = switch(
      spec$template,
      model_fit = pop$rmsea,
      invariance = if (identical(pop$level, "metric")) pop$loading_group2 - pop$loading else pop$intercept_difference,
      factor_correlation = pop$r,
      latent_regression = pop$slopes[[pop$tested %||% 1L]]
    ),
    regression_interaction = if (identical(spec$template, "three_way")) pop$b_XWZ else if (identical(pop$metric, "r2_change")) pop$r2_change else pop$r_XW_Y,
    mediation = {
      nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
      prod(vapply(seq_len(length(nodes) - 1), function(i) {
        as.numeric(paths[[paste0(nodes[i], "->", nodes[i + 1])]])
      }, numeric(1)))
    },
    moderated_mediation = switch(
      spec$template,
      process_7 = paths[[paste0("XW->", modmed_mediator(spec))]] * paths[[paste0(modmed_mediator(spec), "->Y")]],
      process_14 = paths[[paste0("X->", modmed_mediator(spec))]] * paths[[paste0(modmed_mediator(spec), "W->Y")]]
    ),
    meta_analysis = if (identical(spec$template, "subgroups")) {
      e <- as.numeric(unlist(pop$effects))
      max(abs(e - mean(e)))
    } else {
      pop$effect
    },
    dyadic = {
      # Several effects tested together: joint power needs every one, so
      # the smallest of them counts.
      b <- apim_paths(spec)
      labels <- list(actor = "a1", partner = "p21", actor_1 = "a1", actor_2 = "a2", partner_12 = "p12", partner_21 = "p21",
        actor_and_partner = c("a1", "p21"), both_actors = c("a1", "a2"), both_partners = c("p12", "p21"),
        all_four = c("a1", "a2", "p12", "p21"))
      at <- labels[[spec$target_test$effect]]
      values <- b[at]
      if (is.null(at) || anyNA(values)) 1 else min(abs(values))
    }
  )
  isTRUE(abs(value) < 1e-12)
}

# Three factors: how many groups of different people (the combinations of
# the between-participants factors' levels; 1 when every factor is within).
three_factor_groups <- function(spec) {
  as.integer(prod(vapply(c("A", "B", "C"), function(v) {
    if (identical(spec$variables[[v]]$type, "within_factor")) 1L else length(spec$variables[[v]]$levels)
  }, integer(1))))
}

# The mediator whose index of moderated mediation is tested: the middle of
# 'target_test > path' (X->Mk->Y) with several mediators, else M.
modmed_mediator <- function(spec) {
  path <- spec$target_test$path
  if (is.null(path)) {
    return("M")
  }
  nodes <- trimws(strsplit(path, "->", fixed = TRUE)[[1]])
  nodes[2]
}

# Ordinal outcome, two groups ------------------------------------------------

# One share per category of Y, summing to 1 (powertools::propodds() needs
# both).
# Meta-analysis -------------------------------------------------------------

# A planned meta-analysis (metapower): a correlation between -1 and 1, a
# one-sided test in the direction of the effect, and no sensitivity
# analysis yet (metapower solves for power only).
# Dyadic data (E44): the paths that match how the members are told apart,
# the effect tested among them, and variances that stay positive.
check_apim <- function(spec) {
  pop <- spec$population
  distinguishable <- isTRUE(pop$distinguishable)
  own <- if (distinguishable) c("actor_1", "actor_2", "partner_12", "partner_21") else c("actor", "partner")
  other <- if (distinguishable) c("actor", "partner") else c("actor_1", "actor_2", "partner_12", "partner_21")
  effects <- c(own, if (distinguishable) c("both_actors", "both_partners", "all_four") else "actor_and_partner")
  problems <- character()
  missing <- own[vapply(own, function(k) is.null(pop[[k]]), logical(1))]
  if (length(missing)) {
    problems <- c(problems, sprintf("Give %s (0 for no effect).", paste(sprintf("'population > %s'", missing), collapse = ", ")))
  }
  extra <- other[!vapply(other, function(k) is.null(pop[[k]]), logical(1))]
  if (length(extra)) {
    problems <- c(problems, sprintf("%s %s for %s members; remove %s.", paste(sprintf("'population > %s'", extra), collapse = ", "),
      if (length(extra) == 1) "is" else "are", if (distinguishable) "indistinguishable" else "distinguishable",
      if (length(extra) == 1) "it" else "them"))
  }
  if (!distinguishable && !is.null(pop$members)) {
    problems <- c(problems, "'population > members' names the members of distinguishable dyads; remove it, or set 'distinguishable' to true.")
  }
  if (!spec$target_test$effect %in% effects) {
    problems <- c(problems, sprintf("'target_test > effect' should be one of %s for %s members.",
      paste(sprintf("\"%s\"", effects), collapse = ", "), if (distinguishable) "distinguishable" else "indistinguishable"))
  }
  if (length(problems)) return(problems)
  r2 <- apim_r_squared(spec)
  bad <- names(r2)[r2 >= 1]
  if (length(bad)) {
    problems <- c(problems, sprintf("These effects are impossible together: they explain all of the variance in a member's %s (R-squared %s). Make them smaller.",
      var_label(spec, "Y"), format_number(round(max(r2), 3))))
  }
  problems
}

check_meta_analysis <- function(spec) {
  pop <- spec$population
  problems <- character()
  subgroups <- meta_subgroups(spec)
  effects <- as.numeric(unlist(if (subgroups) pop$effects else pop$effect))
  if (identical(pop$metric, "r") && any(abs(effects) >= 1)) {
    problems <- c(problems, sprintf("A correlation ('population > %s' with metric \"r\") must be between -1 and 1.",
      if (subgroups) "effects" else "effect"))
  }
  if (identical(pop$metric, "d") && pop$study_size %% 2 != 0) {
    problems <- c(problems, sprintf(paste0(
      "With Cohen's d each study has two groups of equal size, so 'population > study_size' must be even; ",
      "%d isn't."), as.integer(pop$study_size)))
  }
  alternative <- spec$target_test$alternative %||% "two_sided"
  if (subgroups && !identical(alternative, "two_sided")) {
    problems <- c(problems, "The test that kinds of study differ has no direction (a Q test): remove 'target_test > alternative' or set it to \"two_sided\".")
  }
  if (!subgroups && !identical(alternative, "two_sided") && pop$effect != 0 &&
      !identical(alternative, if (pop$effect > 0) "greater" else "less")) {
    problems <- c(problems, "A one-sided test of a meta-analysis runs in the direction of the expected effect.")
  }
  if (identical(spec$goal$type, "sensitivity")) {
    problems <- c(problems, paste0(
      "For a meta-analysis powerkit gives power, or the number of studies needed; the smallest detectable ",
      "average effect isn't available yet."))
  }
  # The Hartung-Knapp test is for the random-effects model and is
  # simulated; the z test is metapower's formula.
  if (identical(spec$target_test$model, "fixed") && identical(spec$target_test$test, "hartung_knapp")) {
    problems <- c(problems, "The Hartung-Knapp test is for the random-effects model; the fixed-effect model uses the z test.")
  }
  method <- spec$options$method
  if (hartung_knapp_test(spec) && identical(method, "exact")) {
    problems <- c(problems, paste0(
      "The Hartung-Knapp test is simulated (no package has a formula for its power); for metapower's formula, ",
      "set 'target_test > test' to \"z\"."))
  }
  if (!hartung_knapp_test(spec) && (identical(method, "simulation") || !is.null(spec$options$nrep))) {
    problems <- c(problems, "The z test is worked out by formula (metapower), so there is nothing to simulate; remove 'options > nrep'.")
  }
  problems
}

check_ordinal_two_groups <- function(spec) {
  p <- as.numeric(unlist(spec$population$probabilities))
  levels <- unlist(spec$variables$Y$levels)
  problems <- character()
  if (length(p) != length(levels)) {
    problems <- c(problems, sprintf(
      "'population > probabilities' has %d values, but %s has %d categories; give one share for each category, in the same order.",
      length(p), var_label(spec, "Y"), length(levels)
    ))
  }
  if (abs(sum(p) - 1) > 1e-6) {
    problems <- c(problems, sprintf(
      "The shares of group 1 in each category must add up to 1; they add up to %s.",
      format_number(round(sum(p), 4))
    ))
  }
  problems
}

# Logistic factorial ---------------------------------------------------------

# One row of proportions per level of A, one value per level of B.
check_logistic_factorial <- function(spec) {
  rows <- spec$population$probabilities
  a <- length(spec$variables$A$levels)
  b <- length(spec$variables$B$levels)
  if (length(rows) == a && all(lengths(rows) == b)) {
    return(character())
  }
  sprintf(
    "'population > probabilities' needs %d rows (one per level of %s), each with %d proportions (one per level of %s).",
    a, var_label(spec, "A"), b, var_label(spec, "B")
  )
}

# An ANOVA given by its partial eta-squared (pwrss's F test, as in G*Power):
# equal groups and the ANOVA F test only, since the group means that
# Welch's F, the Kruskal-Wallis test and unequal cells need aren't given.
check_eta_squared_anova <- function(spec) {
  if (!spec$template %in% eta_squared_templates) {
    return(paste0(
      "An effect given as partial eta-squared ('population > metric' \"eta_squared\") is available for ",
      "between-participants ANOVA (templates oneway_between, 2x2_between, factorial_between and factorial_three), ",
      "ANCOVA (oneway_ancova, factorial_ancova) and repeated-measures or mixed ANOVA with one within factor ",
      "(oneway_within, 2x2_mixed, mixed) only."))
  }
  if (identical(spec$template, "factorial_three") &&
      any(vapply(c("A", "B", "C"), function(v) identical(spec$variables[[v]]$type, "within_factor"), logical(1)))) {
    return(paste0(
      "With three factors, partial eta-squared is available when every factor is between participants (different ",
      "people in every cell), as in G*Power. With a within-participants factor, give the cell means, the SD and the ",
      "correlation instead."))
  }
  ancova <- spec$template %in% c("oneway_ancova", "factorial_ancova")
  method <- spec$target_test$method %||% if (ancova) "ancova_f" else "anova_f"
  if (!identical(method, if (ancova) "ancova_f" else "anova_f")) {
    test <- switch(method, welch_f = "Welch's F test", kruskal_wallis = "The Kruskal-Wallis test", friedman = "Friedman's test",
      jonckheere_terpstra = "The Jonckheere-Terpstra test",
      t_test = "Pairwise comparisons, which need to know which groups differ,", sprintf("The test '%s'", method))
    return(sprintf(paste0(
      "Partial eta-squared works only with the ANOVA F test. %s needs the mean in each group or condition and the SD: ",
      "give the means instead ('population > metric' \"raw\" or \"standardised\")."), test))
  }
  if (!is.null(spec$options$cell_ratio) && length(unique(as.numeric(unlist(spec$options$cell_ratio)))) > 1) {
    return("With partial eta-squared the groups are equal in size; for unequal groups, give the cell means instead.")
  }
  if (identical(spec$options$method, "simulation")) {
    return("With partial eta-squared power is worked out by formula (pwrss); simulation needs the group means.")
  }
  character()
}
