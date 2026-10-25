# Checks that span the repository: the docs have to agree with the scripts
# and the engine's tests, not only with tree.yaml (which test-docs-match.R
# covers). They live in the app's suite because it is the only one that
# runs with the repository root to hand: the engine's own tests run against
# a built copy of engine/ and can't see docs/ or scripts/.

test_that("every validation file is in a chunk of run-validation.R, with a time estimate", {
  # Sourced inside this function, so the script's command-line block (which
  # is guarded by sys.nframe() == 0) doesn't start a validation run.
  script <- new.env()
  sys.source(file.path(repo_dir, "scripts", "run-validation.R"), envir = script)
  chunks <- script$validation_chunks()

  on_disk <- basename(Sys.glob(file.path(repo_dir, "engine", "tests", "testthat", "test-validation-*.R")))
  # A file in no chunk never runs in the full validation; a chunk naming a
  # file that doesn't exist fails only when someone runs that chunk.
  expect_setequal(unlist(chunks, use.names = FALSE), on_disk)
  # Without an estimate the progress report has no time to divide.
  expect_setequal(names(chunks), names(script$validation_minutes()))
})

test_that("every chunk of run-validation.R can be chosen in the full-validation workflow", {
  script <- new.env()
  sys.source(file.path(repo_dir, "scripts", "run-validation.R"), envir = script)
  workflow <- yaml::read_yaml(file.path(repo_dir, ".github", "workflows", "full-validation.yaml"))
  # YAML 1.1 reads the key "on" as the boolean true, so it arrives named
  # "TRUE" rather than "on".
  triggers <- workflow[[which(names(workflow) %in% c("on", "true", "TRUE"))[1]]]
  offered <- unlist(triggers$workflow_dispatch$inputs$chunk$options)
  expect_false(is.null(offered))
  # interaction_grid is on demand only and deliberately not offered.
  expect_setequal(setdiff(names(script$validation_chunks()), "interaction_grid"), offered)
})

test_that("every test named in conventions.md exists, with the name it is given", {
  text <- read_doc("conventions.md")
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  bullets <- grep("^- \\*\\*", lines)
  blocks <- lapply(grep("^- \\*\\*Test", lines), function(start) {
    after <- bullets[bullets > start]
    stop_at <- if (length(after)) after[1] - 1 else length(lines)
    paste(lines[start:stop_at], collapse = " ")
  })
  expect_gt(length(blocks), 10)

  test_dirs <- file.path(repo_dir, c("engine/tests/testthat", "app/routing/tests/testthat"))
  squash <- function(x) gsub("\\s+", " ", trimws(x))
  found <- function(pattern, block) {
    hits <- regmatches(block, gregexpr(pattern, block, perl = TRUE))[[1]]
    gsub("^[`\"]|[`\"]$", "", hits)
  }
  for (block in blocks) {
    files <- Filter(function(f) grepl("test-.*\\.R$", f), found("`[^`]+`", block))
    paths <- unlist(lapply(basename(files), function(f) {
      Filter(file.exists, file.path(test_dirs, f))
    }))
    # A named file must exist; a quoted test name must be in one of them.
    expect_equal(length(paths), length(files), info = block)
    if (!length(paths)) next
    contents <- squash(paste(vapply(paths, function(p) {
      paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = " ")
    }, ""), collapse = " "))
    for (name in found('"[^"]+"', block)) {
      # conventions.md escapes * for markdown; the test name doesn't.
      expect_true(grepl(squash(gsub("\\\\\\*", "*", name)), contents, fixed = TRUE), info = name)
    }
  }
})

test_that("coverage-roadmap.md's summary counts match the rows", {
  rows <- roadmap_rows()
  part <- substr(rows$id, 1, 1)
  summary_lines <- grep("^\\| [A-Z]", strsplit(read_doc("coverage-roadmap.md"), "\n", fixed = TRUE)[[1]], value = TRUE)
  summary_lines <- Filter(function(l) grepl("\\| [0-9]+ \\| [0-9]+ \\| [0-9]+ \\| [0-9]+ \\|$", l), summary_lines)
  expect_gt(length(summary_lines), 5)
  for (line in summary_lines) {
    cells <- split_row(line)
    # "Done (validated and wired)" counts the rows whose status starts "Done".
    term <- trimws(sub("\\(.*", "", cells[1]))
    counted <- vapply(c("A", "B", "C"), function(p) {
      sum(part == p & startsWith(rows$status, term), na.rm = TRUE)
    }, integer(1))
    expect_equal(
      as.integer(cells[2:5]), unname(c(counted, sum(counted))),
      info = sprintf("%s: rows give %s", cells[1], paste(counted, collapse = "/"))
    )
  }
})
