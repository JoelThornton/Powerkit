# Split from test-sensitivity-search.R so that the slow simulated searches
# run as files of their own and the CI parts stay within their time.
# The checks are in helper-sensitivity-simulated.R.

test_that("simulated searches for moderation with a binary variable, logistic and Poisson moderation and group moderators land where a fresh simulation has the target power", {
  skip_on_cran()
  sensitivity_simulated_check(c("regression_interaction_binary", "logistic_interaction", "poisson_interaction", "group_moderator"))
})
