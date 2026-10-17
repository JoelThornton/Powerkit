#' Write an R script that reproduces a result
#'
#' Writes a standalone R script that reproduces a [run_spec()] result by
#' calling the package that computed it (Spower, Superpower,
#' InteractionPoweR or power4mome) directly, with the design's values
#' filled in and a comment on each argument. powerkit is not needed to run
#' the script.
#'
#' The script repeats what powerkit did, so it gives the same numbers with
#' the same package versions:
#' * simulations use powerkit's seeds and its split of the replications
#'   into batches (one per core, or for power4mome batches of at most
#'   `provenance$batch_size` replications), each an ordinary call to the
#'   backend with its own seed;
#' * for a sample-size goal it simulates every sample size powerkit
#'   simulated and fits the same probit curve to find the required n and
#'   its 95% interval (powerkit's quicker first pass, which only chose
#'   those sizes, is not repeated);
#' * exact 2x2 results use `ANOVA_exact()` under the run's seed.
#'
#' The script ends by comparing its numbers with powerkit's and printing
#' `sessionInfo()`. It doesn't repeat the check run.
#'
#' @param spec The spec the result was run from: a list, a JSON string or a
#'   path to a JSON file.
#' @param result The `powerkit_result` returned by [run_spec()] for `spec`.
#' @param file Path to write the script to (UTF-8), or `NULL` to only
#'   return it.
#'
#' @return The script as a single string; invisibly if `file` is given.
#' @seealso [export_citations()]
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' result <- run_spec(spec)
#' cat(export_script(spec, result))
#' }
export_script <- function(spec, result, file = NULL) {
  spec <- spec_for_export(spec, result)
  lines <- switch(
    result$provenance$backend,
    Spower = spower_script(spec, result),
    Superpower = superpower_script(spec, result),
    InteractionPoweR = interactionpower_script(spec, result),
    power4mome = power4mome_script(spec, result),
    abort_export(sprintf(
      "Script export isn't available for results from %s.", result$provenance$backend
    ))
  )
  text <- paste(c(lines, ""), collapse = "\n")
  if (is.null(file)) {
    return(text)
  }
  write_utf8(text, file)
  invisible(text)
}

