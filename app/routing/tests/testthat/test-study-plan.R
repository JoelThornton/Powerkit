# The study plan any card can join (R/study-plan.R): the plan lists each
# analysis, names the largest sample size counted in people, says that
# joint power isn't calculated, and saves through the engine.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
write_plan <- engine_function("write_study_plan", file.path(repo_dir, "engine"))
read_plan <- engine_function("read_study_plan", file.path(repo_dir, "engine"))
skip_without_engine_plan <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

fake_entry <- function(label, n, comparable = TRUE, headline = paste("You need", n)) {
  list(endpoint = "E2", label = label, headline = headline, goal = "sample_size", n = n, comparable = comparable)
}

test_that("the plan names the largest sample size counted in people", {
  html <- as.character(study_plan_ui(list(fake_entry("A t-test", 128), fake_entry("A correlation", 194), fake_entry("A cluster trial", 900, comparable = FALSE))))
  expect_match(html, "<strong>N = 194</strong>, for A correlation", fixed = TRUE)
  expect_match(html, "counts groups, not people", fixed = TRUE)
  expect_match(html, "powerkit doesn't calculate it for these designs yet", fixed = TRUE)
  expect_match(html, "Add another analysis", fixed = TRUE)
  expect_match(html, "Save study plan", fixed = TRUE)
})

test_that("one analysis has no joint-power note, and an empty plan says how to add one", {
  one <- as.character(study_plan_ui(list(fake_entry("A t-test", 128))))
  expect_no_match(one, "powerkit doesn't calculate it", fixed = TRUE)
  empty <- as.character(study_plan_ui(list()))
  expect_match(empty, "Your plan is empty", fixed = TRUE)
  expect_no_match(empty, "download_study_plan", fixed = TRUE)
})

test_that("the bar under a result adds the analysis once and links to the plan", {
  expect_match(as.character(study_plan_bar_ui(list(), FALSE)), "Add this to my study plan", fixed = TRUE)
  added <- as.character(study_plan_bar_ui(list(fake_entry("A t-test", 128)), TRUE))
  expect_match(added, "Added to your study plan.", fixed = TRUE)
  expect_match(added, "See your study plan (1 analysis)", fixed = TRUE)
  expect_no_match(added, "Add this to my study plan", fixed = TRUE)
})

test_that("results from two cards save as one plan file and open again", {
  skip_without_engine_plan()
  entry_for <- function(ep) {
    spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), form_examples[[ep]])
    spec$goal <- list(type = "sample_size", power = 0.8)
    spec$options$seed <- 5L
    calc <- run_calculation(spec, run, seed = 5L)
    plan_entry(tree, ep, calc, list(app = "routing-prototype", endpoint = ep))
  }
  entries <- list(entry_for("E2"), entry_for("E3"))
  expect_true(all(vapply(entries, function(e) is.numeric(e$n), logical(1))))
  expect_match(entries[[1]]$headline, "participants", fixed = TRUE)
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_plan(plan_analyses(entries), file = path)
  reopened <- lapply(read_plan(path)$analyses, function(p) plan_entry_from_project(tree, p))
  expect_identical(vapply(reopened, `[[`, "", "endpoint"), c("E2", "E3"))
  expect_identical(vapply(reopened, function(e) e$n, numeric(1)), vapply(entries, function(e) e$n, numeric(1)))
  expect_match(as.character(study_plan_ui(reopened)), "Sample size from the saved result", fixed = TRUE)
})
