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

# One row per test_that() block in the selected chunks.
validation_tests <- function(root, only) {
  chunks <- validation_chunks()
  if (!is.null(only)) {
    only <- trimws(unlist(strsplit(only, ",")))
    unknown <- setdiff(only, names(chunks))
    if (length(unknown) > 0) {
      stop(sprintf(
        "Unknown chunk %s. Choose from: %s.",
        paste0("'", unknown, "'", collapse = ", "), paste(names(chunks), collapse = ", ")
      ), call. = FALSE)
    }
    chunks <- chunks[only]
  }
  minutes <- validation_minutes()
  rows <- lapply(names(chunks), function(chunk) {
    do.call(rbind, lapply(chunks[[chunk]], function(file) {
      path <- file.path(root, "engine", "tests", "testthat", file)
      descriptions <- test_descriptions(path)
      data.frame(
        chunk = chunk,
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
  do.call(rbind, rows)
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
        c(script, "--run-one", row$file, as.character(row$index), row$result),
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
    lines <- c(lines, sprintf(
      "%-7s %s / %s%s", status[i], tests$chunk[i], tests$test[i],
      if (is.null(r)) "" else sprintf(" (%s)", format_minutes(r$minutes))
    ))
    if (!is.null(r) && status[i] != "SKIP") {
      lines <- c(lines, paste0("          ", r$messages))
    }
  }
  lines <- c(lines, "===== end of summary =====")
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
