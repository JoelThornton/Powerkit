# The "About" tab.

about_html <- function() as.character(about_ui(tree, forms))

test_that("the About panel says it's a prototype and what it does", {
  html <- about_html()
  expect_match(html, "About powerkit", fixed = TRUE)
  expect_match(html, "This is a prototype.", fixed = TRUE)
  expect_match(html, "not yet fully validated", fixed = TRUE)
  expect_match(html, "Documented formulas and simulations", fixed = TRUE)
  expect_no_match(html, "every number comes from", fixed = TRUE)
  expect_match(html, "on the host for the online app", fixed = TRUE)
  expect_no_match(html, "everything else you enter stays on your computer", fixed = TRUE)
})

test_that("About says how many analyses calculate and links to the full list instead of repeating it", {
  html <- about_html()
  # The full list is "I know my analysis" (layout review, 16 November 2026).
  expect_false(grepl("data-endpoint=", html, fixed = TRUE))
  expect_match(html, "See every analysis", fixed = TRUE)
  expect_match(html, "route:known", fixed = TRUE)
})

test_that("the About page leads with what powerkit does and links to its sections", {
  html <- about_html()
  for (id in c("about-how", "about-plans", "about-trust", "about-privacy", "about-credits")) {
    expect_match(html, sprintf("id=\"%s\"", id), fixed = TRUE, label = id)
    expect_match(html, sprintf("href=\"#%s\"", id), fixed = TRUE, label = id)
  }
  expect_match(html, "Start planning", fixed = TRUE)
  # Feedback has one way in, the top bar's button (layout review, 16 November 2026).
  expect_no_match(html, "pkAboutTab(&#39;Feedback&#39;)", fixed = TRUE)
  expect_no_match(html, "about-feedback", fixed = TRUE)
  # Each package's citation is folded away under "How to cite".
  expect_match(html, "<summary>How to cite</summary>", fixed = TRUE)
})

test_that("the About panel says what the app keeps and sends", {
  html <- about_html()
  expect_match(html, "Nothing is sent from this app", fixed = TRUE)
  expect_match(html, "they stay in this browser and are not sent anywhere", fixed = TRUE)
  # The way to delete the saved answers is named as the plan tab names it.
  expect_match(html, "Discard my draft", fixed = TRUE)
  expect_no_match(html, "Start fresh", fixed = TRUE)
  # The same words as the link on the cards.
  expect_match(as.character(mismatch_ui("x", "path")), "Something doesn&#39;t fit?|Something doesn't fit?")
})

test_that("the About panel credits every foundation tool, from its own citation()", {
  html <- about_html()
  foundation <- c("pwr", "pwrss", "Spower", "Superpower", "InteractionPoweR", "power4mome", "powertools", "semPower",
    "TOSTER", "bfpwr", "BayesFactor", "metapower", "simr", "PUMP", "MBESS", "presize")
  expect_setequal(vapply(about_foundation_tools, `[[`, "", "package"), foundation)
  for (p in c(foundation, "SimDesign", "afex", "MASS", "lavaan", "manymome", "shiny", "ARTool", "brunnermunzel", "quantreg")) {
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
  expect_true(any(grepl('tabPanel(tab_title("About", "About"), value = "About"', app, fixed = TRUE)))
})

test_that("the About panel says what powerkit doesn't do and how far along it is", {
  html <- about_html()
  expect_match(html, "What it doesn&#39;t do|What it doesn't do")
  expect_match(html, "choose your effect size", fixed = TRUE)
  expect_match(html, "Where the numbers come from", fixed = TRUE)
  expect_match(html, "How far along it is", fixed = TRUE)
  expect_match(html, "review is still required before release", fixed = TRUE)
  expect_no_match(html, "have passed their published checks", fixed = TRUE)
  expect_match(html, "representative cases", fixed = TRUE)
})

test_that("About counts the analyses as the methods map does, folds the capability table and puts trust first", {
  html <- as.character(about_ui(tree, forms))
  in_families <- length(unique(unlist(lapply(tree$analysis_families, `[[`, "endpoints"))))
  expect_match(html, sprintf("of the %d analyses calculate", in_families), fixed = TRUE)
  expect_match(html, "Every version of every analysis, and how it was checked (", fixed = TRUE)
  expect_lt(regexpr('id="about-trust"', html, fixed = TRUE), regexpr('id="about-capabilities"', html, fixed = TRUE))
  expect_no_match(html, "?:", fixed = TRUE)
})

test_that("phones show short tab names so every tab fits", {
  html <- as.character(tab_title("Plan a power analysis", "Plan"))
  expect_match(html, '<span class="tab-short">Plan</span>', fixed = TRUE)
  expect_identical(tab_title("About", "About"), "About")
})

test_that("the About page built in a separate process is the same page", {
  skip_on_cran()
  out <- withr::local_tempdir()
  callr::r(about_build_worker, args = list(routing_dir = routing_dir, out_dir = out))
  built <- paste(readLines(file.path(out, "about.html"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_identical(built, paste(as.character(about_ui(tree, forms)), collapse = "\n"))
  expect_false(file.exists(file.path(out, "about.part")))
})
