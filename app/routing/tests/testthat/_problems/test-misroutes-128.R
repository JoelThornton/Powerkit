# Extracted from test-misroutes.R:128

# prequel ----------------------------------------------------------------------
routes <- c("choose", "known", "guided")
screen_score <- c("A score or scale", "Independent people")
leads_to <- function(labels) vapply(routes, function(r) follow_answers(tree, labels, r), character(1))
expect_all_routes <- function(labels, endpoint) {
  ends <- leads_to(labels)
  for (r in routes) expect_identical(ends[[r]], endpoint, label = paste(r, ":", paste(labels, collapse = " > ")))
}
segmented <- c(screen_score, "Many times", "Measurements over time, to see whether a trend changes at a known point")

# test -------------------------------------------------------------------------
expect_all_routes(segmented, "E45")
card <- as.character(card_ui(tree, "E45"))
expect_match(card, "known breakpoint", fixed = TRUE)
expect_match(card, "added predictor in a regression", fixed = TRUE)
expect_match(card, "estimated from the data, a custom simulation is needed", fixed = TRUE)
expect_match(card, "autocorrelation", fixed = TRUE)
expect_match(card, "too optimistic", fixed = TRUE)
expect_match(card, "No ready-made tool.", fixed = TRUE)
