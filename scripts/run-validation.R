# Full validation of the powerkit engine, run locally or on GitHub.
#
# Runs the high-replication validation tests (engine/tests/testthat/
# test-validation-*.R) with POWERKIT_FULL_VALIDATION=true, each test in its
# own R process, a few at a time. It is:
#   * resumable: each test's result is saved to validation-results/ as soon
#     as it finishes, and tests with a saved result are skipped next time;
#   * runnable in chunks by design (--only);
#   * complete: every test_that() block runs, including blocks generated in
#     loops, each in its own process and recorded under its own name. Before
#     anything runs, the script checks that its list of tests is the list
#     testthat reports for each file, and a test whose run reports anything
#     other than that one test is recorded as an ERROR;
#   * independent of any other tool: start it yourself from a terminal or
#     RStudio, and stop it at any time (Ctrl+C in a terminal, Esc or the red
#     stop button in RStudio); rerun the same command to carry on.
# It prints progress and an estimate of the time remaining, and ends with a
# summary (also saved to validation-results/summary.txt) to paste back.
# After a full run, paste the summary into docs/validation-log.md.
#
# From a terminal, in the repository's top folder:
#   Rscript scripts/run-validation.R                        everything
#   Rscript scripts/run-validation.R --only interactions    one chunk
#   Rscript scripts/run-validation.R --only process_4,process_6 --cores 3
#   Rscript scripts/run-validation.R --list                 chunks, progress, test-list check
#   Rscript scripts/run-validation.R --summary              summary only
#   Rscript scripts/run-validation.R --retry-failed         rerun FAIL / ERROR
#   Rscript scripts/run-validation.R --retry-skipped        rerun SKIP
#   Rscript scripts/run-validation.R --fresh                forget saved results
#   Rscript scripts/run-validation.R --only process_7 --cores 4 --cores-per-test 4
#                       one test at a time, its replications on 4 cores
#                       (Linux and macOS only; on Windows each test uses
#                       one core and --cores runs several tests at once)
# From RStudio, with Powerkit.Rproj open:
#   source("scripts/run-validation.R")
#   run_validation(only = "interactions", cores = 2)
#   run_validation(retry_skipped = TRUE)
#
# On GitHub (no need to keep a computer on; one chunk per run, up to 6
# hours each; .github/workflows/full-validation.yaml):
#   1. On the repository's GitHub page, open the Actions tab.
#   2. In the list on the left, click "full-validation".
#   3. Click "Run workflow" (on the right), pick the chunk, and click the
#      green "Run workflow" button.
#   4. When the run finishes (a green tick or a red cross), open it and
#      download the artifact "validation-results-<chunk>-run-<number>"
#      at the bottom of its Summary page. It is a zip of validation-
#      results/: summary.txt (paste it into docs/validation-log.md) and each
#      test's .rds and .log files.
# Step-by-step, with what to expect: docs/validation-log.md, "Running the
# full validation on GitHub".
#
# Memory: mediation simulations run in batches of at most 200
# replications per power4mome call (simulate_in_chunks(); docs/
# decisions.md), so a test needs well under 1 GB per core it uses.
#
# A test skipped for a TODO_PUBLISHED_VALUE is saved as SKIP and counts as
# done, so it doesn't run again on its own. After filling in published
# values, rerun those tests with --retry-skipped (retry_skipped = TRUE):
# it reruns only the tests whose saved result is SKIP, and keeps every
# other saved result. --retry-failed and --retry-skipped can be combined.
# As everywhere in this script, a saved result belongs to a test only if
# it records that test's name and position in its file; a result saved
# under another name or position is ignored, and that test runs anyway.
#
# Chunks: basic, anova, interactions, process_4 (simple and parallel
# mediation), process_4_binary (simple mediation with a yes/no X; its own
# chunk so each stays within GitHub's six-hour job), process_6 (serial mediation), process_7, process_14,
# mediation_crosscheck (simple mediation against pwrss and simsem, two
# tools written independently of power4mome; both are in Suggests and
# renv.lock), mediation_crosscheck_parallel and mediation_crosscheck_serial
# (parallel and serial mediation, joint test, against simsem), logistic
# and poisson (logistic and Poisson regression by formula; published values
# to transcribe), whole_study (the experimental whole-study simulation
# against powerkit's separate calculations, and Type I error), cluster
# (cluster-randomised trials by formula, powertools; published values to
# transcribe), multisite (multisite trials, the same) and sem_fit
# (structural equation model fit by formula, semPower; the same) and
# sem_latent (measurement invariance, factor correlations and latent
# slopes by formula, semPower; the same).
#
# On demand only (not part of "everything", and never run by
# devtools::test()): interaction_grid, which compares InteractionPoweR's
# analytic power_interaction_r2() with powerkit's simulation over a grid of
# designs (72 cells), one cell per R process. Kept so it can be rerun,
# for example after an InteractionPoweR update (docs/decisions.md):
#   Rscript scripts/run-validation.R --only interaction_grid
#   run_validation(only = "interaction_grid")

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}

