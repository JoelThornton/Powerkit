# What an analysis commits the researcher to: its name, its decision rule
# (direction, bounds, what counts as success) and how to read each outcome,
# built once from the spec. The write-ups, the single-analysis planning
# document and a study plan's target column and Registered Report table all
# take their wording from here, so they state the same decision (an audit of
# the exports, 21 November 2026, found a non-inferiority plan's table
# calling it TOST, a validation plan's target calling it development, and
# designs without a test given "a significance test at alpha = ,").
# Nothing here calculates.

# The analysis's name as the methods paragraph gives it, with its version
# and correction ("a z test of one proportion (R's prop.test()) with the
# continuity correction ..."), from the card's methods_name. The write-ups,
# the planning document and a study plan's tables all use it, so they name
# the same test (21 November 2026).
methods_test_name <- function(form, spec, result = NULL) {
  name <- form$methods_name
  # "Welch's independent-samples t-test (two-sided, ...)": one set of
  # brackets, not two in a row (P-15).
  if (identical(spec$target_test$method, "welch_t")) name <- paste0("Welch's ", sub("^an? ", "", name))
  if (identical(spec$target_test$method, "fisher_exact")) name <- "Fisher's exact test of two proportions"
  # A two-sided exact binomial test: which p-value (next.md item 30, 19
  # November 2026), since equal tails and binom.test() need different n.
  if (identical(spec$template, "one_proportion") && isTRUE(spec$target_test$method %in% c("z_test", "z_test_corrected"))) {
    name <- paste("a z test of one proportion (R's prop.test())",
      if (identical(spec$target_test$method, "z_test")) "without the continuity correction" else "with the continuity correction",
      "with power summed over every possible count")
  }
  if (identical(spec$template, "one_proportion") && identical(spec$target_test$alternative %||% "two_sided", "two_sided")) {
    if (identical(spec$target_test$method, "exact_binomial")) name <- paste(name, "with alpha / 2 in each tail")
    if (identical(spec$target_test$method, "binom_test")) {
      name <- paste(name, "with the two-sided p-value of R's binom.test(), which adds up every count no more likely than the one observed")
    }
  }
  # McNemar's chi-square test and the variance tests that don't assume
  # normal scores (17 November 2026, next.md item 27).
  if (identical(spec$target_test$method, "mcnemar_chisq")) name <- "McNemar's chi-square test without the continuity correction, simulated"
  if (identical(spec$target_test$method, "mcnemar_chisq_corrected")) {
    name <- "McNemar's chi-square test with the continuity correction (the default in R's mcnemar.test()), simulated"
  }
  if (isTRUE(spec$target_test$method %in% c("levene", "brown_forsythe"))) {
    name <- sprintf("%s of two variances (car's leveneTest(), deviations from each group's %s), simulated assuming %s",
      if (identical(spec$target_test$method, "levene")) "Levene's test" else "the Brown-Forsythe test",
      if (identical(spec$target_test$method, "levene")) "mean" else "median",
      score_shape_text(spec$population$score_shape))
  }
  # An ANCOVA's covariates: fixed by the design (as G*Power, and for an
  # effect given as partial eta-squared) or measured (Shieh's method).
  if (is_fixed_ancova(spec)) name <- "an ANCOVA with the covariates fixed by the design (F test)"
  # A mixed model's test with Kenward and Roger's degrees of freedom in
  # place of Satterthwaite's (17 November 2026).
  if (identical(spec$target_test$df_method, "kenward_roger")) {
    name <- if (grepl("Satterthwaite", name, fixed = TRUE)) gsub("Satterthwaite", "Kenward-Roger", name, fixed = TRUE) else
      paste0(name, " (Kenward-Roger tests)")
  }
  if (identical(spec$design, "survival")) {
    name <- switch(spec$target_test$method %||% "",
      log_rank = "a time-to-event analysis (the log-rank test)",
      cox_regression = "a time-to-event analysis (a Cox regression)", name)
  }
  if (isTRUE(spec$target_test$method %in% c("zero_inflated_poisson", "zero_inflated_negative_binomial"))) {
    name <- sprintf("a zero-inflated %s regression (%s, %s%% extra zeros%s), simulated",
      if (identical(spec$target_test$method, "zero_inflated_poisson")) "Poisson" else "negative binomial",
      switch(spec$target_test$effect,
        zero_odds_ratio = "the Wald z test of one predictor in the zero part",
        rate_and_zero = "the likelihood-ratio test of one predictor in both parts",
        "the Wald z test of one predictor in the count part"
      ),
      format(100 * spec$population$zero_prob),
      if (identical(spec$target_test$method, "zero_inflated_negative_binomial")) sprintf(", overdispersion k = %s", format(spec$population$dispersion)) else "")
  }
  if (identical(spec$target_test$method, "permanova")) {
    name <- sprintf("a PERMANOVA (vegan's adonis2() permutation test on Euclidean distances between the standardised outcomes), simulated assuming %s", score_shape_text(spec$population$score_shape))
  }
  if (identical(spec$target_test$method, "negative_binomial")) {
    name <- sprintf("a negative binomial regression (the Wald z test of one predictor, overdispersion k = %s), simulated", format(spec$population$dispersion))
  }
  if (identical(spec$template, "single_coefficient")) {
    name <- switch(spec$target_test$method %||% "f_test",
      ols_hc3 = "the t test of one regression coefficient with HC3 robust standard errors, simulated",
      ols_hc4 = "the t test of one regression coefficient with HC4 robust standard errors, simulated",
      quantile_regression = sprintf("a quantile regression test of one coefficient (quantile %s), simulated", format(spec$population$quantile %||% 0.5)),
      "the t test of one regression coefficient (as an F test)"
    )
  }
  # Moderation of a count and mediation with a yes/no or count outcome
  # (E32): the model the outcome takes.
  if (identical(spec$design, "poisson_regression") && identical(spec$template, "interaction")) {
    name <- if (identical(spec$target_test$method, "negative_binomial")) {
      sprintf("a negative binomial regression with an interaction (the Wald z test of the X x W coefficient, overdispersion k = %s), simulated", format(spec$population$dispersion))
    } else "a Poisson regression with an interaction (the Wald z test of the X x W coefficient), simulated"
  }
  if (identical(spec$template, "multinomial_interaction")) {
    name <- if (identical(spec$target_test$method, "wald_z")) {
      sprintf("a multinomial logistic regression with an interaction (the Wald z test of the X x W coefficient for '%s' against '%s'), simulated",
        spec$target_test$category, unlist(spec$variables$Y$levels)[[1]])
    } else "a multinomial logistic regression with an interaction (the likelihood-ratio test of the X x W terms for every category together), simulated"
  }
  if (identical(spec$template, "binary_or_count_outcome")) {
    name <- sprintf("regression-based causal mediation analysis with %s outcome (the natural indirect effect, delta method), simulated",
      if (identical(spec$variables$Y$type, "binary")) "a yes/no (logistic)" else if (identical(spec$population$count_model, "negative_binomial"))
        sprintf("a count (negative binomial, overdispersion k = %s)", format(spec$population$dispersion)) else "a count (Poisson)")
  }
  # Mediation with a mediator in ordered categories (E39).
  if (identical(spec$template, "ordinal_mediator")) {
    name <- sprintf(paste0("mediation with a mediator in %d ordered categories, as a structural equation model in which the categories are cut from ",
      "an underlying normal score (lavaan's latent-response model for ordered variables, theta parameterisation, with %s), ",
      "the indirect effect a*b tested by the delta method, simulated"),
      length(spec$population$m_probabilities),
      if (identical(spec$variables$Y$type, "binary")) "the yes/no outcome declared ordered too" else "the outcome a score")
  }
  # One yes/no answer in each of three or more conditions (E75).
  if (identical(spec$target_test$method, "cochran_q")) {
    name <- sprintf(paste0("Cochran's Q, simulated from a logistic model with a random intercept for each person ",
      "(SD %s on the log-odds scale), each person answering once in each condition"), format(spec$population$sd_person))
  }
  if (is_rank_test(spec)) name <- rank_test_name(spec)
  if (is_rank_correlation(spec)) name <- rank_correlation_name(spec)
  if (identical(spec$target_test$method, "welch_f")) name <- "Welch's one-way ANOVA (F test not assuming equal variances)"
  if (is_pairwise(spec)) name <- pairwise_test_name(spec)
  if (is_meta(spec)) name <- meta_methods_name(spec)
  # A sphericity correction (E54, when the SDs or correlations differ).
  correction <- spec$target_test$correction %||% "none"
  if (!identical(correction, "none") && !is_pairwise(spec)) {
    name <- sprintf("%s with the %s correction for sphericity", name, c(GG = "Greenhouse-Geisser", HF = "Huynh-Feldt")[[correction]])
  }
  if (is_bayes_test(spec)) name <- bayes_test_name(spec)
  if (is_minimum_effect(spec)) name <- sprintf("%s as a minimum-effect test against a smallest effect of interest of %s (pwrss's t-test against the margin)",
    name, minimum_effect_margin_text(spec))
  if (identical(spec$design, "sem") && !is_sem_fit(spec)) name <- sem_test_name(spec)
  # The test of fit chosen, not only the test of exact fit.
  if (is_sem_fit(spec)) name <- sem_fit_test_name(spec$target_test$method, spec$population$rmsea_null %||% 0.05)
  telescopes <- result$small_telescopes
  if (!is.null(telescopes)) {
    name <- sprintf(paste0("a small-telescopes replication test (Simonsohn, 2015): a one-sided test of whether the effect is smaller ",
      "than %s, the effect the original study (%s) had 33%% power to detect (%s), computed with pwrss"),
      telescope_effect_text(telescopes), telescope_original_text(telescopes), sub("^pwr[:]+", "pwr's ", telescopes$function_used))
  }
  if (isTRUE(spec$template %in% c("2x2_between", "2x2_mixed", "mixed", "factorial_between", "factorial_within", "factorial_ancova", "factorial_three"))) name <- sprintf("%s (target effect: %s)", name, anova_effect_words(spec))
  if (identical(spec$design, "equivalence_test")) {
    name <- paste(name, switch(spec$template, tost_independent = "of two independent groups",
      tost_paired = "of two paired measurements", tost_one_sample = "of one mean against a fixed value",
      tost_correlation = "of a correlation (z tests on Fisher's z)", tost_two_proportions = "of two independent proportions (z tests)",
      noninf_independent = "of two independent groups", noninf_paired = "of two paired measurements",
      noninf_one_sample = "of one mean against a reference value", noninf_two_proportions = "of two independent proportions"))
    if (is_noninferiority(spec)) name <- sub("^an equivalence test \\(two one-sided tests, TOST\\)", "a non-inferiority test (one-sided, against the margin)", name)
  }
  name
}

