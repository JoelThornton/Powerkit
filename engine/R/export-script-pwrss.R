# Scripts for the tests pwrss computes by formula (backend-pwrss.R): one
# proportion, McNemar's test, Welch's t-test by formula, R-squared in
# multiple regression, Fisher's exact test, goodness of fit, two
# correlations, dependent correlations, ANCOVA, and logistic and Poisson
# regression. Each passes the same values to pwrss as powerkit does
# (pwrss_inputs()).

pwrss_script <- function(spec, result) {
  inputs <- pwrss_inputs(spec)
  c(
    script_header(spec, result, "pwrss", inputs$description),
    "library(pwrss)",
    "",
    "# Inputs ----",
    pwrss_script_inputs(spec),
    goal_inputs(spec, result),
    "",
    "# Power at a total sample size, from pwrss's formula.",
    "power_at <- function(n_total) {",
    pwrss_script_call_lines(spec, inputs),
    "}",
    "",
    pwrss_goal_section(spec, result),
    comparison_section()
  )
}

pwrss_script_inputs <- function(spec) {
  pop <- spec$population
  v <- spec$variables
  lv <- function(role, i) comment_text(unlist(v[[role]]$levels)[i])
  alternative <- pwrss_alternative(spec)
  alt_line <- sprintf(
    "alternative <- %s # %s", r_code(alternative),
    if (alternative == "two.sided") "two-sided test" else "one-sided, in the direction of the specified effect"
  )
  switch(
    pwrss_key(spec),
    interaction_r2_change = c(
      sprintf("r2_change <- %s # R-squared the interaction %s x %s adds", r_code(pop$r2_change), comment_text(v$X$label), comment_text(v$W$label)),
      sprintf("r2_main <- %s # R-squared of %s and %s without the interaction", r_code(pop$r2_main %||% 0), comment_text(v$X$label), comment_text(v$W$label)),
      "# pwrss turns r.squared.change into f^2 = r / (1 - r); the partial R-squared",
      "# change gives Cohen's f^2 = r2_change / (1 - r2_main - r2_change), as in G*Power.",
      "partial <- r2_change / (1 - r2_main)"
    ),
    anova_eta_squared = {
      design <- eta_anova_design(spec)
      factors <- if (length(design$levels) == 1) {
        sprintf("levels <- %d # groups of %s", design$levels, comment_text(v$A$label))
      } else if (length(design$levels) == 3) {
        sprintf("levels <- c(%d, %d, %d) # levels of %s (A), %s (B) and %s (C)", design$levels[1], design$levels[2],
          design$levels[3], comment_text(v$A$label), comment_text(v$B$label), comment_text(v$C$label))
      } else {
        sprintf("levels <- c(%d, %d) # levels of %s (A) and %s (B)", design$levels[1], design$levels[2],
          comment_text(v$A$label), comment_text(v$B$label))
      }
      if (isTRUE(design$mixed)) {
        factors <- sprintf("levels <- c(%d, %d) # groups (between participants) and measurements (within): %s, %s",
          design$levels[1], design$levels[2],
          if (design$levels[1] == 1) "one group" else comment_text(v$A$label),
          comment_text(if (identical(spec$template, "oneway_within")) v$A$label else v$B$label))
      }
      c(
        sprintf("eta_squared <- %s # partial eta-squared of the effect tested, taken as the population value (as in G*Power)",
          r_code(pop$eta_squared)),
        factors,
        if (isTRUE(design$mixed)) {
          if (identical(pop$eta_source, "published")) {
            c("rho <- NA # NA: the eta-squared is as a repeated-measures ANOVA reports it, so it already reflects the correlation",
              "# A published partial eta-squared is the effect's sum of squares over the error sum of squares, so",
              "# the F test's noncentrality is f^2 x the error df (as Superpower's ANOVA_exact() and G*Power's",
              "# \"as in SPSS\" setting have it). pwrss takes it as f^2 x n_total, so f^2 is rescaled first.",
              "eta_for_pwrss <- function(n_total) {",
              sprintf("  df_error <- (n_total - levels[1]) * %s", if (identical(design$target, "between")) "1 # the between effect" else "(levels[2] - 1)"),
              "  f2 <- eta_squared / (1 - eta_squared) * df_error / n_total",
              "  f2 / (1 + f2)",
              "}")
          } else {
            sprintf("rho <- %s # correlation between measurements (the eta-squared doesn't include it, as in G*Power)", r_code(pop$r))
          }
        },
        if (!is.null(design$target)) sprintf("effect <- %s # the effect tested", r_code(design$target)),
        if (!is.null(pop$covariates)) {
          sprintf("covariates <- %d # number of covariates (each takes one error df, as in G*Power)", as.integer(pop$covariates))
        }
      )
    },
    one_proportion = c(
      sprintf("p <- %s # expected proportion with %s = %s", r_code(pop$p), comment_text(v$Y$label), lv("Y", 2)),
      sprintf("p0 <- %s # the fixed value it is compared with (the null hypothesis)", r_code(pop$p0)),
      alt_line
    ),
    mcnemar = c(
      sprintf(
        "p_first_only <- %s # proportion with %s = %s in %s only (%s, not %s)",
        r_code(pop$p_first_only), comment_text(v$Y$label), lv("Y", 2), lv("X", 1), lv("X", 1), lv("X", 2)
      ),
      sprintf(
        "p_second_only <- %s # proportion with %s = %s in %s only (%s, not %s)",
        r_code(pop$p_second_only), comment_text(v$Y$label), lv("Y", 2), lv("X", 2), lv("X", 2), lv("X", 1)
      ),
      alt_line
    ),
    independent_t = c(
      sprintf("d <- %s # standardised mean difference (%s minus %s) / %s", r_code(pop$d), lv("X", 2), lv("X", 1),
        if (unequal_welch(spec)) "root mean square SD" else "pooled SD"),
      if (unequal_welch(spec)) c("# With unequal spreads, d uses sqrt((SD1^2 + SD2^2)/2), not the weighted pooled SD.",
        sprintf("sds <- %s # group SDs in fixed RMS-SD units", r_code(welch_population_sds(spec)))),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(allocation_ratio(spec)), lv("X", 2), lv("X", 1)
      ),
      alt_line
    ),
    two_proportions = c(
      sprintf("p1 <- %s # proportion with %s = %s in %s", r_code(pop$p1), comment_text(v$Y$label), lv("Y", 2), lv("X", 1)),
      sprintf("p2 <- %s # proportion with %s = %s in %s", r_code(pop$p2), comment_text(v$Y$label), lv("Y", 2), lv("X", 2)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(allocation_ratio(spec)), lv("X", 2), lv("X", 1)
      ),
      alt_line
    ),
    two_correlations = c(
      sprintf("r1 <- %s # correlation of %s with %s in %s", r_code(pop$r1), comment_text(v$X$label), comment_text(v$Y$label), lv("G", 1)),
      sprintf("r2 <- %s # correlation of %s with %s in %s", r_code(pop$r2), comment_text(v$X$label), comment_text(v$Y$label), lv("G", 2)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(allocation_ratio(spec)), lv("G", 2), lv("G", 1)
      ),
      alt_line
    ),
    overlapping_correlations = c(
      sprintf("r_X_Y <- %s # correlation of %s with %s (the first compared)", r_code(pop$r_X_Y), comment_text(v$X$label), comment_text(v$Y$label)),
      sprintf("r_X_Z <- %s # correlation of %s with %s (the second compared)", r_code(pop$r_X_Z), comment_text(v$X$label), comment_text(v$Z$label)),
      sprintf("r_Y_Z <- %s # correlation of %s with %s (not compared)", r_code(pop$r_Y_Z), comment_text(v$Y$label), comment_text(v$Z$label)),
      alt_line
    ),
    nonoverlapping_correlations = c(
      sprintf("r_X1_Y1 <- %s # correlation of %s with %s (the first compared)", r_code(pop$r_X1_Y1), comment_text(v$X1$label), comment_text(v$Y1$label)),
      sprintf("r_X2_Y2 <- %s # correlation of %s with %s (the second compared)", r_code(pop$r_X2_Y2), comment_text(v$X2$label), comment_text(v$Y2$label)),
      sprintf("r_X1_X2 <- %s # correlation of %s with %s (not compared)", r_code(pop$r_X1_X2), comment_text(v$X1$label), comment_text(v$X2$label)),
      sprintf("r_X1_Y2 <- %s # correlation of %s with %s (not compared)", r_code(pop$r_X1_Y2), comment_text(v$X1$label), comment_text(v$Y2$label)),
      sprintf("r_Y1_X2 <- %s # correlation of %s with %s (not compared)", r_code(pop$r_Y1_X2), comment_text(v$Y1$label), comment_text(v$X2$label)),
      sprintf("r_Y1_Y2 <- %s # correlation of %s with %s (not compared)", r_code(pop$r_Y1_Y2), comment_text(v$Y1$label), comment_text(v$Y2$label)),
      alt_line
    ),
    chi_square_gof = if (chisq_by_w(spec)) c(
      sprintf("effect <- list(w = %s, df = %d) # Cohen's w, taken as the population value (as in G*Power), and its df (%d categories - 1)",
        r_code(pop$w), as.integer(chisq_df(spec)), length(v$Y$levels))
    ) else c(
      sprintf("probabilities <- %s # expected proportion in each category: %s",
        r_code(as.numeric(unlist(pop$probabilities))), paste(comment_text(unlist(v$Y$levels)), collapse = ", ")),
      if (!is.null(pop$null_probabilities)) {
        sprintf("null_probabilities <- %s # the fixed proportions they are compared with", r_code(as.numeric(unlist(pop$null_probabilities))))
      },
      "# Rescaled to sum to exactly 1, as pwrss requires (they already sum to 1 within rounding).",
      "probabilities <- probabilities / sum(probabilities)",
      if (!is.null(pop$null_probabilities)) "null_probabilities <- null_probabilities / sum(null_probabilities)",
      "# Cohen's w and its degrees of freedom (categories - 1), from pwrss.",
      if (is.null(pop$null_probabilities)) "# Compared with equal proportions (pwrss's default when none are given).",
      sprintf(
        "effect <- probs.to.w(prob.matrix = probabilities%s, verbose = 0)",
        if (is.null(pop$null_probabilities)) "" else ", null.prob.matrix = null_probabilities"
      )
    ),
    oneway_contrast = c(
      sprintf("means <- %s # expected mean of each group: %s",
        r_code(as.numeric(unlist(pop$means))), paste(comment_text(unlist(v$A$levels)), collapse = ", ")),
      sprintf("sd <- %s # SD of the outcome within each group", r_code(pop$sd)),
      sprintf("weights <- %s # the comparison being tested, one weight per group",
        r_code(as.numeric(unlist(spec$target_test$weights)))),
      sprintf("groups <- %s", r_code(length(unlist(v$A$levels))))
    ),
    oneway_ancova = c(
      sprintf("means <- %s # expected adjusted mean of each group: %s",
        r_code(as.numeric(unlist(pop$means))), paste(comment_text(unlist(v$A$levels)), collapse = ", ")),
      sprintf("sd <- %s # SD of the outcome within each group, before adjusting", r_code(pop$sd)),
      sprintf("r2_covariates <- %s # variance in the outcome the covariates explain", r_code(pop$r2_covariates)),
      sprintf("covariates <- %s # number of covariates", r_code(pop$covariates)),
      sprintf("groups <- %s", r_code(length(unlist(v$A$levels))))
    ),
    factorial_ancova = {
      k <- length(unlist(v$A$levels))
      m <- length(unlist(v$B$levels))
      cells <- as.vector(t(outer(comment_text(unlist(v$A$levels)), comment_text(unlist(v$B$levels)), paste, sep = " x ")))
      c(
        sprintf("means <- %s # expected adjusted cell means, A1:B1, A1:B2, ...: %s",
          r_code(as.numeric(unlist(pop$means))), paste(cells, collapse = ", ")),
        sprintf("sd <- %s # SD of the outcome within each cell, before adjusting", r_code(pop$sd)),
        sprintf("r2_covariates <- %s # variance in the outcome the covariates explain", r_code(pop$r2_covariates)),
        sprintf("covariates <- %s # number of covariates", r_code(pop$covariates)),
        sprintf("levels <- c(%d, %d) # levels of %s (A) and %s (B)", k, m, comment_text(v$A$label), comment_text(v$B$label)),
        "# pwrss's contrast matrix for this design; its rows named A1, ... test A,",
        "# B1, ... test B, and A1:B1, ... the interaction.",
        "contrasts <- factorial.contrasts(factor.levels = levels, intercept = FALSE, verbose = 0)$contrast.matrix",
        sprintf("contrasts <- contrasts[grepl(%s, rownames(contrasts)), , drop = FALSE] # %s",
          r_code(switch(spec$target_test$effect, main_effect_A = "^A[0-9]+$", main_effect_B = "^B[0-9]+$", interaction = ":")),
          anova_effect_name(spec))
      )
    },
    single_predictor = c(
      sprintf("odds_ratio <- %s # %s", r_code(pop$odds_ratio), if (identical(v$X$type, "binary")) {
        sprintf("odds of %s = %s in %s against %s", comment_text(v$Y$label), lv("Y", 2), lv("X", 2), lv("X", 1))
      } else {
        sprintf("odds of %s = %s per SD of %s", comment_text(v$Y$label), lv("Y", 2), comment_text(v$X$label))
      }),
      sprintf("base_prob <- %s # proportion with %s = %s %s", r_code(pop$base_prob), comment_text(v$Y$label), lv("Y", 2),
        if (identical(v$X$type, "binary")) sprintf("in %s", lv("X", 1)) else sprintf("at the mean of %s", comment_text(v$X$label))),
      sprintf("r2_other <- %s # R-squared of %s on the other predictors", r_code(pop$r2_other_predictors %||% 0), comment_text(v$X$label)),
      if (identical(v$X$type, "binary")) {
        sprintf("predictor <- list(dist = \"bernoulli\", prob = %s) # proportion in %s", r_code(pop$x_prob %||% 0.5), lv("X", 2))
      } else {
        sprintf("predictor <- list(dist = \"normal\", mean = 0, sd = 1) # %s, standardised", comment_text(v$X$label))
      },
      alt_line
    ),
    single_predictor_count = c(
      sprintf("rate_ratio <- %s # %s", r_code(pop$rate_ratio), if (identical(v$X$type, "binary")) {
        sprintf("multiple of the rate of %s in %s against %s", comment_text(v$Y$label), lv("X", 2), lv("X", 1))
      } else {
        sprintf("multiple of the rate of %s per SD of %s", comment_text(v$Y$label), comment_text(v$X$label))
      }),
      sprintf("base_rate <- %s # expected %s per unit of exposure %s", r_code(pop$base_rate), comment_text(v$Y$label),
        if (identical(v$X$type, "binary")) sprintf("in %s", lv("X", 1)) else sprintf("at the mean of %s", comment_text(v$X$label))),
      sprintf("mean_exposure <- %s # mean exposure per person", r_code(pop$mean_exposure %||% 1)),
      sprintf("r2_other <- %s # R-squared of %s on the other predictors", r_code(pop$r2_other_predictors %||% 0), comment_text(v$X$label)),
      if (identical(v$X$type, "binary")) {
        sprintf("predictor <- list(dist = \"bernoulli\", prob = %s) # proportion in %s", r_code(pop$x_prob %||% 0.5), lv("X", 2))
      } else {
        sprintf("predictor <- list(dist = \"normal\", mean = 0, sd = 1) # %s, standardised", comment_text(v$X$label))
      },
      alt_line
    ),
    r2_zero = c(
      sprintf("r2 <- %s # expected R-squared of the model", r_code(pop$r2)),
      sprintf("predictors <- %s # number of predictors", r_code(pop$predictors))
    ),
    single_coefficient = c(
      sprintf("partial_r2 <- %s # partial R-squared of %s: the share of the variance the other predictors leave that it explains",
        r_code(pop$partial_r2), comment_text(spec$variables$X$label %||% "the predictor")),
      sprintf("predictors_total <- %s # predictors in the model, counting the tested one", r_code(pop$predictors_total)),
      "# The test of one coefficient is the F test of one predictor (k.tested = 1),",
      "# the square of its t test. pwrss turns r.squared.change into Cohen's f^2 as",
      "# r / (1 - r), so passing the partial R-squared gives f^2 = partial_r2 / (1 - partial_r2)."
    ),
    r2_increase = c(
      sprintf("r2_full <- %s # expected R-squared with every predictor", r_code(pop$r2_full)),
      sprintf("r2_reduced <- %s # expected R-squared without the tested set", r_code(pop$r2_reduced)),
      sprintf("predictors_total <- %s # predictors in the full model", r_code(pop$predictors_total)),
      sprintf("predictors_tested <- %s # predictors in the tested set", r_code(pop$predictors_tested)),
      "# pwrss turns r.squared.change into Cohen's f^2 as r / (1 - r). Passing the",
      "# partial R-squared of the tested set gives f^2 = (r2_full - r2_reduced) / (1 - r2_full),",
      "# Cohen's f^2 for an increase in R-squared.",
      "partial_r2 <- (r2_full - r2_reduced) / (1 - r2_reduced)"
    )
  )
}

