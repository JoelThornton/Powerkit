# Runs kept in a study plan (16 November 2026): a long run can move from
# the input screen to a study plan and carry on while the person goes
# elsewhere in the app, with its progress on the plan's page.

test_that("a long run offers a place in a study plan, hidden until it has run a while", {
  html <- as.character(calculating_background_ui(120, keep = TRUE))
  expect_match(html, 'id="calc-keep"', fixed = TRUE)
  expect_match(html, "hidden", fixed = TRUE)
  expect_match(html, 'id="calc_keep"', fixed = TRUE)
  expect_match(html, "Keep this browser tab open", fixed = TRUE)
  # Previews and quick runs don't offer it.
  expect_no_match(as.character(calculating_background_ui(20)), "calc_keep", fixed = TRUE)
  expect_gt(keep_offer_after, 0)
  moved <- as.character(kept_run_moved_ui("My study"))
  expect_match(moved, "Running in your study plan “My study”", fixed = TRUE)
  expect_match(moved, "plan_view", fixed = TRUE)
})

test_that("a plan's page shows its running analyses with a bar and a Stop button", {
  plan <- new_plan("My study")
  runs <- list(list(id = "abc", plan = plan$id, label = "Repeated measures", usual = 120))
  page <- as.character(plan_page_ui(plan, 1L, runs))
  expect_match(page, "Still running", fixed = TRUE)
  expect_match(page, 'id="kept-bar-abc"', fixed = TRUE)
  expect_match(page, 'id="kept-text-abc"', fixed = TRUE)
  expect_match(page, "kept_stop", fixed = TRUE)
  # A plan with only a running analysis isn't described as empty.
  expect_no_match(page, "This plan has no analyses yet", fixed = TRUE)
  expect_match(as.character(plan_page_ui(plan, 1L)), "This plan has no analyses yet", fixed = TRUE)
  expect_null(plan_running_ui(list()))
  # The list of plans counts them.
  plans <- stats::setNames(list(plan), plan$id)
  expect_match(as.character(plans_list_ui(plans, running = plan$id)), "1 still running", fixed = TRUE)
  expect_no_match(as.character(plans_list_ui(plans)), "still running", fixed = TRUE)
})

test_that("the server moves the run, keeps the page connected and stops kept runs with the session", {
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "observeEvent(input$calc_keep", fixed = TRUE)
  expect_match(code, "session$sendCustomMessage(\"kept_progress\"", fixed = TRUE)
  expect_match(code, "Shiny.addCustomMessageHandler('kept_progress'", fixed = TRUE)
  expect_match(code, "session$onSessionEnded(function() for (id in names(kept$runs)) kept_stop(id))", fixed = TRUE)
  expect_match(code, "plan_add_entry(plan, plan_entry(tree, shown$ep_id, calc, calc$route))", fixed = TRUE)
  connection <- paste(readLines(file.path(routing_dir, "R", "connection.R")), collapse = "\n")
  expect_match(connection, "e.message.custom.kept_progress", fixed = TRUE)
})
