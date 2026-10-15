# expect_n_near() (helper-validation.R), which the published required-n
# validation tests use. A published n is either a single n, which must lie
# in powerkit's interval, or a range c(lower, upper), which must overlap it.

n_interval <- function(n, lower, upper) list(n = n, lower = lower, upper = upper)

test_that("a single published n must lie in powerkit's interval", {
  powerkit <- n_interval(3620, 3580, 3660)
  expect_success(expect_n_near(powerkit, 3600))
  expect_success(expect_n_near(powerkit, 3580))
  expect_success(expect_n_near(powerkit, 3660))
  expect_failure(
    expect_n_near(powerkit, 3750),
    "Published n = 3750; must lie in powerkit's interval \\[3580, 3660\\] \\(estimate 3620\\)"
  )
})

test_that("a published range passes if it overlaps powerkit's interval", {
  overlapping <- list(
    # The InteractionPoweR tutorial's "approximately 3,750", searched in
    # steps of 250: the true value lies in 3,501 to 3,750.
    list(n_interval(3620, 3580, 3660), c(3501, 3750)),
    # power4mome's n_region_from_power(): a region such as 300 to 347.
    list(n_interval(320, 290, 350), c(300, 347)),
    # powerkit's interval inside the published range, and the other way round.
    list(n_interval(320, 310, 330), c(300, 347)),
    list(n_interval(320, 250, 400), c(300, 347))
  )
  for (case in overlapping) {
    expect_success(expect_n_near(case[[1]], case[[2]]))
    # powerkit's estimate is inside the published range: not a narrow pass.
    expect_no_warning(expect_n_near(case[[1]], case[[2]]))
  }
})

test_that("a narrow overlap passes but is reported", {
  # powerkit's estimate (3,790) lies outside the published range; the
  # intervals overlap only from 3,740 to 3,750.
  narrow <- n_interval(3790, 3740, 3840)
  expect_success(suppressWarnings(expect_n_near(narrow, c(3501, 3750))))
  expect_warning(
    expect_n_near(narrow, c(3501, 3750)),
    "Narrow pass: powerkit's estimate n = 3790 lies outside the published range [3501, 3750]; the intervals overlap only in [3740, 3750]",
    fixed = TRUE
  )
  # Touching at a single n counts as overlap.
  touching <- n_interval(370, 347, 390)
  expect_success(suppressWarnings(expect_n_near(touching, c(300, 347))))
  expect_warning(expect_n_near(touching, c(300, 347)), "overlap only in [347, 347]", fixed = TRUE)
})

test_that("a published range that doesn't overlap powerkit's interval fails, stating both intervals", {
  expect_failure(
    expect_n_near(n_interval(3870, 3800, 3950), c(3501, 3750)),
    "Published n range \\[3501, 3750\\]; must overlap powerkit's interval \\[3800, 3950\\] \\(estimate 3870\\)\\. Overlap: none\\."
  )
  expect_failure(expect_n_near(n_interval(280, 250, 299), c(300, 347)), "Overlap: none")
})

test_that("a malformed published n stops with a clear message", {
  powerkit <- n_interval(320, 290, 350)
  expect_error(expect_n_near(powerkit, c(347, 300)), "lower <= upper")
  expect_error(expect_n_near(powerkit, c(300, 320, 347)), "single n or a range")
  expect_error(expect_n_near(powerkit, NA), "single n or a range")
})

test_that("required-n tests take exactly one of a published n and a published range", {
  expect_identical(published_n_value(3750, NULL), 3750)
  expect_identical(published_n_value(NULL, c(3501, 3750)), c(3501, 3750))
  expect_error(published_n_value(NULL, NULL), "exactly one")
  expect_error(published_n_value(3750, c(3501, 3750)), "exactly one")
})
