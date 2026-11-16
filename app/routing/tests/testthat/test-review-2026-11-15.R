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

# Layout review, 16 November 2026 ---------------------------------------------

test_that("the whole-study route says which route it is on every screen", {
  for (screen in c("aim", "node", "g_vars", "g_analyses")) {
    html <- as.character(route_marker_ui("guided", screen))
    expect_match(html, "Planning a whole study", fixed = TRUE)
    expect_match(html, "route:choose", fixed = TRUE)
  }
  expect_null(route_marker_ui("choose", "node"))
  expect_null(route_marker_ui("guided", "start"))
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "tagList(route_marker_ui(state$route, state$screen), switch(", fixed = TRUE)
})

test_that("Replicate a published finding starts a replication plan at the original study", {
  aim <- aim_question(tree)
  expect_match(aim$options$replicate$help %||% "", "^Starts a replication plan")
  shiny::testServer(routing_dir, {
    before <- length(state$plans)
    session$setInputs(pick = "aim:replicate")
    expect_identical(length(state$plans), before + 1L)
    plan <- state$plans[[state$rep_plan]]
    expect_true(plan_is_replication(plan))
    expect_identical(state$plans_view, plan$id)
  })
})