validation_chunks <- function() {
  list(
    basic = c("test-validation-basic-tests.R", "test-validation-justified-alpha.R"),
    variances = "test-validation-variance-tests.R",
    manova = c("test-validation-manova.R", "test-validation-hotelling-one.R"),
    rank = c("test-validation-rank-tests.R", "test-validation-friedman.R"),
    bayes = c("test-validation-bayes-factor.R", "test-validation-bayes-sequential.R"),
    meta = c("test-validation-meta-analysis.R", "test-validation-meta-subgroups.R"),
    dyadic = "test-validation-apim.R",
    anova = c(
      "test-validation-anova-2x2-between.R", "test-validation-anova-2x2-mixed.R",
      "test-validation-anova-oneway-within.R", "test-validation-anova-mixed.R",
      "test-validation-anova-factorial.R", "test-validation-anova-three.R",
      "test-validation-anova-unequal.R", "test-validation-anova-eta.R", "test-validation-anova-pairwise.R",
      "test-validation-anova-within-covariance.R"
    ),
    interactions = c("test-validation-regression-interaction.R", "test-validation-interaction-binary.R"),
    three_way = "test-validation-three-way.R",
    process_4 = c("test-validation-mediation-simple.R", "test-validation-mediation-parallel.R"),
    process_4_binary = "test-validation-mediation-binary.R",
    process_6 = "test-validation-mediation-serial.R",
    process_7 = "test-validation-modmed-process7.R",
    process_14 = "test-validation-modmed-process14.R",
    modmed_parallel = "test-validation-modmed-parallel.R",
    mediation_crosscheck = "test-validation-mediation-crosscheck.R",
    mediation_crosscheck_parallel = "test-validation-mediation-crosscheck-parallel.R",
    mediation_crosscheck_serial = "test-validation-mediation-crosscheck-serial.R",
    logistic = "test-validation-logistic-regression.R",
    ordinal = "test-validation-ordinal.R",
    logistic_factorial = "test-validation-logistic-factorial.R",
    poisson = "test-validation-poisson-regression.R",
    contrast = "test-validation-anova-contrast.R",
    ancova = "test-validation-anova-ancova.R",
    two_correlations = "test-validation-two-correlations.R",
    generic = "test-validation-generic-tests.R",
    equivalence = c("test-validation-equivalence-tests.R", "test-validation-minimum-effect.R"),
    trend = "test-validation-trend.R",
    precision = "test-validation-precision.R",
    whole_study = "test-validation-whole-study-crosscheck.R",
    cluster = "test-validation-cluster-randomised.R",
    multisite = "test-validation-multisite.R",
    sem_fit = "test-validation-sem-model-fit.R",
    sem_latent = "test-validation-sem-latent.R",
    mixed_model = c("test-validation-mixed-model.R", "test-validation-two-level.R", "test-validation-crossed-conditions.R", "test-validation-crossed-binary.R", "test-validation-three-level.R", "test-validation-item-predictor.R")
  )
}

# Rough minutes for one test on one core, by chunk, used only for the time
# estimate (which is then corrected by how fast tests actually run).
# Direct-call tests run two simulations, so count double.
validation_minutes <- function() {
  c(basic = 0.3, variances = 2, manova = 3, rank = 2, bayes = 1, meta = 3, dyadic = 10, anova = 15, interactions = 1.5, three_way = 0.3, process_4 = 60, process_4_binary = 60,
    process_6 = 60, process_7 = 120, process_14 = 120, modmed_parallel = 120,
    mediation_crosscheck = 40, mediation_crosscheck_parallel = 40,
    mediation_crosscheck_serial = 40, logistic = 0.3, ordinal = 0.3, logistic_factorial = 2, poisson = 0.3,
    contrast = 0.3, ancova = 0.3, two_correlations = 0.3, generic = 0.3, equivalence = 0.3, trend = 2, precision = 1,
    whole_study = 90, cluster = 0.3, multisite = 0.3, sem_fit = 0.3,
    sem_latent = 0.3, mixed_model = 420)
}

