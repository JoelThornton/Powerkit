# Scripts for the tests pwrss computes by formula (backend-pwrss.R): one
# proportion, McNemar's test, Welch's t-test by formula, R-squared in
# multiple regression, Fisher's exact test, goodness of fit, two
# correlations and ANCOVA. Each passes the same values to pwrss
# as powerkit does (pwrss_inputs()).

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
    spec$template,
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
      sprintf("d <- %s # Cohen's d: (mean of %s minus mean of %s) / pooled SD", r_code(pop$d), lv("X", 2), lv("X", 1)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(spec$options$allocation_ratio %||% 1), lv("X", 2), lv("X", 1)
      ),
      alt_line
    ),
    two_proportions = c(
      sprintf("p1 <- %s # proportion with %s = %s in %s", r_code(pop$p1), comment_text(v$Y$label), lv("Y", 2), lv("X", 1)),
      sprintf("p2 <- %s # proportion with %s = %s in %s", r_code(pop$p2), comment_text(v$Y$label), lv("Y", 2), lv("X", 2)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(spec$options$allocation_ratio %||% 1), lv("X", 2), lv("X", 1)
      ),
      alt_line
    ),
    two_correlations = c(
      sprintf("r1 <- %s # correlation of %s with %s in %s", r_code(pop$r1), comment_text(v$X$label), comment_text(v$Y$label), lv("G", 1)),
      sprintf("r2 <- %s # correlation of %s with %s in %s", r_code(pop$r2), comment_text(v$X$label), comment_text(v$Y$label), lv("G", 2)),
      sprintf(
        "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
        r_code(spec$options$allocation_ratio %||% 1), lv("G", 2), lv("G", 1)
      ),
      alt_line
    ),
    chi_square_gof = c(
      sprintf("probabilities <- %s # expected proportion in each category: %s",
        r_code(as.numeric(unlist(pop$probabilities))), paste(comment_text(unlist(v$Y$levels)), collapse = ", ")),
      if (!is.null(pop$null_probabilities)) {
        sprintf("null_probabilities <- %s # the fixed proportions they are compared with", r_code(as.numeric(unlist(pop$null_probabilities))))
      },
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
    r2_zero = c(
      sprintf("r2 <- %s # expected R-squared of the model", r_code(pop$r2)),
      sprintf("predictors <- %s # number of predictors", r_code(pop$predictors))
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
    spec$template,
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
        "  n_group2 <- n_total - n_group1"
      ),
      head = "power.t.welch( # Welch's t-test (unequal variances allowed)",
      args = c(
        "d = d", "var.ratio = 1 # sd1^2 / sd2^2: the spec gives one pooled SD",
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
    r2_zero = list(head = "power.f.regression( # F test of R-squared", args = c(
      "r.squared.change = r2", "k.total = predictors", "k.tested = predictors",
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
  if (spec$goal$type != "sample_size" || !isTRUE(pwrss_backend(spec)$sawtooth)) {
    return(pwr_goal_section(spec, result))
  }
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
