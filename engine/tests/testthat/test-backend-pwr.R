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
    # Two proportions in equal groups use base R's power.prop.test()
    # (Departure 11); every other basic test uses pwr.
    backend <- if (name == "two_proportions") "stats" else "pwr"
    expect_equal(result$provenance$backend, backend, info = name)
    expect_equal(result$provenance$method, "exact", info = name)
    expect_equal(result$curve$mcse, 0, info = name)
    expect_true(all(result$check_run$ok), info = name)
    expect_true(all(c(backend, "powerkit") %in% names(result$provenance$packages)), info = name)
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
    stats::power.prop.test(n = 150, p1 = pop$p1, p2 = pop$p2, strict = TRUE)$power
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
    two_proportions = list(n = 340, formula = 0.4892, simulation = 0.4858),
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

test_that("departure: correlation by Fisher's z, not G*Power's exact method (Departure 10)", {
  # pwr.r.test() uses Fisher's z; G*Power uses the exact distribution of r
  # (docs/conventions.md, Departure 10). Reference values: pwrss 1.3.3,
  # power.exact.onecor(), the exact method of Barabesi and Greco (2002) that
  # G*Power uses; it reproduces the G*Power 3.1 manual's examples for this
  # test (section 3.3: N = 1928; power 0.482927). Two-sided, alpha .05.
  exact <- list(
    "0.3" = c(`20` = 0.2539, `50` = 0.5722, `100` = 0.8652),
    "0.4" = c(`20` = 0.4303, `50` = 0.8352, `100` = 0.9871),
    "0.5" = c(`20` = 0.6417, `50` = 0.9672, `100` = 0.9997)
  )
  for (r in names(exact)) {
    for (n in names(exact[[r]])) {
      spec <- pwr_spec("correlation", list(type = "power", n = as.integer(n)))
      spec$population$r <- as.numeric(r)
      power <- run_quietly(spec)$curve$power
      expect_lt(abs(power - exact[[r]][[n]]), 0.004, label = paste("r =", r, "n =", n))
    }
  }
  # Required N for 80% power at r = .3: 85 by Fisher's z, 84 exactly.
  spec <- pwr_spec("correlation", list(type = "sample_size", power = 0.8))
  spec$population$r <- 0.3
  expect_identical(as.integer(run_quietly(spec)$n_required$n), 85L)
})

test_that("two proportions: the z test equals G*Power's (Departure 11)", {
  # G*Power 3.1.9.7, z tests, "Proportions: Difference between two
  # independent proportions", default options (no continuity correction,
  # no arcsine transformation), two tails, alpha .05, p1 = .10, p2 = .25.
  # Maintainer's screenshots, 17 October 2026 (docs/figures/gpower/):
  # post hoc with 20 per group, power 0.2344921; a priori for power .95,
  # 164 per group, actual power 0.9502464.
  spec <- pwr_spec("two_proportions", list(type = "power", n = 40))
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  result <- run_spec(spec)
  expect_equal(result$provenance$backend_function, "stats::power.prop.test")
  expect_equal(round(result$curve$power, 7), 0.2344921)
  expect_true(all(result$check_run$ok))

  spec$goal <- list(type = "sample_size", power = 0.95)
  result <- run_spec(spec)
  expect_identical(as.integer(result$n_required$n), 328L)
  expect_equal(round(result$curve$power[result$curve$n == 328], 7), 0.9502464)
})

test_that("departure: both tails counted (strict = TRUE), and the size of the change from the arcsine (Departure 11)", {
  # power.prop.test()'s default, strict = FALSE, ignores rejections in the
  # opposite tail: 0.2339595 instead of G*Power's 0.2344921 (p1 = .10,
  # p2 = .25, 20 per group).
  expect_equal(
    round(stats::power.prop.test(n = 20, p1 = 0.10, p2 = 0.25)$power, 7), 0.2339595
  )
  # powerkit's earlier default, pwr's arcsine formula, still available as
  # options > proportions_formula = "arcsine": 0.2478 at 20 per group,
  # and 160 rather than 164 per group for 95% power.
  spec <- pwr_spec("two_proportions", list(type = "power", n = 40))
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  spec$options$proportions_formula <- "arcsine"
  result <- run_spec(spec)
  expect_equal(result$provenance$backend_function, "pwr::pwr.2p2n.test")
  expect_equal(round(result$curve$power, 4), 0.2478)
  spec$goal <- list(type = "sample_size", power = 0.95)
  expect_identical(as.integer(run_spec(spec)$n_required$n), 320L)
})

test_that("two proportions in unequal groups use pwrss's z test, as G*Power (Departure 11)", {
  # power.prop.test() takes one n for both groups, so unequal groups use
  # pwrss::power.z.twoprops(std.error = "pooled") (maintainer's decision,
  # 17 October 2026). G*Power 3.1.9.7, z test, two tails, alpha .05,
  # p1 = .10, p2 = .25, a priori for power .95 with N2/N1 = 2: 123 + 247,
  # actual power 0.9498668 (maintainer's screenshot,
  # docs/figures/gpower/E5_z_test_a_priori_ratio2.png). The same groups:
  spec <- pwr_spec(
    "two_proportions", list(type = "power", n = 370),
    options = list(seed = 7, allocation_ratio = 247 / 123)
  )
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  result <- run_spec(spec)
  expect_equal(result$provenance$backend, "pwrss")
  expect_equal(result$provenance$backend_function, "pwrss::power.z.twoprops")
  expect_true(all(result$check_run$ok))
  expect_equal(round(result$curve$power, 7), 0.9498668)
})