run_validation <- function(only = NULL, cores = 2, retry_failed = FALSE,
                            retry_skipped = FALSE, fresh = FALSE,
                            list_only = FALSE, summary_only = FALSE,
                            cores_per_test = 1) {
  cores <- whole_count(cores, "--cores (cores)")
  cores_per_test <- validation_cores_per_test(cores, whole_count(cores_per_test, "--cores-per-test (cores_per_test)"))
  cores_label <- if (cores_per_test == 1) cores else sprintf("%d (%d per test)", cores, cores_per_test)
  root <- validation_root()
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  results_dir <- file.path(root, "validation-results")
  dir.create(results_dir, showWarnings = FALSE)
  if (isTRUE(fresh)) {
    unlink(file.path(results_dir, c("*.rds", "*.log", "summary.txt")))
    message("Forgot all saved results.")
  }

  tests <- validation_tests(root, only)
  tests$done <- tests_done(tests)
  if (isTRUE(summary_only)) {
    return(invisible(write_summary(tests, results_dir, cores_label)))
  }
  check_test_lists(tests)
  if (isTRUE(list_only)) {
    return(invisible(print_chunk_progress(tests)))
  }
  retry <- c(
    if (isTRUE(retry_failed)) c("FAIL", "ERROR"),
    if (isTRUE(retry_skipped)) "SKIP"
  )
  if (length(retry) > 0) {
    tests <- forget_results(tests, retry)
  }

  todo <- tests[!tests$done, ]
  todo <- todo[order(-todo$estimate), ]
  slots <- max(1L, cores %/% cores_per_test)
  cat(sprintf(
    "powerkit validation: %d tests selected, %d already saved, %d to run, on %d core%s%s.\n",
    nrow(tests), sum(tests$done), nrow(todo), cores, if (cores == 1) "" else "s",
    if (cores_per_test == 1) "" else sprintf(" (%d test%s at a time, %d cores each)", slots, if (slots == 1) "" else "s", cores_per_test)
  ))
  if (nrow(todo) > 0) {
    cat(sprintf(
      "First estimate of the time needed: %s (it is corrected as tests finish).\n",
      format_minutes(sum(todo$estimate) / cores_per_test / min(slots, nrow(todo)))
    ))
    cat("Stop at any time with Ctrl+C (terminal) or Esc (RStudio); rerun the same command to carry on.\n\n")
    run_queue(todo, slots, cores_per_test, nrow(tests) - nrow(todo), nrow(tests))
  }
  tests$done <- tests_done(tests)
  invisible(write_summary(tests, results_dir, cores_label))
}

# Cores given to each test (its POWERKIT_CORES). With 1 (the default),
# `cores` tests run at once, each on one core. With k > 1, cores %/% k tests
# run at once, each spreading its simulation replications over k cores:
# better for chunks of a few long tests (the mediation chunks, whose
# replications run in batches; simulate_in_chunks() in engine/R/route.R).
# Spreading replications over cores works on Unix-alikes only
# (run_in_parallel()), so on Windows each test gets one core.
validation_cores_per_test <- function(cores, cores_per_test) {
  cores_per_test <- min(cores, cores_per_test)
  if (cores_per_test > 1 && .Platform$OS.type != "unix") {
    message("--cores-per-test has no effect on Windows: each test runs on one core (--cores sets how many tests run at once).")
    cores_per_test <- 1L
  }
  cores_per_test
}

# A number of cores as a positive whole number, or stop with a message
# naming the option (`what`). Accepts a number or text such as "4".
whole_count <- function(value, what) {
  shown <- if (length(value) == 0) "nothing" else paste0("'", paste(value, collapse = " "), "'")
  number <- if (length(value) == 1) suppressWarnings(as.numeric(value)) else NA
  if (is.na(number) || number < 1 || number != round(number)) {
    stop(sprintf(
      "%s must be a positive whole number, such as 1 or 4; got %s.", what, shown
    ), call. = FALSE)
  }
  as.integer(number)
}

tests_done <- function(tests) {
  vapply(seq_len(nrow(tests)), function(i) !is.null(saved_result(tests[i, ])), logical(1))
}

# The saved status of each test ("NOT RUN" if it has no saved result).
saved_status <- function(tests) {
  vapply(seq_len(nrow(tests)), function(i) {
    r <- saved_result(tests[i, ])
    if (is.null(r)) "NOT RUN" else r$status
  }, character(1))
}

# Delete the saved results whose status is one of `statuses` (for
# --retry-failed and --retry-skipped), so those tests run again. Only
# results that belong to the test (same name and position, as in
# saved_result()) are touched.
forget_results <- function(tests, statuses) {
  status <- saved_status(tests)
  again <- status %in% statuses
  file.remove(tests$result[again])
  tests$done[again] <- FALSE
  counts <- table(factor(status[again], levels = statuses))
  cat(sprintf(
    "Running again: %s.\n",
    paste(sprintf("%d %s", as.integer(counts), names(counts)), collapse = ", ")
  ))
  tests
}

# The repository's top folder: the working directory or one above it.
validation_root <- function() {
  for (dir in c(".", "..", "../..")) {
    if (file.exists(file.path(dir, "engine", "DESCRIPTION"))) {
      return(normalizePath(dir, winslash = "/"))
    }
  }
  stop("Run this from the Powerkit folder (the one containing 'engine' and 'scripts').", call. = FALSE)
}

