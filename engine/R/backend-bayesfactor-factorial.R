# Backend adapter: the Bayes factor of an effect in a two-factor
# between-participants ANOVA (2 x 2, or a x b), simulated with Spower, via
# BayesFactor and bayestestR.
#
# The Bayes factor is JASP's for a Bayesian ANOVA's effect: BayesFactor's
# anovaBF() (Rouder, Morey, Speckman & Province, 2012, the reference in its
# help) fits every model that respects marginality (whichModels =
# "withmain": an interaction only with both main effects), with a Cauchy
# prior of scale r on the standardised effects (JASP's r scale for fixed
# effects, 0.5; jaspAnova's AdditionalOptions.qml), and the effect's
# inclusion Bayes factor is taken across all models with uniform model
# priors, as JASP's Effects table gives it by default (jaspAnova's
# DefaultOptions.qml, effectsType "allModels"; docs/decisions.md,
# 4 November 2026), by bayestestR's bayesfactor_inclusion(); the
# comparison across matched models is the option (`target_test >
# inclusion` "matched_models"). Each simulated study draws normal scores
# with the cells' means and one SD, n times each cell's share; power is the
# share of studies whose inclusion Bayes factor reaches the threshold.
# anovaBF() integrates by sampling, so each Bayes factor carries a small
# error of its own (under 2% here), part of the simulation's random error.
#
# Repeated measures (5 November 2026): with a within-participants factor
# (one-way and two-factor within, 2 x 2 and larger mixed designs) each
# person's scores share their own level, the one correlation r of the spec
# between any two of them (a random intercept, as JASP's repeated-measures
# ANOVA fits it), and anovaBF() takes the participants as a random factor
# (whichRandom, with JASP's r scale of 1 for random effects; jaspAnova's
# AdditionalOptions.qml). About 0.8 s per simulated study, so in the app
# these take the preview and R script route (forms.yaml, simulations).

bffactorial_between_templates <- c("2x2_between", "factorial_between")
bffactorial_within_templates <- c("oneway_within", "factorial_within", "2x2_mixed", "mixed")

bffactorial_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "factorial_anova") &&
    isTRUE(spec$template %in% c(bffactorial_between_templates, bffactorial_within_templates))
}

bffactorial_defaults <- list(prior_scale = 0.5, prior_scale_random = 1, inclusion = "all_models")

# The design's layout: the cell means as a matrix (rows A's levels; one
# column for a one-way design), which factors are within participants, and
# the correlation of a person's scores.
bffactorial_layout <- function(spec) {
  pop <- spec$population
  to_matrix <- function(x) do.call(rbind, lapply(x, function(row) as.numeric(unlist(row))))
  means <- if (identical(spec$template, "oneway_within")) matrix(as.numeric(unlist(pop$means)), ncol = 1) else to_matrix(pop$means)
  type <- function(v) spec$variables[[v]]$type %||% "between_factor"
  list(means = means, within = c(A = identical(type("A"), "within_factor"),
    B = !identical(spec$template, "oneway_within") && identical(type("B"), "within_factor")),
    r = as.numeric(unlist(pop$r %||% 0))[1], two_factors = !identical(spec$template, "oneway_within"))
}

bffactorial_inputs <- function(spec) {
  tt <- spec$target_test
  if (spec$template %in% bffactorial_within_templates) {
    lay <- bffactorial_layout(spec)
    return(list(
      means = lay$means, sd = as.numeric(unlist(spec$population$sd))[1], ratios = matrix(1, nrow(lay$means), ncol(lay$means)),
      within = lay$within, r = lay$r, two_factors = lay$two_factors,
      term = art_term(tt$effect), effect = tt$effect,
      threshold = bayes_threshold(spec),
      prior_scale = tt$prior_scale %||% bffactorial_defaults$prior_scale,
      inclusion = tt$inclusion %||% bffactorial_defaults$inclusion
    ))
  }
  cells <- art_cells(spec)
  list(
    within = c(A = FALSE, B = FALSE), r = 0, two_factors = TRUE,
    means = cells$means, sd = cells$sds[1, 1], ratios = cells$n.ratios,
    term = art_term(tt$effect), effect = tt$effect,
    threshold = bayes_threshold(spec),
    prior_scale = tt$prior_scale %||% bffactorial_defaults$prior_scale,
    inclusion = tt$inclusion %||% bffactorial_defaults$inclusion
  )
}

