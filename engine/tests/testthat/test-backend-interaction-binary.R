# A two-way regression interaction with a yes/no X or W (E15):
# InteractionPoweR with k.x1 or k.x2 = 2.

binary_example <- function(goal = list(type = "power", n = 200), ...) {
  spec <- read_spec(system.file("specs", "regression_interaction_binary.json", package = "powerkit"))
  spec$goal <- goal
  spec$options <- utils::modifyList(spec$options, list(...))
  spec
}

test_that("a yes/no X reaches InteractionPoweR as a two-level variable and passes its check run", {
  spec <- validate_spec(binary_example())
  inputs <- interactionpower_inputs(spec)
  expect_equal(c(inputs$k.x1, inputs$k.x2), c(2, 0))
  result <- run_spec(binary_example(nrep = 200))
  expect_true(all(result$check_run$ok))
  expect_identical(result$provenance$method, "simulation")
})

test_that("a yes/no X agrees with InteractionPoweR called directly", {
  result <- run_spec(binary_example(goal = list(type = "power", n = 300), nrep = 2000, seed = 3))
  direct <- with_seed(4, suppressMessages(InteractionPoweR::power_interaction(
    n.iter = 2000, N = 300, r.x1.y = 0.2, r.x2.y = -0.3, r.x1x2.y = 0.15, r.x1.x2 = 0, rel.x2 = 0.85, k.x1 = 2
  )))$pwr[1]
  expect_lt(abs(result$curve$power - direct), 4 * sqrt(2) * result$curve$mcse)
})

test_that("the yes/no variable's correlation is shown as the group difference it implies", {
  d <- implied_group_difference(validate_spec(binary_example()))[[1]]
  expect_identical(d$role, "X")
  expect_identical(d$kind, "correlation")
  expect_equal(d$d, psych::r2d(0.2))
  expect_null(implied_group_difference(read_spec(system.file("specs", "regression_interaction.json", package = "powerkit"))))
})

test_that("a yes/no variable's reliability, both variables yes/no and the smallest effect are refused", {
  spec <- binary_example()
  spec$variables$X$reliability <- 0.9
  expect_error(validate_spec(spec), "can't be used for a yes/no variable")
  spec <- binary_example()
  spec$variables$W <- list(type = "binary", label = "Sex", levels = list("Female", "Male"))
  expect_error(run_spec(spec), "use the 2x2 ANOVA design", class = "powerkit_not_available")
  expect_error(run_spec(binary_example(goal = list(type = "sensitivity", n = 200, power = 0.8))), "isn't available yet")
})

test_that("the exported script and the simulated data use the two-level variable", {
  result <- run_spec(binary_example(nrep = 200))
  script <- export_script(binary_example(nrep = 200), result)
  expect_true(any(grepl("k_x1 <- 2", script, fixed = TRUE)))
  expect_true(any(grepl("k.x1 = k_x1, k.x2 = k_x2,", script, fixed = TRUE)))
  data <- simulated_data(binary_example(), 2000, seed = 1)
  expect_setequal(unique(data$Training), c("Waitlist", "Mindfulness training"))
  expect_equal(mean(data$Training == "Mindfulness training"), 0.5, tolerance = 0.05)
})
