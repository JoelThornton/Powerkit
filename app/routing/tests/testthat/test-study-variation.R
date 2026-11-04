test_that("research and educational Labs tools have separate, complete menus", {
  html <- as.character(labs_ui(tree))
  expect_match(html, "Research tools", fixed = TRUE)
  expect_match(html, "Educational tools", fixed = TRUE)
  expect_setequal(unlist(labs_tool_sections), vapply(labs_tools, `[[`, "", "id"))
  expect_equal(anyDuplicated(unlist(labs_tool_sections)), 0)
  expect_match(html, "Open 1,000 studies", fixed = TRUE)
  expect_match(html, "No missing data or publication selection is generated", fixed = TRUE)
})

variation_fixture <- function(d = 0.3) {
  list(settings = list(n = 64, n_per_group = 32, d = d, alpha = 0.05, seed = 12,
      replications = 1000, population = "Independent normal scores", analysis = "Two-sided pooled t-test"),
    summary = list(significant = 100, valid = 1000, proportion_significant = 0.1,
      simulation_interval = c(0.08, 0.12), overestimated_significant = 90,
      wrong_direction_significant = 1, selected_mean_magnitude = 0.7,
      selected_magnitude_ratio = 0.7 / 0.3, mean_estimate = 0.31),
    studies = data.frame(study = 1:2, estimate = c(0.7, -0.2), t = c(2.8, -0.8),
      p_value = c(0.01, 0.4), significant = c(TRUE, FALSE)),
    provenance = list(spec_hash = "HASH", seed = 12, r_version = "R version test",
      packages = c(stats = "test", effectsize = "test")))
}

test_that("the teaching tool labels selection, simulation uncertainty and stale settings", {
  run <- variation_fixture()
  html <- as.character(study_variation_summary(run, changed = TRUE))
  expect_match(html, "90 of 100 (90.0%)", fixed = TRUE)
  expect_match(html, "1 estimated the wrong direction", fixed = TRUE)
  expect_match(html, "previous run", fixed = TRUE)
  expect_match(html, "not uncertainty about the true population effect", fixed = TRUE)
  null <- as.character(study_variation_summary(variation_fixture(0)))
  expect_match(null, "every significant result here is a false positive", fixed = TRUE)
  expect_match(null, "relative to zero is undefined", fixed = TRUE)
  run$summary$significant <- 0
  expect_match(as.character(study_variation_summary(run)), "no significant subset", fixed = TRUE)
})

test_that("downloaded study results retain their simulated status and run assumptions", {
  csv <- study_variation_csv(variation_fixture())
  expect_true(all(csv$data_kind == "SIMULATED_STUDY_RESULTS_NOT_REAL_DATA"))
  expect_true(all(csv$total_n == 64))
  expect_true(all(csv$true_d == 0.3))
  expect_true(all(csv$spec_hash == "HASH"))
  expect_true(all(csv$seed == 12))
})

test_that("changing controls leaves a teaching run intact until the next explicit run", {
  engine <- function(n, d, alpha, seed, replications) {
    result <- variation_fixture(d)
    result$settings$n <- n
    result$settings$alpha <- alpha
    result$settings$seed <- seed
    result
  }
  local_mocked_bindings(engine_function = function(name) engine, .env = globalenv())
  shiny::testServer(study_variation_server, {
    session$setInputs(variation_n = 64, variation_d = 0.3, variation_alpha = "0.05",
      variation_fixed_seed = TRUE, variation_seed = 12, variation_run = 1)
    expect_equal(run()$settings$n, 64)
    session$setInputs(variation_n = 128)
    expect_equal(run()$settings$n, 64)
    session$setInputs(variation_run = 2)
    expect_equal(run()$settings$n, 128)
  })
})