# One row per test_that() block in the selected chunks, plus one row per
# grid cell if interaction_grid is selected (it is never selected by
# default).
validation_tests <- function(root, only) {
  chunks <- validation_chunks()
  grid <- FALSE
  if (!is.null(only)) {
    only <- trimws(unlist(strsplit(only, ",")))
    known <- c(names(chunks), "interaction_grid")
    unknown <- setdiff(only, known)
    if (length(unknown) > 0) {
      stop(sprintf(
        "Unknown chunk %s. Choose from: %s.",
        paste0("'", unknown, "'", collapse = ", "), paste(known, collapse = ", ")
      ), call. = FALSE)
    }
    grid <- "interaction_grid" %in% only
    chunks <- chunks[intersect(only, names(chunks))]
  }
  minutes <- validation_minutes()
  rows <- lapply(names(chunks), function(chunk) {
    do.call(rbind, lapply(chunks[[chunk]], function(file) {
      path <- file.path(root, "engine", "tests", "testthat", file)
      descriptions <- test_descriptions(path)
      data.frame(
        chunk = chunk,
        kind = "test",
        file = file,
        index = seq_along(descriptions),
        test = descriptions,
        # Exact (non-simulated) ANOVA checks take seconds.
        estimate = ifelse(
          grepl(", exact:", descriptions), 0.2,
          minutes[[chunk]] * ifelse(grepl("direct", descriptions), 2, 1)
        ),
        result = file.path(
          root, "validation-results",
          sprintf("%s__%s__%02d.rds", chunk, sub("\\.R$", "", file), seq_along(descriptions))
        ),
        stringsAsFactors = FALSE
      )
    }))
  })
  if (grid) {
    rows <- c(rows, list(interaction_grid_rows(root)))
  }
  do.call(rbind, rows)
}

# Interaction grid ----------------------------------------------------------------
#
# InteractionPoweR's analytic power_interaction_r2() against powerkit's
# simulation (InteractionPoweR::power_interaction(), 10,000 replications),
# for Y ~ X + W + XW with continuous X and W. Main effects are fixed at
# r_X_Y = r_W_Y = 0.2; the same reliability is given to X, W and Y.

interaction_grid <- function() {
  expand.grid(
    n = c(50, 100, 200, 500),
    r_XW_Y = c(0.05, 0.10, 0.20),
    reliability = c(1, 0.8, 0.7),
    r_X_W = c(0, 0.3)
  )
}

interaction_grid_rows <- function(root) {
  grid <- interaction_grid()
  data.frame(
    chunk = "interaction_grid",
    kind = "cell",
    file = NA_character_,
    index = seq_len(nrow(grid)),
    test = sprintf(
      "N = %d, r_XW_Y = %.2f, reliability = %.1f, r_X_W = %.1f",
      grid$n, grid$r_XW_Y, grid$reliability, grid$r_X_W
    ),
    # Rough minutes on one core: loading the package, plus simulation time
    # that grows with n.
    estimate = 0.2 + grid$n / 500,
    result = file.path(root, "validation-results", sprintf("interaction_grid__cell_%02d.rds", seq_len(nrow(grid)))),
    stringsAsFactors = FALSE
  )
}

interaction_grid_spec <- function(cell, seed) {
  variable <- function(label) {
    v <- list(type = "continuous", label = label)
    if (cell$reliability < 1) v$reliability <- cell$reliability
    v
  }
  list(
    spec_version = "0.1",
    design = "regression_interaction",
    template = "two_way",
    variables = list(X = variable("Predictor"), W = variable("Moderator"), Y = variable("Outcome")),
    population = list(
      metric = "correlation",
      r_X_Y = 0.2, r_W_Y = 0.2, r_XW_Y = cell$r_XW_Y, r_X_W = cell$r_X_W
    ),
    effect_justification = list(
      type = "smallest_effect_of_interest",
      source = "powerkit interaction grid (not a real study)"
    ),
    target_test = list(effect = "interaction", method = "ols_t", alpha = 0.05),
    goal = list(type = "power", n = cell$n),
    options = list(nrep = 10000L, seed = seed)
  )
}

