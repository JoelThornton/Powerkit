# Fixes from the reviews of 15 November 2026 (completeness and design P-..,
# colleague walkthrough W-..).

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

test_that("an effect source of one study with no adjustment written still calculates, and the write-up says so (P-05)", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples$E2, list(just_type = "prior_study", just_adjustment = ""))
  expect_length(form_problems(fields, values), 0)
  skip_without_run()
  spec <- build_spec(forms, "E2", fields, values)
  calc <- run_calculation(spec, run, seed = 1L)
  w <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "No adjustment for the uncertainty of a single study was recorded.", fixed = TRUE)
  # Welch's test is named once, without two sets of brackets in a row (P-15).
  expect_no_match(w[["short"]], ") (", fixed = TRUE)
  expect_match(w[["short"]], "Welch's independent-samples t-test", fixed = TRUE)
})

test_that("no internal card code is shown in a card's points (P-03)", {
  for (id in names(tree$endpoints)) {
    points <- unlist(tree$endpoints[[id]]$card_points)
    expect_false(any(grepl("\\bE[0-9]+\\b", points)), label = id)
  }
})

test_that("Labs has no 'more tools will be added' line, and links end without a space before the full stop (P-09, P-12)", {
  html <- as.character(labs_ui(tree))
  expect_no_match(html, "More tools will be added", fixed = TRUE)
  expect_no_match(html, "</a>\\s+\\.")
})

test_that("Cohen's f is offered as soon as the effect size is chosen, before a goal (W-03)", {
  fields <- form_fields(form_groups(forms, "E7"))
  conv <- Filter(function(f) identical(f$id, "conv_from"), fields)[[1]]
  values <- modifyList(form_examples$E7, list(metric = "eta_squared", goal = NULL))
  expect_true(field_applies(conv, values))
  expect_match(conv$choices$f, "Cohen's f", fixed = TRUE)
  expect_false(field_applies(conv, modifyList(values, list(goal = "sensitivity"))))
  # The screen switches the test version to the classical ANOVA.
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'updateSelectInput(session, "f_test_version", selected = "anova_f")', fixed = TRUE)
})

test_that("the start screen says which designs give their sample size as an R script (W-02)", {
  expect_match(tree$routes$tester_note, "sample size comes as an R script", fixed = TRUE)
})
