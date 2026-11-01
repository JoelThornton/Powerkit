# The "About" tab.

about_html <- function() as.character(about_ui(tree, forms))

test_that("the About panel says it's a prototype and what it does", {
  html <- about_html()
  expect_match(html, "About powerkit", fixed = TRUE)
  expect_match(html, "This is a prototype.", fixed = TRUE)
  expect_match(html, "not yet fully validated", fixed = TRUE)
  expect_match(html, "never does the statistics itself", fixed = TRUE)
})

test_that("the About panel lists every end point that calculates, and only those", {
  html <- about_html()
  calculating <- c(unlist(forms$calculates), names(forms$simulations$endpoints))
  for (id in calculating) {
    expect_match(html, sprintf("data-endpoint=\"%s\"", id), fixed = TRUE, label = id)
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
  }
  listed <- regmatches(html, gregexpr("data-endpoint=\"[^\"]+\"", html))[[1]]
  expect_setequal(sub("data-endpoint=\"([^\"]+)\"", "\\1", listed), calculating)
  # Users see the analyses' names, not powerkit's internal codes.
  expect_false(grepl("<strong>E[0-9]+</strong>", html))
  # Each says how it calculates: E9 runs in the background; E10-E12 run the
  # full analysis here; E13-E14 give a script.
  expect_match(html, "class=\"about-ep how-background\" data-endpoint=\"E9\"", fixed = TRUE)
  expect_match(html, "class=\"about-ep how-full\" data-endpoint=\"E10\"", fixed = TRUE)
  expect_match(html, "class=\"about-ep how-script\" data-endpoint=\"E13\"", fixed = TRUE)
  expect_match(html, "an R script to run the full analysis on your computer", fixed = TRUE)
  # Grouped by family, and each one opens its card.
  expect_match(html, "Comparing averages (t-tests)", fixed = TRUE)
  expect_match(html, "pkAboutPlan(this.dataset.endpoint)", fixed = TRUE)
  expect_match(about_js, "Shiny.setInputValue('map_plan'", fixed = TRUE)
})

test_that("the About page leads with what powerkit does and links to its sections", {
  html <- about_html()
  for (id in c("about-how", "about-plans", "about-trust", "about-feedback", "about-credits")) {
    expect_match(html, sprintf("id=\"%s\"", id), fixed = TRUE, label = id)
    expect_match(html, sprintf("href=\"#%s\"", id), fixed = TRUE, label = id)
  }
  expect_match(html, "Start planning", fixed = TRUE)
  expect_match(html, "pkAboutTab(&#39;Feedback&#39;)", fixed = TRUE)
  # Each package's citation is folded away under "How to cite".
  expect_match(html, "<summary>How to cite</summary>", fixed = TRUE)
})

test_that("the About panel explains how to report problems: the Feedback tab and 'Something doesn't fit?'", {
  html <- about_html()
  expect_match(html, "<strong>Feedback</strong> tab", fixed = TRUE)
  expect_match(html, "Something doesn&#39;t fit?|Something doesn't fit?")
  expect_match(html, "Nothing is sent from this app", fixed = TRUE)
  # The same words as the link on the cards.
  expect_match(as.character(mismatch_ui("x", "path")), "Something doesn&#39;t fit?|Something doesn't fit?")
})

test_that("the About panel credits every foundation tool, from its own citation()", {
  html <- about_html()
  foundation <- c("pwr", "pwrss", "Spower", "Superpower", "InteractionPoweR", "power4mome", "powertools", "semPower",
    "TOSTER", "bfpwr", "BayesFactor", "metapower", "simr", "PUMP")
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
  expect_true(any(grepl('tabPanel("About"', app, fixed = TRUE)))
})

test_that("the About panel says what powerkit doesn't do and how far along it is", {
  html <- about_html()
  expect_match(html, "What it doesn&#39;t do|What it doesn't do")
  expect_match(html, "choose your effect size", fixed = TRUE)
  expect_match(html, "Where the numbers come from", fixed = TRUE)
  expect_match(html, "How far along it is", fixed = TRUE)
  expect_match(html, "until a statistician has checked it", fixed = TRUE)
})

test_that("the analysis families fold, and start folded on a phone", {
  html <- as.character(about_plans_ui(tree, forms))
  expect_match(html, '<details class="about-family" open>', fixed = TRUE)
  expect_match(html, '<summary class="about-family-head">', fixed = TRUE)
  expect_match(about_js, "(max-width: 767px)", fixed = TRUE)
})
