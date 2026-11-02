# Backend adapter: the Bayes factor test of association in a contingency
# table (two categorical variables, any number of levels), simulated with
# Spower, via BayesFactor.
#
# The Bayes factor is BayesFactor's contingencyTableBF() (Morey & Rouder,
# the package's own citation(); Gunel and Dickey's Bayes factors, the
# reference in its help), with JASP's defaults: independent multinomial
# sampling with the row totals fixed ("Indep. multinomial, rows fixed") and
# prior concentration 1 (jaspFrequencies' ContingencyTablesBayesian.qml,
# read for the two-proportion test, decisions.md, 1 November 2026). The
# other sampling plans JASP offers for tables of any size (Poisson, joint
# multinomial, columns fixed) can be chosen (`target_test >
# sampling_plan`); the hypergeometric plan is for 2 x 2 tables only and is
# not offered.
#
# The rows are X's levels and the columns Y's, as in the spec's
# `probabilities`. Each simulated study draws its table from the
# multinomial with those cell probabilities and the total n (the design the
# chi-square card assumes), and contingencyTableBF() scores it. Power is
# the share of studies with BF10 at least the threshold. No package
# computes it, and summing over every table is out of reach beyond very
# small samples (a 3 x 2 table of 200 people has billions), so it is
# simulated; test-validation-bayes-table.R checks it against the exact sum
# over every table at small n.

bftable_test <- function(spec) bayes_factor_test(spec) && identical(spec$template, "chi_square_independence")

bftable_defaults <- list(prior_concentration = 1, sampling_plan = "rows_fixed")

# contingencyTableBF()'s sampleType and fixedMargin for each plan.
bftable_plans <- list(
  rows_fixed = list(sampleType = "indepMulti", fixedMargin = "rows", words = "independent multinomial sampling with the row totals fixed"),
  columns_fixed = list(sampleType = "indepMulti", fixedMargin = "cols", words = "independent multinomial sampling with the column totals fixed"),
  joint_multinomial = list(sampleType = "jointMulti", fixedMargin = NULL, words = "joint multinomial sampling (only the total fixed)"),
  poisson = list(sampleType = "poisson", fixedMargin = NULL, words = "Poisson sampling (no total fixed)")
)

bftable_inputs <- function(spec) {
  tt <- spec$target_test
  list(
    probs = probability_matrix(spec),
    threshold = bayes_threshold(spec),
    a = tt$prior_concentration %||% bftable_defaults$prior_concentration,
    plan = tt$sampling_plan %||% bftable_defaults$sampling_plan
  )
}

# log BF10 for one table, from contingencyTableBF() itself.
bftable_log_bf10 <- function(table, a, plan) {
  p <- bftable_plans[[plan]]
  args <- list(table, sampleType = p$sampleType, priorConcentration = a)
  if (!is.null(p$fixedMargin)) args$fixedMargin <- p$fixedMargin
  BayesFactor::extractBF(do.call(BayesFactor::contingencyTableBF, args), logbf = TRUE)$bf[1]
}

# The experiment Spower runs: one study of n people, its table drawn from
# the cell probabilities `probs`. `outcome` "effect" returns whether BF10
# reaches the threshold, "null" whether BF01 does (strong evidence of no
# association).
p_bayes_table <- function(n, probs, threshold, a, plan, outcome = "effect") {
  table <- matrix(stats::rmultinom(1, n, as.vector(t(probs))), nrow(probs), byrow = TRUE)
  log_bf <- bftable_log_bf10(table, a, plan)
  if (identical(outcome, "effect")) log_bf >= log(threshold) else log_bf <= -log(threshold)
}

