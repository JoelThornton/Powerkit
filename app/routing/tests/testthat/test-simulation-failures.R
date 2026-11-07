test_that("failed decisions expose both denominators without changing reported power", {
  record <- data.frame(n = 200, attempted = 1000, valid = 900, failed = 100,
    successful = 720, conditional_power = 0.8, successful_study_probability = 0.72, denominator = "valid")
  result <- list(provenance = list(simulations = record))
  words <- simulation_outcome_text(result)
  expect_match(words, "900", fixed = TRUE)
  expect_match(words, "80%", fixed = TRUE)
  expect_match(words, "72%", fixed = TRUE)
  expect_match(words, "valid decisions only", fixed = TRUE)
  expect_match(as.character(simulation_failures_ui(result)), "Some simulated studies", fixed = TRUE)
  result$provenance$simulations <- data.frame(n = 200, rejections = 720, nrep = 900)
  expect_length(simulation_outcome_text(result), 0)
})

test_that("whole-study output distinguishes failed fits in each and joint decisions", {
  row <- data.frame(attempted = 1000, valid = 900, failed = 100, successful = 720,
    conditional_power = 0.8, successful_study_probability = 0.72)
  r <- list(n = 200, analyses = cbind(label = "Main regression", row),
    joint = c(list(rule = "all"), as.list(row[1, ])))
  words <- whole_study_outcomes(r)
  expect_length(words, 2)
  expect_true(all(grepl("80%", words, fixed = TRUE)))
  expect_true(all(grepl("72%", words, fixed = TRUE)))
  expect_match(words[2], "The chance that every main analysis was significant", fixed = TRUE)
  expect_no_match(words[2], "Joint all criterion", fixed = TRUE)
})
