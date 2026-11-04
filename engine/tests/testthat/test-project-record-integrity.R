test_that("result records and reproduction include goal-specific numbers", {
  result <- list(goal_type = "precision", curve = data.frame(n = 100, power = NA_real_),
    n_required = list(n = 100), precision = list(width = 0.4, target_width = 0.4),
    justified_alpha = list(alpha = 0.03), bayes = list(effect_sd = 0.2),
    check_run = data.frame(ok = TRUE), provenance = list())
  record <- result_record(result)
  expect_identical(record$precision, result$precision)
  expect_identical(record$justified_alpha, result$justified_alpha)
  expect_identical(record$bayes, result$bayes)
  changed <- record
  changed$precision$width <- 0.8
  expect_false(identical(result_numbers(record), result_numbers(changed)))
  # Older numerical records can still be compared using their saved fields.
  old <- record[c("curve", "n_required")]
  expect_named(result_numbers(old), c("curve", "n_required"))
})

test_that("study plans preserve results and original provenance through repeated saves", {
  spec <- example_spec("independent_t")
  spec$options$seed <- 11L
  spec$goal <- list(type = "power", n = 128)
  result <- run_spec(spec)
  first <- read_study_plan(write_study_plan(list(list(spec = spec, result = result))))
  second <- read_study_plan(write_study_plan(first$analyses))
  third <- read_study_plan(write_study_plan(second$analyses))
  expect_identical(second$analyses[[1]]$result, first$analyses[[1]]$result)
  expect_identical(third$analyses[[1]]$screen, first$analyses[[1]]$screen)
  expect_identical(third$analyses[[1]]$saved, first$analyses[[1]]$saved)
  expect_equal(saved_result(third$analyses[[1]])$curve, result$curve)

  legacy <- first$analyses[[1]]
  legacy$screen <- NULL
  again <- read_study_plan(write_study_plan(list(legacy)))
  expect_identical(again$analyses[[1]]$result, legacy$result)
  expect_null(again$analyses[[1]]$screen)
})

test_that("older numerical records recover omitted fields from an intact screen", {
  spec <- example_spec("independent_t")
  spec$options$seed <- 11L
  spec$goal <- list(type = "power", n = 128)
  result <- run_spec(spec)
  raw <- jsonlite::parse_json(write_project(spec, result), simplifyVector = FALSE)
  raw$result$details <- NULL
  project <- read_project(jsonlite::toJSON(raw, auto_unbox = TRUE, digits = NA, null = "null"))
  expect_equal(project$result$details, result$details)
})
