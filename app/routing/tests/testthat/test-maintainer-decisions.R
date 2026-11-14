# Maintainer decisions of 16 October 2026 on items left by PRs #21 and #22
# (docs/decisions.md, "Routing prototype: maintainer decisions from PRs #21
# and #22").

test_that("E15 (yes/no X or W) asks for reliability of the score and outcome only (29 October 2026)", {
  expect_true("Q-rel" %in% vapply(closing_questions_for(tree, "E15"), `[[`, "", "doc_id"))
  expect_true("Q-rel" %in% vapply(closing_questions_for(tree, "E9"), `[[`, "", "doc_id"))
  # The yes/no variable's reliability is never asked: X's only when W is
  # the yes/no one, and W's only when X is.
  fields <- form_fields(form_groups(forms, "E15"))
  shown_if <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]$shown_if
  expect_identical(shown_if("rel_X")$is, "W")
  expect_identical(shown_if("rel_W")$is, "X")
})

test_that("E37 says which IRT designs aren't covered (flag F7)", {
  # Since 5 November 2026 differential item functioning has its own card
  # (E71), so E37 points to it and says the other IRT designs aren't covered.
  said <- "differential item functioning between two groups has its own card; other IRT designs aren't covered yet"
  expect_true(any(grepl(said, tree$endpoints$E37$card_points, fixed = TRUE)))
  html <- as.character(card_ui(tree, "E37"))
  expect_match(html, said, fixed = TRUE)
})

test_that("a test-retest study answered 'Twice' reaches E41, as the audit says (flag F11)", {
  base <- c("A score or scale", "Independent people")
  rel <- c("A relationship between two things you measure")
  # Since 13 November 2026, R2 asks what the other variable is: the same
  # score measured twice isn't two scores measured together (E76), so a
  # test-retest study answers "Something else".
  other <- "Something else: several predictors, a score measured once per person, or a relationship that depends on something"
  expect_equal(follow_with_context(tree, c(base, "Twice", rel))$id, "r_within")
  expect_equal(follow_with_context(tree, c(base, "Twice", rel, other))$id, "E41")
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

test_that("E45 calculates with PITS's series fitted by REML, and says why (6 November 2026)", {
  # Until 6 November 2026 the card said only that a recent package covers
  # the known-breakpoint case; the maintainer then chose PITS's series with
  # a REML fit, PITS's own test as an option (decisions.md).
  html <- as.character(card_ui(tree, "E45"))
  expect_no_match(html, "No ready-made tool", fixed = TRUE)
  expect_match(html, "PITS", fixed = TRUE)
  expect_match(html, "REML", fixed = TRUE)
  expect_match(html, "more often than alpha", fixed = TRUE)
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
