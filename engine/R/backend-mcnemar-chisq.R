# Backend adapter: McNemar's chi-square test (basic_test / mcnemar, E26,
# target_test > method "mcnemar_chisq" or "mcnemar_chisq_corrected").
#
# McNemar's exact test (the default) is pwrss's exact power
# (backend-pwrss.R). Many analyses use the chi-square version instead:
# stats::mcnemar.test(), which applies the continuity correction unless
# told not to (correct = FALSE, the test jamovi reports). No package gives
# the corrected test's power, so both chi-square versions are simulated with
# Spower's p_mcnemar.test(), which draws the 2 x 2 table of pairs from its
# four proportions and runs mcnemar.test(). Only the two discordant
# proportions matter to the test; the concordant pairs are split equally
# between "no, no" and "yes, yes". A study with no discordant pairs, whose
# statistic is 0 / 0, counts as not significant. The tests are two-sided.

mcnemar_chisq_inputs <- function(spec) {
  pop <- spec$population
  list(
    p_first_only = as.numeric(pop$p_first_only),
    p_second_only = as.numeric(pop$p_second_only),
    correct = identical(spec$target_test$method, "mcnemar_chisq_corrected")
  )
}

# The table's proportions: the first condition in rows and the second in
# columns, each "no" then "yes"; [1, 2] is "no, then yes" (yes in the
# second condition only) and [2, 1] "yes, then no".
mcnemar_table <- function(p_first_only, p_second_only) {
  concordant <- (1 - p_first_only - p_second_only) / 2
  matrix(c(concordant, p_first_only, p_second_only, concordant), 2, 2)
}

# The experiment Spower runs: Spower's own p_mcnemar.test() on the table,
# with a study that has no discordant pairs counted as not significant.
p_mcnemar_chisq <- function(n, p_first_only, p_second_only, correct) {
  p <- Spower::p_mcnemar.test(n = n, prop = mcnemar_table(p_first_only, p_second_only), correct = correct)
  if (is.finite(p)) p else 1
}

mcnemar_chisq_count <- function(inputs, n, nrep, alpha, seed) {
  result <- spower_eval(as.name("p_mcnemar_chisq"), c(list(n = n), inputs), nrep, alpha, seed)
  round(result$power * nrep)
}

mcnemar_chisq_words <- function(spec) {
  if (identical(spec$target_test$method, "mcnemar_chisq_corrected")) {
    "McNemar's chi-square test with the continuity correction (stats::mcnemar.test(correct = TRUE))"
  } else {
    "McNemar's chi-square test without the continuity correction (stats::mcnemar.test(correct = FALSE))"
  }
}

mcnemar_chisq_backend <- function(spec, seed = NULL) {
  inputs <- mcnemar_chisq_inputs(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("Spower::Spower(p_mcnemar_chisq()) (Spower::p_mcnemar.test(), %s)", mcnemar_chisq_words(spec))),
    n_step = 1L,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
        mcnemar_chisq_count(inputs, n, chunk, spec$target_test$alpha, chunk_seed)
      })
    },
    sensitivity = NULL,
    simulated_sensitivity = function(n, power, nrep, seed, cores) simulated_effect_sensitivity(spec, n, power, nrep, seed, cores),
    check_run = function() mcnemar_chisq_check_run(inputs, seed)
  )
}

# Check run: one large table from Spower's generator; the two discordant
# proportions recovered, each with its binomial standard error.
mcnemar_chisq_check_run <- function(inputs, seed) {
  n <- check_run_n()
  table <- call_backend("Spower", with_seed(seed %||% 1L,
    Spower::gen_mcnemar.test(n = n, prop = mcnemar_table(inputs$p_first_only, inputs$p_second_only))))
  recovered <- c(table[2, 1], table[1, 2]) / n
  check_run_rows(
    c("proportion 'yes' in the first condition only", "proportion 'yes' in the second condition only"),
    c(inputs$p_first_only, inputs$p_second_only), recovered, sqrt(recovered * (1 - recovered) / n)
  )
}

# The standalone script (export_script()).
mcnemar_chisq_script <- function(spec, result) {
  inputs <- mcnemar_chisq_inputs(spec)
  v <- spec$variables
  levels <- comment_text(unlist(v$X$levels))
  header <- script_header(spec, result, "Spower", "Spower::Spower, Spower::p_mcnemar.test")
  c(
    header,
    "library(Spower)",
    "",
    "# Inputs ----",
    sprintf("p_first_only <- %s # proportion 'yes' in %s only (yes, then no)", r_code(inputs$p_first_only), levels[1]),
    sprintf("p_second_only <- %s # proportion 'yes' in %s only (no, then yes)", r_code(inputs$p_second_only), levels[2]),
    sprintf("correct <- %s # %s", r_code(inputs$correct),
      if (inputs$correct) "the continuity correction, mcnemar.test()'s default" else "no continuity correction"),
    goal_inputs(spec, result),
    "",
    "# One simulated study: the table of pairs, the first condition in rows",
    "# and the second in columns (no, then yes). Only the discordant pairs",
    "# matter to the test; the others are split equally between the two",
    "# concordant cells. A study with no discordant pairs counts as not",
    "# significant. McNemar's chi-square test is two-sided.",
    "p_mcnemar_chisq <- function(n) {",
    "  concordant <- (1 - p_first_only - p_second_only) / 2",
    "  prop <- matrix(c(concordant, p_first_only, p_second_only, concordant), 2, 2)",
    "  p <- p_mcnemar.test(n = n, prop = prop, correct = correct)",
    "  if (is.finite(p)) p else 1",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_mcnemar_chisq(n = batch_n), sig.level = alpha, replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, 1L),
    comparison_section()
  )
}
