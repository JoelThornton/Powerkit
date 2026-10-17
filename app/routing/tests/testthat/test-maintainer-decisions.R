# Maintainer decisions of 16 October 2026 on items left by PRs #21 and #22
# (docs/decisions.md, "Routing prototype: maintainer decisions from PRs #21
# and #22").

test_that("E15 (yes/no X or W) doesn't ask the reliability question", {
  expect_false("Q-rel" %in% vapply(closing_questions_for(tree, "E15"), `[[`, "", "doc_id"))
  expect_true("Q-rel" %in% vapply(closing_questions_for(tree, "E9"), `[[`, "", "doc_id"))
})

test_that("E37 says IRT designs aren't covered (flag F7)", {
  expect_true(any(grepl("Item response theory (IRT) designs aren't covered", tree$endpoints$E37$card_points, fixed = TRUE)))
  html <- as.character(card_ui(tree, "E37"))
  expect_match(html, "Item response theory (IRT) designs aren't covered", fixed = TRUE)
})

test_that("a test-retest study answered 'Twice' reaches E41, as the audit says (flag F11)", {
  base <- c("A score or scale", "Independent people")
  rel <- c("Detect an effect", "A relationship between two things you measure")
  expect_equal(follow_with_context(tree, c(base, "Twice", rel))$id, "E41")
  audit <- read_doc("routing-audit.md")
  expect_match(audit, "rel reaches **E41** (relationships measured within people)", fixed = TRUE)
})

# Maintainer decisions of 17 October 2026 (docs/decisions.md).

test_that("E7 and E8 describe ANOVA_exact() in Superpower's own terms", {
  for (id in c("E7", "E8")) {
    html <- as.character(card_ui(tree, id))
    expect_no_match(html, "analytic", ignore.case = TRUE, label = id)
    expect_match(html, "Exact dataset (no repeated simulation)", fixed = TRUE, label = id)
  }
})

test_that("E45 says a recent package covers the known-breakpoint case, without naming it", {
  html <- as.character(card_ui(tree, "E45"))
  expect_match(html, "A recently released package addresses the known-breakpoint case; powerkit hasn't checked it.", fixed = TRUE)
  expect_no_match(html, "No ready-made tool", fixed = TRUE)
  expect_no_match(html, "PITS", fixed = TRUE)
})

test_that("E45's autocorrelation point gives both directions (Zhang et al., 2011, Table 1)", {
  html <- as.character(card_ui(tree, "E45"))
  expect_match(html, "Autocorrelation makes standard power calculations wrong: too optimistic when it's positive, too pessimistic when it's negative.", fixed = TRUE)
  expect_no_match(html, "With time-series data, autocorrelation", fixed = TRUE)
  sources <- readLines(file.path(routing_dir, "..", "..", "docs", "card-sources.md"), encoding = "UTF-8")
  row <- grep("^\\| E45 \\| Card point \\| Autocorrelation makes", sources, value = TRUE)
  expect_length(row, 1)
  expect_match(row, "Zhang et al. (2011)", fixed = TRUE)
  expect_match(row, "| sourced |", fixed = TRUE)
})
