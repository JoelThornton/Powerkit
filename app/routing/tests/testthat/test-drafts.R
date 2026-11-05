test_that("incomplete drafts survive two file round trips without a result", {
  route <- list(app = "routing-prototype", route = "choose", endpoint = "E2", came_from = "node",
    start = list(), ctx = list(), history = list(), form_k = 2L,
    form_values = list(d = "", power = "", just_source = "", allocation_ratio = "2"))
  file <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(file))
  for (i in 1:2) {
    write_draft(route, file)
    record <- read_draft_record(file)
    expect_identical(record$format, "powerkit-draft")
    expect_null(record$result)
    expect_null(record$spec)
    restored <- restore_draft(record, tree, forms)
    expect_type(restored, "list")
    expect_identical(restored$form_values, route$form_values)
    expect_null(restored$calc)
    route$form_values <- restored$form_values
  }
  record$result <- list(power = 1)
  expect_null(restore_draft(record, tree, forms)$calc)
  record$version <- 99
  expect_type(restore_draft(record, tree, forms), "character")
})

test_that("drafts allow no answers and reject unsupported fields and malformed values", {
  record <- list(format = "powerkit-draft", version = 1L, route = list(app = "routing-prototype",
    endpoint = "E2", form_values = list()))
  expect_type(restore_draft(record, tree, forms), "list")
  record$route$form_values <- list(not_a_field = "anything")
  expect_type(restore_draft(record, tree, forms), "character")
  record$route$form_values <- list(d = list(deep = list(a = 1)))
  expect_type(restore_draft(record, tree, forms), "character")
  expect_match(as.character(draft_opened_ui("2026-11-04")), "No calculated or validated result", fixed = TRUE)
})
