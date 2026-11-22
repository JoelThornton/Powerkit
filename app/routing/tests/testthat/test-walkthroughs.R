# The worked examples in docs/walkthroughs.md: each scenario's recorded
# answers, in each route, still reach the end point the document reports.

source(file.path(routing_dir, "walkthroughs", "walkthroughs.R"), local = TRUE)
scenarios <- load_scenarios(file.path(routing_dir, "walkthroughs", "scenarios.json"))

test_that("there is a walkthrough for every design in the routing audit", {
  expect_identical(sum(vapply(scenarios, function(s) s$part == "A", logical(1))), 29L)
  expect_identical(sum(vapply(scenarios, function(s) s$part == "B", logical(1))), 32L)
  expect_false(any(duplicated(vapply(scenarios, function(s) s$id, character(1)))))
})

test_that("every walkthrough's answers reach the recorded end point in all three routes", {
  for (s in scenarios) {
    reached <- walk_scenario(tree, s)
    for (r in names(reached)) expect_identical(reached[[r]], s$reaches[[r]], label = paste(s$id, r))
  }
})

# Reaching the recorded end point shows only that the finder follows the
# recorded answers. Where a brief names something the analysis must keep
# (several outcomes analysed together, latent variables, a curve), no
# route may end at a card that drops it.
test_that("no route ends at a card that drops what the brief says the analysis must keep", {
  for (s in Filter(function(s) !is.null(s$must_not_reach), scenarios)) {
    expect_true(nzchar(s$must_not_reach$why %||% ""), label = paste(s$id, "reason"))
    reached <- walk_scenario(tree, s)
    # A route listed in `open_in` is a known gap, named in walkthroughs.md.
    for (r in setdiff(names(reached), unlist(s$must_not_reach$open_in))) {
      expect_false(reached[[r]] %in% unlist(s$must_not_reach$ids), label = paste(s$id, r, reached[[r]]))
    }
  }
})

test_that("every walkthrough example is two sentences", {
  for (s in scenarios) {
    sentences <- regmatches(s$example, gregexpr("[.?!](\\s|$)", s$example))[[1]]
    expect_length(sentences, 2)
  }
})
