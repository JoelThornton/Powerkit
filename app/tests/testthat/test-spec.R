test_that("the examples build specs the engine accepts", {
  for (template in c("2x2_between", "2x2_mixed")) {
    checked <- engine_call(validate_spec(build_spec_2x2(example_values(template))))
    expect_true(checked$ok, info = template)
    expect_identical(checked$value$template, template)
  }
})

test_that("cell means are read row by row: rows are A, columns are B", {
  values <- example_values("2x2_between")
  values[c("m11", "m12", "m21", "m22")] <- list(1, 2, 3, 4)
  spec <- build_spec_2x2(values)
  expect_equal(spec_means(spec), matrix(1:4, nrow = 2, byrow = TRUE))
})

test_that("blank fields give the validator's messages with the form's labels", {
  values <- example_values("2x2_mixed")
  values$sd <- NA
  values$r <- NA
  values$m12 <- NA
  values$just_source <- ""
  values$alpha <- 2
  spec <- build_spec_2x2(values)
  checked <- engine_call(validate_spec(spec))
  expect_false(checked$ok)
  shown <- friendly_problems(checked$problems, spec)
  expect_true("Please fill in \"Standard deviation\"." %in% shown)
  expect_true("Please fill in \"Correlation between the repeated measures\"." %in% shown)
  expect_true("Please fill in \"Mean for a1, b2\"." %in% shown)
  expect_true(any(grepl("\"Effect-size justification\" can't be empty", shown, fixed = TRUE)))
  expect_true(any(grepl("\"Alpha\" must be at most 0.5", shown, fixed = TRUE)))
  expect_false(any(grepl("population >", shown, fixed = TRUE)))
})

test_that("an earlier-study justification needs an adjustment", {
  values <- example_values("2x2_between")
  values$just_type <- "prior_study"
  spec <- build_spec_2x2(values)
  checked <- engine_call(validate_spec(spec))
  expect_false(checked$ok)
  expect_match(friendly_problem(checked$problems, spec), "Adjustment to the earlier estimate")
})

test_that("engine advice is passed on and other warnings are dropped", {
  values <- example_values("2x2_between")
  values$just_type <- "pilot_study"
  checked <- engine_call(validate_spec(build_spec_2x2(values)))
  expect_true(checked$ok)
  expect_match(checked$advice, "pilot")
  expect_identical(engine_call({warning("noise"); 1})$advice, character())
})

test_that("unexpected errors become a plain message", {
  out <- suppressWarnings(engine_call(stop("internal detail")))
  expect_false(out$ok)
  expect_false(grepl("internal detail", out$problems))
})

test_that("an empty form lists each blank field once", {
  values <- lapply(example_values("2x2_between"), function(v) if (is.numeric(v)) NA else "")
  values$template <- "2x2_between"
  values$effect <- "interaction"
  values$just_type <- "smallest_effect_of_interest"
  spec <- build_spec_2x2(values)
  shown <- friendly_problems(engine_call(validate_spec(spec))$problems, spec)
  expect_false(any(grepl("repeated entries", shown)))
  expect_true("Please fill in \"Mean for A level 1, B level 1\"." %in% shown)
  expect_true("Please fill in \"Target power\"." %in% shown)
  expect_false(any(grepl("population|variables|goal", shown)))
})
