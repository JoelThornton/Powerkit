# A study plan checks its shared sample size by rerunning each analysis at
# it (plan_shared_n()), and a replication's agreement criterion has three
# outcomes.

shared_engine <- function(name) engine_function(name, file.path(repo_dir, "engine"))

shared_entry <- function(ep, set, label) {
  run <- shared_engine("run_spec")
  skip_if(is.null(run), "powerkit's engine isn't available here")
  values <- modifyList(form_examples[[ep]], set)
  spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), values)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$status, "ok")
  calc$route <- list(app = "routing-prototype", route = "choose", endpoint = ep, came_from = "node",
    ctx = list(), history = list(), form_k = 2L, form_values = values)
  e <- plan_entry(tree, ep, calc, calc$route)
  e$label <- label
  e
}

test_that("two yes/no outcomes needing 20 and 21 share N = 24, the first N at which both reach 80%", {
  # Two-sided binom.test() at alpha .05, target .80: .80 against .50 and
  # .70 against .40 (audit of the exports, 21 November 2026).
  a <- shared_entry("E25", list(p = "0.8", p0 = "0.5", method = "binom_test", goal = "sample_size", power = "0.8"), "Outcome A")
  b <- shared_entry("E25", list(p = "0.7", p0 = "0.4", method = "binom_test", goal = "sample_size", power = "0.8"), "Outcome B")
  expect_identical(c(a$n, b$n), c(20, 21))
  shared <- plan_shared_n(list(a, b), shared_engine("run_spec"))
  expect_true(shared$checked)
  expect_identical(shared$largest, 21)
  expect_equal(shared$shared, 24)
  expect_equal(shared$at_largest, c(0.769, 0.852), tolerance = 0.001)
  expect_equal(shared$at_shared, c(0.811, 0.847), tolerance = 0.001)
  text <- plan_shared_n_text(shared)
  expect_match(text, "At N = 21, not every analysis reaches its target (Outcome A 76.9%, Outcome B 85.2%).", fixed = TRUE)
  expect_match(text, "The first N at which each one does is N = 24 (Outcome A 81.1%, Outcome B 84.7%).", fixed = TRUE)
  expect_match(text, "not the chance that all of them succeed in the same study", fixed = TRUE)
  # The plan's document says both numbers.
  doc <- paste(plan_planning_document(plan_with(list(a, b)), tree, forms, engine = shared_engine), collapse = "\n")
  expect_match(doc, "The largest of the separate requirements is N = 21, for Outcome B.", fixed = TRUE)
  expect_match(doc, "N = 24", fixed = TRUE)
  # And so does the plan's page.
  html <- as.character(plan_page_ui(plan_with(list(a, b)), shared = shared))
  expect_match(html, "The first N at which each one does is N = 24", fixed = TRUE)
})

test_that("a shared N that can't be rerun is called an unchecked candidate", {
  a <- list(label = "A simulated analysis", n = 100)
  shared <- list(largest = 100, checked = FALSE, unchecked = "A simulated analysis")
  expect_match(plan_shared_n_text(shared), "N = 100 is an unchecked candidate: the power of A simulated analysis at that N couldn't be worked out here", fixed = TRUE)
})

test_that("a replication's agreement criterion reads as three outcomes, with its source", {
  text <- paste(deparse(body(replication_design_table)), collapse = "\n")
  expect_match(text, "Crossing the bound: inconclusive, showing neither agreement nor a difference that matters (Lakens, 2017)", fixed = TRUE)
  expect_true("TOSTER_method" %in% replication_ref_keys)
  bib <- paste(readLines(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"), warn = FALSE), collapse = "\n")
  expect_match(bib, "@Article{TOSTER_method,", fixed = TRUE)
  expect_match(bib, "doi = {10.1177/1948550617697177}", fixed = TRUE)
})