# The cell means with the tested effect removed (the no-effect side): the
# equal-weight decomposition of the cell means into grand mean, A's and B's
# deviations and the interaction, less the tested part.
bffactorial_null_means <- function(means, term) {
  if (ncol(means) == 1) return(matrix(mean(means), nrow(means), 1))
  grand <- mean(means)
  a <- rowMeans(means) - grand
  b <- colMeans(means) - grand
  ab <- means - grand - outer(a, b, "+")
  switch(term,
    A = means - matrix(a, nrow(means), ncol(means)),
    B = means - matrix(b, nrow(means), ncol(means), byrow = TRUE),
    "A:B" = means - ab)
}

# One study's data with a within-participants factor: n people (split
# equally across the between factor's levels, if any), each with a score in
# every within cell, sharing their own level (correlation r).
bffactorial_data_within <- function(n, means, sd, within, r) {
  a <- nrow(means)
  b <- ncol(means)
  cells <- expand.grid(B = seq_len(b), A = seq_len(a))
  if (within[["A"]]) {
    people <- n
    group <- rep(1L, n)
  } else {
    people <- n
    group <- rep(seq_len(a), each = n / a)
  }
  rows <- lapply(seq_len(people), function(i) {
    own <- if (within[["A"]]) cells else cells[cells$A == group[i], , drop = FALSE]
    data.frame(id = i, A = own$A, B = own$B)
  })
  data <- do.call(rbind, rows)
  level <- stats::rnorm(people, 0, sd * sqrt(r))
  data$y <- means[cbind(data$A, data$B)] + level[data$id] + stats::rnorm(nrow(data), 0, sd * sqrt(1 - r))
  data$id <- factor(data$id)
  data$A <- factor(data$A)
  data$B <- factor(data$B)
  data
}

# One study's data: n times each cell's share, the cells row by row.
bffactorial_data <- function(n, means, sd, ratios) {
  per_cell <- n * as.vector(t(ratios)) / sum(ratios)
  a <- rep(rep(seq_len(nrow(means)), each = ncol(means)), round(per_cell))
  b <- rep(rep(seq_len(ncol(means)), times = nrow(means)), round(per_cell))
  data.frame(A = factor(a), B = factor(b), y = means[cbind(a, b)] + stats::rnorm(length(a), 0, sd))
}

# The effect's log inclusion Bayes factor for one data set; with repeated
# measures the participants are a random factor in every model.
bffactorial_log_bf <- function(data, term, prior_scale, inclusion) {
  repeated <- "id" %in% names(data)
  two <- length(unique(data$B)) > 1
  formula <- if (repeated) {
    if (two) y ~ A * B + id else y ~ A + id
  } else {
    y ~ A * B
  }
  bf <- if (repeated) {
    BayesFactor::anovaBF(formula, data = data, whichRandom = "id", whichModels = "withmain", rscaleFixed = prior_scale,
      rscaleRandom = bffactorial_defaults$prior_scale_random, progress = FALSE)
  } else {
    BayesFactor::anovaBF(formula, data = data, whichModels = "withmain", rscaleFixed = prior_scale, progress = FALSE)
  }
  inc <- bayestestR::bayesfactor_inclusion(bf, match_models = identical(inclusion, "matched_models"))
  # bayestestR names the interaction "A:B"; its log_BF column is the
  # natural log.
  inc$log_BF[rownames(inc) == term]
}

