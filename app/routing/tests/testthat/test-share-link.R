# Share (R/share-link.R): the link carries the same text as the save
# button's file, and opening it goes through the same reader.

draft_route <- function() {
  list(app = "routing-prototype", endpoint = "E2", route = "choose",
    start = list(), ctx = list(), history = list(), form_k = 2L,
    form_values = list(d = "0.4", power = "0.8", just_source = ""))
}

draft_text <- function() {
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_draft(draft_route(), path)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

test_that("each screen marks what Share shares, and Share has one box to copy from", {
  html <- as.character(share_link_ui("project"))
  expect_match(html, 'id="share_project"', fixed = TRUE)
  expect_match(html, 'data-kind="project"', fixed = TRUE)
  expect_match(html, "share-target", fixed = TRUE)
  # A marker, not a button: there is one way to share (layout review,
  # 16 November 2026).
  expect_false(grepl("<button", html, fixed = TRUE))
  expect_error(share_link_ui("something_else"))
  top <- as.character(share_page_ui())
  expect_match(top, 'id="share_button"', fixed = TRUE)
  expect_match(top, "pkShare(this)", fixed = TRUE)
  expect_match(top, 'id="share_box"', fixed = TRUE)
  expect_match(top, "Powerkit stores nothing", fixed = TRUE)
  expect_match(top, "</svg>\\s*Share\\s*</button>")
  # The tooltip says what it shares; the analysis comes before the answers
  # so far, and the page when there is nothing else.
  expect_identical(share_link_titles[["project"]], "Share this analysis")
  expect_identical(share_link_titles[["study_plan"]], "Share this study plan")
  expect_identical(share_link_titles[["page"]], "Share this page")
  expect_lt(match("project", names(share_link_kinds)), match("draft", names(share_link_kinds)))
  expect_match(share_link_js, "classList.contains('disabled')", fixed = TRUE)
  expect_match(share_link_js, "window.pkPageLink", fixed = TRUE)
})

test_that("the link is read from the fragment, which browsers don't send to the server", {
  expect_match(share_link_js, "'shared=1.'", fixed = TRUE)
  expect_match(share_link_js, "window.location.hash", fixed = TRUE)
  expect_match(share_link_js, "history.replaceState", fixed = TRUE)
  expect_match(share_link_js, "deflate-raw", fixed = TRUE)
  expect_false(grepl("location.search", sub("window.location.pathname \\+ window.location.search", "", share_link_js)))
})

test_that("every screen with a save button can be shared", {
  sources <- vapply(file.path(routing_dir, "R", c("keep-result.R", "study-plan.R", "drafts.R", "whole-study.R", "forms_ui.R")),
    function(f) paste(readLines(f), collapse = "\n"), character(1))
  expect_match(sources[[1]], 'share_link_ui("project")', fixed = TRUE)
  expect_match(sources[[2]], 'share_link_ui("study_plan")', fixed = TRUE)
  expect_match(sources[[3]], 'share_link_ui("guided_plan")', fixed = TRUE)
  expect_match(sources[[4]], 'share_link_ui("guided_plan"', fixed = TRUE)
  expect_match(sources[[5]], 'share_link_ui("draft"', fixed = TRUE)
})

test_that("an unpacked link becomes a file only when it is plausible", {
  expect_null(shared_link_file(NULL))
  expect_null(shared_link_file(""))
  expect_null(shared_link_file(c("a", "b")))
  expect_null(shared_link_file(strrep("x", share_link_max_text + 1)))
  path <- shared_link_file("{\"format\": \"powerkit-draft\"}")
  on.exit(unlink(path))
  expect_identical(readLines(path), "{\"format\": \"powerkit-draft\"}")
})

test_that("a link to a draft opens it as the file would", {
  text <- draft_text()
  shiny::testServer(routing_dir, {
    state$calc <- list(status = "previous-result")
    session$setInputs(pk_shared_link = list(text = text, at = 1))
    expect_null(state$calc)
    expect_identical(state$screen, "form")
    expect_identical(state$endpoint, "E2")
    expect_identical(state$form_values$d, "0.4")
    expect_match(output$form_result$html, "Unfinished draft opened", fixed = TRUE)
  })
})

test_that("a broken link changes nothing", {
  shiny::testServer(routing_dir, {
    before <- state$screen
    session$setInputs(pk_shared_link = list(text = "", at = 1))
    expect_identical(state$screen, before)
    session$setInputs(pk_shared_link = list(text = "{not json", at = 2))
    expect_identical(state$screen, before)
    expect_null(state$endpoint)
  })
})

test_that("Share sends the draft's own text, and that text opens again", {
  shiny::testServer(routing_dir, {
    sent <- list()
    session$sendCustomMessage <- function(type, message) sent[[type]] <<- message
    session$setInputs(open_project = data.frame(name = "draft.powerkit.json", size = 1,
      type = "application/json", datapath = { p <- tempfile(); write_draft(draft_route(), p); p }))
    session$setInputs(share_link_request = list(kind = "draft", at = 1))
    out <- sent[["pk_share_link"]]
    expect_null(out$problem)
    record <- jsonlite::fromJSON(out$text, simplifyVector = FALSE)
    expect_identical(record$format, "powerkit-draft")
    expect_identical(record$route$endpoint, "E2")
    state$endpoint <- NULL; state$screen <- "start"
    session$setInputs(pk_shared_link = list(text = out$text, at = 2))
    expect_identical(state$endpoint, "E2")
    expect_identical(state$screen, "form")
  })
})

test_that("Share says what to do when there is nothing to share yet", {
  shiny::testServer(routing_dir, {
    sent <- list()
    session$sendCustomMessage <- function(type, message) sent[[type]] <<- message
    session$setInputs(share_link_request = list(kind = "study_plan", at = 1))
    expect_match(sent[["pk_share_link"]]$problem, "Add an analysis", fixed = TRUE)
    session$setInputs(share_link_request = list(kind = "project", at = 2))
    expect_match(sent[["pk_share_link"]]$problem, "Calculate", fixed = TRUE)
    session$setInputs(share_link_request = list(kind = "nonsense", at = 3))
    expect_match(sent[["pk_share_link"]]$problem, "Save the file instead", fixed = TRUE)
  })
})

test_that("a current result hides the draft row, so Share shares the analysis", {
  expect_match(nav_js, "querySelectorAll('.form-draft-save')", fixed = TRUE)
  expect_match(nav_js, "el.hidden = !!current", fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "current <- !is.null(calc) && calculation_matches_values(calc, current_form_values())", fixed = TRUE)
})
