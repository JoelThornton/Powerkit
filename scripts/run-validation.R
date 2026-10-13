# Full validation of the powerkit engine, run locally.
#
# Runs the high-replication validation tests (engine/tests/testthat/
# test-validation-*.R) with POWERKIT_FULL_VALIDATION=true, each test in its
# own R process, a few at a time. It is:
#   * resumable: each test's result is saved to validation-results/ as soon
#     as it finishes, and tests with a saved result are skipped next time;
#   * runnable in chunks by design (--only);
#   * independent of any other tool: start it yourself from a terminal or
#     RStudio, and stop it at any time (Ctrl+C in a terminal, Esc or the red
#     stop button in RStudio); rerun the same command to carry on.
# It prints progress and an estimate of the time remaining, and ends with a
# summary (also saved to validation-results/summary.txt) to paste back.
#
# From a terminal, in the repository's top folder:
#   Rscript scripts/run-validation.R                        everything
#   Rscript scripts/run-validation.R --only interactions    one chunk
#   Rscript scripts/run-validation.R --only process_4,process_6 --cores 3
#   Rscript scripts/run-validation.R --list                 chunks and progress
#   Rscript scripts/run-validation.R --summary              summary only
#   Rscript scripts/run-validation.R --retry-failed         rerun FAIL / ERROR
#   Rscript scripts/run-validation.R --fresh                forget saved results
# From RStudio, with Powerkit.Rproj open:
#   source("scripts/run-validation.R")
#   run_validation(only = "interactions", cores = 2)
#
# Chunks: basic, anova, interactions, process_4 (simple and parallel
# mediation), process_6 (serial mediation), process_7, process_14.
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
    basic = "test-validation-basic-tests.R",
    anova = c("test-validation-anova-2x2-between.R", "test-validation-anova-2x2-mixed.R"),
    interactions = "test-validation-regression-interaction.R",
    process_4 = c("test-validation-mediation-simple.R", "test-validation-mediation-parallel.R"),
    process_6 = "test-validation-mediation-serial.R",
    process_7 = "test-validation-modmed-process7.R",
    process_14 = "test-validation-modmed-process14.R"
  )
}

# Rough minutes for one test on one core, by chunk, used only for the time
# estimate (which is then corrected by how fast tests actually run).
# Direct-call tests run two simulations, so count double.
validation_minutes <- function() {
  c(basic = 0.3, anova = 15, interactions = 1.5, process_4 = 60,
    process_6 = 60, process_7 = 120, process_14 = 120)
}

run_validation <- function(only = NULL, cores = 2, retry_failed = FALSE,
                            fresh = FALSE, list_only = FALSE,
                            summary_only = FALSE) {
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
  tests$done <- file.exists(tests$result)
  if (isTRUE(retry_failed)) {
    failed <- tests$done & vapply(tests$result, function(f) {
      file.exists(f) && readRDS(f)$status %in% c("FAIL", "ERROR")
    }, logical(1))
    file.remove(tests$result[failed])
    tests$done[failed] <- FALSE
  }
  if (isTRUE(list_only)) {
    return(invisible(print_chunk_progress(tests)))
  }
  if (isTRUE(summary_only)) {
    return(invisible(write_summary(tests, results_dir, cores)))
  }

  todo <- tests[!tests$done, ]
  todo <- todo[order(-todo$estimate), ]
  cores <- max(1L, as.integer(cores))
  cat(sprintf(
    "powerkit validation: %d tests selected, %d already saved, %d to run, on %d core%s.\n",
    nrow(tests), sum(tests$done), nrow(todo), cores, if (cores == 1) "" else "s"
  ))
  if (nrow(todo) > 0) {
    cat(sprintf(
      "First estimate of the time needed: %s (it is corrected as tests finish).\n",
      format_minutes(sum(todo$estimate) / min(cores, nrow(todo)))
    ))
    cat("Stop at any time with Ctrl+C (terminal) or Esc (RStudio); rerun the same command to carry on.\n\n")
    run_queue(todo, cores, nrow(tests) - nrow(todo), nrow(tests))
  }
  tests$done <- file.exists(tests$result)
  invisible(write_summary(tests, results_dir, cores))
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
        estimate = minutes[[chunk]] * ifelse(grepl("direct", descriptions), 2, 1),
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

test_descriptions <- function(path) {
  exprs <- parse(path, keep.source = FALSE)
  calls <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("test_that")), as.list(exprs))
  vapply(calls, function(e) as.character(e[[2]]), character(1))
}

# Run the queue, at most `cores` tests at a time, each in its own R process.
run_queue <- function(todo, cores, already, total) {
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
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
        env = c("current", POWERKIT_FULL_VALIDATION = "true", POWERKIT_CORES = "1")
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
      if (file.exists(row$result)) {
        result <- readRDS(row$result)
        status <- result$status
        if (status != "SKIP") {
          speed$actual <- speed$actual + minutes
          speed$estimated <- speed$estimated + row$estimate
        }
      } else {
        status <- "DID NOT FINISH (no result saved; it will run again next time)"
      }
      remaining <- todo$estimate[seq_len(nrow(todo)) >= next_row]
      remaining <- c(remaining, vapply(still, function(j) j$row$estimate, numeric(1)))
      factor <- if (speed$estimated > 0) speed$actual / speed$estimated else 1
      eta <- sum(remaining) * factor / max(1, min(cores, length(remaining)))
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
run_one_test <- function(file, index, result_path) {
  Sys.setenv(POWERKIT_FULL_VALIDATION = "true")
  path <- file.path("engine", "tests", "testthat", file)
  description <- test_descriptions(path)[[index]]
  started <- Sys.time()
  messages <- character()
  results <- tryCatch(
    testthat::test_file(
      path, desc = description, package = "powerkit",
      load_package = "source", reporter = testthat::ListReporter$new()
    ),
    error = function(e) {
      messages <<- paste("Could not run the test:", conditionMessage(e))
      NULL
    }
  )
  status <- "ERROR"
  if (!is.null(results)) {
    expectations <- results[[1]]$results
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
  for (chunk in unique(tests$chunk)) {
    rows <- tests[tests$chunk == chunk, ]
    cat(sprintf("%-13s %2d of %2d tests saved\n", chunk, sum(rows$done), nrow(rows)))
  }
  tests
}

write_summary <- function(tests, results_dir, cores) {
  saved <- lapply(tests$result, function(f) if (file.exists(f)) readRDS(f))
  status <- vapply(saved, function(r) if (is.null(r)) "NOT RUN" else r$status, character(1))
  versions <- c(
    powerkit = unname(read.dcf(file.path("engine", "DESCRIPTION"), "Version")[1, 1]),
    vapply(
      c("Superpower", "Spower", "InteractionPoweR", "power4mome", "lavaan", "testthat"),
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
  } else {
    value_of <- function(flag) {
      i <- match(flag, args)
      if (is.na(i) || i == length(args)) NULL else args[i + 1]
    }
    run_validation(
      only = value_of("--only"),
      cores = as.integer(value_of("--cores") %||% 2),
      retry_failed = "--retry-failed" %in% args,
      fresh = "--fresh" %in% args,
      list_only = "--list" %in% args,
      summary_only = "--summary" %in% args
    )
  }
}
