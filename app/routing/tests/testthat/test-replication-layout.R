# The replication planner in the input screens' style (18 November 2026):
# numbered step titles, a titled card for each group of questions, number
# boxes sized for a number, one bar saying what is still needed beside the
# button, and finished steps ticked.

test_that("each step has a numbered title, and its questions are in titled cards", {
  html <- as.character(replication_workspace_ui(tree))
  for (title in c("1. Whether to replicate", "2. The original study", "3. Goals and sample size",
    "4. How the replication differs", "5. Write-up")) {
    expect_match(html, sprintf("<h3 class=\"form-section-title rep-section-title\">%s</h3>", title), fixed = TRUE)
  }
  for (card in c("Which study, and how it was analysed", "What it reported", "Its significance test, and how it was published",
    "What the replication should show", "How much the effect may vary between studies",
    "How sure the replication should be")) {
    expect_match(html, sprintf("<legend class=\"h6\">%s</legend>", card), fixed = TRUE)
  }
  # The answer routes sit in their own panel, apart from the questions
  # (19 November 2026).
  expect_match(html, "<h4 id=\"rep-routes-title\" class=\"rep-routes-title\">Get the sample size</h4>", fixed = TRUE)
  expect_match(html, "<h5 class=\"h6\">The quick answer</h5>", fixed = TRUE)
  # The button sits in one bar with the status, and the answer in its card.
  expect_match(html, "action-bar rep-run-bar", fixed = TRUE)
  expect_match(html, "id=\"rep_still_needed\"", fixed = TRUE)
  expect_match(html, "<div class=\"rep-answer\">", fixed = TRUE)
  expect_match(html, "rep-steps-done", fixed = TRUE)
})

test_that("number boxes are sized for a number; those that can't be negative bring up a number keyboard", {
  n <- as.character(rep_field("rep_n1", "People"))
  expect_match(n, "class=\"shiny-input-text form-control rep-num\"", fixed = TRUE)
  expect_match(n, "inputmode=\"decimal\"", fixed = TRUE)
  signed <- as.character(rep_field("rep_effect", "The effect"))
  expect_match(signed, "rep-num", fixed = TRUE)
  expect_no_match(signed, "inputmode", fixed = TRUE)
  expect_no_match(as.character(rep_field("rep_study", "The study")), "rep-num", fixed = TRUE)
  expect_match(as.character(shortcut_field("rep_alpha", "Alpha", "0.05", "0.05")), "inputmode=\"decimal\"", fixed = TRUE)
  expect_true(all(c(replication_number_fields, replication_signed_fields) %in% replication_field_ids))
})

test_that("the bar says what is still needed, in the input screens' words", {
  empty <- as.character(replication_still_needed(list(rep_design = "two_groups")))
  expect_match(empty, "class=\"form-needed rep-still-needed\"", fixed = TRUE)
  expect_match(empty, "Still needed: the effect the original study reported, the original study's two group sizes and 2 more", fixed = TRUE)
  one <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "20", rep_n2 = "20", rep_alpha = "0.05")
  expect_match(as.character(replication_still_needed(one)), "Still needed: the chance of success to aim for</span>", fixed = TRUE)
  done <- as.character(replication_still_needed(modifyList(one, list(rep_power = "0.8"))))
  expect_match(done, "form-needed form-needed-done", fixed = TRUE)
  expect_match(done, "Everything needed is in.", fixed = TRUE)
})

test_that("finished steps are ticked", {
  filled <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "20", rep_n2 = "20")
  expect_identical(replication_steps_done(list(rep_design = "two_groups"), FALSE, NULL), character())
  expect_identical(replication_steps_done(filled, FALSE, "go"), c("whether", "original"))
  expect_identical(replication_steps_done(modifyList(filled, list(rep_keeps = "close")), TRUE, ""),
    c("original", "goals", "differences"))
})

test_that("the write-up step previews the document, with typed text kept as text", {
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, "<details class=\"rep-preview\" open>", fixed = TRUE)
  expect_match(html, "Preview the write-up", fixed = TRUE)
  expect_match(html, "id=\"rep_preview\"", fixed = TRUE)
  body <- document_body_html(c("# Pre-replication of: Smith", "", "p < .05 and <b>bold</b>"))
  expect_match(body, "<h1>Pre-replication of: Smith</h1>", fixed = TRUE)
  expect_match(body, "p &lt; .05 and &lt;b&gt;bold&lt;/b&gt;", fixed = TRUE)
  expect_no_match(body, "<b>", fixed = TRUE)
  # The printable page uses the same body.
  expect_match(printable_document(c("# T", "", "Text")), document_body_html(c("# T", "", "Text")), fixed = TRUE)
})