test_that("two proportions: pwrss at 1:1, 1:2 and 1:3, both directions", {
  # Two tails, alpha .05, n1 = 100. G*Power values (G*Power 3.1.9.7, z
  # tests > difference between two independent proportions, post hoc;
  # maintainer's screenshots, 17 October 2026) at 1:2 and 1:3; pwrss 1.3.3
  # gives the same to 7 dp. At 1:1 pwrss equals power.prop.test(strict =
  # TRUE), which matches G*Power.
  expected <- list(
    "1" = c(up = 0.8018306, down = 0.8018306),
    "2" = c(up = 0.8960412, down = 0.9087742),
    "3" = c(up = 0.9292662, down = 0.9388485)
  )
  for (k in names(expected)) {
    for (direction in c("up", "down")) {
      spec <- pwr_spec(
        "two_proportions", list(type = "power", n = 100 * (1 + as.numeric(k))),
        options = list(seed = 7, allocation_ratio = as.numeric(k))
      )
      spec$population$p1 <- if (direction == "up") 0.10 else 0.25
      spec$population$p2 <- if (direction == "up") 0.25 else 0.10
      power <- run_spec(spec)$curve$power
      expect_equal(round(power, 7), expected[[k]][[direction]], label = paste0("1:", k, " ", direction))
    }
  }
  expect_equal(
    expected[["1"]][["up"]],
    round(stats::power.prop.test(n = 100, p1 = 0.10, p2 = 0.25, strict = TRUE)$power, 7)
  )
})

test_that("departure: unequal groups keep the exact ratio, so N can differ from G*Power's by a few (Departure 11)", {
  # For 95% power at N2/N1 = 2 (p1 = .10, p2 = .25), G*Power gives 123 +
  # 247 = 370, actual power 0.9498668, just under the target. powerkit
  # keeps the groups in the exact ratio and needs power >= .95: 124 + 248
  # = 372 (123 + 246 gives 0.9496). Cohen's h, the earlier default, gave
  # 360, 10 fewer than G*Power.
  spec <- pwr_spec(
    "two_proportions", list(type = "sample_size", power = 0.95),
    options = list(seed = 7, allocation_ratio = 2)
  )
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  expect_identical(as.integer(run_spec(spec)$n_required$n), 372L)
  spec$options$proportions_formula <- "arcsine"
  expect_identical(as.integer(run_spec(spec)$n_required$n), 360L)
  # For 80% power at N2/N1 = 3, G*Power gives 70 + 210 = 280, actual
  # power 0.8003695 (maintainer's screenshot); powerkit agrees.
  spec$options <- list(seed = 7, allocation_ratio = 3)
  spec$goal$power <- 0.8
  expect_identical(as.integer(run_spec(spec)$n_required$n), 280L)
  spec$goal <- list(type = "power", n = 280)
  expect_equal(round(run_spec(spec)$curve$power, 7), 0.8003695)
})

test_that("two proportions in unequal groups: a one-sided test keeps the spec's direction", {
  spec <- pwr_spec(
    "two_proportions", list(type = "power", n = 300),
    options = list(seed = 7, allocation_ratio = 2)
  )
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  spec$target_test$alternative <- "greater"
  toward <- run_spec(spec)$curve$power
  # G*Power's one-tailed power at n1 = 100, n2 = 200, alpha .05
  # (maintainer's screenshot); pwrss gives the same.
  expect_equal(round(toward, 7), 0.9473235)
  spec$target_test$alternative <- "less"
  against <- run_spec(spec)$curve$power
  expect_lt(against, 0.05)
  both <- pwrss::power.z.twoprops(
    prob1 = 0.10, prob2 = 0.25, n2 = 200, n.ratio = 0.5, alpha = 0.10,
    alternative = "two.sided", std.error = "pooled", verbose = FALSE
  )$power
  expect_equal(against + toward, both)
})

test_that("two proportions: a one-sided z test keeps the spec's direction", {
  spec <- pwr_spec("two_proportions", list(type = "power", n = 100))
  spec$population$p1 <- 0.10
  spec$population$p2 <- 0.25
  spec$target_test$alternative <- "greater"
  toward <- run_spec(spec)$curve$power
  expect_equal(toward, stats::power.prop.test(n = 50, p1 = 0.10, p2 = 0.25, alternative = "one.sided")$power)
  # Against the difference, power.prop.test() alone would give the same
  # 0.631 (it uses |p1 - p2|). The power of the lower-tail test is
  # 0.0001115 (the pooled z test's lower tail, 50 per group, alpha .05).
  spec$target_test$alternative <- "less"
  against <- run_spec(spec)$curve$power
  expect_equal(round(against, 7), 0.0001115)
  expect_equal(
    against + toward,
    stats::power.prop.test(n = 50, p1 = 0.10, p2 = 0.25, sig.level = 0.10, strict = TRUE)$power
  )
})

test_that("the proportions formula option is only for two proportions by formula", {
  spec <- pwr_spec("correlation", list(type = "power", n = 80))
  spec$options$proportions_formula <- "arcsine"
  expect_spec_problem(spec, "only applies to the two-proportions test")
  spec <- pwr_spec("two_proportions", list(type = "power", n = 80))
  spec$options$proportions_formula <- "z_test"
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "only applies when power is calculated by formula")
})

test_that("two proportions, equal groups, one tail: power matches G*Power", {
  # G*Power 3.1.9.7, post hoc, one tail, p1 .5, p2 .6, alpha .05, 50 per
  # group: 0.2600887 (maintainer's screenshot, 17 October 2026).
  spec <- pwr_spec(
    "two_proportions", list(type = "power", n = 100),
    options = list(seed = 7)
  )
  spec$population$p1 <- 0.5
  spec$population$p2 <- 0.6
  spec$target_test$alternative <- "greater"
  expect_equal(round(run_spec(spec)$curve$power, 7), 0.2600887)
})
