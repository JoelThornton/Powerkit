# Keeping the visitor's place and showing that the app is working
# (R/connection.R, 5 November 2026).

test_that("the page arrives with the starting screen, the busy bar and the connection-lost message", {
  html <- as.character(connection_ui())
  expect_match(html, "Starting powerkit", fixed = TRUE)
  expect_match(html, 'id="pk-busy"', fixed = TRUE)
  expect_match(html, "The connection to powerkit was lost.", fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "session$allowReconnect(TRUE)", fixed = TRUE)
  expect_match(app, "connection_ui()", fixed = TRUE)
})

test_that("answers saved in the browser come back as a draft the app can reopen", {
  state <- list(route = "choose", endpoint = "E2", came_from = "node", ctx = list(outcome = "score"),
    history = list(), form_k = 2L)
  ids <- vapply(form_fields(form_groups(forms, "E2")), `[[`, "", "id")
  route <- project_route(state, form_examples$E2[intersect(names(form_examples$E2), ids)])
  record <- autosave_record(route)
  text <- as.character(jsonlite::toJSON(record, auto_unbox = TRUE, null = "null"))
  back <- autosave_from_browser(text)
  expect_identical(back$format, "powerkit-draft")
  restored <- restore_draft(back, tree, forms)
  expect_false(is.character(restored))
  expect_identical(restored$endpoint, "E2")
  # Anything else is ignored rather than trusted.
  expect_null(autosave_from_browser("not json"))
  expect_null(autosave_from_browser(as.character(jsonlite::toJSON(list(format = "something else"), auto_unbox = TRUE))))
})
