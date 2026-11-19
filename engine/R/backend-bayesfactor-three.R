# Backend adapter: the Bayes factor of an effect in a three-factor ANOVA
# (each factor between or within participants), simulated with Spower, via
# BayesFactor and bayestestR.
#
# The Bayes factor is JASP's for a Bayesian ANOVA's effect, as for the
# two-factor ANOVAs (backend-bayesfactor-factorial.R): BayesFactor's
# anovaBF() (Rouder, Morey, Speckman & Province, 2012, the reference in its
# help) fits every model that respects marginality (whichModels =
# "withmain": an interaction only with every effect it contains, so 18
# models besides the null with three factors), with a Cauchy prior of
# scale r on the standardised effects (JASP's r scale for fixed effects,
# 0.5; jaspAnova's AdditionalOptions.qml), and the effect's inclusion
# Bayes factor is taken across all models with uniform model priors, as
# JASP's Effects table gives it by default (docs/decisions.md, 4 November
# 2026), by bayestestR's bayesfactor_inclusion(); across matched models
# is the option (`target_test > inclusion`).
#
# Each simulated study has n people split equally across the combinations
# of the between-participants factors (the three-factor card's design),
# each with a score in every combination of the within-participants
# factors. With a within factor, a person's scores share their own level,
# the one correlation r of the spec between any two of them (a random
# intercept, as JASP's repeated-measures ANOVA fits it), and anovaBF()
# takes the participants as a random factor (whichRandom, JASP's r scale
# of 1 for random effects). Power is the share of studies whose inclusion
# Bayes factor reaches the threshold. anovaBF() integrates by sampling, so
# each Bayes factor carries a small error of its own, part of the
# simulation's random error. About 1 s per simulated study between
# participants and 5 s with repeated measures, so in the app these take
# the preview and R script route (forms.yaml, simulations).

bfthree_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "factorial_anova") && identical(spec$template, "factorial_three")
}

bfthree_defaults <- list(prior_scale = 0.5, prior_scale_random = 1, inclusion = "all_models")

bfthree_terms <- c(main_effect_A = "A", main_effect_B = "B", main_effect_C = "C", interaction_AB = "A:B",
  interaction_AC = "A:C", interaction_BC = "B:C", interaction_ABC = "A:B:C")

# The cell means as an array m[A, B, C] (the spec nests A, then B, then C).
bfthree_means <- function(spec) {
  levels <- vapply(c("A", "B", "C"), function(v) length(spec$variables[[v]]$levels), integer(1))
  aperm(array(as.numeric(unlist(spec$population$means)), dim = rev(levels)), 3:1)
}

bfthree_inputs <- function(spec) {
  tt <- spec$target_test
  type <- function(v) spec$variables[[v]]$type %||% "between_factor"
  within <- vapply(c("A", "B", "C"), function(v) identical(type(v), "within_factor"), logical(1))
  list(
    means = bfthree_means(spec), sd = as.numeric(unlist(spec$population$sd))[1], within = within,
    r = if (any(within)) as.numeric(unlist(spec$population$r))[1] else 0,
    term = unname(bfthree_terms[[tt$effect]]), effect = tt$effect,
    threshold = bayes_threshold(spec),
    prior_scale = tt$prior_scale %||% bfthree_defaults$prior_scale,
    inclusion = tt$inclusion %||% bfthree_defaults$inclusion
  )
}

# The tested effect's part of the cell means, in the equal-weight
# decomposition into the grand mean, main effects and interactions: for the
# factors S of the term, the sum over every subset T of S of
# (-1)^(|S| - |T|) times the means averaged over the factors outside T.
bfthree_effect_part <- function(means, term) {
  factors <- strsplit(term, ":", fixed = TRUE)[[1]]
  dims <- match(factors, c("A", "B", "C"))
  cells <- as.matrix(expand.grid(lapply(dim(means), seq_len)))
  part <- numeric(nrow(cells))
  for (k in 0:length(dims)) {
    # combn() over positions: combn(2, 1) would read a lone 2 as 1:2.
    subsets <- if (k == 0) list(integer()) else lapply(utils::combn(length(dims), k, simplify = FALSE), function(i) dims[i])
    for (t in subsets) {
      margin <- if (length(t)) apply(means, t, mean)[cells[, t, drop = FALSE]] else mean(means)
      part <- part + (-1)^(length(dims) - length(t)) * margin
    }
  }
  array(part, dim(means))
}

