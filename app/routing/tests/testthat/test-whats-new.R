# The Updates tab (called "What's new" until November 2026) and its source, whats-new.yaml.

whats_new_path <- file.path(routing_dir, "whats-new.yaml")

test_that("every Updates entry has a date, a title and plain-words text", {
  raw <- yaml::read_yaml(whats_new_path, fileEncoding = "UTF-8")$entries
  expect_gt(length(raw), 0)
  for (e in raw) {
    expect_setequal(names(e), c("date", "title", "text"))
    expect_match(e$date, "^\\d{4}-\\d{2}-\\d{2}$", label = e$title)
    expect_false(is.na(as.Date(e$date, optional = TRUE)), label = e$title)
    expect_true(nzchar(e$title) && nzchar(e$text), label = e$date)
    # No internal codes (E5, Departure 6, Known difference 2, #74).
    words <- paste(e$title, e$text)
    expect_false(grepl("\\bE[0-9]+\\b|Departure [0-9]|Known difference [0-9]|#[0-9]+", words), label = e$title)
  }
  # Written newest first, so the file reads the same way as the tab.
  dates <- as.Date(vapply(raw, `[[`, "", "date"))
  expect_identical(dates, sort(dates, decreasing = TRUE))
})

test_that("the Updates tab shows the entries newest first, grouped by day", {
  entries <- load_whats_new(whats_new_path)
  html <- as.character(whats_new_ui(entries))
  expect_match(html, "<h2>Updates</h2>", fixed = TRUE)
  first <- entries[[1]]
  expect_match(html, htmltools::htmlEscape(first$title), fixed = TRUE)
  day <- as.Date(first$date)
  heading <- paste(as.integer(format(day, "%d")), format(day, "%B %Y"))
  expect_match(html, heading, fixed = TRUE)
  # Each day appears once, as a heading; only the latest is open, and the
  # older days fold by month.
  days <- unique(vapply(entries, `[[`, "", "date"))
  expect_length(regmatches(html, gregexpr("<h3 class=\"wn-day-head\">", html))[[1]], length(days))
  months <- unique(format(as.Date(days[-1]), "%Y-%m"))
  expect_length(regmatches(html, gregexpr("<details class=\"wn-month\">", html))[[1]], length(months))
  expect_length(regmatches(html, gregexpr("<article class=\"wn-entry\"", html))[[1]], length(entries))
})

test_that("Updates can be searched and marks changes since your last visit", {
  html <- as.character(whats_new_ui(load_whats_new(whats_new_path)))
  expect_match(html, "id=\"wn-search\"", fixed = TRUE)
  expect_match(html, "pkWhatsNewSearch(this.value)", fixed = TRUE)
  expect_match(html, sprintf("data-latest=\"%s\"", load_whats_new(whats_new_path)[[1]]$date), fixed = TRUE)
  # The newest change seen is kept in the browser only, never sent anywhere.
  expect_match(whats_new_js, "localStorage", fixed = TRUE)
  expect_false(grepl("Shiny.setInputValue", whats_new_js, fixed = TRUE))
  # It opens as a timeline of titles, each opening its description, and
  # "Full details" shows them all.
  expect_match(html, "whats-new-page wn-simple", fixed = TRUE)
  expect_match(html, "pkUpdatesOpen(this)", fixed = TRUE)
  expect_match(html, "pkUpdatesView(&#39;full&#39;)", fixed = TRUE)
})

test_that("the app has an Updates tab, between Labs and Feedback", {
  app <- readLines(file.path(routing_dir, "app.R"))
  tabs <- grep("^\\s*tabPanel\\(", app, value = TRUE)
  expect_identical(sub("^\\s*tabPanel\\(([^,]+),.*", "\\1", tabs)[1:5],
    c('"Plan a power analysis"', '"About"', "labs_tab_title", '"Updates"', '"Feedback"'))
})
