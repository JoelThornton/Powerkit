test_that("plans never take a maximum across different physical sample units", {
  entry <- function(unit, n) list(label = unit, n = n, sample = list(unit = unit, note = "Example sample unit.", compatibility_key = unit))
  entries <- list(entry("participants", 100), entry("pairs", 80), entry("items", 120), entry("studies", 20))
  html <- page_html((entries))
  expect_no_match(html, "result-hero plan-hero", fixed = TRUE)
  expect_match(html, "no single study-wide sample size", fixed = TRUE)
  for (unit in c("participants", "pairs", "items", "studies")) expect_match(html, paste(unit, "needed"), fixed = TRUE)
})

test_that("matching units do not override incompatible sample structures or missing results", {
  entry <- function(key, n) list(label = "An analysis", n = n,
    sample = list(unit = "participants", note = "Participants.", compatibility_key = key))
  expect_false(plan_counts_compatible(list(entry("allocation-1", 100), entry("allocation-2", 120))))
  expect_no_match(page_html((list(entry("same", 100), entry("same", NULL)))), "result-hero plan-hero", fixed = TRUE)
  expect_false(plan_counts_compatible(list(entry(NULL, 100), entry(NULL, 120))))
  expect_true(plan_counts_compatible(list(entry("same", 100), entry("same", 120))))
})

test_that("the plan says which reason leaves it without one study-wide sample size", {
  entry <- function(unit, key, n) list(label = "An analysis", n = n, sample = list(unit = unit, note = "x", compatibility_key = key))
  expect_match(plan_incomparable_text(list(entry("participants", "a", 100), entry("pairs", "b", 80))),
    "These analyses count different things (participants, pairs)", fixed = TRUE)
  expect_match(plan_incomparable_text(list(entry("participants", "a", 100), entry("participants", "b", 80))),
    "These analyses all count participants, but in different designs", fixed = TRUE)
  expect_match(plan_incomparable_text(list(entry("participants", "a", 100), entry("participants", "a", NULL))),
    "Some of these analyses have no sample size to compare", fixed = TRUE)
  expect_match(plan_incomparable_text(list(entry("participants", "a", 100), entry("participants", NULL, 80))),
    "The sample unit of at least one of these analyses isn't known", fixed = TRUE)
  # The reason is in view; the rest follows the explanations switch.
  html <- page_html(list(entry("participants", "a", 100), entry("pairs", "b", 80)))
  expect_match(html, "rep-note-kept", fixed = TRUE)
})

test_that("the plan's settings card has a heading and help that follows the explanations switch", {
  html <- as.character(plan_settings_ui(new_plan("P")))
  expect_match(html, "<legend class=\"h6\">Settings for every analysis in this plan</legend>", fixed = TRUE)
  expect_match(html, "rep-field-more", fixed = TRUE)
  expect_match(html, "aria-describedby=\"plan_setting_alpha_help\"", fixed = TRUE)
})