# The validated spec, after checking that `result` was run from it.
spec_for_export <- function(spec, result) {
  if (!inherits(result, "powerkit_result")) {
    abort_export("'result' should be the result of run_spec() (a powerkit result).")
  }
  spec <- withCallingHandlers(
    validate_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
  if (!identical(spec_hash(spec), result$provenance$spec_hash)) {
    abort_export(
      "This result wasn't produced from this spec (their spec hashes differ). Export the spec and the result from the same run."
    )
  }
  if (identical(result$provenance$method, "simulation") && !is.data.frame(result$provenance$simulations)) {
    abort_export(
      "This result doesn't record the seed of each simulated sample size, which the script needs. It may come from an older version of powerkit; run the spec again."
    )
  }
  spec
}

abort_export <- function(message) {
  abort_run(message, class = "powerkit_export_error")
}

write_utf8 <- function(text, file) {
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(text, con, sep = "")
}

# R code for a value: numbers to 15 significant digits (17 if needed to
# give back exactly the same number), strings quoted, vectors in c().
r_code <- function(x) {
  one <- function(v) {
    if (is.character(v)) {
      return(encodeString(v, quote = "\""))
    }
    if (is.logical(v)) {
      return(if (is.na(v)) "NA" else as.character(v))
    }
    if (is.na(v)) {
      return("NA")
    }
    short <- format(v, digits = 15, scientific = FALSE, trim = TRUE)
    if (as.numeric(short) == v) short else sprintf("%.17g", v)
  }
  x <- unlist(x, use.names = FALSE)
  values <- vapply(x, one, character(1), USE.NAMES = FALSE)
  if (length(values) == 1) values else paste0("c(", paste(values, collapse = ", "), ")")
}

# A label or level for use in a comment, on one line.
comment_text <- function(x) gsub("[\r\n]+", " ", as.character(x))

# Lines of a string built from one line per element, as R code.
r_multiline_string <- function(name, lines, comment) {
  c(
    comment,
    sprintf("%s <- paste(", name),
    paste0("  ", vapply(lines, encodeString, character(1), quote = "\"", USE.NAMES = FALSE), ","),
    "  sep = \"\\n\"",
    ")"
  )
}

# Script sections shared by every backend ------------------------------------

script_header <- function(spec, result, package, call_description) {
  p <- result$provenance
  versions <- p$packages[names(p$packages) != "powerkit"]
  c(
    sprintf("# Reproduces a powerkit power analysis by calling %s directly.", package),
    "# powerkit itself is not needed to run this script.",
    "#",
    sprintf("# Generated by powerkit %s on %s.", p$packages[["powerkit"]], format(Sys.Date(), "%d %B %Y")),
    sprintf("# Design specification hash (SHA-256): %s", p$spec_hash),
    sprintf("# powerkit's run used %s and %s.", p$r_version, paste(names(versions), versions, collapse = ", ")),
    "# Other versions of these packages may give slightly different numbers.",
    "#",
    sprintf("# Design: %s", design_description(spec)),
    sprintf("# Goal: %s", goal_description(spec)),
    sprintf("# Method: %s", method_description(result)),
    sprintf("# Calculation: %s", call_description),
    "#",
    sprintf("# %s did this calculation. Please cite it: run citation(\"%s\"),", package, package),
    "# and see powerkit's citations export for its method paper.",
    ""
  )
}

design_description <- function(spec) {
  v <- spec$variables
  label <- function(role) comment_text(v[[role]]$label)
  levels <- function(role) paste(comment_text(unlist(v[[role]]$levels)), collapse = ", ")
  switch(
    paste(spec$design, spec$template, sep = "/"),
    "basic_test/one_sample_t" = sprintf("one-sample t-test of %s", label("Y")),
    "basic_test/independent_t" = sprintf(
      "independent-samples t-test (%s) of %s between the groups of %s (%s)",
      if (spec$target_test$method == "welch_t") "Welch's" else "Student's",
      label("Y"), label("X"), levels("X")
    ),
    "basic_test/paired_t" = sprintf(
      "paired-samples t-test of %s between the conditions of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "basic_test/correlation" = sprintf("Pearson correlation of %s with %s", label("X"), label("Y")),
    "basic_test/two_proportions" = sprintf(
      "z test of two proportions: %s between the groups of %s (%s)", label("Y"), label("X"), levels("X")
    ),
    "basic_test/chi_square_independence" = sprintf(
      "chi-square test of independence of %s (%s) and %s (%s)", label("X"), levels("X"), label("Y"), levels("Y")
    ),
    "factorial_anova/2x2_between" = sprintf(
      "2 x 2 between-participants ANOVA of %s: %s (%s) by %s (%s); effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "factorial_anova/2x2_mixed" = sprintf(
      "2 x 2 mixed ANOVA of %s: %s (%s, between participants) by %s (%s, within); effect tested: %s",
      label("Y"), label("A"), levels("A"), label("B"), levels("B"), anova_effect_name(spec)
    ),
    "regression_interaction/two_way" = sprintf(
      "regression interaction: does the effect of %s (X) on %s (Y) depend on %s (W)?",
      label("X"), label("Y"), label("W")
    ),
    "mediation/process_4" = sprintf(
      "%s mediation (PROCESS model 4); indirect effect tested: %s",
      if (length(path_model(spec)$mediators) > 1) "parallel" else "simple", spec$target_test$path
    ),
    "mediation/process_6" = sprintf(
      "serial mediation (PROCESS model 6); indirect effect tested: %s", spec$target_test$path
    ),
    "moderated_mediation/process_7" = sprintf(
      "first-stage moderated mediation (PROCESS model 7): %s (W) moderates %s (X) -> %s (M); index of moderated mediation for Y = %s",
      label("W"), label("X"), label("M"), label("Y")
    ),
    "moderated_mediation/process_14" = sprintf(
      "second-stage moderated mediation (PROCESS model 14): %s (W) moderates %s (M) -> %s (Y); index of moderated mediation for X = %s",
      label("W"), label("M"), label("Y"), label("X")
    )
  )
}

anova_effect_name <- function(spec) {
  v <- spec$variables
  switch(
    spec$target_test$effect,
    main_effect_A = sprintf("main effect of %s", comment_text(v$A$label)),
    main_effect_B = sprintf("main effect of %s", comment_text(v$B$label)),
    interaction = sprintf("%s x %s interaction", comment_text(v$A$label), comment_text(v$B$label))
  )
}

goal_description <- function(spec) {
  goal <- spec$goal
  switch(
    goal$type,
    power = sprintf("power at a total sample size of %s, alpha = %s", goal$n, spec$target_test$alpha),
    sample_size = sprintf(
      "the smallest total sample size with power of at least %s, alpha = %s", goal$power, spec$target_test$alpha
    ),
    sensitivity = sprintf(
      "the smallest effect (of the specified pattern) with power %s at a total sample size of %s, alpha = %s",
      goal$power, goal$n, spec$target_test$alpha
    )
  )
}

method_description <- function(result) {
  p <- result$provenance
  if (p$method == "exact") {
    return("exact (no simulation)")
  }
  sprintf("simulation, %s replications per sample size, seed %s", p$nrep, p$seed)
}

# Inputs every script has: alpha, the goal and, for simulation, the
# replications and seed.
goal_inputs <- function(spec, result) {
  goal <- spec$goal
  p <- result$provenance
  c(
    sprintf("alpha <- %s # significance level", r_code(spec$target_test$alpha)),
    if (goal$type != "sample_size") {
      sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(goal$n))
    },
    if (goal$type != "power") {
      sprintf("target_power <- %s", r_code(goal$power))
    },
    if (p$method == "simulation") {
      c(
        sprintf("replications <- %s # simulated data sets per sample size", r_code(p$nrep)),
        sprintf("seed <- %s # powerkit's seed for this run", r_code(p$seed))
      )
    } else {
      sprintf("seed <- %s # powerkit's seed for this run (see below)", r_code(p$seed))
    }
  )
}

# simulate_power(n_total, seed): rejections and analysable replications at
# n_total, from run_batch() over powerkit's batches (simulate_in_chunks()).
batch_section <- function(result, function_name) {
  p <- result$provenance
  batched <- !is.na(p$batch_size)
  c(
    "# powerkit splits the replications at each sample size into batches, as",
    "# equal in size as possible. Each batch is one call with its own seed",
    "# (seed, seed + 1, ...), and only its counts are kept. This is powerkit's",
    "# split, so the script simulates exactly the same data sets.",
    if (batched) {
      c(
        sprintf("# Batches hold at most %s replications: %s keeps every", p$batch_size, function_name),
        "# replication's data and fit until it returns, so batches bound memory use.",
        sprintf("batch_size <- %s", r_code(p$batch_size)),
        "batch_sizes <- function(replications) {",
        "  batches <- max(1, min(ceiling(replications / batch_size), replications))"
      )
    } else {
      c(
        sprintf(
          "# powerkit ran on %s %s, with one batch per core.", p$cores, if (p$cores == 1) "core" else "cores"
        ),
        "batch_sizes <- function(replications) {",
        sprintf("  batches <- max(1, min(%s, replications))", r_code(p$cores))
      )
    },
    "  replications %/% batches +",
    "    c(rep(1, replications %% batches), rep(0, batches - replications %% batches))",
    "}",
    "",
    "simulate_power <- function(n_total, seed) {",
    "  sizes <- batch_sizes(replications)",
    "  counts <- vapply(seq_along(sizes), function(i) {",
    "    batch_seed <- (seed + i - 2) %% 2147483646 + 1 # seed + i - 1, kept within R's range of seeds",
    "    run_batch(n_total, sizes[i], batch_seed)",
    "  }, numeric(2))",
    "  c(rejections = sum(counts[1, ]), valid = sum(counts[2, ]))",
    "}",
    ""
  )
}

# The goal, for a simulated result.
simulation_goal_section <- function(spec, result, n_step) {
  sims <- result$provenance$simulations
  if (spec$goal$type == "power") {
    return(c(
      "# Power at n_total ----",
      "counts <- simulate_power(n_total, seed)",
      "power <- counts[[\"rejections\"]] / counts[[\"valid\"]]",
      "mcse <- sqrt(power * (1 - power) / counts[[\"valid\"]]) # Monte Carlo standard error",
      "cat(sprintf(\"Power with n = %s: %.4f (Monte Carlo SE %.4f)\\n\", n_total, power, mcse))",
      "",
      "reproduced <- list(power = power)",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)),
      ""
    ))
  }
  est <- result$n_required
  c(
    "# Required n ----",
    "# powerkit simulated power at these total sample sizes, each with its own",
    "# seed (it chose them with a quicker first pass, not repeated here).",
    "# `fitted` marks the sizes its power curve was fitted to: those within 20%",
    "# of its first estimate of the required n.",
    "simulated <- data.frame(",
    sprintf("  n = %s,", r_code(sims$n)),
    sprintf("  seed = %s,", r_code(sims$seed)),
    sprintf("  fitted = %s", r_code(sims$fitted)),
    ")",
    "counts <- t(vapply(seq_len(nrow(simulated)), function(i) {",
    "  simulate_power(simulated$n[i], simulated$seed[i])",
    "}, numeric(2)))",
    "simulated$rejections <- counts[, 1]",
    "simulated$valid <- counts[, 2]",
    "simulated$power <- simulated$rejections / simulated$valid",
    "print(simulated)",
    "",
    "# powerkit smooths the simulated power with a probit regression of the",
    "# rejections on sqrt(n): for roughly normal test statistics, power is close",
    "# to pnorm(a + b * sqrt(n)). The required n is the smallest valid n whose",
    "# fitted power reaches the target; its 95% interval runs from the smallest n",
    "# whose upper confidence limit reaches the target to the smallest n whose",
    "# lower limit does.",
    "fitted_points <- simulated[simulated$fitted, ]",
    "fit <- suppressWarnings(glm(",
    "  cbind(rejections, valid - rejections) ~ sqrt(n),",
    "  family = binomial(link = \"probit\"),",
    "  data = fitted_points",
    "))",
    sprintf("n_step <- %s # valid total sample sizes are multiples of this", r_code(n_step)),
    "candidates <- data.frame(n = seq(min(fitted_points$n), max(fitted_points$n), by = n_step))",
    "link <- predict(fit, candidates, se.fit = TRUE)",
    "z <- qnorm(0.975)",
    "first_reaching <- function(p) candidates$n[which(p >= target_power)[1]]",
    "n_required <- first_reaching(pnorm(link$fit))",
    "n_lower <- first_reaching(pnorm(link$fit + z * link$se.fit))",
    "n_upper <- first_reaching(pnorm(link$fit - z * link$se.fit))",
    "cat(sprintf(\"Required n: %s (95%% interval %s to %s)\\n\", n_required, n_lower, n_upper))",
    "",
    "reproduced <- list(n = n_required, lower = n_lower, upper = n_upper, power = simulated$power)",
    "powerkit_result <- list(",
    sprintf("  n = %s, lower = %s, upper = %s,", r_code(est$n), r_code(est$lower), r_code(est$upper)),
    sprintf("  power = %s", r_code(result$curve$power)),
    ")",
    ""
  )
}

