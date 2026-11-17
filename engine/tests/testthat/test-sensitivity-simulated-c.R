# Split from test-sensitivity-search.R so that the slow simulated searches
# run as files of their own and the CI parts stay within their time.
# The checks are in helper-sensitivity-simulated.R.

test_that("simulated searches for unordered categories and factorial logistic effects land where a fresh simulation has the target power", {
  skip_on_cran()
  sensitivity_simulated_check(c("multinomial_regression", "multinomial_interaction", "logistic_factorial"))
  # The factorial logistic effect's size: for a main effect, the odds
  # ratio between the levels with the most and the fewest 'yes' on the
  # log-odds scale averaged over the other factor; for the interaction in
  # a 2 x 2 table, the ratio of the odds ratios.
  spec <- example_spec("logistic_factorial")
  l <- stats::qlogis(do.call(rbind, lapply(spec$population$probabilities, unlist)))
  plan <- simulated_search_plan(spec, 600L, 0.8)
  expect_equal(plan$effect(2), exp(2 * abs(diff(rowMeans(l)))))
  spec$variables$B$levels <- list("Doctor", "Friend")
  spec$population$probabilities <- list(list(0.3, 0.4), list(0.4, 0.45))
  spec$target_test$effect <- "interaction"
  odds <- function(p) p / (1 - p)
  ratio <- (odds(0.3) / odds(0.4)) / (odds(0.4) / odds(0.45))
  expect_equal(simulated_search_plan(spec, 600L, 0.8)$effect(1), max(ratio, 1 / ratio))
  # A time series tested on both changes scales the two together, so it
  # needs one of them.
  both <- example_spec("its")
  both$target_test$effect <- "both"
  both$population$level_change <- 0
  both$goal <- list(type = "sensitivity", n = 24L, power = 0.8)
  expect_error(validate_spec(both), "no effect pattern to scale")
  # A flat pattern of proportions has nothing to scale.
  flat <- example_spec("proportion_trend")
  flat$population$proportions <- list(0.3, 0.3, 0.3, 0.3)
  flat$goal <- list(type = "sensitivity", n = 100L, power = 0.8)
  expect_error(validate_spec(flat), "no effect pattern to scale")
})