# Child process: one grid cell. Saves both power values, their difference
# (simulation minus analytic) and whether the analytic value lies inside
# the 99.9% Monte Carlo interval of the simulation (the validation
# tolerance rule; the analytic value has no Monte Carlo error).
run_one_cell <- function(index, result_path) {
  started <- Sys.time()
  cell <- interaction_grid()[index, ]
  label <- interaction_grid_rows(".")$test[index]
  result <- tryCatch({
    pkgload::load_all("engine", quiet = TRUE, helpers = FALSE)
    run <- getExportedValue("powerkit", "run_spec")(interaction_grid_spec(cell, seed = 60000L + index))
    simulation <- run$curve$power
    mcse <- run$curve$mcse
    analytic <- InteractionPoweR::power_interaction_r2(
      N = cell$n, r.x1.y = 0.2, r.x2.y = 0.2, r.x1x2.y = cell$r_XW_Y, r.x1.x2 = cell$r_X_W,
      rel.x1 = cell$reliability, rel.x2 = cell$reliability, rel.y = cell$reliability,
      alpha = 0.05
    )$pwr[1]
    half_width <- stats::qnorm(0.9995) * mcse
    within <- abs(simulation - analytic) <= half_width
    list(
      status = if (within) "PASS" else "FAIL",
      messages = sprintf(
        "simulation %.4f (MCSE %.4f), analytic %.4f, difference %+.4f; 99.9%% half-width %.4f: %s",
        simulation, mcse, analytic, simulation - analytic, half_width,
        if (within) "within" else "OUTSIDE"
      ),
      grid = c(as.list(cell), list(
        simulation = simulation, mcse = mcse, analytic = analytic,
        difference = simulation - analytic, half_width = half_width, within = within
      ))
    )
  }, error = function(e) {
    list(status = "ERROR", messages = paste("Could not run the cell:", conditionMessage(e)), grid = NULL)
  })
  result <- c(
    result,
    list(
      test = label, index = index,
      minutes = as.numeric(difftime(Sys.time(), started, units = "mins")),
      finished = format(Sys.time(), "%Y-%m-%d %H:%M")
    )
  )
  tmp <- paste0(result_path, ".tmp")
  saveRDS(result, tmp)
  file.rename(tmp, result_path)
  invisible(result)
}

# The grid's results as a table, and whether the differences lean one way.
grid_summary_lines <- function(saved) {
  cells <- Filter(function(r) !is.null(r) && !is.null(r$grid), saved)
  if (length(cells) == 0) {
    return(character())
  }
  g <- do.call(rbind, lapply(cells, function(r) as.data.frame(r$grid)))
  g <- g[order(g$r_X_W, g$reliability, g$r_XW_Y, g$n), ]
  k <- nrow(g)
  higher <- sum(g$difference > 0)
  ties <- sum(g$difference == 0)
  se_mean <- sqrt(sum(g$mcse^2)) / k
  mean_diff <- mean(g$difference)
  sign_p <- if (k - ties > 0) stats::binom.test(higher, k - ties)$p.value else NA
  by_group <- function(var) {
    means <- tapply(g$difference, g[[var]], mean)
    paste(sprintf("%s = %s: %+.4f", var, names(means), means), collapse = "; ")
  }
  c(
    "",
    sprintf("Interaction grid: analytic power_interaction_r2() vs simulation, %d of 72 cells", k),
    "     N  r_XW_Y  rel  r_X_W  simulation (MCSE)  analytic   diff  within 99.9%",
    sprintf(
      "%6d  %6.2f  %3.1f  %5.1f  %8.4f (%.4f)  %8.4f  %+.4f  %s",
      g$n, g$r_XW_Y, g$reliability, g$r_X_W, g$simulation, g$mcse, g$analytic,
      g$difference, ifelse(g$within, "yes", "NO")
    ),
    sprintf("Cells within the 99.9%% interval: %d of %d", sum(g$within), k),
    sprintf(
      "Simulation higher than analytic in %d of %d cells (%.0f%%)%s; sign test p = %s",
      higher, k, 100 * higher / k, if (ties > 0) sprintf(", %d ties", ties) else "",
      if (is.na(sign_p)) "NA" else format(signif(sign_p, 3))
    ),
    sprintf(
      "Mean signed difference (simulation - analytic): %+.4f (Monte Carlo SE %.4f, z = %.2f)",
      mean_diff, se_mean, mean_diff / se_mean
    ),
    paste("Mean difference by N:", by_group("n")),
    paste("Mean difference by reliability:", by_group("reliability")),
    paste("Mean difference by r_XW_Y:", by_group("r_XW_Y")),
    paste("Mean difference by r_X_W:", by_group("r_X_W"))
  )
}

# The description of every test_that() block in a test file, in the order
# testthat runs them, including blocks generated in loops (the 2 x 2 ANOVA
# files make most of theirs in for loops). The file's top-level code is
# evaluated with test_that() replaced by a recorder, so the loops run but no
# test body does. Validation files' top-level code only defines functions
# and constants and loops over test_that() calls; anything else that fails
# here stops the script with the file's name.
test_descriptions <- function(path) {
  found <- character()
  env <- new.env(parent = baseenv())
  env$test_that <- function(desc, code) {
    if (!is.character(desc) || length(desc) != 1) {
      stop("a test_that() description is not a single string", call. = FALSE)
    }
    found <<- c(found, desc)
    invisible(TRUE)
  }
  tryCatch(
    for (e in parse(path, keep.source = FALSE)) eval(e, env),
    error = function(e) {
      stop(sprintf("Could not list the tests in %s: %s", basename(path), conditionMessage(e)), call. = FALSE)
    }
  )
  found
}