comparison_section <- function() {
  c(
    "# Compare with powerkit's result ----",
    "if (isTRUE(all.equal(reproduced, powerkit_result, tolerance = 1e-10))) {",
    "  cat(\"Reproduced powerkit's result.\\n\")",
    "} else {",
    "  cat(\"These numbers differ from powerkit's result. Check that the package\\n\")",
    "  cat(\"versions match those listed at the top of this script.\\n\")",
    "  str(list(reproduced = reproduced, powerkit = powerkit_result))",
    "}",
    "",
    "sessionInfo()"
  )
}

# Spower -------------------------------------------------------------------------

spower_script <- function(spec, result) {
  inputs <- spower_inputs(spec)
  one_sided <- inputs$alternative != "two_sided"
  c(
    script_header(spec, result, "Spower", inputs$description),
    "library(Spower)",
    "",
    "# Inputs ----",
    spower_script_inputs(spec),
    goal_inputs(spec, result),
    "",
    # Spower reads its experiment unevaluated, so values computed from the
    # inputs are given to it by name.
    if (length(spower_derived_lines(spec)) > 0) c(spower_derived_lines(spec), ""),
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    spower_group_size_lines(spec),
    "  set.seed(batch_seed) # Spower draws its own seeds from R's random-number generator",
    "  result <- Spower(",
    paste0("    ", spower_experiment_lines(spec, inputs, one_sided)),
    "    sig.level = alpha,",
    "    replications = batch_replications,",
    "    parallel = FALSE,",
    "    verbose = FALSE",
    "  )",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec)),
    comparison_section()
  )
}

