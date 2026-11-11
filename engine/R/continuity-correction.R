# Use the selected analysis, not an uncorrected power formula for a corrected test.
continuity_corrected <- function(spec) {
  identical(spec$design, "basic_test") && isTRUE(spec$target_test$method %in%
    c("z_test_corrected", "pearson_chi_square_corrected"))
}

continuity_problems <- function(spec) {
  if (!continuity_corrected(spec)) return(character())
  problems <- character()
  if (spec$goal$type %in% c("sensitivity", "sensitivity_curve")) problems <- c(problems,
    "Continuity-corrected tests currently support power at a sample size and finding a sample size. To compare effect sizes, run separate fixed-sample power plans using the same corrected test.")
  if (identical(spec$template, "chi_square_independence") &&
      (identical(spec$population$metric, "w") ||
       length(spec$variables$X$levels) != 2L || length(spec$variables$Y$levels) != 2L)) {
    problems <- c(problems, paste(
      "The continuity correction applies to a 2 by 2 table and needs its four population proportions; Cohen's w alone is not enough.",
      "For larger tables choose Pearson's test without correction. For two groups with fixed group sizes, use the two-proportions design."))
  }
  problems
}

# Spower supplies each simulated study and the base-R test. Keep unsuccessful
# analyses in the attempted-study denominator and report their count, rather
# than reconstructing successes from a power estimate over an unknown subset.
corrected_count_rejections <- function(inputs, args, nrep, seed) {
  experiment <- getExportedValue("Spower", inputs$experiment)
  p <- with_seed(seed, quietly(replicate(nrep,
    tryCatch(do.call(experiment, args), error = function(e) NA_real_))))
  valid <- is.finite(p) & p >= 0 & p <= 1
  c(sum(p[valid] < inputs$alpha), nrep, nrep, sum(valid))
}

# Standalone replay of the same Spower experiments and attempted-study ledger.
corrected_count_script <- function(spec, result) {
  inputs <- spower_inputs(spec)
  batch <- batch_section(result, "the Spower experiment")
  batch <- sub("numeric(2)", "numeric(4)", batch, fixed = TRUE)
  at <- which(batch == '  c(rejections = sum(counts[1, ]), valid = sum(counts[2, ]))')
  batch <- append(batch, c(
    '  cat(sprintf("Attempted: %s; analysable: %s; failed: %s\\n", sum(counts[3, ]), sum(counts[4, ]), sum(counts[3, ] - counts[4, ])))',
    '  # The replay helper calls its denominator valid; here it is ALL attempts.'
  ), after = at - 1L)
  c(script_header(spec, result, "Spower", inputs$description), "library(Spower)", "",
    spower_script_inputs(spec), goal_inputs(spec, result), spower_derived_lines(spec), "",
    "# Invalid analyses count as unsuccessful studies; they are also reported.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    spower_group_size_lines(spec), "  set.seed(batch_seed)",
    if (identical(spec$template, "two_proportions")) c(
      sprintf('  p <- replicate(batch_replications, tryCatch(Spower::p_prop.test(n = n_group1, prop = proportions, n.ratios = group_ratios, correct = TRUE, alternative = "%s"), error = function(e) NA_real_))',
        spower_alternative(spec$template, inputs$alternative))
    ) else '  p <- replicate(batch_replications, tryCatch(Spower::p_chisq.test(n = batch_n, P = probabilities, correct = TRUE), error = function(e) NA_real_))',
    "  valid <- is.finite(p) & p >= 0 & p <= 1",
    "  c(sum(p[valid] < alpha), batch_replications, batch_replications, sum(valid))", "}", "",
    batch,
    if (identical(result$goal_type, "sample_size") && !is.null(result$n_required$verification)) confirmed_count_script_section(result)
    else simulation_goal_section(spec, result, valid_n_step(spec)), comparison_section())
}

# Replay the actual search and confirmation draws with their recorded counts.
# The confirmation uses more replications than the initial curve when needed.
confirmed_count_script_section <- function(result) {
  sims <- result$provenance$simulations
  est <- result$n_required
  c(
    "# Replay search and fresh confirmation studies ----",
    "# The smooth curve only proposed N. The returned N passed a fresh",
    "# one-sided binomial lower-bound check; it is not a minimum-N estimate.",
    "simulated <- data.frame(",
    sprintf("  n = %s,", r_code(sims$n)),
    sprintf("  seed = %s,", r_code(sims$seed)),
    sprintf("  nrep = %s,", r_code(sims$nrep)),
    sprintf("  stage = %s", r_code(sims$stage)), ")",
    "simulated$rejections <- NA_real_",
    "for (i in seq_len(nrow(simulated))) {",
    "  replications <- simulated$nrep[i]",
    "  counts <- simulate_power(simulated$n[i], simulated$seed[i])",
    "  simulated$rejections[i] <- counts[[\"rejections\"]]",
    "}",
    "checks <- simulated[simulated$stage == \"confirmation\", ]",
    sprintf("confidence <- %s # 1 - .01 / 10: 99%% protection across up to ten checks", r_code(est$verification$confidence_per_check)),
    "checks$lower <- vapply(seq_len(nrow(checks)), function(i) {",
    "  unname(binom.test(checks$rejections[i], checks$nrep[i],",
    "    alternative = \"greater\", conf.level = confidence)$conf.int[1])",
    "}, numeric(1))",
    "passed <- which(checks$lower >= target_power)[1]",
    "stopifnot(!is.na(passed))",
    "selected <- checks[passed, ]",
    "n_required <- selected$n",
    "print(checks)",
    "reproduced <- list(n = selected$n, power = selected$rejections / selected$nrep, lower = selected$lower)",
    sprintf("powerkit_result <- list(n = %s, power = %s, lower = %s)",
      r_code(est$n), r_code(est$power), r_code(est$power_lower)), "")
}
