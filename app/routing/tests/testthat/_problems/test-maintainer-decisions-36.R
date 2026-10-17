# Extracted from test-maintainer-decisions.R:36

# test -------------------------------------------------------------------------
html <- as.character(card_ui(tree, "E45"))
expect_match(html, "A recently released package addresses the known-breakpoint case; powerkit hasn&#39;t checked it.", fixed = TRUE)
