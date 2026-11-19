# Backend adapter: the Bayes factor of an effect in a between-participants
# ANCOVA (one factor, or two crossed factors, adjusting for one or more
# covariates), simulated with Spower, via BayesFactor and bayestestR.
#
# The Bayes factor is JASP's for a Bayesian ANCOVA's effect. JASP fits the
# models with BayesFactor's linear-model Bayes factors (Rouder, Morey,
# Speckman & Province, 2012, the reference in anovaBF()'s help, which
# generalTestBF() extends to continuous covariates), with the covariates
# as ordinary model terms (they are not nuisance terms by default:
# jaspAnova's AncovaBayesian.qml, Formula, extraOptions "isNuisance"
# unchecked) and these priors (jaspAnova's
# inst/qml/common/bayesian/AdditionalOptions.qml): a Cauchy prior of scale
# 0.5 on the factors' standardised effects ("r scale fixed effects") and
# of scale 0.354 on the covariates' standardised slopes ("r scale
# covariates"). generalTestBF(whichModels = "withmain") fits every model
# that respects marginality (an interaction only with both main effects;
# each covariate in or out), and the effect's inclusion Bayes factor is
# taken across all models with uniform model priors, as JASP's Effects
# table gives it by default (docs/decisions.md, 4 November 2026), by
# bayestestR's bayesfactor_inclusion(); across matched models is the
# option (`target_test > inclusion`), as for the factorial ANOVA
# (backend-bayesfactor-factorial.R).
#
# Each simulated study has n people split equally across the cells (the
# ANCOVA card's design, as pwrss's power.f.ancova.shieh() assumes). The
# covariates are independent standard normal scores, as Shieh's method
# treats them (random, and unrelated to the groups, as randomisation makes
# them), each with the same slope, so that together they explain
# r2_covariates of the outcome's variance within a cell: the outcome is
# the cell's adjusted mean plus sd * sqrt(r2 / q) times each covariate's
# sum plus a normal error of SD sd * sqrt(1 - r2). Power is the share of
# studies whose inclusion Bayes factor reaches the threshold. Several of
# the models' Bayes factors are integrated by sampling, so each Bayes
# factor carries a small error of its own, part of the simulation's random
# error.

bfancova_templates <- c("oneway_ancova", "factorial_ancova")

bfancova_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "factorial_anova") && isTRUE(spec$template %in% bfancova_templates)
}

bfancova_defaults <- list(prior_scale = 0.5, prior_scale_covariates = 0.354, inclusion = "all_models")

bfancova_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  two <- identical(spec$template, "factorial_ancova")
  means <- if (two) {
    do.call(rbind, lapply(pop$means, function(row) as.numeric(unlist(row))))
  } else {
    matrix(as.numeric(unlist(pop$means)), ncol = 1)
  }
  list(
    means = means, two_factors = two,
    sd = as.numeric(unlist(pop$sd))[1],
    r2 = pop$r2_covariates, covariates = as.integer(pop$covariates),
    term = art_term(tt$effect %||% "main_effect_A"), effect = tt$effect %||% "main_effect_A",
    threshold = bayes_threshold(spec),
    prior_scale = tt$prior_scale %||% bfancova_defaults$prior_scale,
    prior_scale_covariates = tt$prior_scale_covariates %||% bfancova_defaults$prior_scale_covariates,
    inclusion = tt$inclusion %||% bfancova_defaults$inclusion
  )
}

# One study's data: n / cells people in each cell (cells row by row), q
# standard normal covariates, and the outcome.
bfancova_data <- function(n, means, sd, r2, q) {
  per_cell <- n / length(means)
  a <- rep(rep(seq_len(nrow(means)), each = ncol(means)), each = per_cell)
  b <- rep(rep(seq_len(ncol(means)), times = nrow(means)), each = per_cell)
  covs <- matrix(stats::rnorm(length(a) * q), ncol = q, dimnames = list(NULL, paste0("cov", seq_len(q))))
  y <- means[cbind(a, b)] + sd * sqrt(r2 / q) * rowSums(covs) + stats::rnorm(length(a), 0, sd * sqrt(1 - r2))
  data.frame(A = factor(a), B = factor(b), covs, y = y)
}

