# The "What's new" tab and its source, whats-new.yaml.

whats_new_path <- file.path(routing_dir, "whats-new.yaml")

test_that("every What's new entry has a date, a title and plain-words text", {
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

test_that("the What's new tab shows the entries newest first, grouped by day", {
  entries <- load_whats_new(whats_new_path)
  html <- as.character(whats_new_ui(entries))
  expect_match(html, "What&#39;s new|What's new")
  first <- entries[[1]]
  expect_match(html, htmltools::htmlEscape(first$title), fixed = TRUE)
  day <- as.Date(first$date)
  heading <- paste(as.integer(format(day, "%d")), format(day, "%B %Y"))
  expect_match(html, heading, fixed = TRUE)
  # Each day appears once, as a heading.
  days <- unique(vapply(entries, `[[`, "", "date"))
  expect_length(regmatches(html, gregexpr("<h3 class=\"h5\">", html))[[1]], length(days))
})

test_that("the app has a What's new tab", {
  app <- readLines(file.path(routing_dir, "app.R"))
  expect_true(any(grepl('tabPanel("What\'s new"', app, fixed = TRUE)))
})
