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

test_that("every walkthrough example is two sentences", {
  for (s in scenarios) {
    sentences <- regmatches(s$example, gregexpr("[.?!](\\s|$)", s$example))[[1]]
    expect_length(sentences, 2)
  }
})
