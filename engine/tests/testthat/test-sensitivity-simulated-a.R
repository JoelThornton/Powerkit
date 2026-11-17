# Split from test-sensitivity-search.R so that the slow simulated searches
# run as files of their own and the CI parts stay within their time.
# The checks are in helper-sensitivity-simulated.R.

test_that("simulated searches for paired variances, trends, d prime and time series land where a fresh simulation has the target power", {
  skip_on_cran()
  sensitivity_simulated_check(c("paired_variances", "proportion_trend", "dprime", "jonckheere", "its"))
})
