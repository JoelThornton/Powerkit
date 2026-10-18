# The "About this prototype" panel.

about_html <- function() as.character(about_ui(tree, forms))

test_that("the About panel says it's a prototype and what it does", {
  html <- about_html()
  expect_match(html, "About this prototype", fixed = TRUE)
  expect_match(html, "This is a prototype.", fixed = TRUE)
  expect_match(html, "not yet fully validated", fixed = TRUE)
  expect_match(html, "never does the statistics itself", fixed = TRUE)
})

test_that("the About panel lists every end point that calculates, and only those", {
  html <- about_html()
  calculating <- c(unlist(forms$calculates), names(forms$simulations$endpoints))
  for (id in calculating) {
    expect_match(html, sprintf("<strong>%s</strong>", id), fixed = TRUE, label = id)
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
  }
  listed <- regmatches(html, gregexpr("<li>\\s*<strong>E[0-9]+</strong>", html))[[1]]
  expect_setequal(sub(".*<strong>(E[0-9]+)</strong>", "\\1", listed), calculating)
  # E9 runs in the background; E10-E12 run the full analysis here; E13-E14 give a script.
  expect_match(html, "E9</strong>\\s*: [^<]*Calculates here, in the background", perl = TRUE)
  expect_match(html, "E13</strong>\\s*: [^<]*an R script to run the full analysis on your computer", perl = TRUE)
})

test_that("the About panel explains how to report problems with 'Something doesn't fit?'", {
  html <- about_html()
  expect_match(html, "Something doesn&#39;t fit?|Something doesn't fit?")
  expect_match(html, "Copy the path", fixed = TRUE)
  expect_match(html, "Nothing is sent from this app", fixed = TRUE)
  # The same words as the link on the cards.
  expect_match(as.character(mismatch_ui("x", "path")), "Something doesn&#39;t fit?|Something doesn't fit?")
})

test_that("the About panel credits every foundation tool, from its own citation()", {
  html <- about_html()
  foundation <- c("pwr", "pwrss", "Spower", "Superpower", "InteractionPoweR", "power4mome")
  expect_setequal(vapply(about_foundation_tools, `[[`, "", "package"), foundation)
  for (p in c(foundation, "SimDesign", "afex", "MASS", "lavaan", "manymome", "shiny")) {
    expect_match(html, sprintf("<strong>%s</strong>", p), fixed = TRUE, label = p)
  }
  expect_match(html, "<strong>R</strong>", fixed = TRUE)
  # Credits are the packages' own citation(), never written by hand.
  expect_identical(
    about_citation_text("shiny"),
    gsub("[*_]{1,2}([^*_]+)[*_]{1,2}", "\\1", format(utils::citation("shiny"), style = "text"))
  )
  expect_match(about_citation_text("notapackage.powerkit"), "Not installed", fixed = TRUE)
})

test_that("the app has an About tab", {
  app <- readLines(file.path(routing_dir, "app.R"))
  expect_true(any(grepl('tabPanel("About this prototype"', app, fixed = TRUE)))
})
