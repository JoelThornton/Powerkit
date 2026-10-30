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

test_that("the scheduled validation knows every chunk and what each long chunk depends on", {
  old <- setwd(repo_dir)
  on.exit(setwd(old))
  plan <- new.env()
  sys.source(file.path("scripts", "validation-plan.R"), envir = plan)
  scheduled <- setdiff(names(plan$validation_chunks()), "interaction_grid")
  expect_setequal(names(plan$validation_minutes()), scheduled)
  expect_setequal(names(plan$chunk_sources()), plan$long_chunks())
  for (path in c(unlist(plan$chunk_sources()), plan$shared_sources)) {
    expect_true(file.exists(path), label = path)
  }
  expect_setequal(plan$plan_chunks(all = TRUE), scheduled)
  expect_length(plan$plan_chunks("docs/status.md"), 0)
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

# powerkit's version (docs/adding-a-test.md, "Version numbers") -------------
#
# engine/DESCRIPTION is the single source. The About page, CITATION.cff and
# NEWS.md all have to agree with it, or a user quoting a version can't
# trace what produced their number.

test_that("the version in DESCRIPTION, CITATION.cff and the About page agree", {
  description <- read.dcf(file.path(repo_dir, "engine", "DESCRIPTION"))
  version <- unname(description[1, "Version"])
  # 0.x.y while powerkit is a prototype; 1.0.0 is the release.
  expect_match(version, "^[0-9]+\\.[0-9]+\\.[0-9]+$")

  cff <- readLines(file.path(repo_dir, "CITATION.cff"), warn = FALSE)
  expect_true(paste("version:", version) %in% cff)

  # The About page quotes the installed engine's version, so it can only be
  # checked where the engine is installed.
  skip_if_not(nzchar(system.file(package = "powerkit")), "powerkit isn't installed")
  expect_equal(powerkit_version(), version)
  expect_match(as.character(about_ui(tree, forms)), paste("powerkit", version), fixed = TRUE)
})

test_that("_dependencies.R names every package the engine imports", {
  # scripts/setup-cloud-session-apt.sh installs exactly this list, so a
  # missing import leaves the engine uninstallable on that route.
  description <- read.dcf(file.path(repo_dir, "engine", "DESCRIPTION"), fields = "Imports")
  imports <- trimws(sub("\\(.*", "", strsplit(description[1, "Imports"], ",")[[1]]))
  base <- rownames(installed.packages(priority = "base"))
  declared <- sub("^library\\(([^)]+)\\).*", "\\1",
                  grep("^library\\(", readLines(file.path(repo_dir, "_dependencies.R")), value = TRUE))
  expect_equal(setdiff(setdiff(imports, base), declared), character(0))
})

test_that("every analysis the app calculates is listed on the About page", {
  html <- as.character(about_ui(tree, forms))
  calculates <- c(unlist(forms$calculates), names(forms$simulations$endpoints %||% list()))
  expect_gte(length(calculates), 20)
  for (id in calculates) {
    expect_match(html, sprintf("<strong>%s</strong>", id), fixed = TRUE, label = id)
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
  }
})

# The engine and the app can't drift apart (docs/adding-a-test.md) ----------
#
# Five designs once ran in the engine with no way to reach them in the app,
# and three of them had cards saying powerkit couldn't do what it could.
# This test makes that state declared rather than accidental: every design
# the engine accepts is either named by a card or listed in forms.yaml's
# `engine_only`, with the batch that will finish it.

engine_templates <- function() {
  schema <- jsonlite::fromJSON(
    file.path(repo_dir, "engine", "inst", "schema", "design.schema.json"),
    simplifyVector = FALSE
  )
  found <- character()
  walk <- function(node) {
    if (is.list(node)) {
      # A design lists its templates as an enum; a design with only one
      # could use a const instead, and the branch that selects each
      # template's definition always does. Collect both, or a design could
      # be added that this test never sees.
      template <- node$properties$template
      if (!is.null(template)) {
        found <<- c(found, unlist(template$enum), unlist(template$const))
      }
      lapply(node, walk)
    }
    invisible(NULL)
  }
  walk(schema)
  sort(unique(found))
}

test_that("every design the engine computes is named by a card or listed as waiting", {
  templates <- engine_templates()
  expect_gte(length(templates), 30)
  # Cards name their engine design and template, e.g. "basic_test /
  # one_sample_t" or "generic_test / t, f, chi_square or z".
  named <- unlist(lapply(tree$endpoints, function(e) e$template))
  tokens <- unlist(regmatches(named, gregexpr("[a-z0-9_]+", named)))
  waiting <- as.character(names(forms$engine_only))

  unreachable <- setdiff(templates, c(tokens, waiting))
  expect_equal(unreachable, character(), info = paste(
    "these designs run in the engine but no card names them and forms.yaml's",
    "engine_only doesn't list them:", paste(unreachable, collapse = ", ")
  ))

  # The register is for designs that really are missing from the app: once a
  # card names a template, its entry has to go, or the register lies.
  stale <- intersect(waiting, tokens)
  expect_equal(stale, character(), info = paste(
    "forms.yaml's engine_only lists designs a card already names:",
    paste(stale, collapse = ", ")
  ))
  # Every entry says which design it is and which batch will finish it.
  for (name in waiting) {
    expect_match(forms$engine_only[[name]], "batch", fixed = TRUE, label = name)
  }
})

# The queue (docs/next.md) ---------------------------------------------------
#
# "Work on the next thing" only works if every item says whether it can be
# started. This checks the shape of the queue, not its contents.

test_that("every item in the queue says whether it is ready to start", {
  lines <- strsplit(read_doc("next.md"), "\n", fixed = TRUE)[[1]]
  items <- grep("^\\| [0-9]+ \\|", lines, value = TRUE)
  expect_gte(length(items), 10)
  states <- vapply(strsplit(items, "|", fixed = TRUE), function(cells) {
    trimws(cells[[length(cells)]])
  }, "")
  allowed <- "^(Ready|Ready \\(|Needs a decision:|Needs the maintainer:|Blocked by [0-9]+)"
  expect_true(all(grepl(allowed, states)), info = paste(
    "an item's state must start with Ready, 'Needs a decision:',",
    "'Needs the maintainer:' or 'Blocked by <n>'; found:",
    paste(unique(states[!grepl(allowed, states)]), collapse = " / ")
  ))
  # The numbers are in order, so "the first Ready item" is unambiguous.
  numbers <- as.integer(sub("^\\| ([0-9]+) \\|.*", "\\1", items))
  expect_equal(numbers, seq_along(numbers))
})