# The effect's log inclusion Bayes factor for one data set.
bfancova_log_bf <- function(data, term, prior_scale, prior_scale_covariates, inclusion) {
  covs <- grep("^cov", names(data), value = TRUE)
  factors <- if (length(unique(data$B)) > 1) "A * B" else "A"
  formula <- stats::as.formula(paste("y ~", factors, "+", paste(covs, collapse = " + ")))
  bf <- BayesFactor::generalTestBF(formula, data = data, whichModels = "withmain", rscaleFixed = prior_scale,
    rscaleCont = prior_scale_covariates, progress = FALSE)
  inc <- bayestestR::bayesfactor_inclusion(bf, match_models = identical(inclusion, "matched_models"))
  inc$log_BF[rownames(inc) == term]
}

# The experiment Spower runs: one study of n people. `outcome` "effect"
# returns whether the inclusion BF reaches the threshold, "null" whether
# its reciprocal does (strong evidence that the effect is absent).
p_bayes_ancova <- function(n, means, sd, r2, q, term, threshold, prior_scale, prior_scale_covariates, inclusion,
                           outcome = "effect") {
  data <- bfancova_data(n, means, sd, r2, q)
  log_bf <- bfancova_log_bf(data, term, prior_scale, prior_scale_covariates, inclusion)
  if (identical(outcome, "effect")) log_bf >= log(threshold) else log_bf <= -log(threshold)
}