# A stand-in for test_that() that runs only the index-th test_that() call
# in a file (counting loop-generated ones) and skips the others, without
# evaluating their code.
only_test_number <- function(index) {
  seen <- 0L
  function(desc, code) {
    seen <<- seen + 1L
    if (seen != index) {
      return(invisible(TRUE))
    }
    eval(as.call(list(quote(testthat::test_that), desc, substitute(code))), parent.frame())
  }
}

# Run a test file with testthat in a fresh environment of the loaded
# package (helpers are sourced into it); `test_that` overrides testthat's
# when given. Returns testthat's list of the tests it ran.
run_test_file <- function(path, test_that = NULL) {
  env <- new.env(parent = asNamespace("powerkit"))
  if (!is.null(test_that)) env$test_that <- test_that
  testthat::test_file(
    path, package = "powerkit", load_package = "none",
    reporter = testthat::ListReporter$new(), env = env
  )
}

reported_names <- function(reported) {
  vapply(reported, function(t) as.character(t$test), character(1))
}

# Check, before anything runs, that the script's list of tests is the list
# testthat itself reports for each file. testthat's list comes from a child
# R process that runs the files with the validation tests switched off, so
# each test skips at its first line (a few seconds per file).
check_test_lists <- function(tests) {
  rows <- tests[tests$kind == "test", ]
  files <- unique(rows$file)
  if (length(files) == 0) {
    return(invisible(TRUE))
  }
  out <- tempfile(fileext = ".rds")
  on.exit(unlink(out), add = TRUE)
  run <- processx::run(
    rscript_path(), c(file.path("scripts", "run-validation.R"), "--list-tests", out, files),
    error_on_status = FALSE, env = c("current", POWERKIT_FULL_VALIDATION = "false")
  )
  if (!file.exists(out)) {
    stop(paste(
      "Could not ask testthat for its list of tests:",
      paste(utils::tail(strsplit(paste(run$stdout, run$stderr), "\n")[[1]], 10), collapse = "\n")
    ), call. = FALSE)
  }
  theirs <- readRDS(out)
  problems <- character()
  for (file in files) {
    ours <- rows$test[rows$file == file][order(rows$index[rows$file == file])]
    if (length(ours) != length(theirs[[file]])) {
      problems <- c(problems, sprintf(
        "%s: the script finds %d tests, testthat reports %d.", file, length(ours), length(theirs[[file]])
      ))
    } else if (!identical(ours, theirs[[file]])) {
      problems <- c(problems, sprintf(
        "%s: the script and testthat both find %d tests, but their names or order differ.", file, length(ours)
      ))
    }
  }
  if (length(problems) > 0) {
    stop(paste(c("The script's list of tests does not match testthat's:", problems), collapse = "\n"), call. = FALSE)
  }
  cat(sprintf(
    "Tests found, checked against testthat: %s.\n",
    paste(sprintf("%s %d", sub("^test-validation-(.*)\\.R$", "\\1", files), lengths(theirs[files])), collapse = ", ")
  ))
  invisible(TRUE)
}

# Child process: save testthat's list of test names for each file.
list_tests_with_testthat <- function(out, files) {
  Sys.setenv(POWERKIT_FULL_VALIDATION = "false")
  pkgload::load_all("engine", helpers = FALSE, quiet = TRUE)
  found <- lapply(files, function(file) {
    reported_names(run_test_file(file.path("engine", "tests", "testthat", file)))
  })
  names(found) <- files
  saveRDS(found, out)
}

# A saved result, or NULL if there is none or it belongs to a different test
# (for example one saved by an earlier version of this script, which
# numbered the tests differently): such a result is ignored and the test
# runs again.
saved_result <- function(row) {
  if (!file.exists(row$result)) {
    return(NULL)
  }
  r <- tryCatch(readRDS(row$result), error = function(e) NULL)
  if (is.null(r) || !identical(r$test, row$test) || !identical(as.integer(r$index), as.integer(row$index))) {
    return(NULL)
  }
  r
}

rscript_path <- function() {
  file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
}