# Studies (of nrep) with the outcome, at total n.
bftable_count <- function(inputs, n, nrep, seed, probs = inputs$probs, outcome = "effect") {
  args <- list(n = n, probs = probs, threshold = inputs$threshold, a = inputs$a, plan = inputs$plan, outcome = outcome)
  result <- spower_eval(as.name("p_bayes_table"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

# No association: the same row and column shares, cells their products.
bftable_null_probs <- function(probs) outer(rowSums(probs), colSums(probs))

bftable_backend <- function(spec, seed = NULL) {
  inputs <- bftable_inputs(spec)
  step <- valid_n_step(spec)
  list(
    name = "BayesFactor",
    packages = c("BayesFactor", "Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "Spower::Spower(p_bayes_table()) (BayesFactor::contingencyTableBF() on each simulated table)"),
    n_step = step,
    exact_min_n = step * ceiling(max(length(inputs$probs) * 2, minimum_n(spec)) / step),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bftable_count(inputs, n, k, chunk_seed))
    },
    # The no-association side at the n found: both outcomes simulated
    # with the same number of studies (bayes_summary()).
    null_side = function(n, nrep, seed) bftable_null_side(inputs, n, nrep, seed),
    sensitivity = NULL,
    check_run = function() bftable_check_run(spec, inputs, seed)
  )
}

bftable_null_side <- function(inputs, n, nrep, seed) {
  null <- bftable_null_probs(inputs$probs)
  list(
    evidence_for_null = bftable_count(inputs, n, nrep, seed + 1L, probs = null, outcome = "null") / nrep,
    misleading_evidence = bftable_count(inputs, n, nrep, seed + 2L, probs = null) / nrep,
    null_nrep = nrep
  )
}

bftable_hypotheses_words <- function(inputs) {
  "no association between the two variables (independence) against an association"
}

# Check run: a large table drawn as the experiment draws them gives back
# the cell probabilities and Cohen's w, and contingencyTableBF() receives
# the prior concentration and sampling plan.
bftable_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  table <- with_seed(seed %||% 1L, matrix(stats::rmultinom(1, n, as.vector(t(inputs$probs))), nrow(inputs$probs), byrow = TRUE))
  observed <- table / n
  w_of <- function(p) {
    e <- bftable_null_probs(p)
    sqrt(sum((p - e)^2 / e))
  }
  w_spec <- w_of(inputs$probs)
  se_w <- 1 / sqrt(n)
  log_bf <- call_backend("BayesFactor", bftable_log_bf10(table, inputs$a, inputs$plan))
  data.frame(
    parameter = c(
      "Largest difference between a simulated cell share and the specified probability",
      "Cohen's w of the association",
      sprintf("BF10 of that large table is far above the threshold (log BF10 %s)", format(round(log_bf, 1)))
    ),
    specified = c(0, w_spec, log(inputs$threshold)),
    recovered = c(max(abs(observed - inputs$probs)), w_of(observed), log_bf),
    ok = c(
      max(abs(observed - inputs$probs)) < 4 * sqrt(0.25 / n),
      abs(w_of(observed) - w_spec) < 4 * se_w + 0.01,
      w_spec < 0.05 || log_bf > log(inputs$threshold)
    )
  )
}

check_bayes_table <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  problems <- character()
  if (!identical(pop$metric, "proportion")) {
    problems <- c(problems, "The Bayes factor test of a table needs the proportion in each cell ('population > probabilities'), not Cohen's w: the Bayes factor depends on the table itself.")
  }
  if (!is.null(tt$prior_scale) || !is.null(tt$prior_a) || !is.null(tt$prior_b) || !is.null(tt$one_sided_null) ||
    !is.null(tt$prior_width) || !is.null(pop$effect_sd) || !is.null(pop$r_sd) || !is.null(pop$p_sd)) {
    problems <- c(problems, paste0(
      "The Bayes factor test of a table has a prior concentration ('target_test > prior_concentration') ",
      "and a sampling plan ('target_test > sampling_plan'); remove the other Bayes factor settings."))
  }
  if (identical(spec$options$method, "exact")) {
    problems <- c(problems, "The Bayes factor test of a table is simulated; remove 'options > method'.")
  }
  problems
}

# The R script: the same simulation with Spower and contingencyTableBF(),
# in powerkit's batches, so it reproduces the run's counts.
bftable_script <- function(spec, result) {
  inputs <- bftable_inputs(spec)
  p <- bftable_plans[[inputs$plan]]
  margin <- if (is.null(p$fixedMargin)) "" else sprintf(", fixedMargin = \"%s\"", p$fixedMargin)
  goal <- spec$goal
  prov <- result$provenance
  c(
    script_header(spec, result, "BayesFactor", "Spower::Spower, BayesFactor::contingencyTableBF"),
    "library(Spower)",
    "library(BayesFactor)",
    "",
    "# Inputs ----",
    sprintf("probs <- matrix(%s, nrow = %d, byrow = TRUE) # cell probabilities: rows X, columns Y",
      r_code(as.vector(t(inputs$probs))), nrow(inputs$probs)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("a <- %s # prior concentration (JASP's default 1)", r_code(inputs$a)),
    switch(goal$type,
      sample_size = sprintf("target_power <- %s # target probability that BF10 reaches the threshold", r_code(goal$power)),
      power = sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(goal$n))),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# One simulated study: a table drawn from the cell probabilities, scored",
    sprintf("# by contingencyTableBF() with %s.", p$words),
    "p_bayes_table <- function(n, probs, threshold, a) {",
    "  table <- matrix(rmultinom(1, n, as.vector(t(probs))), nrow(probs), byrow = TRUE)",
    sprintf("  bf <- contingencyTableBF(table, sampleType = \"%s\"%s, priorConcentration = a)", p$sampleType, margin),
    "  extractBF(bf, logbf = TRUE)$bf[1] >= log(threshold)",
    "}",
    "",
    "# One batch: studies reaching the threshold, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  # Spower reads its experiment's arguments unevaluated, so each is a name.",
    "  result <- Spower(p_bayes_table(n = batch_n, probs = probs, threshold = threshold, a = a),",
    "    replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec))
  )
}

bftable_design_description <- function(spec, label, levels) {
  inputs <- bftable_inputs(spec)
  sprintf(
    "Bayes factor test of association between %s (%s) and %s (%s): BayesFactor's contingency table Bayes factor with %s and prior concentration %s; strong evidence is BF10 of at least %s",
    label("X"), paste(levels("X"), collapse = ", "), label("Y"), paste(levels("Y"), collapse = ", "),
    bftable_plans[[inputs$plan]]$words, format_number(inputs$a), format_number(inputs$threshold)
  )
}
