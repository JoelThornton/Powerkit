# Documents to save as PDF (R/documents.R, 6 November 2026): the
# pre-replication notes and the study-planning document are typeset as a
# page of their own and printed alone, rather than printing the app.

test_that("a document is a standalone page with its title, the text and a footer", {
  html <- printable_document(c("# Pre-replication notes", "", "**The finding.** Practice helps recall.", "", "- one", "- two"), "0.33.3")
  expect_match(html, "^<!DOCTYPE html>")
  expect_match(html, "<title>Pre-replication notes</title>", fixed = TRUE)
  expect_match(html, "<h1>Pre-replication notes</h1>", fixed = TRUE)
  expect_match(html, "<strong>The finding.</strong>", fixed = TRUE)
  expect_match(html, "<li>two</li>", fixed = TRUE)
  expect_match(html, "Made with powerkit 0.33.3", fixed = TRUE)
  expect_match(html, "@page", fixed = TRUE)
  # Nothing of the app comes with it.
  expect_no_match(html, "shiny", ignore.case = TRUE)
  expect_no_match(html, "topbar", fixed = TRUE)
})

test_that("text a user typed can't add markup or scripts to the document", {
  html <- printable_document(c("# Notes", "", "<script>alert(1)</script> <b>bold</b>"))
  expect_no_match(html, "<script>", fixed = TRUE)
  expect_no_match(html, "<b>bold</b>", fixed = TRUE)
  expect_match(html, "&lt;script&gt;", fixed = TRUE)
  expect_match(html, "&lt;b&gt;bold", fixed = TRUE)
  # A less-than sign in ordinary text survives as text.
  expect_match(printable_document(c("# N", "", "p < .05")), "p &lt; .05", fixed = TRUE)
  # Markdown's own links stay links (the citation's DOI).
  link <- printable_document(c("# N", "", "See <https://doi.org/10.15626/MP.2024.4155>."))
  expect_match(link, '<a href="https://doi.org/10.15626/MP.2024.4155">', fixed = TRUE)
  expect_no_match(link, "&lt;https", fixed = TRUE)
  # A script disguised as a link is still text.
  expect_no_match(printable_document(c("# N", "", "<https://x.org/><script>")), "<script>", fixed = TRUE)
})

test_that("the notes and the planning document both print as documents, not as the app", {
  labs <- as.character(labs_ui(tree))
  expect_match(labs, "pkPrintDocument(&#39;labs_document&#39;)", fixed = TRUE)
  expect_no_match(labs, "window.print()", fixed = TRUE)
  results <- paste(readLines(file.path(routing_dir, "R", "results.R")), collapse = "\n")
  expect_match(results, 'print_document_button("planning_document", "Planning document (PDF)")', fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "observeEvent(input$labs_document, send_document(", fixed = TRUE)
  expect_match(app, "observeEvent(input$planning_document, send_document(", fixed = TRUE)
  expect_match(app, "tags$script(HTML(documents_js))", fixed = TRUE)
  # Printed from a hidden frame, so only the document is printed.
  expect_match(documents_js, "contentWindow.print()", fixed = TRUE)
  # The button is disabled with the other exports when the answers change.
  expect_match(nav_js, "#planning_document_button", fixed = TRUE)
})

test_that("the real notes typeset as a document", {
  md <- labs_markdown(list(labs_study = "Smith (2020)", labs_finding = "Practice helps recall"), "not_worth", citation = "Karhulahti et al. (2025).")
  html <- printable_document(md)
  expect_match(html, "<h1>Pre-replication notes</h1>", fixed = TRUE)
  expect_match(html, "Practice helps recall", fixed = TRUE)
  expect_match(html, "negative pre-replication report", fixed = TRUE)
})
