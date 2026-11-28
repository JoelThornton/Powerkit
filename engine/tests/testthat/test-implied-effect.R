# implied_effect_size(): the effect size the input screens show beside
# means and an SD.

levels_of <- function(k) as.list(letters[seq_len(k)])

test_that("a one-way ANOVA's means and SD give the population Cohen's f and partial eta-squared", {
  spec <- list(design = "factorial_anova", template = "oneway_between",
    variables = list(A = list(type = "between_factor", levels = levels_of(3))),
    population = list(metric = "raw", means = list(10, 11, 13), sd = 6))
  got <- implied_effect_size(spec)
  # An independent route to the same population values: pwrss's
  # means.to.etasq() with equal groups.
  check <- pwrss::means.to.etasq(c(10, 11, 13), rep(6, 3), rep(50, 3), verbose = 0)
  expect_equal(got$name, "Cohen's f")
  expect_equal(got$value, check$f, tolerance = 1e-3)
  expect_equal(got$eta_squared, check$eta.squared, tolerance = 1e-3)
  # By definition: the SD of the means (dividing by the number of groups) over the SD.
  m <- c(10, 11, 13)
  expect_equal(got$value, sqrt(mean((m - mean(m))^2)) / 6, tolerance = 1e-3)
})

test_that("a 2 x 2 interaction's Cohen's f follows its definition", {
  spec <- list(design = "factorial_anova", template = "2x2_between",
    variables = list(A = list(levels = levels_of(2)), B = list(levels = levels_of(2))),
    population = list(metric = "standardised", means = list(list(0, 0.5), list(0, 0)), sd = 1),
    target_test = list(effect = "interaction"))
  # The interaction's effects in a 2 x 2 design are +/- (a1b1 - a1b2 - a2b1 + a2b2) / 4.
  expect_equal(implied_effect_size(spec)$value, 0.5 / 4, tolerance = 1e-3)
})

test_that("an ANCOVA's effect is the adjusted one", {
  spec <- list(design = "factorial_anova", template = "oneway_ancova",
    variables = list(A = list(levels = levels_of(3))),
    population = list(metric = "raw", means = list(10, 11, 13), sd = 6, r2_covariates = 0.36, covariates = 1),
    target_test = list(effect = "main_effect_A"))
  got <- implied_effect_size(spec)
  check <- pwrss::means.to.etasq(c(10, 11, 13), rep(6, 3), rep(50, 3), k.covariates = 1, r.squared = 0.36, verbose = 0)
  expect_equal(got$value, check$f, tolerance = 1e-6)
  expect_true(got$adjusted)
})

test_that("the t-tests' means and SD give d, and partial eta-squared gives f", {
  spec <- list(design = "basic_test", template = "independent_t",
    population = list(metric = "raw", raw = list(mean_1 = 10, mean_2 = 13, sd = 6)))
  expect_equal(implied_effect_size(spec)[c("name", "value")], list(name = "Cohen's d", value = 0.5))
  eta <- implied_effect_size(list(design = "factorial_anova", template = "oneway_between",
    population = list(metric = "eta_squared", eta_squared = 0.06)))
  expect_equal(eta$value, sqrt(0.06 / 0.94))
})

test_that("incomplete or unsuitable inputs give NULL rather than an error", {
  base <- list(design = "factorial_anova", template = "oneway_between", variables = list(A = list(levels = levels_of(3))))
  expect_null(implied_effect_size(c(base, list(population = list(metric = "raw", means = list(10, 11), sd = 6)))))
  expect_null(implied_effect_size(c(base, list(population = list(metric = "raw", means = list(10, 11, 13))))))
  expect_null(implied_effect_size(c(base, list(population = list(metric = "raw", means = list(10, 11, 13), sd = -1)))))
  expect_null(implied_effect_size(list(design = "basic_test", template = "correlation", population = list(r = 0.3))))
  expect_null(implied_effect_size(list()))
})
