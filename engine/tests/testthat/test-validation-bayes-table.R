# Validation: the Bayes factor test of a contingency table (BayesFactor's
# contingencyTableBF(), JASP's defaults), simulated with Spower.
#   1. a published example (placeholder for the maintainer)
#   2. agreement with the exact power: at small n, every possible table is
#      scored by contingencyTableBF() and its multinomial probability
#      summed where BF10 reaches the threshold (and, for no association,
#      where BF01 does)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

table_bf_validation_spec <- function(n, probs, threshold = 10, plan = "rows_fixed") {
  spec <- example_spec("chi_square_independence")
  spec$population <- list(metric = "proportion", probabilities = lapply(seq_len(nrow(probs)), function(i) as.list(probs[i, ])))
  spec$variables$X$levels <- as.list(paste0("x", seq_len(nrow(probs))))
  spec$variables$Y$levels <- as.list(paste0("y", seq_len(ncol(probs))))
  spec$target_test <- list(effect = "association", method = "bayes_factor", evidence_threshold = threshold, sampling_plan = plan)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 11L, nrep = validation_nrep())
  spec
}

test_that("matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the default contingency table Bayes factor (Gunel and
  #   Dickey's, as BayesFactor and JASP compute it). Transcribe the cell
  #   probabilities, the sampling plan, the prior concentration, the
  #   threshold, n and the published chance of reaching the threshold.
  probs <- TODO_PUBLISHED_VALUE
  plan <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(probs, plan, threshold, n, published_power)
  result <- engine_function("run_spec")(table_bf_validation_spec(n, probs, threshold, plan))
  expect_equal(result$curve$power, published_power, tolerance = 0.02)
})

# Every table of `cells` counts adding up to n.
all_tables <- function(n, cells) {
  if (cells == 1) return(matrix(n, 1, 1))
  do.call(rbind, lapply(0:n, function(x) cbind(x, all_tables(n - x, cells - 1))))
}

# The exact chances, from every table: BF10 at least the threshold, and
# BF01 at least the threshold.
exact_table_chances <- function(n, probs, threshold, sample_type = "indepMulti", margin = "rows") {
  tables <- all_tables(n, length(probs))
  cell_p <- as.vector(t(probs))
  log_bf <- apply(tables, 1, function(x) {
    args <- list(matrix(x, nrow(probs), byrow = TRUE), sampleType = sample_type, priorConcentration = 1)
    if (!is.null(margin)) args$fixedMargin <- margin
    BayesFactor::extractBF(do.call(BayesFactor::contingencyTableBF, args), logbf = TRUE)$bf
  })
  weight <- function(p) apply(tables, 1, function(x) stats::dmultinom(x, prob = p))
  w_alt <- weight(cell_p)
  w_null <- weight(as.vector(t(outer(rowSums(probs), colSums(probs)))))
  list(
    power = sum(w_alt[log_bf >= log(threshold)]),
    for_null = sum(w_null[log_bf <= -log(threshold)]),
    misleading = sum(w_null[log_bf >= log(threshold)])
  )
}

check_table_case <- function(n, probs, threshold, plan, sample_type, margin) {
  exact <- exact_table_chances(n, probs, threshold, sample_type, margin)
  result <- engine_function("run_spec")(table_bf_validation_spec(n, probs, threshold, plan))
  nrep <- result$provenance$nrep
  near <- function(estimate, truth) abs(estimate - truth) < 4 * sqrt(max(truth * (1 - truth), 1e-3) / nrep) + 2e-3
  expect_true(near(result$curve$power, exact$power), info = sprintf("power %.4f against exact %.4f", result$curve$power, exact$power))
  expect_true(near(result$bayes$evidence_for_null, exact$for_null), info = sprintf("for no association %.4f against %.4f", result$bayes$evidence_for_null, exact$for_null))
  expect_true(near(result$bayes$misleading_evidence, exact$misleading), info = sprintf("misleading %.4f against %.4f", result$bayes$misleading_evidence, exact$misleading))
}

test_that("a 2 x 2 table, rows fixed (JASP's default): agrees with the exact power over every table (simulation)", {
  skip_unless_full_validation()
  check_table_case(40, matrix(c(0.35, 0.15, 0.15, 0.35), 2, byrow = TRUE), 3, "rows_fixed", "indepMulti", "rows")
})

test_that("a 3 x 2 table, joint multinomial, threshold 10: agrees with the exact power over every table (simulation)", {
  skip_unless_full_validation()
  check_table_case(20, matrix(c(0.30, 0.03, 0.17, 0.17, 0.03, 0.30), 3, byrow = TRUE), 10, "joint_multinomial", "jointMulti", NULL)
})