# The user's values, in the spec's terms.
spower_script_inputs <- function(spec) {
  pop <- spec$population
  v <- spec$variables
  lv <- function(role, i) comment_text(unlist(v[[role]]$levels)[i])
  ratio <- spec$options$allocation_ratio %||% 1
  ratio_line <- sprintf(
    "allocation_ratio <- %s # size of group 2 (%s) relative to group 1 (%s)",
    r_code(ratio), lv("X", 2), lv("X", 1)
  )
  switch(
    spec$template,
    one_sample_t = sprintf(
      "d <- %s # Cohen's d: (expected mean of %s minus the fixed value) / SD", r_code(pop$d), comment_text(v$Y$label)
    ),
    independent_t = c(
      sprintf("d <- %s # Cohen's d: (mean of %s minus mean of %s) / pooled SD", r_code(pop$d), lv("X", 2), lv("X", 1)),
      ratio_line
    ),
    paired_t = sprintf(
      "dz <- %s # d_z: mean of the differences (%s minus %s) / SD of the differences",
      r_code(pop$dz), lv("X", 2), lv("X", 1)
    ),
    correlation = sprintf("r <- %s # population correlation", r_code(pop$r)),
    two_proportions = c(
      sprintf(
        "proportions <- %s # proportion with %s = %s in %s, then in %s",
        r_code(c(pop$p1, pop$p2)), comment_text(v$Y$label), lv("Y", 2), lv("X", 1), lv("X", 2)
      ),
      ratio_line
    ),
    chi_square_independence = c(
      sprintf(
        "# Probability of each combination: rows are %s (%s), columns %s (%s).",
        comment_text(v$X$label), paste(comment_text(unlist(v$X$levels)), collapse = ", "),
        comment_text(v$Y$label), paste(comment_text(unlist(v$Y$levels)), collapse = ", ")
      ),
      sprintf(
        "probabilities <- matrix(%s, nrow = %d, byrow = TRUE)",
        r_code(t(probability_matrix(spec))), nrow(probability_matrix(spec))
      )
    )
  )
}

