# Participants to recruit, allowing for attrition: each group's analysed n
# divided by (1 - attrition), rounded up (the maintainer's decision of
# 17 October 2026).

with_attrition <- function(name, attrition, ...) {
  spec <- small_run_spec(name, ...)
  spec$options$attrition <- attrition
  spec
}

test_that("without attrition there is nothing to recruit beyond n", {
  spec <- example_spec("correlation")
  spec$options$attrition <- NULL
  expect_true(is.na(recruitment_target(spec, 100)))
  spec <- with_attrition("correlation", 0)
  expect_true(is.na(recruitment_target(spec, 100)))
})

test_that("one group: n / (1 - attrition), rounded up", {
  spec <- with_attrition("correlation", 0.1)
  r <- recruitment_target(spec, 85)
  expect_equal(r$n_recruit, 95) # 85 / 0.9 = 94.4
  expect_equal(r$n_analysed, 85)
  # An exact quotient isn't pushed up by floating-point error.
  expect_equal(recruitment_target(spec, 90)$n_recruit, 100)
  expect_equal(recruitment_target(with_attrition("correlation", 0.2), 100)$n_recruit, 125)
})

test_that("groups are rounded up one by one, in the design's split", {
  spec <- with_attrition("independent_t", 0.1)
  r <- recruitment_target(spec, 128)
  expect_equal(r$groups_analysed, c(64, 64))
  expect_equal(r$groups_recruit, c(72, 72)) # 64 / 0.9 = 71.1
  expect_equal(r$n_recruit, 144) # not ceiling(128 / 0.9) = 143
  expect_equal(r$unit, "group")

  spec$options$allocation_ratio <- 2
  r <- recruitment_target(spec, 150)
  expect_equal(r$groups_analysed, c(50, 100))
  expect_equal(r$groups_recruit, c(56, 112))
  expect_equal(r$n_recruit, 168)

  r <- recruitment_target(with_attrition("anova_2x2_between", 0.15), 80)
  expect_equal(r$groups_recruit, rep(24, 4)) # 20 / 0.85 = 23.5
  expect_equal(r$n_recruit, 96)
  expect_equal(r$unit, "cell")

  r <- recruitment_target(with_attrition("anova_2x2_mixed", 0.25), 60)
  expect_equal(r$groups_recruit, c(40, 40))

  # The two-variance test splits its total into two equal groups too, so
  # each group is rounded up on its own.
  r <- recruitment_target(with_attrition("two_variances", 0.1), 200)
  expect_equal(r$groups_analysed, c(100, 100))
  expect_equal(r$groups_recruit, c(112, 112)) # not ceiling(200 / 0.9) = 223
  expect_equal(r$n_recruit, 224)
  expect_equal(r$unit, "group")
})

test_that("run_spec() records the number to recruit for each goal", {
  spec <- with_attrition("independent_t", 0.1)
  spec$goal <- list(type = "sample_size", power = 0.8)
  result <- run_spec(spec)
  expect_equal(result$recruitment$n_analysed, result$n_required$n)
  expect_equal(result$recruitment$n_recruit, 2 * ceiling(result$n_required$n / 2 / 0.9 - 1e-9))
  expect_output(print(result), "To recruit: ", fixed = TRUE)

  spec$goal <- list(type = "power", n = 100)
  result <- run_spec(spec)
  expect_equal(result$recruitment$n_recruit, 112) # 50 / 0.9 = 55.6 per group

  spec$options$attrition <- NULL
  expect_true(is.na(run_spec(spec)$recruitment))
})

test_that("the exported script works out the same number to recruit", {
  skip_on_cran()
  spec <- with_attrition("independent_t", 0.1)
  spec$options$allocation_ratio <- 2
  spec$goal <- list(type = "sample_size", power = 0.8)
  result <- run_spec(spec)
  text <- export_script(spec, result)
  expect_match(text, "doi:10.1002/ijop.70017", fixed = TRUE)
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced$n_recruit, result$recruitment$n_recruit)
  expect_equal(out$reproduced, out$powerkit)

  # Without attrition the script has no recruitment section.
  spec$options$attrition <- NULL
  expect_no_match(export_script(spec, run_spec(spec)), "Participants to recruit", fixed = TRUE)
})