bfancova_count <- function(inputs, n, nrep, seed, means = inputs$means, outcome = "effect") {
  args <- list(n = n, means = means, sd = inputs$sd, r2 = inputs$r2, q = inputs$covariates, term = inputs$term,
    threshold = inputs$threshold, prior_scale = inputs$prior_scale,
    prior_scale_covariates = inputs$prior_scale_covariates, inclusion = inputs$inclusion, outcome = outcome)
  result <- spower_eval(as.name("p_bayes_ancova"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

bfancova_backend <- function(spec, seed = NULL) {
  inputs <- bfancova_inputs(spec)
  step <- length(inputs$means)
  list(
    name = "BayesFactor",
    packages = c("BayesFactor", "bayestestR", "Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "Spower::Spower(p_bayes_ancova()) (BayesFactor::generalTestBF() and bayestestR::bayesfactor_inclusion() on each simulated study)"),
    n_step = step,
    exact_min_n = step * ceiling(max(2 * step + inputs$covariates + 2, minimum_n(spec)) / step),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bfancova_count(inputs, n, k, chunk_seed))
    },
    null_side = function(n, nrep, seed) bfancova_null_side(inputs, n, nrep, seed),
    sensitivity = NULL,
    check_run = function() bfancova_check_run(spec, inputs, seed)
  )
}

# The no-effect side: the cell means with the tested effect removed
# (bffactorial_null_means()), the covariates unchanged.
bfancova_null_side <- function(inputs, n, nrep, seed) {
  null <- bffactorial_null_means(inputs$means, inputs$term)
  list(
    evidence_for_null = bfancova_count(inputs, n, nrep, seed + 1L, means = null, outcome = "null") / nrep,
    misleading_evidence = bfancova_count(inputs, n, nrep, seed + 2L, means = null) / nrep,
    null_nrep = nrep
  )
}

bfancova_effect_words <- function(inputs) {
  if (!inputs$two_factors) return("the group effect")
  bffactorial_effect_words(inputs$term)
}

bfancova_hypotheses_words <- function(inputs) {
  sprintf("the models with %s against those without, adjusting for %s (its inclusion Bayes factor, %s)",
    bfancova_effect_words(inputs), if (inputs$covariates == 1) "the covariate" else sprintf("the %d covariates", inputs$covariates),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models")
}

# Check run: a large study drawn as the experiment draws them recovers the
# adjusted cell means, the SD before adjusting and the covariates'
# R-squared within cells, and generalTestBF() with
# bayesfactor_inclusion() gives a smaller study a Bayes factor for the
# effect.
bfancova_check_run <- function(spec, inputs, seed) {
  cells <- length(inputs$means)
  n <- cells * ceiling(check_run_n() / cells)
  data <- with_seed(seed %||% 1L, bfancova_data(n, inputs$means, inputs$sd, inputs$r2, inputs$covariates))
  covs <- grep("^cov", names(data), value = TRUE)
  # The adjusted cell means: one coefficient per cell (cells row by row),
  # with the covariates in the model.
  data$cell <- factor((as.integer(data$A) - 1L) * ncol(inputs$means) + as.integer(data$B))
  fit <- stats::lm(stats::as.formula(paste("y ~ cell - 1 +", paste(covs, collapse = " + "))), data = data)
  adjusted <- stats::coef(fit)[paste0("cell", seq_len(cells))]
  observed <- tapply(data$y, list(data$A, data$B), mean)
  centred <- data$y - observed[cbind(as.integer(data$A), as.integer(data$B))]
  within_sd <- stats::sd(centred)
  r2 <- summary(stats::lm(centred ~ as.matrix(data[covs])))$r.squared
  small <- cells * ceiling(min(n, 2000) / cells)
  sample_rows <- with_seed(seed %||% 1L, bfancova_data(small, inputs$means, inputs$sd, inputs$r2, inputs$covariates))
  log_bf <- call_backend("BayesFactor", with_seed(seed %||% 1L, bfancova_log_bf(sample_rows, inputs$term, inputs$prior_scale,
    inputs$prior_scale_covariates, inputs$inclusion)))
  effect_size <- max(abs(inputs$means - bffactorial_null_means(inputs$means, inputs$term))) / (inputs$sd * sqrt(1 - inputs$r2))
  se_mean <- inputs$sd * sqrt(1 - inputs$r2) * sqrt(cells / n)
  data.frame(
    parameter = c("Largest difference between a simulated adjusted cell mean and the specified mean", "SD within cells, before adjusting",
      "R-squared of the covariates within cells",
      sprintf("Inclusion BF of a study of %s people for %s is far above the threshold (log BF %s)",
        format(small, big.mark = ","), bfancova_effect_words(inputs), format(round(log_bf, 1)))),
    specified = c(0, inputs$sd, inputs$r2, log(inputs$threshold)),
    recovered = c(max(abs(adjusted - as.vector(t(inputs$means)))), within_sd, r2, log_bf),
    ok = c(max(abs(adjusted - as.vector(t(inputs$means)))) < 5 * se_mean,
      abs(within_sd - inputs$sd) < 5 * inputs$sd / sqrt(2 * n) + 0.01 * inputs$sd,
      abs(r2 - inputs$r2) < 0.02,
      effect_size < 0.2 || log_bf > log(inputs$threshold))
  )
}

check_bayes_ancova <- function(spec) {
  problems <- character()
  pop <- spec$population
  tt <- spec$target_test
  if (identical(pop$metric, "eta_squared")) {
    problems <- c(problems, "The Bayes factor ANCOVA is simulated from the adjusted means, the SD and the covariates' R-squared; give them instead of 'population > eta_squared' (metric 'raw' or 'standardised').")
  }
  if (!identical(tt$alternative %||% "two_sided", "two_sided")) {
    problems <- c(problems, "The Bayes factor of an ANCOVA effect has no direction; remove 'target_test > alternative'.")
  }
  if (!is.null(pop$effect_sd)) {
    problems <- c(problems, "'population > effect_sd' isn't used by the Bayes factor ANCOVA: the effect is the adjusted means given.")
  }
  if (identical(spec$options$method, "exact")) {
    problems <- c(problems, "The Bayes factor of an ANCOVA effect is simulated; remove 'options > method'.")
  }
  if (!is.null(tt$prior_width) || !is.null(tt$prior_a) || !is.null(tt$prior_b) || !is.null(tt$one_sided_null) ||
    !is.null(tt$prior_concentration) || !is.null(tt$sampling_plan)) {
    problems <- c(problems, "The Bayes factor ANCOVA has Cauchy priors on the effects and the covariates' slopes, set by 'target_test > prior_scale' and 'prior_scale_covariates'; remove the other prior settings.")
  }
  problems
}

# The R script: the same simulation with Spower, generalTestBF() and
# bayesfactor_inclusion(), in powerkit's batches, so it reproduces the
# run's counts.
bfancova_script <- function(spec, result) {
  inputs <- bfancova_inputs(spec)
  goal <- spec$goal
  prov <- result$provenance
  c(
    script_header(spec, result, "BayesFactor", "Spower::Spower, BayesFactor::generalTestBF, bayestestR::bayesfactor_inclusion"),
    "library(Spower)",
    "library(BayesFactor)",
    "library(bayestestR)",
    "",
    "# Inputs ----",
    sprintf("means <- matrix(%s, nrow = %d, byrow = TRUE) # adjusted cell means: rows A's levels, columns B's (one column for one factor)",
      r_code(as.vector(t(inputs$means))), nrow(inputs$means)),
    sprintf("sd <- %s # the SD within each cell, before adjusting for the covariates", r_code(inputs$sd)),
    sprintf("r2 <- %s # the share of the outcome's variance within a cell the covariates explain", r_code(inputs$r2)),
    sprintf("q <- %s # the number of covariates", r_code(inputs$covariates)),
    sprintf("term <- %s # %s", r_code(inputs$term), bfancova_effect_words(inputs)),
    sprintf("threshold <- %s # evidence threshold: an inclusion BF at least this", r_code(inputs$threshold)),
    sprintf("r_scale <- %s # Cauchy prior scale on the factors' standardised effects (the package default, 0.5)", r_code(inputs$prior_scale)),
    sprintf("r_scale_covariates <- %s # Cauchy prior scale on the covariates' standardised slopes (the package default, 0.354)", r_code(inputs$prior_scale_covariates)),
    sprintf("matched <- %s # FALSE: across all models (JASP's default); TRUE: across matched models", r_code(identical(inputs$inclusion, "matched_models"))),
    switch(goal$type,
      sample_size = sprintf("target_power <- %s # target probability that the inclusion BF reaches the threshold", r_code(goal$power)),
      power = sprintf("n_total <- %s # total sample size (equal cells; every participant analysed)", r_code(goal$n))),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# One simulated study: equal cells, q standard normal covariates that",
    "# together explain r2 of the variance within a cell, then the effect's",
    "# inclusion Bayes factor over the models that respect marginality.",
    "p_bayes_ancova <- function(n, means, sd, r2, q, term, threshold, r_scale, r_scale_covariates, matched) {",
    "  per_cell <- n / length(means)",
    "  a <- rep(rep(seq_len(nrow(means)), each = ncol(means)), each = per_cell)",
    "  b <- rep(rep(seq_len(ncol(means)), times = nrow(means)), each = per_cell)",
    "  covs <- matrix(rnorm(length(a) * q), ncol = q, dimnames = list(NULL, paste0(\"cov\", seq_len(q))))",
    "  y <- means[cbind(a, b)] + sd * sqrt(r2 / q) * rowSums(covs) + rnorm(length(a), 0, sd * sqrt(1 - r2))",
    "  data <- data.frame(A = factor(a), B = factor(b), covs, y = y)",
    "  factors <- if (ncol(means) > 1) \"A * B\" else \"A\"",
    "  formula <- as.formula(paste(\"y ~\", factors, \"+\", paste(colnames(covs), collapse = \" + \")))",
    "  bf <- generalTestBF(formula, data = data, whichModels = \"withmain\", rscaleFixed = r_scale,",
    "    rscaleCont = r_scale_covariates, progress = FALSE)",
    "  inc <- bayesfactor_inclusion(bf, match_models = matched)",
    "  inc$log_BF[rownames(inc) == term] >= log(threshold)",
    "}",
    "",
    "# One batch: studies reaching the threshold, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  # Spower reads its experiment's arguments unevaluated, so each is a name.",
    "  result <- Spower(p_bayes_ancova(n = batch_n, means = means, sd = sd, r2 = r2, q = q, term = term,",
    "    threshold = threshold, r_scale = r_scale, r_scale_covariates = r_scale_covariates, matched = matched),",
    "    replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, length(inputs$means))
  )
}

bfancova_design_description <- function(spec, label, levels) {
  inputs <- bfancova_inputs(spec)
  layout <- if (inputs$two_factors) {
    sprintf("a %d x %d between-participants ANCOVA of %s by %s (%s) and %s (%s)", nrow(inputs$means), ncol(inputs$means), label("Y"),
      label("A"), paste(levels("A"), collapse = ", "), label("B"), paste(levels("B"), collapse = ", "))
  } else {
    sprintf("a one-way ANCOVA of %s by %s (%s)", label("Y"), label("A"), paste(levels("A"), collapse = ", "))
  }
  effect <- if (inputs$two_factors) {
    sub("of A", paste("of", label("A")), sub("of B", paste("of", label("B")), bffactorial_effect_words(inputs$term)))
  } else {
    sprintf("the effect of %s", label("A"))
  }
  sprintf(
    "Bayes factor of %s in %s, adjusting for %s: the inclusion Bayes factor %s (BayesFactor's generalTestBF(), r scale %s on the effects and %s on the covariates' slopes, models respecting marginality); evidence at the threshold is an inclusion BF of at least %s",
    effect, layout, if (inputs$covariates == 1) "one covariate" else sprintf("%d covariates", inputs$covariates),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models",
    format_number(inputs$prior_scale), format_number(inputs$prior_scale_covariates), format_number(inputs$threshold)
  )
}