spower_group_size_lines <- function(spec) {
  if (spec$template %in% c("independent_t", "two_proportions")) {
    return(c(
      "  # Spower's n is the size of group 1; group 2 has allocation_ratio times as many.",
      "  n_group1 <- round(batch_n / (1 + allocation_ratio))"
    ))
  }
  character()
}

# The arguments of Spower's experiment function, one per line, with a
# comment on each. powerkit passes the same values (spower_inputs()).
spower_experiment_lines <- function(spec, inputs, one_sided) {
  welch <- identical(spec$target_test$method, "welch_t")
  args <- switch(
    spec$template,
    one_sample_t = c(
      "n = batch_n, # sample size",
      "d = d, # Cohen's d",
      "type = \"one.sample\""
    ),
    independent_t = c(
      "n = n_group1, # size of group 1",
      "d = d_spower, # -d (see above)",
      "type = \"two.sample\",",
      "n2_n1 = allocation_ratio, # size of group 2 relative to group 1",
      sprintf("var.equal = %s # %s", if (welch) "FALSE" else "TRUE", if (welch) "FALSE: Welch's t-test" else "TRUE: Student's t-test")
    ),
    paired_t = c(
      "n = batch_n, # number of participants (pairs)",
      "d = d_spower, # -sqrt(2) * d_z (see above)",
      "type = \"paired\""
    ),
    correlation = c(
      "n = batch_n, # sample size",
      "r = r # population correlation"
    ),
    two_proportions = c(
      "n = n_group1, # size of group 1",
      "prop = proportions, # proportion in group 1, then group 2",
      "n.ratios = group_ratios, # group sizes relative to group 1",
      "correct = FALSE # no continuity correction (Spower's default is TRUE; powerkit's Departure 5)"
    ),
    chi_square_independence = c(
      "n = batch_n, # total sample size",
      "P = probabilities, # probability of each combination",
      "correct = FALSE # no continuity correction (Spower's default is TRUE; powerkit's Departure 5)"
    )
  )
  if (one_sided) {
    args <- c(args, spower_alternative_line(spec, inputs))
  }
  args <- ensure_commas(args)
  c(sprintf("%s(", inputs$experiment), paste0("  ", args), "),")
}

# A one-sided test: Spower's `alternative` (Spower 0.7 and later), in
# Spower's orientation (powerkit's spower_alternative()).
spower_alternative_line <- function(spec, inputs) {
  alternative <- spower_alternative(spec$template, inputs$alternative)
  positive <- inputs$alternative == "greater"
  why <- switch(
    spec$template,
    independent_t = sprintf(
      "your test expects group 2's mean to be %s; Spower tests group 1 minus group 2",
      if (positive) "higher" else "lower"
    ),
    paired_t = sprintf(
      "your test expects the second condition to be %s; Spower tests first minus second",
      if (positive) "higher" else "lower"
    ),
    two_proportions = sprintf(
      "your test expects p2 to be %s than p1; Spower tests p1 minus p2",
      if (positive) "higher" else "lower"
    ),
    sprintf("one-sided: the effect is expected to be %s", if (positive) "positive" else "negative")
  )
  sprintf("alternative = %s # %s", r_code(alternative), why)
}

# Put a comma after every argument but the last, before any comment.
ensure_commas <- function(args) {
  code <- sub(" #.*$", "", args)
  comment <- ifelse(grepl(" #", args), sub("^.*?( #.*)$", "\\1", args, perl = TRUE), "")
  code <- sub(",$", "", code)
  last <- length(code)
  code[-last] <- paste0(code[-last], ",")
  paste0(code, comment)
}

# Spower's values computed from the user's (powerkit's spower_inputs()).
spower_derived_lines <- function(spec) {
  switch(
    spec$template,
    independent_t = "d_spower <- -d # Spower puts the effect in group 1, so d (group 2 minus group 1) changes sign",
    paired_t = c(
      "# Spower's paired generator draws the two time points with SD 1 and the",
      "# effect in the first, so the differences have SD sqrt(2): Spower's d is",
      "# -sqrt(2) * d_z.",
      "d_spower <- -sqrt(2) * dz"
    ),
    two_proportions = "group_ratios <- c(1, allocation_ratio) # group sizes relative to group 1",
    character()
  )
}

# Superpower ----------------------------------------------------------------------