pwrss_script_call_lines <- function(spec, inputs) {
  call <- switch(
    pwrss_key(spec),
    interaction_r2_change = list(head = "power.f.regression( # F test of the interaction term, a fixed model as in G*Power", args = c(
      "r.squared.change = partial", "k.total = 3 # X, W and their product", "k.tested = 1 # the product",
      "n = n_total", "alpha = alpha", "verbose = 0"
    )),
    anova_eta_squared = if (isTRUE(eta_anova_design(spec)$mixed)) {
      list(head = "power.f.mixed.anova( # repeated-measures or mixed ANOVA from its partial eta-squared", args = c(
        if (identical(spec$population$eta_source, "published")) "eta.squared = eta_for_pwrss(n_total)" else "eta.squared = eta_squared", "factor.levels = levels", "rho.within = rho",
        "epsilon = 1 # sphericity assumed", "n.total = n_total # equal groups", "alpha = alpha",
        "effect = effect", "ceil.n = FALSE", "verbose = 0"
      ))
    } else {
      list(head = "power.f.ancova( # the ANOVA F test from its partial eta-squared", args = c(
        "eta.squared = eta_squared", "factor.levels = levels",
        if (!is.null(eta_anova_design(spec)$target)) "target.effect = effect",
        if (is.null(spec$population$covariates)) "k.covariates = 0 # no covariates" else "k.covariates = covariates",
        "n.total = n_total # equal groups", "alpha = alpha",
        "ceil.n = FALSE", "verbose = 0"
      ))
    },
    one_proportion = list(head = "power.exact.oneprop( # exact binomial test", args = c(
      "prob = p", "null.prob = p0", "n = n_total", "alpha = alpha",
      "alternative = alternative", "verbose = 0"
    )),
    mcnemar = list(head = "power.exact.mcnemar(", args = c(
      "prob10 = p_second_only # pwrss: success after (or in case), failure before (or in control)",
      "prob01 = p_first_only", "n.paired = n_total # number of people (pairs)",
      "alpha = alpha", "alternative = alternative",
      "method = \"exact\" # McNemar's exact test", "ceil.n = FALSE", "verbose = 0"
    )),
    independent_t = list(
      pre = c(
        "  n_group1 <- round(n_total / (1 + allocation_ratio))",
        "  n_group2 <- n_total - n_group1",
        if (unequal_welch(spec)) c(
          "  # Change units to pwrss's sample-size-weighted pooled SD at this allocation.",
          "  d_backend <- suppressWarnings(means.to.d(mu1 = d, mu2 = 0, sd1 = sds[1], sd2 = sds[2],",
          "    n.ratio = n_group1 / n_group2, n2 = n_group2, verbose = 0))$d")
      ),
      head = "power.t.welch( # Welch's t-test (unequal variances allowed)",
      args = c(
        if (unequal_welch(spec)) "d = d_backend" else "d = d",
        if (unequal_welch(spec)) "var.ratio = sds[1]^2 / sds[2]^2" else "var.ratio = 1 # equal population SDs",
        "n.ratio = n_group1 / n_group2 # pwrss's n.ratio is n1 / n2", "n2 = n_group2",
        "alpha = alpha", "alternative = alternative",
        "claim.basis = \"md.pval\" # power of the test of the mean difference", "verbose = 0"
      )
    ),
    two_proportions = list(
      pre = c(
        "  n_group1 <- round(n_total / (1 + allocation_ratio))",
        "  n_group2 <- n_total - n_group1"
      ),
      head = "power.exact.fisher( # Fisher's exact test",
      args = c(
        "prob1 = p1", "prob2 = p2", "n.ratio = n_group1 / n_group2 # pwrss's n.ratio is n1 / n2",
        "n2 = n_group2", "alpha = alpha", "alternative = alternative",
        "method = \"exact\"", "ceil.n = FALSE", "verbose = 0"
      )
    ),
    two_correlations = list(
      pre = c(
        "  n_group1 <- round(n_total / (1 + allocation_ratio))",
        "  n_group2 <- n_total - n_group1"
      ),
      head = "power.z.twocors( # Fisher's z test of two independent correlations",
      args = c(
        "rho1 = r1", "rho2 = r2", "n.ratio = n_group1 / n_group2 # pwrss's n.ratio is n1 / n2",
        "n2 = n_group2", "alpha = alpha", "alternative = alternative", "ceil.n = FALSE", "verbose = 0"
      )
    ),
    overlapping_correlations = list(
      head = "power.z.twocors.steiger( # Steiger's z test, two correlations sharing a variable",
      args = c(
        "rho12 = r_X_Y # pwrss numbers the variables: 1 = X (shared), 2 = Y, 3 = Z",
        "rho13 = r_X_Z", "rho23 = r_Y_Z", "n = n_total", "alpha = alpha", "alternative = alternative",
        "pooled = FALSE # as G*Power (powerkit's Departure 12; pwrss's default is TRUE)",
        "common.index = TRUE", "ceil.n = FALSE", "verbose = 0"
      )
    ),
    nonoverlapping_correlations = list(
      head = "power.z.twocors.steiger( # Steiger's z test, two correlations with no variable in common",
      args = c(
        "rho12 = r_X1_Y1 # pwrss numbers the variables: 1 = X1, 2 = Y1, 3 = X2, 4 = Y2",
        "rho34 = r_X2_Y2", "rho13 = r_X1_X2", "rho14 = r_X1_Y2", "rho23 = r_Y1_X2", "rho24 = r_Y1_Y2",
        "n = n_total", "alpha = alpha", "alternative = alternative",
        "pooled = FALSE # as G*Power (powerkit's Departure 12; pwrss's default is TRUE)",
        "common.index = FALSE", "ceil.n = FALSE", "verbose = 0"
      )
    ),
    chi_square_gof = list(head = "power.chisq.gof( # chi-square goodness-of-fit test", args = c(
      "w = effect$w", "df = effect$df", "n = n_total", "alpha = alpha", "ceil.n = FALSE", "verbose = 0"
    )),
    oneway_contrast = list(head = "power.t.contrasts( # t test of a planned comparison", args = c(
      "mu.vector = means", "sd.vector = rep(sd, groups) # the same SD in every group",
      "n.vector = rep(n_total / groups, groups) # equal groups",
      "contrast.matrix = matrix(weights, nrow = 1)",
      "r.squared = 0", "k.covariates = 0 # no covariates (pwrss defaults this to 1)",
      "alpha = alpha", "adjust.alpha = \"none\"", "ceil.n = FALSE", "verbose = 0"
    )),
    oneway_ancova = list(head = "power.f.ancova.shieh( # one-way ANCOVA, Shieh's method", args = c(
      "mu.vector = means", "sd.vector = rep(sd, groups) # the same SD in every group",
      "n.vector = rep(n_total / groups, groups) # equal groups", "r.squared = r2_covariates",
      "k.covariates = covariates", "alpha = alpha", "ceil.n = FALSE", "verbose = 0"
    )),
    factorial_ancova = list(head = "power.f.ancova.shieh( # two-way ANCOVA, Shieh's method", args = c(
      "mu.vector = means", "sd.vector = rep(sd, prod(levels)) # the same SD in every cell",
      "n.vector = rep(n_total / prod(levels), prod(levels)) # equal cells", "factor.levels = levels",
      "r.squared = r2_covariates", "k.covariates = covariates", "contrast.matrix = contrasts",
      "alpha = alpha", "ceil.n = FALSE", "verbose = 0"
    )),
    single_predictor = list(head = "power.z.logistic( # Wald z test of the predictor in logistic regression", args = c(
      "base.prob = base_prob", "odds.ratio = odds_ratio", "n = n_total",
      "r.squared.predictor = r2_other", "alpha = alpha", "alternative = alternative",
      "method = \"demidenko(vc)\" # Demidenko (2007) with variance correction, pwrss's default",
      "distribution = predictor", "ceil.n = FALSE", "verbose = 0"
    )),
    single_predictor_count = list(head = "power.z.poisson( # Wald z test of the predictor in Poisson regression", args = c(
      "base.rate = base_rate", "rate.ratio = rate_ratio", "n = n_total",
      "mean.exposure = mean_exposure", "r.squared.predictor = r2_other",
      "alpha = alpha", "alternative = alternative",
      "method = \"demidenko(vc)\" # Demidenko's method with variance correction, pwrss's default",
      "distribution = predictor", "ceil.n = FALSE", "verbose = 0"
    )),
    r2_zero = list(head = "power.f.regression( # F test of R-squared", args = c(
      "r.squared.change = r2", "k.total = predictors", "k.tested = predictors",
      "n = n_total", "alpha = alpha", "verbose = 0"
    )),
    single_coefficient = list(head = "power.f.regression( # F test of one coefficient (its t test squared)", args = c(
      "r.squared.change = partial_r2", "k.total = predictors_total", "k.tested = 1",
      "n = n_total", "alpha = alpha", "verbose = 0"
    )),
    r2_increase = list(head = "power.f.regression( # F test of the R-squared increase", args = c(
      "r.squared.change = partial_r2", "k.total = predictors_total", "k.tested = predictors_tested",
      "n = n_total", "alpha = alpha", "verbose = 0"
    ))
  )
  c(call$pre, paste0("  ", call$head), paste0("    ", ensure_commas(call$args)), "  )$power")
}