# The experiment Spower runs: one study of n people. `outcome` "effect"
# returns whether the inclusion BF reaches the threshold, "null" whether
# its reciprocal does (strong evidence that the effect is absent).
p_bayes_factorial <- function(n, means, sd, ratios, term, threshold, prior_scale, inclusion, outcome = "effect",
                              within = c(A = FALSE, B = FALSE), r = 0) {
  data <- if (any(within)) bffactorial_data_within(n, means, sd, within, r) else bffactorial_data(n, means, sd, ratios)
  log_bf <- bffactorial_log_bf(data, term, prior_scale, inclusion)
  if (identical(outcome, "effect")) log_bf >= log(threshold) else log_bf <= -log(threshold)
}

bffactorial_count <- function(inputs, n, nrep, seed, means = inputs$means, outcome = "effect") {
  args <- list(n = n, means = means, sd = inputs$sd, ratios = inputs$ratios, term = inputs$term,
    threshold = inputs$threshold, prior_scale = inputs$prior_scale, inclusion = inputs$inclusion, outcome = outcome,
    within = inputs$within, r = inputs$r)
  result <- spower_eval(as.name("p_bayes_factorial"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

bffactorial_backend <- function(spec, seed = NULL) {
  inputs <- bffactorial_inputs(spec)
  step <- valid_n_step(spec)
  list(
    name = "BayesFactor",
    packages = c("BayesFactor", "bayestestR", "Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "Spower::Spower(p_bayes_factorial()) (BayesFactor::anovaBF() and bayestestR::bayesfactor_inclusion() on each simulated study)"),
    n_step = step,
    exact_min_n = step * ceiling(max(2 * length(inputs$means), minimum_n(spec)) / step),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bffactorial_count(inputs, n, k, chunk_seed))
    },
    null_side = function(n, nrep, seed) bffactorial_null_side(inputs, n, nrep, seed),
    sensitivity = NULL,
    check_run = function() bffactorial_check_run(spec, inputs, seed)
  )
}

bffactorial_null_side <- function(inputs, n, nrep, seed) {
  null <- bffactorial_null_means(inputs$means, inputs$term)
  list(
    evidence_for_null = bffactorial_count(inputs, n, nrep, seed + 1L, means = null, outcome = "null") / nrep,
    misleading_evidence = bffactorial_count(inputs, n, nrep, seed + 2L, means = null) / nrep,
    null_nrep = nrep
  )
}

bffactorial_effect_words <- function(term) {
  switch(term, A = "the main effect of A", B = "the main effect of B", "A:B" = "the A x B interaction")
}

bffactorial_hypotheses_words <- function(inputs) {
  sprintf("the models with %s against those without (its inclusion Bayes factor, %s)", bffactorial_effect_words(inputs$term),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models")
}

# Check run: a large study drawn as the experiment draws them recovers the
# cell means, the SD and the cell shares, and anovaBF() with
# bayesfactor_inclusion() gives that study a Bayes factor for the effect.
bffactorial_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  repeated <- any(inputs$within)
  if (repeated) {
    people <- n %/% (2 * length(inputs$means)) * nrow(inputs$means)
    data <- with_seed(seed %||% 1L, bffactorial_data_within(people, inputs$means, inputs$sd, inputs$within, inputs$r))
  } else {
    data <- with_seed(seed %||% 1L, bffactorial_data(n, inputs$means, inputs$sd, inputs$ratios))
  }
  observed <- tapply(data$y, list(data$A, data$B), mean)
  within_sd <- stats::sd(data$y - observed[cbind(as.integer(data$A), as.integer(data$B))])
  shares <- as.vector(t(table(data$A, data$B))) / nrow(data)
  expected_shares <- as.vector(t(inputs$ratios)) / sum(inputs$ratios)
  sample_rows <- if (repeated) {
    # 200 people spread over the whole sample, so every group is in it.
    ids <- unique(data$id)
    keep <- ids[unique(round(seq(1, length(ids), length.out = min(length(ids), 200))))]
    data[data$id %in% keep, , drop = FALSE]
  } else {
    data[with_seed(seed %||% 1L, sample.int(nrow(data), min(nrow(data), 4000))), ]
  }
  log_bf <- call_backend("BayesFactor", with_seed(seed %||% 1L, bffactorial_log_bf(droplevels(sample_rows), inputs$term, inputs$prior_scale, inputs$inclusion)))
  effect_size <- max(abs(inputs$means - bffactorial_null_means(inputs$means, inputs$term))) / inputs$sd
  rows <- data.frame(
    parameter = c("Largest difference between a simulated cell mean and the specified mean", "SD within cells",
      if (!repeated) "Largest difference between a cell's simulated share and its specified share",
      sprintf("Inclusion BF of a large study (%s) for %s is far above the threshold (log BF %s)",
        if (repeated) "200 people" else "4,000 people", bffactorial_effect_words(inputs$term), format(round(log_bf, 1)))),
    specified = c(0, inputs$sd, if (!repeated) 0, log(inputs$threshold)),
    recovered = c(max(abs(observed - inputs$means), na.rm = TRUE), within_sd, if (!repeated) max(abs(shares - expected_shares)), log_bf),
    ok = c(max(abs(observed - inputs$means), na.rm = TRUE) < 5 * inputs$sd * sqrt(length(inputs$means) / nrow(data)),
      abs(within_sd - inputs$sd) < 5 * inputs$sd / sqrt(2 * nrow(data)) + 0.01 * inputs$sd,
      if (!repeated) max(abs(shares - expected_shares)) < 1e-3,
      effect_size < 0.2 || log_bf > log(inputs$threshold))
  )
  if (repeated) {
    # The correlation of a person's scores in two within cells.
    # Two cells the first person has a score in (in a mixed design, cells
    # of their own group), and everyone who has both.
    data$cell <- interaction(data$A, data$B, drop = TRUE)
    first_two <- as.character(data$cell[data$id == data$id[1]])[1:2]
    y1 <- data$y[data$cell == first_two[1]]
    y2 <- data$y[data$cell == first_two[2]]
    id1 <- data$id[data$cell == first_two[1]]
    id2 <- data$id[data$cell == first_two[2]]
    common <- intersect(id1, id2)
    rec <- stats::cor(y1[match(common, id1)], y2[match(common, id2)])
    rows <- rbind(rows, data.frame(parameter = "Correlation of a person's scores in two cells", specified = inputs$r, recovered = rec,
      ok = abs(atanh(rec) - atanh(inputs$r)) <= 5 / sqrt(length(common) - 3)))
  }
  rows
}

check_bayes_factorial <- function(spec) {
  problems <- character()
  pop <- spec$population
  tt <- spec$target_test
  if (length(unlist(pop$sd)) != 1) {
    problems <- c(problems, "The Bayes factor ANOVA takes one SD for every cell ('population > sd'), as JASP's Bayesian ANOVA assumes.")
  }
  if (!identical(tt$alternative %||% "two_sided", "two_sided")) {
    problems <- c(problems, "The Bayes factor of an ANOVA effect has no direction; remove 'target_test > alternative'.")
  }
  if (!is.null(pop$effect_sd)) {
    problems <- c(problems, "'population > effect_sd' isn't used by the Bayes factor ANOVA: the effect is the cell means given.")
  }
  if (identical(spec$options$method, "exact")) {
    problems <- c(problems, "The Bayes factor of an ANOVA effect is simulated; remove 'options > method'.")
  }
  if (spec$template %in% bffactorial_within_templates) {
    r <- as.numeric(unlist(pop$r %||% NA))
    if (length(r) != 1 || is.na(r) || r < 0) {
      problems <- c(problems, "The Bayes factor with repeated measures takes one correlation between a person's scores ('population > r'), 0 or more, as JASP's model of a level for each person assumes.")
    }
    if (!is.null(spec$options$group_ratio)) {
      problems <- c(problems, "The Bayes factor with repeated measures is calculated for groups of equal size; remove 'options > group_ratio'.")
    }
    if (!is.null(tt$correction) && !identical(tt$correction, "none")) {
      problems <- c(problems, "A sphericity correction belongs to the F test; remove 'target_test > correction' for the Bayes factor.")
    }
  }
  problems
}

# The R script: the same simulation with Spower, anovaBF() and
# bayesfactor_inclusion(), in powerkit's batches, so it reproduces the
# run's counts.
bffactorial_script <- function(spec, result) {
  inputs <- bffactorial_inputs(spec)
  goal <- spec$goal
  prov <- result$provenance
  c(
    script_header(spec, result, "BayesFactor", "Spower::Spower, BayesFactor::anovaBF, bayestestR::bayesfactor_inclusion"),
    "library(Spower)",
    "library(BayesFactor)",
    "library(bayestestR)",
    "",
    "# Inputs ----",
    sprintf("means <- matrix(%s, nrow = %d, byrow = TRUE) # cell means: rows A's levels, columns B's", r_code(as.vector(t(inputs$means))), nrow(inputs$means)),
    sprintf("sd <- %s # the SD within each cell", r_code(inputs$sd)),
    sprintf("ratios <- matrix(%s, nrow = %d, byrow = TRUE) # each cell's share of the sample", r_code(as.vector(t(inputs$ratios))), nrow(inputs$ratios)),
    sprintf("term <- %s # %s", r_code(inputs$term), bffactorial_effect_words(inputs$term)),
    sprintf("threshold <- %s # strong evidence: an inclusion BF at least this", r_code(inputs$threshold)),
    sprintf("r_scale <- %s # Cauchy prior scale on the standardised effects (JASP's default 0.5)", r_code(inputs$prior_scale)),
    sprintf("matched <- %s # FALSE: across all models (JASP's default); TRUE: across matched models", r_code(identical(inputs$inclusion, "matched_models"))),
    switch(goal$type,
      sample_size = sprintf("target_power <- %s # target probability that the inclusion BF reaches the threshold", r_code(goal$power)),
      power = sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(goal$n))),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# One simulated study: normal scores in each cell, then the effect's",
    "# inclusion Bayes factor over the models that respect marginality.",
    "p_bayes_factorial <- function(n, means, sd, ratios, term, threshold, r_scale, matched) {",
    "  per_cell <- n * as.vector(t(ratios)) / sum(ratios)",
    "  a <- rep(rep(seq_len(nrow(means)), each = ncol(means)), round(per_cell))",
    "  b <- rep(rep(seq_len(ncol(means)), times = nrow(means)), round(per_cell))",
    "  data <- data.frame(A = factor(a), B = factor(b), y = means[cbind(a, b)] + rnorm(length(a), 0, sd))",
    "  bf <- anovaBF(y ~ A * B, data = data, whichModels = \"withmain\", rscaleFixed = r_scale, progress = FALSE)",
    "  inc <- bayesfactor_inclusion(bf, match_models = matched)",
    "  inc$log_BF[rownames(inc) == term] >= log(threshold)",
    "}",
    "",
    "# One batch: studies reaching the threshold, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  # Spower reads its experiment's arguments unevaluated, so each is a name.",
    "  result <- Spower(p_bayes_factorial(n = batch_n, means = means, sd = sd, ratios = ratios, term = term,",
    "    threshold = threshold, r_scale = r_scale, matched = matched), replications = batch_replications,",
    "    parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec))
  )
}

bffactorial_design_description <- function(spec, label, levels) {
  inputs <- bffactorial_inputs(spec)
  sprintf(
    "Bayes factor of %s in a %d x %d between-participants ANOVA of %s by %s (%s) and %s (%s): the inclusion Bayes factor %s (BayesFactor's anovaBF(), r scale %s, models respecting marginality); strong evidence is an inclusion BF of at least %s",
    sub("of A", paste("of", label("A")), sub("of B", paste("of", label("B")), bffactorial_effect_words(inputs$term))),
    nrow(inputs$means), ncol(inputs$means), label("Y"), label("A"), paste(levels("A"), collapse = ", "), label("B"),
    paste(levels("B"), collapse = ", "),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models",
    format_number(inputs$prior_scale), format_number(inputs$threshold)
  )
}