# Run the queue, at most `cores` tests at a time, each in its own R process
# with `cores_per_test` cores for its simulations.
run_queue <- function(todo, cores, cores_per_test, already, total) {
  rscript <- rscript_path()
  script <- file.path("scripts", "run-validation.R")
  running <- list()
  started_all <- Sys.time()
  finished <- 0
  speed <- list(actual = 0, estimated = 0)
  next_row <- 1
  on.exit({
    for (job in running) if (job$process$is_alive()) job$process$kill()
  }, add = TRUE)

  while (next_row <= nrow(todo) || length(running) > 0) {
    while (length(running) < cores && next_row <= nrow(todo)) {
      row <- todo[next_row, ]
      log <- sub("\\.rds$", ".log", row$result)
      process <- processx::process$new(
        rscript,
        if (row$kind == "cell") {
          c(script, "--run-cell", as.character(row$index), row$result)
        } else {
          c(script, "--run-one", row$file, as.character(row$index), row$result)
        },
        stdout = log, stderr = "2>&1", cleanup = TRUE,
        env = c("current", POWERKIT_FULL_VALIDATION = "true", POWERKIT_CORES = as.character(cores_per_test))
      )
      running[[length(running) + 1]] <- list(process = process, row = row, started = Sys.time())
      cat(sprintf("  started   %s: %s\n", row$chunk, row$test))
      next_row <- next_row + 1
    }
    Sys.sleep(2)
    still <- list()
    for (job in running) {
      if (job$process$is_alive()) {
        still[[length(still) + 1]] <- job
        next
      }
      finished <- finished + 1
      minutes <- as.numeric(difftime(Sys.time(), job$started, units = "mins"))
      row <- job$row
      result <- saved_result(row)
      if (!is.null(result)) {
        status <- result$status
        if (status != "SKIP") {
          speed$actual <- speed$actual + minutes
          speed$estimated <- speed$estimated + row$estimate / cores_per_test
        }
      } else {
        status <- "DID NOT FINISH (no result saved; it will run again next time)"
      }
      remaining <- todo$estimate[seq_len(nrow(todo)) >= next_row]
      remaining <- c(remaining, vapply(still, function(j) j$row$estimate, numeric(1)))
      factor <- if (speed$estimated > 0) speed$actual / speed$estimated else 1
      eta <- sum(remaining) * factor / cores_per_test / max(1, min(cores, length(remaining)))
      cat(sprintf(
        "[%d/%d] %-5s %s: %s (%s)  |  elapsed %s, about %s left\n",
        already + finished, total, status, row$chunk, row$test, format_minutes(minutes),
        format_minutes(as.numeric(difftime(Sys.time(), started_all, units = "mins"))),
        format_minutes(eta)
      ))
    }
    running <- still
  }
}

# Child process: run one test_that() block and save its result.
# Only the index-th test_that() block runs (loop-generated blocks count);
# the file's other code runs too, but the other blocks are skipped without
# evaluating them. The result recorded is the one testthat reports under
# this test's description; if testthat reports anything other than exactly
# that one test, the result is an ERROR.
run_one_test <- function(file, index, result_path) {
  Sys.setenv(POWERKIT_FULL_VALIDATION = "true")
  path <- file.path("engine", "tests", "testthat", file)
  description <- test_descriptions(path)[[index]]
  started <- Sys.time()
  messages <- character()
  reported <- tryCatch(
    {
      pkgload::load_all("engine", helpers = FALSE, quiet = TRUE)
      run_test_file(path, test_that = only_test_number(index))
    },
    error = function(e) {
      messages <<- paste("Could not run the test:", conditionMessage(e))
      NULL
    }
  )
  status <- "ERROR"
  if (!is.null(reported)) {
    ran <- reported_names(reported)
    matching <- which(ran == description)
    if (length(ran) != 1 || length(matching) != 1) {
      messages <- sprintf(
        "Expected testthat to report only this test; it reported %d test%s (%d with this name)%s.",
        length(ran), if (length(ran) == 1) "" else "s", length(matching),
        if (length(ran) > 0) paste0(": ", paste0("\"", ran, "\"", collapse = ", ")) else ""
      )
      reported <- NULL
    }
  }
  if (!is.null(reported)) {
    expectations <- reported[[matching]]$results
    classes <- vapply(expectations, function(x) class(x)[1], character(1))
    messages <- vapply(expectations, function(x) {
      paste0(sub("^expectation_", "", class(x)[1]), ": ", conditionMessage(x))
    }, character(1))
    status <- if (any(classes %in% c("expectation_error", "error"))) {
      "ERROR"
    } else if (any(classes == "expectation_failure")) {
      "FAIL"
    } else if (any(classes == "expectation_skip")) {
      "SKIP"
    } else {
      "PASS"
    }
  }
  result <- list(
    status = status, file = file, index = index, test = description,
    minutes = as.numeric(difftime(Sys.time(), started, units = "mins")),
    messages = messages, finished = format(Sys.time(), "%Y-%m-%d %H:%M")
  )
  # Write then rename, so a result file is never half-written.
  tmp <- paste0(result_path, ".tmp")
  saveRDS(result, tmp)
  file.rename(tmp, result_path)
  invisible(result)
}

print_chunk_progress <- function(tests) {
  status <- saved_status(tests)
  for (chunk in unique(tests$chunk)) {
    here <- status[tests$chunk == chunk]
    cat(sprintf(
      "%-16s %2d of %2d tests saved (%d PASS, %d FAIL, %d ERROR, %d SKIP)\n",
      chunk, sum(here != "NOT RUN"), length(here), sum(here == "PASS"),
      sum(here == "FAIL"), sum(here == "ERROR"), sum(here == "SKIP")
    ))
  }
  cat(strwrap(paste(
    "Saved tests count as done and don't run again.",
    "Rerun FAIL and ERROR with --retry-failed, and SKIP (for example, tests",
    "skipped for a TODO_PUBLISHED_VALUE that has since been filled in) with",
    "--retry-skipped; --fresh forgets every saved result."
  ), width = 78), sep = "\n")
  tests
}

