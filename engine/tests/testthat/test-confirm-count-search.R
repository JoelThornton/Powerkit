count_search_fixture <- function() list(
  n_required = list(n = 362, lower = 360, upper = 364, power = .8),
  curve = data.frame(n = 362, power = .8, mcse = .004),
  simulations = simulation_record(360, 51, 4000, 5000, TRUE))

test_that("discrete-count confirmation rejects an underpowered fitted N and checks a larger allocation", {
  spec <- list(goal = list(power = .8))
  calls <- list()
  backend <- list(n_step = 2, simulate = function(n, nrep, seed, cores) {
    calls[[length(calls) + 1]] <<- list(n = n, nrep = nrep, seed = seed)
    list(rejections = nrep * if (n == 362) .795 else .84, nrep = nrep,
      attempted = nrep, valid = nrep - 20)
  })
  found <- confirm_count_search(spec, backend, count_search_fixture(), 5000, 51, 1)
  expect_equal(found$n_required$n, 382)
  expect_equal(length(calls), 2)
  expect_equal(vapply(calls, `[[`, 0, "nrep"), c(10000, 10000))
  expect_equal(found$n_required$search_estimate$n, 362)
  expect_true(is.na(found$n_required$lower))
  expect_gte(found$n_required$power_lower, .8)
  expect_equal(found$n_required$power_lower,
    unname(stats::binom.test(8400, 10000, alternative = "greater", conf.level = .999)$conf.int[1]))
  expect_equal(found$simulations$stage, c("search", "confirmation", "confirmation"))
  expect_equal(length(unique(found$simulations$seed)), 3)
  expect_equal(tail(found$simulations$failed, 1), 20)
  expect_equal(tail(found$simulations$successful_study_probability, 1), .84)
})

test_that("a noisy target hit cannot become a recommendation and the confirmation is bounded", {
  calls <- 0L
  backend <- list(n_step = 2, simulate = function(n, nrep, seed, cores) {
    calls <<- calls + 1L
    list(rejections = .8 * nrep, nrep = nrep)
  })
  expect_error(confirm_count_search(list(goal = list(power = .8)), backend,
    count_search_fixture(), 1000, 51, 1), "No sample size is recommended", fixed = TRUE)
  expect_equal(calls, 10)
  calls <- 0L
  backend$n_max <- 362
  expect_error(confirm_count_search(list(goal = list(power = .8)), backend,
    count_search_fixture(), 1000, 51, 1), "checking limit", fixed = TRUE)
  expect_equal(calls, 1)
})
