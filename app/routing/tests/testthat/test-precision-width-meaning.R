test_that("width explanations follow the backend's actual planning quantity", {
  read <- engine_function("read_spec")
  run <- engine_function("run_spec")
  get <- function(name) read(file.path(repo_dir, "engine/inst/specs", paste0(name, ".json")))
  standardised <- get("precision_two_groups")
  result <- run(standardised)
  expect_identical(result$provenance$backend, "MBESS")
  expect_match(precision_sentences(standardised, result)[["reading"]], "average across studies", fixed = TRUE)
  proportion <- get("precision_proportion")
  result <- run(proportion)
  expect_identical(result$provenance$backend, "presize")
  words <- precision_sentences(proportion, result)
  expect_match(words[["reading"]], "values you specified", fixed = TRUE)
  expect_no_match(words[["reading"]], "average|half of", ignore.case = TRUE)
  standardised$goal$assurance <- 0.8
  words <- precision_sentences(standardised, run(standardised))
  expect_match(words[["headline"]], "80% of studies", fixed = TRUE)
  expect_match(words[["reading"]], "assurance", fixed = TRUE)
  expect_no_match(words[["reading"]], "average", fixed = TRUE)
  proportion$goal <- list(type = "precision", n = 100L)
  words <- precision_sentences(proportion, run(proportion))
  expect_match(words[["reading"]], "different question", fixed = TRUE)
  expect_no_match(words[["reading"]], "doesn't depend", fixed = TRUE)
})

# Assurance by default on MBESS's routes (Departure 25, 8 November 2026).
test_that("the precision card asks for an assurance by default on MBESS's routes, starting empty", {
  fields <- form_fields(form_groups(forms, "E46"))
  base <- c(list(estimate = "regression_coefficient", P_label = "Sleep quality", Y_label = "Wellbeing", reg_b = "0.2",
    reg_r2 = "0.2", reg_r2_predictor = "0.1", reg_predictors = "3", goal = "precision_n", width = "0.2", conf_level = "0.95"), closing_ok)
  width_target <- Filter(function(f) identical(f$id, "width_target"), fields)[[1]]
  expect_identical(width_target$default, "assurance")
  assurance <- Filter(function(f) identical(f$id, "assurance"), fields)[[1]]
  expect_null(assurance$default)
  chosen <- c(base, list(width_target = "assurance"))
  applies <- Filter(function(f) field_applies(f, chosen), fields)
  expect_true(length(form_problems(applies, chosen)) > 0) # the chance is the user's to give
  chosen$assurance <- "0.9"
  applies <- Filter(function(f) field_applies(f, chosen), fields)
  expect_length(form_problems(applies, chosen), 0)
  expect_equal(build_spec(forms, "E46", fields, chosen)$goal$assurance, 0.9)
  expected <- c(base, list(width_target = "expected", assurance = "0.9"))
  expect_null(build_spec(forms, "E46", fields, expected)$goal$assurance)
  # Not offered where presize plans the width.
  proportion <- modifyList(form_examples$E46, list(goal = "precision_n", width = "0.1"))
  expect_false("width_target" %in% vapply(Filter(function(f) field_applies(f, proportion), fields), function(f) f$id, ""))
})

test_that("an assurance plan shows Departure 25, compares 80%, 90% and 95%, and writes the reason up", {
  run <- engine_function("run_spec")
  spec <- engine_function("read_spec")(file.path(repo_dir, "engine/inst/specs", "precision_regression_coefficient.json"))
  spec$population[c("b", "r2", "r2_predictor", "predictors")] <- list(0.2, 0.2, 0.1, 3L)
  spec$goal <- list(type = "precision", width = 0.2)
  expect_false("25" %in% names(departures_for(forms, "E46", spec)))
  spec$goal$assurance <- 0.9
  result <- run(spec)
  expect_equal(result$precision$n, 386)
  expect_true("25" %in% names(departures_for(forms, "E46", spec)))
  # The size of the difference: 349 on average, 373, 386 and 396 at 80%,
  # 90% and 95% assurance (docs/conventions.md, Departure 25).
  line <- assurance_cost_line(spec, result, run)
  expect_match(line, "349 participants give this width on average", fixed = TRUE)
  expect_match(line, "373 give it with 80% assurance, 386 with 90% and 396 with 95%", fixed = TRUE)
  values <- list(just_source = "a meta-analysis", just_type = "meta_analysis", assurance_reason = "a second study is not affordable.")
  text <- precision_writeup(forms$forms$E46, spec, result, list(), values, departures_for(forms, "E46", spec))
  expect_match(text[["short"]], "with 90% assurance (the chance that it is no wider), chosen because a second study is not affordable. This requires", fixed = TRUE)
  expect_match(text[["full"]], "Departures from the established tools' defaults: Precision planning", fixed = TRUE)
})