superpower_script <- function(spec, result) {
  inputs <- superpower_inputs(spec)
  p <- result$provenance
  call_description <- if (p$method == "exact") {
    "Superpower::ANOVA_exact()"
  } else {
    "Superpower::ANOVA_power()"
  }
  c(
    script_header(spec, result, "Superpower", call_description),
    "library(Superpower)",
    "",
    "# Inputs ----",
    superpower_script_inputs(spec, inputs),
    goal_inputs(spec, result),
    "",
    "# Superpower's design. ANOVA_design() draws random numbers, so powerkit",
    "# builds it under the run's seed.",
    "build_design <- function(n_total, means = mu) {",
    "  set.seed(seed)",
    "  ANOVA_design(",
    "    design = design_string,",
    "    n = n_total / groups, # Superpower's n is per between-participants group",
    "    mu = means,",
    "    sd = cell_sd,",
    "    r = r,",
    "    plot = FALSE",
    "  )",
    "}",
    "",
    if (p$method == "exact") {
      superpower_exact_sections(spec, result, inputs)
    } else {
      c(
        "# One batch of simulated data sets: rejections and analysable data sets.",
        "# The design is built before ANOVA_power() is called, as in powerkit.",
        "run_batch <- function(batch_n, batch_replications, batch_seed) {",
        "  design <- build_design(batch_n)",
        "  result <- ANOVA_power(",
        "    design,",
        "    alpha_level = alpha,",
        "    nsims = batch_replications,",
        "    seed = batch_seed,",
        "    verbose = FALSE",
        "  )",
        "  power <- result$main_results[paste0(\"anova_\", effect_row), \"power\"] / 100",
        "  c(round(power * batch_replications), batch_replications)",
        "}",
        "",
        batch_section(result, "ANOVA_power()"),
        simulation_goal_section(spec, result, inputs$groups)
      )
    },
    comparison_section()
  )
}

superpower_script_inputs <- function(spec, inputs) {
  v <- spec$variables
  factor_line <- function(role, letter) {
    lv <- comment_text(unlist(v[[role]]$levels))
    sprintf(
      "#   %s = %s: %s1 = %s, %s2 = %s", letter, comment_text(v[[role]]$label), letter, lv[1], letter, lv[2]
    )
  }
  between <- spec$template == "2x2_between"
  c(
    "# Superpower names the factors a and b and their levels a1, a2, b1, b2:",
    factor_line("A", "a"),
    factor_line("B", "b"),
    sprintf(
      "design_string <- %s # %s",
      r_code(inputs$design),
      if (between) "two between-participants factors" else "a between participants, b within"
    ),
    sprintf(
      "mu <- %s # cell means of %s, in Superpower's order a1_b1, a1_b2, a2_b1, a2_b2",
      r_code(inputs$mu), comment_text(v$Y$label)
    ),
    sprintf(
      "cell_sd <- %s # %s", r_code(inputs$sd),
      if (length(inputs$sd) == 1) "SD in every cell" else "SD of each cell, in the same order"
    ),
    sprintf(
      "r <- %s # %s", r_code(inputs$r),
      if (between) "correlation between repeated measures (none in a between design)" else
        "correlation between the two measurements of b"
    ),
    sprintf(
      "groups <- %s # between-participants groups: the total n is split equally across them", inputs$groups
    ),
    sprintf(
      "effect_row <- %s # Superpower's row for the effect tested (\"a\", \"b\" or \"a:b\")", r_code(inputs$effect)
    )
  )
}

superpower_exact_sections <- function(spec, result, inputs) {
  exact <- c(
    "# Exact power for the effect tested, and Superpower's Cohen's f.",
    "# ANOVA_exact() also draws random numbers (its results vary around the",
    "# 15th decimal place), so powerkit runs it under the run's seed too.",
    if (spec$template == "2x2_mixed") {
      c(
        "# powerkit uses ANOVA_exact() rather than ANOVA_exact2() for mixed",
        "# designs: it reproduces G*Power's values (powerkit's Departure 2)."
      )
    },
    "exact_result <- function(n_total, means = mu) {",
    "  design <- build_design(n_total, means)",
    "  set.seed(seed)",
    "  result <- ANOVA_exact(design, alpha_level = alpha, verbose = FALSE)",
    "  row <- result$main_results[effect_row, ]",
    "  list(power = row$power / 100, cohen_f = row$cohen_f)",
    "}",
    "exact_power <- function(n_total, means = mu) exact_result(n_total, means)$power",
    ""
  )
  goal <- switch(
    spec$goal$type,
    power = c(
      "# Power at n_total ----",
      "power <- exact_power(n_total)",
      "cat(sprintf(\"Power with n = %s: %.4f\\n\", n_total, power))",
      "",
      "reproduced <- list(power = power)",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)),
      ""
    ),
    sample_size = c(
      "# Required n ----",
      "# Exact power at the required n that powerkit found and at three valid",
      sprintf(
        "# sizes either side (valid sizes are multiples of %s). Power rises with n,", inputs$groups
      ),
      "# so the required n is the first of these that reaches the target power:",
      "# the size before it doesn't.",
      sprintf("sizes <- %s", r_code(result$curve$n)),
      "power <- vapply(sizes, exact_power, numeric(1))",
      "n_required <- sizes[which(power >= target_power)[1]]",
      "print(data.frame(n = sizes, power = power))",
      "cat(sprintf(\"Required n: %s\\n\", n_required))",
      "",
      "reproduced <- list(n = n_required, power = power)",
      sprintf(
        "powerkit_result <- list(n = %s, power = %s)",
        r_code(result$n_required$n), r_code(result$curve$power)
      ),
      ""
    ),
    sensitivity = superpower_sensitivity_section(spec, result)
  )
  c(exact, goal)
}