# The cell means with the tested effect removed (the no-effect side).
bfthree_null_means <- function(means, term) means - bfthree_effect_part(means, term)

# One study's data: n people split equally across the combinations of the
# between factors, each with a score in every combination of the within
# factors; with a within factor a person's scores share their own level
# (correlation r) and the data carry the person's id.
bfthree_data <- function(n, means, sd, within, r) {
  cells <- expand.grid(C = seq_len(dim(means)[3]), B = seq_len(dim(means)[2]), A = seq_len(dim(means)[1]))
  cells <- cells[, c("A", "B", "C")]
  between <- names(within)[!within]
  groups <- if (length(between)) unique(cells[between]) else data.frame(row.names = 1)
  per_group <- n / nrow(groups)
  rows <- lapply(seq_len(nrow(groups)), function(g) {
    own <- if (length(between)) cells[Reduce(`&`, lapply(between, function(v) cells[[v]] == groups[[v]][g])), , drop = FALSE] else cells
    people <- (g - 1) * per_group + seq_len(per_group)
    data.frame(id = rep(people, each = nrow(own)), own[rep(seq_len(nrow(own)), per_group), , drop = FALSE], row.names = NULL)
  })
  data <- do.call(rbind, rows)
  level <- if (any(within)) stats::rnorm(n, 0, sd * sqrt(r)) else rep(0, n)
  noise_sd <- if (any(within)) sd * sqrt(1 - r) else sd
  data$y <- means[cbind(data$A, data$B, data$C)] + level[data$id] + stats::rnorm(nrow(data), 0, noise_sd)
  for (v in c("A", "B", "C")) data[[v]] <- factor(data[[v]])
  if (any(within)) data$id <- factor(data$id) else data$id <- NULL
  data
}

# The effect's log inclusion Bayes factor for one data set; with repeated
# measures the participants are a random factor in every model.
bfthree_log_bf <- function(data, term, prior_scale, inclusion) {
  bf <- if ("id" %in% names(data)) {
    BayesFactor::anovaBF(y ~ A * B * C + id, data = data, whichRandom = "id", whichModels = "withmain",
      rscaleFixed = prior_scale, rscaleRandom = bfthree_defaults$prior_scale_random, progress = FALSE)
  } else {
    BayesFactor::anovaBF(y ~ A * B * C, data = data, whichModels = "withmain", rscaleFixed = prior_scale, progress = FALSE)
  }
  inc <- bayestestR::bayesfactor_inclusion(bf, match_models = identical(inclusion, "matched_models"))
  # bayestestR names the interactions "A:B" and "A:B:C"; its log_BF column
  # is the natural log.
  inc$log_BF[rownames(inc) == term]
}

# The experiment Spower runs: one study of n people. `outcome` "effect"
# returns whether the inclusion BF reaches the threshold, "null" whether
# its reciprocal does (strong evidence that the effect is absent).
p_bayes_three <- function(n, means, sd, within, r, term, threshold, prior_scale, inclusion, outcome = "effect") {
  data <- bfthree_data(n, means, sd, within, r)
  log_bf <- bfthree_log_bf(data, term, prior_scale, inclusion)
  if (identical(outcome, "effect")) log_bf >= log(threshold) else log_bf <= -log(threshold)
}

