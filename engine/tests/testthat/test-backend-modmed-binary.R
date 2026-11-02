# A yes/no X or W in moderated mediation (PROCESS models 7 and 14, E17):
# power4mome with rbinary_rs(), rescaled to mean 0 and SD 1.

binary_modmed_spec <- function(template = "process_7", x_binary = TRUE, w_binary = FALSE, nrep = 100L) {
  spec <- read_spec(system.file("specs", paste0(template, ".json"), package = "powerkit"))
  spec$variables$X <- if (x_binary) list(type = "binary", label = "Condition") else list(type = "continuous", label = "Score")
  spec$variables$W <- if (w_binary) list(type = "binary", label = "Group") else list(type = "continuous", label = "Moderator")
  spec$population$correlations <- NULL
  if (x_binary) spec$population$x_prob <- 0.5
  if (w_binary) spec$population$w_prob <- 0.4
  spec$goal <- list(type = "power", n = 300L)
  spec$options <- list(nrep = nrep, seed = 17L, ci_draws = 200L)
  spec
}

test_that("a yes/no X, W or both run on power4mome, and the check run recovers the paths and the splits", {
  for (case in list(c(TRUE, FALSE), c(FALSE, TRUE), c(TRUE, TRUE))) {
    spec <- binary_modmed_spec("process_7", case[1], case[2])
    result <- suppressWarnings(run_spec(spec))
    expect_true(all(result$check_run$ok), label = paste(case, collapse = " "))
    if (case[2]) expect_true("proportion in W's second level" %in% result$check_run$parameter)
  }
  result <- suppressWarnings(run_spec(binary_modmed_spec("process_14", FALSE, TRUE)))
  expect_true(all(result$check_run$ok))
})

test_that("a yes/no X or W can't be correlated with the other, and its proportion needs it to be yes/no", {
  spec <- binary_modmed_spec()
  spec$population$correlations <- list("X<->W" = 0.2)
  expect_spec_problem(spec, "must be uncorrelated")
  spec <- binary_modmed_spec(w_binary = FALSE)
  spec$population$w_prob <- 0.3
  expect_spec_problem(spec, "'population > w_prob'")
})

test_that("the exported script draws the yes/no variables with rbinary_rs()", {
  spec <- binary_modmed_spec("process_14", TRUE, TRUE)
  result <- suppressWarnings(run_spec(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("X = list(rbinary_rs, p1 = 0.5), W = list(rbinary_rs, p1 = 0.4)", script, fixed = TRUE)))
  expect_script_reproduces_power(spec, result)
})

test_that("parallel mediators take a yes/no X or W too", {
  spec <- binary_modmed_spec("process_7_parallel", TRUE, TRUE)
  result <- suppressWarnings(run_spec(spec))
  expect_true(all(result$check_run$ok))
  expect_true(all(c("proportion in X's second level", "proportion in W's second level") %in% result$check_run$parameter))
})

test_that("the simulated data set draws a yes/no W as power4mome does", {
  spec <- binary_modmed_spec("process_7", FALSE, TRUE)
  spec$variables$W$levels <- list("No", "Yes")
  data <- simulated_data(spec, 2000)
  share <- mean(data$Group == "Yes")
  expect_lt(abs(share - 0.4), 0.05)
})