superpower_sensitivity_section <- function(spec, result) {
  s <- result$sensitivity
  contrast <- switch(
    spec$target_test$effect,
    main_effect_A = "mean(means[1, ]) - mean(means[2, ])",
    main_effect_B = "mean(means[, 1]) - mean(means[, 2])",
    interaction = "(means[1, 1] - means[1, 2]) - (means[2, 1] - means[2, 2])"
  )
  c(
    "# Smallest detectable effect ----",
    "# powerkit keeps the shape of your pattern of means and scales its size",
    "# (each cell mean's distance from the grand mean) until the effect tested",
    "# reaches the target power at n_total. Scale 1 is the pattern as given;",
    "# scale 0 makes all means equal.",
    "grand_mean <- mean(mu)",
    "means_at <- function(scale) grand_mean + scale * (mu - grand_mean)",
    "power_at <- function(scale) exact_power(n_total, means_at(scale))",
    "upper <- 1",
    "while (power_at(upper) < target_power) upper <- upper * 2",
    "scale <- uniroot(function(k) power_at(k) - target_power, lower = 0, upper = upper, tol = 1e-10)$root",
    "at_scale <- exact_result(n_total, means_at(scale))",
    "means <- matrix(means_at(scale), nrow = 2, byrow = TRUE) # rows: a1, a2; columns: b1, b2",
    sprintf("effect <- %s # %s", contrast, comment_text(s$effect_description)),
    "print(means)",
    "cat(sprintf(\"Smallest detectable effect: %.4g (Cohen's f = %.3f, power %.4f)\\n\",",
    "  effect, at_scale$cohen_f, at_scale$power))",
    "",
    "reproduced <- list(scale = scale, effect = effect, cohen_f = at_scale$cohen_f, power = at_scale$power)",
    "powerkit_result <- list(",
    sprintf("  scale = %s, effect = %s,", r_code(s$scale), r_code(s$effect)),
    sprintf("  cohen_f = %s, power = %s", r_code(s$cohen_f), r_code(s$power)),
    ")",
    ""
  )
}

# InteractionPoweR -----------------------------------------------------------------

interactionpower_script <- function(spec, result) {
  inputs <- interactionpower_inputs(spec)
  v <- spec$variables
  label <- function(role) comment_text(v[[role]]$label)
  c(
    script_header(spec, result, "InteractionPoweR", "InteractionPoweR::power_interaction()"),
    "library(InteractionPoweR)",
    "",
    "# Inputs ----",
    sprintf("# InteractionPoweR's x1 is X (%s), x2 is W (%s, the moderator), y is Y (%s);", label("X"), label("W"), label("Y")),
    "# x1x2 is their product. Correlations are among the true scores.",
    sprintf("r_x1_y <- %s # X with Y", r_code(inputs$r.x1.y)),
    sprintf("r_x2_y <- %s # W with Y", r_code(inputs$r.x2.y)),
    sprintf("r_x1x2_y <- %s # the interaction XW with Y", r_code(inputs$r.x1x2.y)),
    sprintf("r_x1_x2 <- %s # X with W", r_code(inputs$r.x1.x2)),
    sprintf("rel_x1 <- %s # reliability of X (1 = no measurement error)", r_code(inputs$rel.x1)),
    sprintf("rel_x2 <- %s # reliability of W", r_code(inputs$rel.x2)),
    sprintf("rel_y <- %s # reliability of Y", r_code(inputs$rel.y)),
    goal_inputs(spec, result),
    "",
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "# Each data set is analysed with lm(y ~ x1 + x2 + x1x2), testing the",
    "# product of the observed X and W. powerkit reports this simulated power;",
    "# fixed-model calculations such as InteractionPoweR's power_interaction_r2()",
    "# give slightly higher power (powerkit's conventions, Known difference 1).",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed) # power_interaction() has no seed argument; on one core it uses R's generator",
    "  result <- power_interaction(",
    "    n.iter = batch_replications, # simulated data sets",
    "    N = batch_n, # sample size",
    "    r.x1.y = r_x1_y,",
    "    r.x2.y = r_x2_y,",
    "    r.x1x2.y = r_x1x2_y,",
    "    r.x1.x2 = r_x1_x2,",
    "    rel.x1 = rel_x1,",
    "    rel.x2 = rel_x2,",
    "    rel.y = rel_y,",
    "    alpha = alpha",
    "  )",
    "  c(round(result$pwr[1] * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "power_interaction()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}