bfthree_count <- function(inputs, n, nrep, seed, means = inputs$means, outcome = "effect") {
  args <- list(n = n, means = means, sd = inputs$sd, within = inputs$within, r = inputs$r, term = inputs$term,
    threshold = inputs$threshold, prior_scale = inputs$prior_scale, inclusion = inputs$inclusion, outcome = outcome)
  result <- spower_eval(as.name("p_bayes_three"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

# The number of groups: the combinations of the between factors' levels.
bfthree_groups <- function(inputs) prod(dim(inputs$means)[!inputs$within])

bfthree_backend <- function(spec, seed = NULL) {
  inputs <- bfthree_inputs(spec)
  step <- valid_n_step(spec)
  list(
    name = "BayesFactor",
    packages = c("BayesFactor", "bayestestR", "Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "Spower::Spower(p_bayes_three()) (BayesFactor::anovaBF() and bayestestR::bayesfactor_inclusion() on each simulated study)"),
    n_step = step,
    exact_min_n = step * ceiling(max(2 * bfthree_groups(inputs), minimum_n(spec)) / step),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bfthree_count(inputs, n, k, chunk_seed))
    },
    null_side = function(n, nrep, seed) bfthree_null_side(inputs, n, nrep, seed),
    sensitivity = NULL,
    check_run = function() bfthree_check_run(spec, inputs, seed)
  )
}

bfthree_null_side <- function(inputs, n, nrep, seed) {
  null <- bfthree_null_means(inputs$means, inputs$term)
  list(
    evidence_for_null = bfthree_count(inputs, n, nrep, seed + 1L, means = null, outcome = "null") / nrep,
    misleading_evidence = bfthree_count(inputs, n, nrep, seed + 2L, means = null) / nrep,
    null_nrep = nrep
  )
}

# The effect in words; `label` names each factor (A, B, C by default).
bfthree_effect_words <- function(term, label = identity) {
  factors <- vapply(strsplit(term, ":", fixed = TRUE)[[1]], label, character(1))
  if (length(factors) == 1) return(sprintf("the main effect of %s", factors))
  sprintf("the %s interaction", paste(factors, collapse = " x "))
}

bfthree_hypotheses_words <- function(inputs) {
  sprintf("the models with %s against those without (its inclusion Bayes factor, %s)", bfthree_effect_words(inputs$term),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models")
}

# Check run: a large study drawn as the experiment draws them recovers the
# cell means, the SD within cells and (with repeated measures) the
# correlation of a person's scores, and anovaBF() with
# bayesfactor_inclusion() gives a smaller study a Bayes factor for the
# effect.
bfthree_check_run <- function(spec, inputs, seed) {
  groups <- bfthree_groups(inputs)
  per_person <- length(inputs$means) / groups
  n <- groups * max(2, ceiling(check_run_n() / per_person / groups))
  data <- with_seed(seed %||% 1L, bfthree_data(n, inputs$means, inputs$sd, inputs$within, inputs$r))
  index <- cbind(as.integer(data$A), as.integer(data$B), as.integer(data$C))
  observed <- tapply(data$y, list(data$A, data$B, data$C), mean)
  within_sd <- stats::sd(data$y - observed[index])
  repeated <- any(inputs$within)
  small <- groups * max(2, ceiling((if (repeated) 200 else 2000) / groups))
  sample_rows <- with_seed(seed %||% 1L, bfthree_data(small, inputs$means, inputs$sd, inputs$within, inputs$r))
  log_bf <- call_backend("BayesFactor", with_seed(seed %||% 1L, bfthree_log_bf(sample_rows, inputs$term, inputs$prior_scale,
    inputs$inclusion)))
  effect_size <- max(abs(bfthree_effect_part(inputs$means, inputs$term))) / inputs$sd
  cell_n <- nrow(data) / length(inputs$means)
  rows <- data.frame(
    parameter = c("Largest difference between a simulated cell mean and the specified mean", "SD within cells",
      sprintf("Inclusion BF of a study of %s people for %s is far above the threshold (log BF %s)",
        format(small, big.mark = ","), bfthree_effect_words(inputs$term), format(round(log_bf, 1)))),
    specified = c(0, inputs$sd, log(inputs$threshold)),
    recovered = c(max(abs(observed - inputs$means)), within_sd, log_bf),
    ok = c(max(abs(observed - inputs$means)) < 5 * inputs$sd / sqrt(cell_n),
      abs(within_sd - inputs$sd) < 5 * inputs$sd / sqrt(2 * nrow(data)) + 0.01 * inputs$sd,
      effect_size < 0.2 || log_bf > log(inputs$threshold))
  )
  if (repeated) {
    # The correlation of a person's scores in the first two cells the
    # first person has, across everyone who has both.
    data$cell <- interaction(data$A, data$B, data$C, drop = TRUE)
    first_two <- as.character(data$cell[data$id == data$id[1]])[1:2]
    one <- data[data$cell == first_two[1], ]
    two <- data[data$cell == first_two[2], ]
    common <- intersect(one$id, two$id)
    rec <- stats::cor(one$y[match(common, one$id)], two$y[match(common, two$id)])
    rows <- rbind(rows, data.frame(parameter = "Correlation of a person's scores in two cells", specified = inputs$r, recovered = rec,
      ok = abs(atanh(rec) - atanh(inputs$r)) <= 5 / sqrt(length(common) - 3)))
  }
  rows
}

check_bayes_three <- function(spec) {
  problems <- character()
  pop <- spec$population
  tt <- spec$target_test
  if (!identical(tt$alternative %||% "two_sided", "two_sided")) {
    problems <- c(problems, "The Bayes factor of an ANOVA effect has no direction; remove 'target_test > alternative'.")
  }
  if (identical(spec$options$method, "exact")) {
    problems <- c(problems, "The Bayes factor of an ANOVA effect is simulated; remove 'options > method'.")
  }
  if (!is.null(tt$prior_width) || !is.null(tt$prior_a) || !is.null(tt$prior_b) || !is.null(tt$one_sided_null) ||
    !is.null(tt$prior_concentration) || !is.null(tt$sampling_plan) || !is.null(tt$prior_scale_covariates)) {
    problems <- c(problems, "The Bayes factor ANOVA has a Cauchy prior on the standardised effects, set by 'target_test > prior_scale'; remove the other prior settings.")
  }
  r <- as.numeric(unlist(pop$r %||% NA))
  if (!is.na(r[1]) && r[1] < 0) {
    problems <- c(problems, "The Bayes factor with repeated measures takes a correlation between a person's scores ('population > r') of 0 or more, as JASP's model of a level for each person assumes.")
  }
  problems
}

# The R script: the same simulation with Spower, anovaBF() and
# bayesfactor_inclusion(), in powerkit's batches, so it reproduces the
# run's counts.
bfthree_script <- function(spec, result) {
  inputs <- bfthree_inputs(spec)
  goal <- spec$goal
  prov <- result$provenance
  d <- dim(inputs$means)
  c(
    script_header(spec, result, "BayesFactor", "Spower::Spower, BayesFactor::anovaBF, bayestestR::bayesfactor_inclusion"),
    "library(Spower)",
    "library(BayesFactor)",
    "library(bayestestR)",
    "",
    "# Inputs ----",
    sprintf("means <- array(%s, dim = %s) # cell means[A, B, C]", r_code(as.vector(inputs$means)), r_code(d)),
    sprintf("sd <- %s # the SD within each cell", r_code(inputs$sd)),
    sprintf("within <- %s # which factors are within participants", r_code(inputs$within)),
    sprintf("r <- %s # the correlation of a person's scores in any two cells (with a within factor)", r_code(inputs$r)),
    sprintf("term <- %s # %s", r_code(inputs$term), bfthree_effect_words(inputs$term)),
    sprintf("threshold <- %s # evidence threshold: an inclusion BF at least this", r_code(inputs$threshold)),
    sprintf("r_scale <- %s # Cauchy prior scale on the standardised effects (the default in BayesFactor and JASP, 0.5)", r_code(inputs$prior_scale)),
    sprintf("matched <- %s # FALSE: across all models (JASP's default); TRUE: across matched models", r_code(identical(inputs$inclusion, "matched_models"))),
    switch(goal$type,
      sample_size = sprintf("target_power <- %s # target probability that the inclusion BF reaches the threshold", r_code(goal$power)),
      power = sprintf("n_total <- %s # total number of people (equal groups; every participant analysed)", r_code(goal$n))),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# One simulated study: n people split equally across the combinations of",
    "# the between factors, each scored in every combination of the within",
    "# factors, with a level of their own; then the effect's inclusion Bayes",
    "# factor over the models that respect marginality.",
    "p_bayes_three <- function(n, means, sd, within, r, term, threshold, r_scale, matched) {",
    "  cells <- expand.grid(C = seq_len(dim(means)[3]), B = seq_len(dim(means)[2]), A = seq_len(dim(means)[1]))",
    "  cells <- cells[, c(\"A\", \"B\", \"C\")]",
    "  between <- names(within)[!within]",
    "  groups <- if (length(between)) unique(cells[between]) else data.frame(row.names = 1)",
    "  per_group <- n / nrow(groups)",
    "  rows <- lapply(seq_len(nrow(groups)), function(g) {",
    "    own <- if (length(between)) cells[Reduce(`&`, lapply(between, function(v) cells[[v]] == groups[[v]][g])), , drop = FALSE] else cells",
    "    people <- (g - 1) * per_group + seq_len(per_group)",
    "    data.frame(id = rep(people, each = nrow(own)), own[rep(seq_len(nrow(own)), per_group), , drop = FALSE], row.names = NULL)",
    "  })",
    "  data <- do.call(rbind, rows)",
    "  level <- if (any(within)) rnorm(n, 0, sd * sqrt(r)) else rep(0, n)",
    "  noise_sd <- if (any(within)) sd * sqrt(1 - r) else sd",
    "  data$y <- means[cbind(data$A, data$B, data$C)] + level[data$id] + rnorm(nrow(data), 0, noise_sd)",
    "  for (v in c(\"A\", \"B\", \"C\")) data[[v]] <- factor(data[[v]])",
    "  bf <- if (any(within)) {",
    "    data$id <- factor(data$id)",
    "    anovaBF(y ~ A * B * C + id, data = data, whichRandom = \"id\", whichModels = \"withmain\", rscaleFixed = r_scale,",
    "      rscaleRandom = 1, progress = FALSE)",
    "  } else {",
    "    data$id <- NULL",
    "    anovaBF(y ~ A * B * C, data = data, whichModels = \"withmain\", rscaleFixed = r_scale, progress = FALSE)",
    "  }",
    "  inc <- bayesfactor_inclusion(bf, match_models = matched)",
    "  inc$log_BF[rownames(inc) == term] >= log(threshold)",
    "}",
    "",
    "# One batch: studies reaching the threshold, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  # Spower reads its experiment's arguments unevaluated, so each is a name.",
    "  result <- Spower(p_bayes_three(n = batch_n, means = means, sd = sd, within = within, r = r, term = term,",
    "    threshold = threshold, r_scale = r_scale, matched = matched), replications = batch_replications,",
    "    parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec))
  )
}

bfthree_design_description <- function(spec, label, levels) {
  inputs <- bfthree_inputs(spec)
  factor_words <- vapply(c("A", "B", "C"), function(v) {
    sprintf("%s (%s; %s)", label(v), paste(levels(v), collapse = ", "), if (inputs$within[[v]]) "within participants" else "between participants")
  }, character(1))
  effect <- bfthree_effect_words(inputs$term, label)
  sprintf(
    "Bayes factor of %s in a %s ANOVA of %s by %s: the inclusion Bayes factor %s (BayesFactor's anovaBF(), r scale %s, models respecting marginality%s); evidence at the threshold is an inclusion BF of at least %s",
    effect, paste(dim(inputs$means), collapse = " x "), label("Y"), paste(factor_words, collapse = ", "),
    if (identical(inputs$inclusion, "matched_models")) "across matched models" else "across all models",
    format_number(inputs$prior_scale), if (any(inputs$within)) ", participants a random factor" else "", format_number(inputs$threshold)
  )
}
