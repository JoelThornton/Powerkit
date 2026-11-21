# Runs one part of a test suite on a CI runner, several test files at a
# time.
#
#   Rscript .github/ci/run-test-part.R <suite> <part> <parts> <lanes>
#
# <suite> is "engine" (engine/tests/testthat, against the installed
# powerkit) or "app" (app/routing/tests/testthat). The suite's test files
# are dealt to parts * lanes lanes by the time each took in an earlier run
# (.github/ci/<suite>-test-times.csv): longest first, each to the lane
# with the least time so far, so every lane takes about the same time. A
# file with no recorded time counts as the median. Lanes 1 to <lanes>
# belong to part 1, the next <lanes> to part 2, and so on, so every file
# runs in exactly one part. This part's lanes run side by side, each in
# its own R process (one process per lane, its files one after another),
# and their output is printed lane by lane once all have finished.
#
# The seconds each file took are printed at the end ("<suite>-test-times
# (file,seconds)"); paste the rows of every part into the times file to
# rebalance. The script fails if any test failed or erred, if a lane's
# process ended without its results, or if a part was given no files.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4)
suite <- args[[1]]
part <- as.integer(args[[2]])
parts <- as.integer(args[[3]])
lanes <- as.integer(args[[4]])
stopifnot(suite %in% c("engine", "app"), part >= 1, part <= parts, lanes >= 1)

dir <- switch(suite, engine = "engine/tests/testthat", app = "app/routing/tests/testthat")
times_file <- file.path(".github/ci", paste0(suite, "-test-times.csv"))

deal_files <- function(names, seconds, bins) {
  seconds[is.na(seconds)] <- if (all(is.na(seconds))) 1 else stats::median(seconds, na.rm = TRUE)
  load <- numeric(bins)
  bin_of <- integer(length(names))
  for (i in order(-seconds, names)) {
    bin_of[i] <- which.min(load)
    load[bin_of[i]] <- load[bin_of[i]] + seconds[i]
  }
  list(bin_of = bin_of, load = load)
}

files <- sort(list.files(dir, pattern = "^test-.*\\.R$"))
names <- sub("^test-(.*)\\.R$", "\\1", files)
times <- if (file.exists(times_file)) utils::read.csv(times_file) else data.frame(file = character(), seconds = numeric())
dealt <- deal_files(names, times$seconds[match(names, times$file)], parts * lanes)
my_lanes <- (part - 1L) * lanes + seq_len(lanes)
lane_files <- lapply(my_lanes, function(b) names[dealt$bin_of == b])
lane_files <- lane_files[lengths(lane_files) > 0]
if (length(lane_files) == 0) stop("This part was given no test files.", call. = FALSE)

cat(sum(lengths(lane_files)), "of", length(names), "test files in part", part, "of", parts, "in",
  length(lane_files), "lanes; recorded minutes per lane:",
  paste(round(dealt$load[my_lanes] / 60, 1), collapse = ", "), "\n\n")

run_lane <- function(dir, suite, files) {
  # One file at a time in this process: the lanes are the parallelism.
  Sys.setenv(TESTTHAT_PARALLEL = "false")
  if (suite == "engine") library(powerkit)
  results <- testthat::test_dir(dir,
    package = if (suite == "engine") "powerkit",
    load_package = if (suite == "engine") "installed" else "none",
    filter = paste0("^(", paste(files, collapse = "|"), ")$"),
    reporter = "progress", stop_on_failure = FALSE)
  as.data.frame(results)
}

logs <- vapply(seq_along(lane_files), function(i) tempfile(sprintf("lane-%d-", i), fileext = ".log"), "")
started <- Sys.time()
procs <- lapply(seq_along(lane_files), function(i) {
  callr::r_bg(run_lane, args = list(dir = dir, suite = suite, files = lane_files[[i]]),
    stdout = logs[[i]], stderr = "2>&1", supervise = TRUE)
})
for (p in procs) p$wait()

results <- list()
broken <- character()
for (i in seq_along(procs)) {
  cat(sprintf("\n===== Lane %d: %s =====\n", i, paste(lane_files[[i]], collapse = ", ")))
  cat(readLines(logs[[i]], warn = FALSE), sep = "\n")
  res <- tryCatch(procs[[i]]$get_result(), error = function(e) {
    cat("\nThis lane's R process ended without its results:", conditionMessage(e), "\n")
    NULL
  })
  if (is.null(res)) broken <- c(broken, sprintf("lane %d", i)) else results[[length(results) + 1]] <- res
}
df <- do.call(rbind, results)
cat(sprintf("\nPart %d took %.1f minutes.\n", part, as.numeric(difftime(Sys.time(), started, units = "mins"))))

if (!is.null(df) && nrow(df) > 0) {
  took <- tapply(df$real, sub("^test-(.*)\\.R$", "\\1", df$file), sum)
  cat(sprintf("\n%s-test-times (file,seconds):\n", suite))
  cat(sprintf("%s,%.1f", names(took), took), sep = "\n")
}
if (length(broken) > 0) stop("No results from ", paste(broken, collapse = ", "), "; see above.", call. = FALSE)
failed <- df[df$failed > 0 | df$error, c("file", "test")]
if (nrow(failed) > 0) {
  cat("\nFailed or erred:\n")
  cat(sprintf("  %s: %s", failed$file, failed$test), sep = "\n")
  stop("Some ", suite, " tests failed; see above.", call. = FALSE)
}