# power4mome --------------------------------------------------------------------------

power4mome_script <- function(spec, result) {
  inputs <- power4mome_inputs(spec)
  args <- inputs$test_args
  monte_carlo <- inputs$ci_type == "mc"
  roles <- c("x", "m", "y", "w")
  roles <- roles[roles %in% names(args)]
  role_lines <- vapply(roles, function(r) sprintf("%s = %s,", r, r_code(args[[r]])), character(1))
  tested <- if (spec$design == "mediation") {
    sprintf("# the indirect effect tested: %s", spec$target_test$path)
  } else {
    "# the index of moderated mediation"
  }
  c(
    script_header(spec, result, "power4mome", result$provenance$backend_function),
    "library(power4mome)",
    "",
    "# Inputs ----",
    r_multiline_string(
      "model", strsplit(inputs$model, "\n", fixed = TRUE)[[1]],
      c(
        "# The model fitted to each data set, in lavaan syntax.",
        if (spec$design == "moderated_mediation") {
          "# A product such as X:W is the interaction of X and W."
        },
        "# power4mome fits it with lavaan (maximum likelihood). PROCESS uses OLS,",
        "# which gives the same estimates and slightly larger standard errors",
        "# (powerkit's Departure 6).",
        if (any(grepl("~~", strsplit(inputs$model, "\n", fixed = TRUE)[[1]]))) {
          c(
            "# The mediators' residuals are free to correlate, as in PROCESS",
            "# (powerkit's Departure 7)."
          )
        }
      )
    ),
    r_multiline_string(
      "pop_es", strsplit(inputs$pop_es, "\n", fixed = TRUE)[[1]],
      c(
        "# Population values, \"outcome ~ predictor: value\", all standardised.",
        power4mome_covariance_comment(spec)
      )
    ),
    sprintf(
      "ci_draws <- %s # %s per confidence interval (power4mome's R)",
      r_code(inputs$ci_draws), if (monte_carlo) "Monte Carlo draws" else "bootstrap resamples"
    ),
    goal_inputs(spec, result),
    "",
    "# Boos and Zhang's (2000) method off: powerkit always tests with the",
    "# confidence interval (powerkit's Departure 8). power4mome 0.2.1's test",
    "# functions don't read this option, so test_method = \"ci\" below asks for",
    "# the CI rule explicitly; power4mome's summaries do read it.",
    "options(power4mome.bz = FALSE)",
    "",
    "# One batch of simulated data sets: rejections and analysable data sets.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  # iseed sets the simulated data sets. set.seed() as well, because for a",
    "  # model with a product term power4test() first standardises the",
    "  # population by Monte Carlo, using R's generator as it finds it.",
    "  set.seed(batch_seed)",
    "  result <- power4test(",
    "    nrep = as.integer(batch_replications), # simulated data sets",
    "    model = model,",
    "    pop_es = pop_es,",
    "    n = batch_n, # sample size",
    "    R = ci_draws,",
    sprintf(
      "    ci_type = %s, # %s", r_code(inputs$ci_type),
      if (monte_carlo) "Monte Carlo confidence intervals" else "percentile bootstrap confidence intervals"
    ),
    sprintf("    test_fun = %s,", inputs$test_name),
    "    test_args = list(",
    paste0("      ", role_lines[1], " ", tested),
    if (length(role_lines) > 1) paste0("      ", role_lines[-1]),
    sprintf("      mc_ci = %s,", r_code(args$mc_ci)),
    sprintf("      boot_ci = %s,", r_code(args$boot_ci)),
    "      level = 1 - alpha, # confidence level",
    "      test_method = \"ci\" # significant if the confidence interval excludes 0",
    "    ),",
    "    iseed = batch_seed,",
    "    parallel = FALSE,",
    "    progress = FALSE",
    "  )",
    "  rates <- rejection_rates(result)",
    "  # power4mome drops data sets whose model can't be fitted.",
    "  valid <- round(rates$pvalid[1] * batch_replications)",
    "  c(round(rates$reject[1] * valid), valid)",
    "}",
    "",
    batch_section(result, "power4test()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}

power4mome_covariance_comment <- function(spec) {
  model <- path_model(spec)
  if (spec$design == "mediation" && !isTRUE(model$serial) && length(model$mediators) > 1) {
    return(c(
      "# Between two mediators, \"~~\" is their residual covariance: each",
      "# residual correlation you gave, times the two residual SDs, sqrt(1 - R^2)."
    ))
  }
  if (spec$design == "moderated_mediation") {
    return("# \"X ~~ W\" is the correlation of X and W.")
  }
  character()
}