write_summary <- function(tests, results_dir, cores) {
  saved <- lapply(seq_len(nrow(tests)), function(i) saved_result(tests[i, ]))
  status <- vapply(saved, function(r) if (is.null(r)) "NOT RUN" else r$status, character(1))
  versions <- c(
    powerkit = unname(read.dcf(file.path("engine", "DESCRIPTION"), "Version")[1, 1]),
    vapply(
      c("Superpower", "Spower", "InteractionPoweR", "power4mome", "manymome", "lavaan", "testthat"),
      function(p) tryCatch(as.character(utils::packageVersion(p)), error = function(e) "not installed"),
      character(1)
    )
  )
  git <- function(...) {
    tryCatch(
      system2("git", c(...), stdout = TRUE, stderr = FALSE),
      error = function(e) character(), warning = function(w) character()
    )
  }
  commit <- paste(git("rev-parse", "--short", "HEAD"), collapse = "")
  if (!nzchar(commit)) commit <- "unknown"
  if (length(git("status", "--porcelain", "--untracked-files=no")) > 0) {
    commit <- paste(commit, "(with uncommitted changes)")
  }
  lines <- c(
    "===== powerkit validation summary (copy from here) =====",
    sprintf("Date: %s   Commit: %s   Cores: %s", format(Sys.time(), "%Y-%m-%d %H:%M"), commit, cores),
    sprintf("R: %s   Platform: %s", R.version.string, R.version$platform),
    paste0("Packages: ", paste(names(versions), versions, collapse = ", ")),
    sprintf(
      "Totals: %d PASS, %d FAIL, %d ERROR, %d SKIP, %d NOT RUN (of %d)",
      sum(status == "PASS"), sum(status == "FAIL"), sum(status == "ERROR"),
      sum(status == "SKIP"), sum(status == "NOT RUN"), length(status)
    ),
    ""
  )
  for (i in seq_len(nrow(tests))) {
    r <- saved[[i]]
    # Grid cells with results are shown in the grid table below.
    if (tests$kind[i] == "cell" && status[i] %in% c("PASS", "FAIL")) {
      next
    }
    lines <- c(lines, sprintf(
      "%-7s %s / %s%s", status[i], tests$chunk[i], tests$test[i],
      if (is.null(r)) "" else sprintf(" (%s)", format_minutes(r$minutes))
    ))
    if (!is.null(r) && status[i] != "SKIP") {
      lines <- c(lines, paste0("          ", r$messages))
    }
  }
  lines <- c(lines, grid_summary_lines(saved[tests$kind == "cell"]), "===== end of summary =====")
  writeLines(lines, file.path(results_dir, "summary.txt"))
  cat("\n", paste(lines, collapse = "\n"), "\n", sep = "")
  cat(sprintf("\nSaved to %s\n", file.path(results_dir, "summary.txt")))
  invisible(lines)
}

format_minutes <- function(minutes) {
  minutes <- max(0, minutes)
  if (minutes < 1) {
    return(sprintf("%ds", round(minutes * 60)))
  }
  sprintf("%dh %02dm", floor(minutes / 60), round(minutes %% 60))
}

# Command line ------------------------------------------------------------------

if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 1 && args[1] == "--run-one") {
    run_one_test(args[2], as.integer(args[3]), args[4])
  } else if (length(args) >= 1 && args[1] == "--run-cell") {
    run_one_cell(as.integer(args[2]), args[3])
  } else if (length(args) >= 2 && args[1] == "--list-tests") {
    list_tests_with_testthat(args[2], args[-(1:2)])
  } else {
    value_of <- function(flag) {
      i <- match(flag, args)
      if (is.na(i) || i == length(args)) NULL else args[i + 1]
    }
    # A count option: its default if the flag isn't given; otherwise the
    # value after it, which must be there (not another --flag).
    count_of <- function(flag, default) {
      if (!flag %in% args) {
        return(default)
      }
      value <- value_of(flag)
      if (is.null(value) || startsWith(value, "--")) {
        stop(sprintf("%s needs a value, such as %s 4.", flag, flag), call. = FALSE)
      }
      value
    }
    run_validation(
      only = value_of("--only"),
      cores = count_of("--cores", 2),
      cores_per_test = count_of("--cores-per-test", 1),
      retry_failed = "--retry-failed" %in% args,
      retry_skipped = "--retry-skipped" %in% args,
      fresh = "--fresh" %in% args,
      list_only = "--list" %in% args,
      summary_only = "--summary" %in% args
    )
  }
}
