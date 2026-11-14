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
  # Code (an R script) shows "<-" as written, and markup in it is still text.
  code <- printable_document(c("# N", "", "```r", "x <- 1", "<script>alert(1)</script>", "```", "", "`a <- b`"))
  expect_match(code, "x &lt;- 1", fixed = TRUE)
  expect_match(code, "a &lt;- b", fixed = TRUE)
  expect_no_match(code, "<script>", fixed = TRUE)
  expect_no_match(code, "&amp;lt;", fixed = TRUE)
})

test_that("the notes and the planning document both print as documents, not as the app", {
  labs <- as.character(labs_ui(tree))
  expect_match(labs, "pkPrintDocument(&#39;labs_document&#39;)", fixed = TRUE)
  expect_no_match(labs, "window.print()", fixed = TRUE)
  results <- paste(readLines(file.path(routing_dir, "R", "results.R")), collapse = "\n")
  expect_match(results, 'document_menu("planning_document", "download_planning_docx", "download_planning_document",\n        "Planning document (PDF)"', fixed = TRUE)
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

# --- Word (.docx) ---------------------------------------------------------------

docx_parts <- function(file) {
  dir <- tempfile("docx-test-")
  utils::unzip(file, exdir = dir)
  list(files = sort(utils::unzip(file, list = TRUE)$Name), dir = dir,
    document = xml2::read_xml(file.path(dir, "word", "document.xml")),
    rels = paste(readLines(file.path(dir, "word", "_rels", "document.xml.rels"), warn = FALSE), collapse = ""))
}

test_that("a table in a Word document keeps its rows and cells, header in bold", {
  file <- tempfile(fileext = ".docx")
  docx_document(c("# Plan", "", "| Analysis | N needed |", "|---|---|", "| Two groups | 128 |", "| Correlation | 85 |", "", "After."), file)
  parts <- docx_parts(file)
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
  expect_length(xml2::xml_find_all(parts$document, "//w:tbl", ns), 1)
  expect_length(xml2::xml_find_all(parts$document, "//w:tr", ns), 3)
  expect_length(xml2::xml_find_all(parts$document, "//w:tc", ns), 6)
  expect_length(xml2::xml_find_all(parts$document, "//w:tr[1]//w:b", ns), 2)
  expect_match(xml2::xml_text(parts$document), "Correlation85After.", fixed = TRUE)
})

test_that("a Word document has the parts Word needs and well-formed XML", {
  file <- tempfile(fileext = ".docx")
  docx_document(c("# Pre-replication of: Smith & Lee (2019)", "", "Text with **bold**, _italic_ and <https://doi.org/10.15626/MP.2024.4155>.",
    "", "## Section", "", "- one", "- two", "", "1. first", "", "---", "", "Last."), file, "0.34.1")
  parts <- docx_parts(file)
  expect_setequal(parts$files, c("[Content_Types].xml", "_rels/.rels", "docProps/core.xml",
    "word/_rels/document.xml.rels", "word/styles.xml", "word/document.xml"))
  for (f in setdiff(parts$files, "word/document.xml")) expect_no_error(xml2::read_xml(file.path(parts$dir, f)))
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
  styles <- xml2::xml_attr(xml2::xml_find_all(parts$document, "//w:pStyle", ns), "val")
  expect_true(all(c("Heading1", "Heading2", "ListParagraph", "Footer") %in% styles))
  text <- xml2::xml_text(parts$document)
  expect_match(text, "Pre-replication of: Smith & Lee (2019)", fixed = TRUE)
  expect_match(text, "•\tone", fixed = TRUE)
  expect_match(text, "1.\tfirst", fixed = TRUE)
  expect_match(text, "Made with powerkit 0.34.1.", fixed = TRUE)
  expect_length(xml2::xml_find_all(parts$document, "//w:b", ns), 1)
  expect_length(xml2::xml_find_all(parts$document, "//w:hyperlink", ns), 1)
  expect_match(parts$rels, 'Target="https://doi.org/10.15626/MP.2024.4155" TargetMode="External"', fixed = TRUE)
})

test_that("text typed into a Word document stays text", {
  file <- tempfile(fileext = ".docx")
  docx_document(c("# Notes", "", "p < .05 & <b>bold</b> <w:p/>"), file)
  parts <- docx_parts(file)
  expect_match(xml2::xml_text(parts$document), "p < .05 & <b>bold</b> <w:p/>", fixed = TRUE)
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
  # Only the title, the one paragraph and the footer: nothing typed became a paragraph.
  expect_length(xml2::xml_find_all(parts$document, "//w:body/w:p", ns), 3)
})

# --- Where the user landed (Karhulahti et al., 2025) -----------------------------

labs_example <- list(labs_study = "Smith & Lee (2019)", labs_finding = "Practice helps recall.",
  labs_goals = "To test it before a training programme.", labs_smallest = "a 5-point gain.",
  labs_quality = "Only 40 participants.", labs_improve = "Several sets of materials.",
  labs_value = "It underpins a curriculum change.", labs_alternatives = "A classroom study.")

test_that("not worth replicating gives a negative pre-replication report in the paper's shape", {
  md <- labs_report(labs_example, "not_worth", citation = "Karhulahti et al. (2025).")
  expect_match(md, "^# Pre-replication of: Smith & Lee \\(2019\\)")
  expect_no_match(md, "## ")    # short prose, as in the paper's examples
  expect_match(md, "Only 40 participants. Several sets of materials.", fixed = TRUE)
  expect_match(md, "Pre-replication as proposed by Karhulahti et al. (2025).", fixed = TRUE)
  # No question-and-answer worksheet.
  expect_no_match(md, labs_questions$quality, fixed = TRUE)
})

test_that("going ahead or changing the plan gives a section under the paper's three assessments", {
  for (outcome in c("go", "change")) {
    md <- labs_report(labs_example, outcome, citation = "Karhulahti et al. (2025).")
    for (h in c("## Epistemic assessment", "## Methodological assessment", "## Value assessment")) expect_match(md, h, fixed = TRUE, label = outcome)
    expect_match(md, "**Finding:** Practice helps recall.", fixed = TRUE)
  }
  change <- labs_report(labs_example, "change", citation = "x")
  expect_match(change, "# Pre-replication: a redesigned replication", fixed = TRUE)
  expect_match(change, "**How the design changes:** Several sets of materials.", fixed = TRUE)
  # With no outcome, the full notes.
  expect_match(labs_report(labs_example, NULL, citation = "x"), "# Pre-replication notes", fixed = TRUE)
  # Blank answers are left out rather than shown as gaps.
  expect_no_match(labs_report(list(labs_finding = "F."), "go", citation = "x"), "left blank", fixed = TRUE)
})

test_that("a document's formats are one button with a menu", {
  html <- as.character(document_menu("planning_document", "download_planning_docx", "download_planning_document",
    "Planning document (PDF)", "the planning document"))
  expect_match(html, 'id="planning_document_button"', fixed = TRUE)
  expect_match(html, 'id="planning_document_formats"', fixed = TRUE)
  expect_match(html, 'data-bs-toggle="dropdown"', fixed = TRUE)
  expect_match(html, 'Other formats: the planning document', fixed = TRUE)
  # The Word and Markdown items are Shiny download links, in the menu.
  for (id in c("download_planning_docx", "download_planning_document")) {
    link <- regmatches(html, regexpr(sprintf('<a [^>]*id="%s"[^>]*>', id), html))
    expect_match(link, "shiny-download-link", fixed = TRUE)
    expect_match(link, "dropdown-item", fixed = TRUE)
  }
  expect_match(nav_js, "#planning_document_formats", fixed = TRUE)
  # Every download in a menu is kept ready while the menu is closed.
  sources <- paste(unlist(lapply(c(file.path(routing_dir, "app.R"), Sys.glob(file.path(routing_dir, "R", "*.R"))), readLines)), collapse = "\n")
  menus <- regmatches(sources, gregexpr('document_menu\\("[a-z_]+", "([a-z_]+)", "([a-z_]+)"', sources))[[1]]
  ids <- unlist(regmatches(menus, gregexpr('"[a-z_]+"', menus)))
  ids <- gsub('"', "", ids[-seq(1, length(ids), by = 3)])
  expect_setequal(ids, document_menu_downloads)
  expect_match(sources, "for (id in document_menu_downloads) outputOptions(output, id, suspendWhenHidden = FALSE)", fixed = TRUE)
})

test_that("Word downloads are offered for the notes and the planning document", {
  labs <- as.character(labs_ui(tree))
  expect_match(labs, 'id="labs_docx"', fixed = TRUE)
  results <- paste(readLines(file.path(routing_dir, "R", "results.R")), collapse = "\n")
  expect_match(results, 'document_menu("planning_document", "download_planning_docx", "download_planning_document"', fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "output$labs_docx <- downloadHandler(", fixed = TRUE)
  expect_match(app, "output$download_planning_docx <- downloadHandler(", fixed = TRUE)
  expect_match(nav_js, "#download_planning_docx", fixed = TRUE)
})