pwrss_goal_section <- function(spec, result) {
  if (identical(spec$goal$type, "sensitivity") && identical(spec$template, "independent_t")) {
    return(welch_sensitivity_section(spec, result))
  }
  if (spec$goal$type != "sample_size" || !isTRUE(pwrss_backend(spec)$sawtooth)) {
    return(pwr_goal_section(spec, result))
  }
  sawtooth_goal_section(spec, result)
}

# Welch's smallest detectable effect, found as powerkit finds it
# (welch_sensitivity()): d searched with pwrss's own power, the spread
# ratio and the group sizes kept.
welch_sensitivity_section <- function(spec, result) {
  s <- result$sensitivity
  c(
    "# Smallest detectable effect ----",
    "# pwrss's power.t.welch() has no option to solve for d, so powerkit searches",
    "# d with the same power call (power_at() above), keeping the spread ratio",
    "# and the group sizes; the sign is the direction of the effect you specified.",
    sprintf("direction <- %s", r_code(if (isTRUE(s$effect < 0)) -1 else 1)),
    "power_with_d <- function(x) {",
    "  d <<- direction * x",
    "  power_at(n_total)",
    "}",
    "found <- uniroot(function(x) power_with_d(x) - target_power, lower = 1e-6, upper = 10, tol = 1e-10)$root",
    "d <- direction * found",
    "power <- power_at(n_total)",
    sprintf(
      "cat(sprintf(\"Smallest detectable effect: %s = %%.4g (power %%.4f)\\n\", d, power))",
      gsub("%", "%%", gsub("\"", "'", comment_text(s$effect_description)), fixed = TRUE)
    ),
    "",
    "reproduced <- list(effect = d, power = power)",
    sprintf("powerkit_result <- list(effect = %s, power = %s)", r_code(s$effect), r_code(s$power)),
    ""
  )
}

