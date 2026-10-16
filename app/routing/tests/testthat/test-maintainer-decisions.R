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
