# search_n() and its helpers, tested with a mock backend whose true power
# curve is known, so the search can be checked exactly and quickly.

mock_backend <- function(power_at, step = 4) {
  list(
    name = "mock",
    simulation_function = "mock",
    packages = character(),
    n_step = step,
    exact_min_n = step,
    simulate = function(n, nrep, seed, cores) {
      set.seed(seed)
      list(rejections = stats::rbinom(1, nrep, power_at(n)), nrep = nrep)
    },
    exact_power = power_at,
    check_run = function() data.frame(parameter = "x", specified = 0, recovered = 0, ok = TRUE)
  )
}

# Power reaches .80 at n = 784.6 (sqrt(n) * 0.1 = 1.96 + 0.84).
true_power <- function(n) stats::pnorm(0.1 * sqrt(n) - stats::qnorm(0.975))

test_that("bracket_n() finds the smallest valid n reaching the target", {
  expect_equal(bracket_n(true_power, 0.8, 8, 4), 788)
  expect_equal(bracket_n(true_power, 0.8, 800, 4), 800)
  expect_error(bracket_n(function(n) 0.1, 0.8, 8, 4), "too small to detect", class = "powerkit_run_error")
})

test_that("search_n() brackets the true required n with its interval", {
  spec <- example_spec("anova_2x2_between")
  result <- search_n(spec, mock_backend(true_power), power = 0.8, nrep = 20000, seed = 1)
  est <- result$n_required
  expect_true(est$lower <= 788 && 788 <= est$upper)
  expect_true(est$lower <= est$n && est$n <= est$upper)
  expect_lte(abs(est$n - 788), 12)
  expect_true(all(c(est$n, est$lower, est$upper) %% 4 == 0))
  expect_named(result$curve, c("n", "power", "mcse"))
  expect_true(all(diff(result$curve$n) > 0))
})

test_that("search_n() widens the grid when the interval runs off the end", {
  spec <- example_spec("anova_2x2_between")
  # A misleading approximation sends the first grid far too low.
  backend <- mock_backend(true_power)
  backend$exact_power <- function(n) true_power(4 * n)
  result <- search_n(spec, backend, power = 0.8, nrep = 20000, seed = 2)
  expect_true(result$n_required$lower <= 788 && 788 <= result$n_required$upper)
})

test_that("search_n() is reproducible for a given seed", {
  spec <- example_spec("anova_2x2_between")
  a <- search_n(spec, mock_backend(true_power), power = 0.8, nrep = 2000, seed = 5)
  b <- search_n(spec, mock_backend(true_power), power = 0.8, nrep = 2000, seed = 5)
  expect_identical(a, b)
})

test_that("replications are split evenly across cores", {
  expect_equal(split_replications(10000, 4), rep(2500, 4))
  expect_equal(split_replications(10, 3), c(4, 3, 3))
  expect_equal(split_replications(10, 1), 10)
  expect_equal(sum(split_replications(1001, 8)), 1001)
})

test_that("large simulations run in batches no larger than the batch size", {
  expect_equal(number_of_chunks(10000, 1, 500), 20)
  expect_equal(number_of_chunks(10000, 4, 500), 20)
  # With a batch size, the number of batches never depends on the cores.
  expect_equal(number_of_chunks(1000, 4, 500), 2)
  expect_equal(number_of_chunks(10, 1, 4), 3)
  expect_equal(number_of_chunks(10, 4, 4), 3)
  expect_equal(number_of_chunks(100, 8, 500), 1)
  # Without one, one chunk per core.
  expect_equal(number_of_chunks(1000, 4), 4)
  expect_equal(split_replications(1001, number_of_chunks(1001, 1, 500)), c(334, 334, 333))

  calls <- list()
  run_chunk <- function(k, seed) {
    calls[[length(calls) + 1]] <<- c(k = k, seed = seed)
    c(k %/% 2, k - 1)
  }
  sim <- simulate_in_chunks(1000, seed = 7, cores = 1, run_chunk, batch_size = 300)
  calls <- do.call(rbind, calls)
  expect_equal(unname(calls[, "k"]), rep(250, 4))
  expect_equal(unname(calls[, "seed"]), 7:10)
  # Only the counts are kept, summed over batches.
  expect_equal(sim, list(rejections = 4 * 125, nrep = 4 * 249))
})

test_that("derived seeds stay in R's valid range", {
  expect_equal(offset_seed(20261012, 0:2), 20261012 + 0:2)
  expect_equal(offset_seed(2147483646, 1), 1)
})