# The decision, as a list: `kind`; `rule`, a sentence for the planning
# document; `analysis`, the Registered Report table's analysis cell (the
# test, its settings and what counts as success); `interpretation`, what
# each outcome means; and `target`, what the plan aims for. `form` names
# the test as the methods paragraph does; without it the cells use the
# test's settings alone.
decision_rule <- function(spec, result = NULL, form = NULL) {
  tt <- spec$target_test %||% list()
  method <- tt$method %||% ""
  goal <- spec$goal %||% list()
  name <- if (!is.null(form$methods_name) && nzchar(form$methods_name)) methods_test_name(form, spec, result)
  cap <- function(x) paste0(toupper(substr(x, 1, 1)), substring(x, 2))
  cell <- function(detail, success) {
    lead <- if (is.null(name)) detail else if (is.null(detail)) name else sprintf("%s (%s)", name, sub("^an? ", "", detail))
    paste0(cap(lead), if (is.null(success)) "." else paste0("; ", success, "."))
  }
  power_target <- if (!is.null(goal$power)) paste("power", format(goal$power)) else gsub("_", " ", goal$type %||% "")
  alpha <- if (!is.null(tt$alpha)) alpha_text(tt$alpha)
  out <- function(kind, rule, analysis, interpretation, target = power_target) {
    list(kind = kind, rule = rule, analysis = analysis, interpretation = interpretation, target = target)
  }

  if (identical(spec$design, "prediction_model")) {
    if (!is.null(name)) name <- sub("developing or validating a prediction model", if (identical(spec$template, "validation")) "validating an existing prediction model" else "developing a prediction model", name, fixed = TRUE)
    if (identical(spec$template, "validation")) {
      widths <- sprintf("95%% intervals no wider than %s for the O/E ratio, %s for the calibration slope and %s for the C-statistic",
        format(goal$oe_ci_width %||% 0.2), format(goal$cslope_ci_width %||% 0.2), format(goal$cstat_ci_width %||% 0.1))
      return(out("prediction_validation",
        sprintf("Minimum sample size for validating an existing prediction model, not a significance decision: the criteria of Riley and colleagues, with %s.", widths),
        cell(NULL, sprintf("the sample size meets every validation criterion (%s)", widths)),
        "Not a test: report the O/E ratio, calibration slope and C-statistic with their intervals (fill in what values would change your conclusion).",
        sprintf("the criteria for validating an existing prediction model (%s)", widths)))
    }
    shrink <- format(goal$shrinkage %||% 0.9)
    return(out("prediction_development",
      sprintf("Minimum sample size for developing a prediction model, not a significance decision: the criteria of Riley and colleagues, with a shrinkage target of %s.", shrink),
      cell(NULL, sprintf("the sample size meets every development criterion (shrinkage target %s)", shrink)),
      "Not a test: report the model's performance with its intervals (fill in what values would change your conclusion).",
      paste0("the criteria for developing a prediction model, shrinkage ", shrink)))
  }
  if (identical(spec$design, "precision")) {
    interval <- precision_interval_name(spec)
    aim <- if (is.null(goal$assurance)) sprintf("an expected (average) width of %s", format(goal$width)) else
      sprintf("a width of %s with assurance %s", format(goal$width), format(goal$assurance))
    return(out("precision",
      paste(sprintf("Precision planning for a %s, not a significance decision.", interval),
        if (is.null(goal$assurance)) sprintf("Target: an expected (average) interval width of %s; no probability of meeting that width is specified.", format(goal$width)) else
          sprintf("Target: width %s with assurance %s.", format(goal$width), format(goal$assurance))),
      cell(interval, sprintf("planned for %s", aim)),
      "Not a test: report the estimate and its interval (fill in what values would change your conclusion).",
      paste0("interval width ", format(goal$width), if (!is.null(goal$assurance)) paste0(", assurance ", format(goal$assurance)))))
  }
  if (identical(spec$template, "efa")) {
    threshold <- format(tt$congruence %||% 0.95)
    success <- sprintf("a success if every factor's loadings are recovered with Tucker's congruence of at least %s", threshold)
    return(out("recovery",
      sprintf("Factor recovery, not a significance decision: %s. This plans recovery of the loadings stated, not how many factors to retain.", success),
      cell(NULL, success),
      sprintf("Every factor's congruence at least %s: the loadings are recovered. Otherwise: at least one factor is not recovered at that level.", threshold),
      if (!is.null(goal$power)) sprintf("%s chance of recovering every factor", with_article(percent(goal$power))) else power_target))
  }
  if (identical(spec$template, "lpa")) {
    k <- as.integer(spec$population$profiles)
    success <- sprintf("a success if the BIC chooses %d profiles among models with 1 to %d", k, k + 1L)
    return(out("selection",
      sprintf("Choosing the number of profiles, not a significance decision: %s.", success),
      cell(NULL, success),
      sprintf("The BIC chooses %d: the expected profiles are found. Otherwise: a different number of profiles is chosen.", k),
      if (!is.null(goal$power)) sprintf("%s chance of the BIC choosing %d profiles", with_article(percent(goal$power)), k) else power_target))
  }
  if (identical(method, "bayes_factor") || is_bayes_test(spec)) {
    thr <- format(tt$evidence_threshold %||% 10)
    return(out("bayes",
      "Bayes factor evidence decision using the stated prior and evidence threshold, rather than a p-value significance rule.",
      cell(test_text(spec), sprintf("a success if the Bayes factor for the effect reaches %s", thr)),
      sprintf("BF10 of %s or more: evidence for the effect. BF01 of %s or more: evidence for no effect. Between: not enough evidence either way.", thr, thr)))
  }
  if (is_noninferiority(spec)) {
    test <- noninf_test_text(spec)
    return(out("noninferiority",
      sprintf("A non-inferiority decision: %s. Non-inferiority is shown if this test is significant, that is, if the new condition is shown to be worse than the comparison by less than the margin. A two-sided equivalence claim is a different decision.", test),
      cell(if (is.null(name)) test else sprintf("alpha = %s, margin %s%s, %s values better", alpha, switch(spec$template, noninf_paired = "d_z = ", noninf_two_proportions = "", "d = "),
        format(spec$population$margin), spec$population$better %||% "higher"), "a success if the one-sided test against the margin is significant"),
      "Significant: the new condition is no worse than the comparison by more than the margin. Not significant: non-inferiority is not shown; report the estimate and its interval."))
  }
  if (identical(spec$design, "equivalence_test")) {
    test <- if (is.null(result)) sprintf("two one-sided tests (TOST), each at alpha = %s", alpha) else equivalence_test_text(spec, result)
    return(out("equivalence",
      sprintf("An equivalence decision: %s. Equivalence is shown if both one-sided tests are significant; a non-significant ordinary test does not establish equivalence.", test),
      cell(test, "a success if both one-sided tests are significant"),
      "Both significant: the effect is within the bounds. Otherwise: an effect beyond them is not ruled out."))
  }
  if (is_minimum_effect(spec)) {
    margin <- minimum_effect_margin_text(spec)
    return(out("minimum_effect",
      sprintf("A minimum-effect decision: %s. A success needs the effect shown to be larger than the smallest effect of interest (%s), not merely different from 0; the expected effect and that threshold are separate assumptions.", minimum_effect_test_text(spec), margin),
      cell(if (is.null(name)) minimum_effect_test_text(spec) else sprintf("%s, alpha = %s", switch(tt$alternative %||% "two_sided", greater = "one-sided", less = "one-sided", "two-sided"), alpha),
        sprintf("a success if it is significant, showing the effect is %s %s", switch(tt$alternative %||% "two_sided", less = "below minus", greater = "larger than", "further from zero than"), margin)),
      sprintf("Significant: the effect exceeds the smallest effect of interest (%s). Not significant: it is not shown to exceed it.", margin)))
  }
  if (is_sem_fit(spec)) {
    rmsea0 <- format(spec$population$rmsea_null %||% 0.05)
    test <- test_text(spec)
    reading <- switch(method,
      chi_square_not_close_fit = c(
        sprintf("A significant result shows the model fits closely, its RMSEA below %s (MacCallum, Browne and Sugawara, 1996); it does not detect misfit or test a particular path.", rmsea0),
        sprintf("a success if it is significant, showing the RMSEA is below %s", rmsea0),
        sprintf("Significant: the model fits closely (its RMSEA is shown to be below %s). Not significant: close fit is not shown.", rmsea0)),
      chi_square_close_fit = c(
        sprintf("A significant result shows the model's misfit is worse than close fit, its RMSEA above %s; a model that is not rejected is not shown to fit closely.", rmsea0),
        sprintf("a success if it is significant, showing the RMSEA is above %s", rmsea0),
        sprintf("Significant: the model's misfit exceeds RMSEA = %s. Not significant: misfit beyond that is not shown; this does not show the model fits.", rmsea0)),
      c("A significant result shows the model does not fit exactly; a model that is not rejected is not shown to be correct.",
        "a success if it is significant, detecting the misfit",
        "Significant: the model does not fit exactly (misfit detected). Not significant: misfit is not detected; this does not show the model is correct."))
    return(out("sem_fit", sprintf("A test of overall model fit: %s. %s", test, reading[[1]]),
      cell(if (is.null(name)) test else sprintf("alpha = %s", alpha), reading[[2]]), reading[[3]]))
  }
  # A significance test. F and chi-square tests have no sides.
  unsided <- if (is.null(tt$alternative)) unsided_test_name(spec)
  sides <- c(two_sided = "two-sided", greater = "one-sided (greater)", less = "one-sided (less)")
  alternative <- tt$alternative %||% "two_sided"
  side <- if (alternative %in% names(sides)) sides[[alternative]] else gsub("_", " ", alternative)
  rule <- paste0(if (is.null(unsided)) paste0("A significance test at alpha = ", tt$alpha, ", ", side, ". ") else
      sprintf("A significance test at alpha = %s: %s, which detects a difference in any direction. ", tt$alpha, unsided),
    if (identical(spec$design, "sem")) "Overall model fit and a particular path or correlation are different hypotheses; the plan tests the one selected." else
      "A significant result rejects the selected null hypothesis; it does not show that the effect matters in practice or that the theory is true.")
  null_value <- spec$population$icc_null %||% spec$population$reliability_null %||% spec$population$kappa_null
  interpretation <- if (identical(spec$design, "reliability") && !is.null(null_value)) {
    hypothesis <- sub(" at alpha = .*$", "", test_text(spec))
    claim <- if (grepl(" test that ", hypothesis, fixed = TRUE)) sub("^.* test that ", "", hypothesis) else sprintf("kappa differs from %s", format(null_value))
    sprintf("Significant: evidence that %s. Not significant: that is not shown.", claim)
  } else "Significant: evidence against no effect. Not significant: the effect is not shown; this test alone cannot show it is absent."
  out("test", rule, cell(test_text(spec), "a success if it is significant"), interpretation)
}
