test_that("opening a draft clears an earlier result and restores an incomplete form", {
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  route <- list(app = "routing-prototype", endpoint = "E2", route = "choose",
    start = list(), ctx = list(), history = list(), form_k = 2L,
    form_values = list(d = "", power = "0.8", just_source = ""))
  write_draft(route, path)
  shiny::testServer(routing_dir, {
    state$calc <- list(status = "previous-result")
    session$setInputs(open_project = data.frame(name = "draft.powerkit.json",
      size = file.info(path)$size, type = "application/json", datapath = path))
    expect_null(state$calc)
    expect_null(state$long_spec)
    expect_identical(state$endpoint, "E2")
    expect_identical(state$screen, "form")
    expect_identical(state$form_values$d, "")
    expect_identical(state$form_values$power, "0.8")
    expect_match(output$form_result$html, "Unfinished draft opened", fixed = TRUE)
  })
})
