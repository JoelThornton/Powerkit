test_that("plans never take a maximum across different physical sample units", {
  entry <- function(unit, n) list(label = unit, n = n, sample = list(unit = unit, note = "Example sample unit.", compatibility_key = unit))
  entries <- list(entry("participants", 100), entry("pairs", 80), entry("items", 120), entry("studies", 20))
  html <- as.character(study_plan_ui(entries))
  expect_no_match(html, "result-hero plan-hero", fixed = TRUE)
  expect_match(html, "no single study-wide sample size", fixed = TRUE)
  for (unit in c("participants", "pairs", "items", "studies")) expect_match(html, paste(unit, "needed"), fixed = TRUE)
})

test_that("matching units do not override incompatible sample structures or missing results", {
  entry <- function(key, n) list(label = "An analysis", n = n,
    sample = list(unit = "participants", note = "Participants.", compatibility_key = key))
  expect_false(plan_counts_compatible(list(entry("allocation-1", 100), entry("allocation-2", 120))))
  expect_no_match(as.character(study_plan_ui(list(entry("same", 100), entry("same", NULL)))), "result-hero plan-hero", fixed = TRUE)
  expect_false(plan_counts_compatible(list(entry(NULL, 100), entry(NULL, 120))))
  expect_true(plan_counts_compatible(list(entry("same", 100), entry("same", 120))))
})
