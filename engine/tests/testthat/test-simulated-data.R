spec_file <- function(name) system.file("specs", paste0(name, ".json"), package = "powerkit")

test_that("every row is marked as simulated, and columns are named after the labels", {
  data <- simulated_data(read_spec(spec_file("independent_t")), 40, seed = 2)
  expect_equal(names(data), c("SIMULATED_NOT_REAL_DATA", "participant", "Condition", "Recall_score"))
  expect_true(all(data$SIMULATED_NOT_REAL_DATA == "simulated by powerkit"))
  expect_equal(nrow(data), 40)
  expect_setequal(unique(data$Condition), c("Control", "Training"))
})

test_that("the same seed gives the same data, and the CSV keeps the marker column first", {
  spec <- read_spec(spec_file("anova_2x2_mixed"))
  expect_identical(simulated_data(spec, 40, seed = 5), simulated_data(spec, 40, seed = 5))
  file <- tempfile(fileext = ".csv")
  simulated_data(spec, 40, seed = 5, file = file)
  csv <- utils::read.csv(file)
  expect_equal(names(csv)[1], "SIMULATED_NOT_REAL_DATA")
  expect_equal(names(csv)[-(1:2)], c("Group", "Depression_score_Pre", "Depression_score_Post"))
  expect_equal(nrow(csv), 40)
})

test_that("a large simulated data set recovers the population, in the spec's orientation", {
  big <- 20000
  spec <- read_spec(spec_file("independent_t"))
  data <- simulated_data(spec, big, seed = 1)
  levels <- unlist(spec$variables$X$levels)
  y <- split(data$Recall_score, data$Condition)
  expect_equal(mean(y[[levels[2]]]) - mean(y[[levels[1]]]), spec$population$d, tolerance = 0.05 / abs(spec$population$d))

  spec <- read_spec(spec_file("paired_t"))
  data <- simulated_data(spec, big, seed = 1)
  diff <- data[[4]] - data[[3]]
  expect_equal(mean(diff) / stats::sd(diff), spec$population$dz, tolerance = 0.05 / abs(spec$population$dz))

  spec <- read_spec(spec_file("two_proportions"))
  data <- simulated_data(spec, big, seed = 1)
  yes <- unlist(spec$variables$Y$levels)[2]
  groups <- unlist(spec$variables$X$levels)
  p <- vapply(groups, function(g) mean(data$Attended[data$Reminder == g] == yes), numeric(1))
  expect_equal(unname(p), c(spec$population$p1, spec$population$p2), tolerance = 0.02)

  spec <- read_spec(spec_file("anova_2x2_mixed"))
  data <- simulated_data(spec, big, seed = 1)
  means <- matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
  waitlist <- data$Group == unlist(spec$variables$A$levels)[1]
  expect_equal(mean(data$Depression_score_Post[waitlist]), means[1, 2], tolerance = 0.02)
  expect_equal(mean(data$Depression_score_Pre[!waitlist]), means[2, 1], tolerance = 0.02)
  expect_equal(stats::cor(data$Depression_score_Pre, data$Depression_score_Post), spec$population$r, tolerance = 0.05)

  spec <- read_spec(spec_file("regression_interaction"))
  data <- simulated_data(spec, big, seed = 1)
  rel <- spec$variables$X$reliability * (spec$variables$Y$reliability %||% 1)
  expect_equal(stats::cor(data$Daily_stress, data$Sleep_quality), spec$population$r_X_Y * sqrt(rel), tolerance = 0.05)
})

test_that("designs without a generator say so", {
  spec <- read_spec(spec_file("sem_model_fit"))
  expect_false(simulated_data_available(spec))
  expect_error(simulated_data(spec, 100), class = "powerkit_not_available")
  expect_true(simulated_data_available(read_spec(spec_file("mediation_simple"))))
})

test_that("the R script builds the same data set as simulated_data()", {
  spec <- read_spec(spec_file("correlation"))
  spec$goal <- list(type = "power", n = 30)
  result <- run_spec(spec)
  script <- export_script(spec, result)
  expect_match(script, "A simulated data set (NOT real data)", fixed = TRUE)
  expect_match(script, "SIMULATED-not-real-data-correlation.csv", fixed = TRUE)
  lines <- strsplit(script, "\n")[[1]]
  start <- grep("^set\\.seed\\(", lines)
  start <- start[length(start)]
  env <- new.env(parent = baseenv())
  eval(parse(text = lines[start:length(lines)]), envir = env)
  expect_identical(env$simulated, simulated_data(spec, 30, seed = result$provenance$seed))
})
