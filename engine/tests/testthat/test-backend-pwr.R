# Basic tests by exact formula via pwr (the default for basic tests;
# docs/decisions.md, 17 October 2026): routing, agreement with direct pwr
# calls, and the methods that stay on Spower.

# An example basic-test spec on the default (pwr) path: Student's t-test for
# the independent design, seed 7, and the goal given.
pwr_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  if (name == "independent_t") {
    spec$target_test$method <- "student_t"
  }
  spec$goal <- goal
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

pwr_templates <- c(
  "one_sample_t", "independent_t", "paired_t", "correlation",
  "two_proportions", "chi_square_independence"
)

test_that("every basic test except Welch's runs on pwr by default, exactly", {
  for (name in pwr_templates) {
    result <- run_spec(pwr_spec(name, list(type = "power", n = 100)))
    expect_equal(result$provenance$backend, "pwr", info = name)
    expect_equal(result$provenance$method, "exact", info = name)
    expect_equal(result$curve$mcse, 0, info = name)
    expect_true(all(result$check_run$ok), info = name)
    expect_true(all(c("pwr", "powerkit") %in% names(result$provenance$packages)), info = name)
  }
})

test_that("pwr's results equal direct pwr calls", {
  at <- function(name, n, ...) run_spec(pwr_spec(name, list(type = "power", n = n), ...))$curve$power
  one_sample <- example_spec("one_sample_t")$population$d
  expect_equal(at("one_sample_t", 60), pwr::pwr.t.test(n = 60, d = one_sample, type = "one.sample")$power)
  expect_equal(at("independent_t", 128), pwr::pwr.t.test(n = 64, d = 0.4, type = "two.sample")$power)
  paired <- example_spec("paired_t")$population$dz
  expect_equal(at("paired_t", 40), pwr::pwr.t.test(n = 40, d = paired, type = "paired")$power)
  r <- example_spec("correlation")$population$r
  expect_equal(at("correlation", 90), pwr::pwr.r.test(n = 90, r = r)$power)
  pop <- example_spec("two_proportions")$population
  expect_equal(
    at("two_proportions", 300),
    pwr::pwr.2p2n.test(h = pwr::ES.h(pop$p2, pop$p1), n1 = 150, n2 = 150)$power
  )
  p <- probability_matrix(example_spec("chi_square_independence"))
  expect_equal(
    at("chi_square_independence", 200),
    pwr::pwr.chisq.test(w = pwr::ES.w2(p), N = 200, df = (nrow(p) - 1) * (ncol(p) - 1))$power
  )
})

test_that("unequal groups use pwr.t2n.test(), and one-sided tests keep the spec's direction", {
  spec <- pwr_spec(
    "independent_t", list(type = "power", n = 150),
    options = list(seed = 7, allocation_ratio = 2)
  )
  result <- run_spec(spec)
  expect_equal(result$provenance$backend_function, "pwr::pwr.t2n.test")
  expect_equal(result$curve$power, pwr::pwr.t2n.test(n1 = 50, n2 = 100, d = 0.4)$power)

  greater <- pwr_spec("independent_t", list(type = "power", n = 100))
  greater$target_test$alternative <- "greater"
  expect_equal(
    run_spec(greater)$curve$power,
    pwr::pwr.t.test(n = 50, d = 0.4, alternative = "greater")$power
  )
  # A one-sided test in the wrong direction has almost no power.
  less <- greater
  less$target_test$alternative <- "less"
  expect_lt(run_spec(less)$curve$power, 0.01)
})

test_that("the required n is the smallest valid n whose pwr power reaches the target", {
  spec <- pwr_spec("independent_t", list(type = "sample_size", power = 0.8))
  result <- run_spec(spec)
  n <- result$n_required$n
  expect_equal(n %% 2, 0)
  expect_gte(pwr::pwr.t.test(n = n / 2, d = 0.4)$power, 0.8)
  expect_lt(pwr::pwr.t.test(n = n / 2 - 1, d = 0.4)$power, 0.8)
  expect_equal(result$n_required$lower, n)
  expect_equal(result$n_required$upper, n)
  # The same answers give the same result: nothing is random.
  spec$options$seed <- 8
  expect_equal(run_spec(spec)$n_required$n, n)
})

test_that("Welch's t-test and requested simulation run on Spower", {
  welch <- example_spec("independent_t")
  welch$options <- list(seed = 7, nrep = 100)
  welch$goal <- list(type = "power", n = 100)
  expect_equal(run_quietly(welch)$provenance$backend, "Spower")

  simulated <- pwr_spec("correlation", list(type = "power", n = 80))
  simulated$options$method <- "simulation"
  simulated$options$nrep <- 100
  result <- run_quietly(simulated)
  expect_equal(result$provenance$backend, "Spower")
  expect_equal(result$provenance$method, "simulation")
})

test_that("the exact method can't be asked for Welch's t-test", {
  welch <- example_spec("independent_t")
  welch$options$method <- "exact"
  expect_spec_problem(welch, "isn't available for Welch's t-test")
})

test_that("departure: pwr's formula vs Spower's simulation (Departure 9)", {
  # powerkit's earlier default was Spower simulation for every basic test;
  # the formula is now the default (docs/conventions.md, Departure 9). The
  # same design by both methods, 5,000 seeded replications (seed 9): the
  # differences are Monte Carlo noise (within 2 standard errors), largest
  # .008 for the independent t-test. One core: Spower's replications are
  # split one batch per core, so the core count changes the draws.
  skip_on_cran()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  designs <- list(
    one_sample_t = list(n = 90, formula = 0.8038, simulation = 0.8060),
    independent_t = list(n = 200, formula = 0.8036, simulation = 0.7954),
    paired_t = list(n = 60, formula = 0.7601, simulation = 0.7580),
    correlation = list(n = 120, formula = 0.5952, simulation = 0.5926),
    two_proportions = list(n = 340, formula = 0.4911, simulation = 0.4858),
    chi_square_independence = list(n = 150, formula = 0.0855, simulation = 0.0870)
  )
  for (name in names(designs)) {
    d <- designs[[name]]
    spec <- pwr_spec(name, list(type = "power", n = d$n), options = list(seed = 9, nrep = 5000L))
    formula <- run_quietly(spec)$curve
    spec$options$method <- "simulation"
    simulated <- run_quietly(spec)$curve
    expect_equal(round(formula$power, 4), d$formula, info = name)
    expect_equal(round(simulated$power, 4), d$simulation, info = name)
    expect_lte(abs(simulated$power - formula$power), 2 * simulated$mcse, label = name)
  }
})