# The required-n section for a test whose exact power goes up and down
# with n (pwrss's tests of counts, and the binomial Bayes factor).
sawtooth_goal_section <- function(spec, result) {
  # Exact tests of counts: power goes up and down with n, so the script
  # checks every n up to powerkit's, as search_n_exact() does.
  step <- valid_n_step(spec)
  c(
    "# Required n ----",
    "# For an exact test of counts, power goes up and down as n grows, so",
    "# powerkit takes the smallest n whose power reaches the target, checking",
    "# every n from the smallest it can calculate.",
    sprintf("smallest <- %s # the smallest n powerkit calculates for this test", r_code(step * ceiling(minimum_n(spec) / step))),
    sprintf(
      "all_sizes <- seq(smallest, %s, by = %s) # up to powerkit's answer, in valid steps",
      r_code(result$n_required$n), r_code(step)
    ),
    "all_power <- vapply(all_sizes, power_at, numeric(1))",
    "n_required <- all_sizes[which(all_power >= target_power)[1]]",
    sprintf("sizes <- %s", r_code(result$curve$n)),
    "power <- vapply(sizes, power_at, numeric(1))",
    "print(data.frame(n = sizes, power = power))",
    "cat(sprintf(\"Required n: %s\\n\", n_required))",
    "",
    "reproduced <- list(n = n_required, power = power)",
    sprintf(
      "powerkit_result <- list(n = %s, power = %s)",
      r_code(result$n_required$n), r_code(result$curve$power)
    ),
    ""
  )
}
