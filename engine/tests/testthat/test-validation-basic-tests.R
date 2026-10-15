# Validation: basic tests (one-sample, independent and paired t-tests,
# correlation, two proportions, chi-square test of independence).
# Backend: Spower. Build guide section 6:
#   1. analytic agreement with pwr
#   2. published-example agreement with G*Power 3.1
#   3. direct-call agreement with Spower
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

basic_variables <- function(template, levels_x = 2, levels_y = 2) {
  v <- validation_variable
  categories <- function(prefix, k) as.list(paste(prefix, seq_len(k)))
  switch(
    template,
    one_sample_t = list(Y = v("continuous", "Score")),
    independent_t = list(X = v("binary", "Group"), Y = v("continuous", "Score")),
    paired_t = list(
      X = v("within_factor", "Condition", levels = list("First", "Second")),
      Y = v("continuous", "Score")
    ),
    correlation = list(X = v("continuous", "Predictor"), Y = v("continuous", "Outcome")),
    two_proportions = list(X = v("binary", "Group"), Y = v("binary", "Outcome")),
    chi_square_independence = list(
      X = v("categorical", "Row variable", levels = categories("Row", levels_x)),
      Y = v("categorical", "Column variable", levels = categories("Column", levels_y))
    )
  )
}

basic_test_settings <- list(
  one_sample_t = list(metric = "standardised", effect = "mean", method = "t_test"),
  independent_t = list(metric = "standardised", effect = "mean_difference", method = "student_t"),
  paired_t = list(metric = "standardised", effect = "mean_difference", method = "t_test"),
  correlation = list(metric = "correlation", effect = "correlation", method = "pearson"),
  two_proportions = list(metric = "proportion", effect = "proportion_difference", method = "z_test"),
  chi_square_independence = list(metric = "proportion", effect = "association", method = "pearson_chi_square")
)

# `population` holds the effect size fields only (d, dz, r, p1/p2 or
# probabilities); `n` is the total number of participants.
basic_spec <- function(template, population, n, seed, alpha = 0.05,
                       alternative = "two_sided", options = list()) {
  settings <- basic_test_settings[[template]]
  dims <- if (template == "chi_square_independence") dim(population$probabilities) else c(2, 2)
  validation_spec(
    design = "basic_test",
    template = template,
    variables = basic_variables(template, dims[1], dims[2]),
    population = c(list(metric = settings$metric), population),
    target_test = list(
      effect = settings$effect, method = settings$method,
      alpha = alpha, alternative = alternative
    ),
    seed = seed,
    n = n,
    options = options
  )
}

# 1. Analytic agreement with pwr ------------------------------------------------

test_that("independent t-test: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("independent_t", list(d = 0.5), n = 128, seed = 101)
  reference <- pwr::pwr.t.test(n = 64, d = 0.5, sig.level = 0.05, type = "two.sample")$power
  expect_power_near(engine_power(spec), reference)
})

test_that("independent t-test, one-sided: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("independent_t", list(d = 0.4), n = 160, seed = 102, alternative = "greater")
  reference <- pwr::pwr.t.test(n = 80, d = 0.4, sig.level = 0.05, alternative = "greater")$power
  expect_power_near(engine_power(spec), reference)
})

test_that("independent t-test, unequal groups: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec(
    "independent_t", list(d = 0.45), n = 150, seed = 103,
    options = list(allocation_ratio = 2)
  )
  reference <- pwr::pwr.t2n.test(n1 = 50, n2 = 100, d = 0.45, sig.level = 0.05)$power
  expect_power_near(engine_power(spec), reference)
})

test_that("one-sample t-test: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("one_sample_t", list(d = 0.3), n = 90, seed = 104)
  reference <- pwr::pwr.t.test(n = 90, d = 0.3, sig.level = 0.05, type = "one.sample")$power
  expect_power_near(engine_power(spec), reference)
})

test_that("paired t-test: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("paired_t", list(dz = 0.4), n = 52, seed = 105)
  reference <- pwr::pwr.t.test(n = 52, d = 0.4, sig.level = 0.05, type = "paired")$power
  expect_power_near(engine_power(spec), reference)
})

test_that("correlation at alpha = .01: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("correlation", list(r = 0.3), n = 150, seed = 106, alpha = 0.01)
  # pwr.r.test uses Fisher's z approximation; with n = 150 it is close to exact.
  reference <- pwr::pwr.r.test(n = 150, r = 0.3, sig.level = 0.01)$power
  expect_power_near(engine_power(spec), reference)
})

test_that("two proportions: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  spec <- basic_spec("two_proportions", list(p1 = 0.5, p2 = 0.65), n = 340, seed = 107)
  # pwr.2p.test uses the arcsine (Cohen's h) approximation.
  reference <- pwr::pwr.2p.test(h = pwr::ES.h(0.65, 0.5), n = 170, sig.level = 0.05)$power
  expect_power_near(engine_power(spec), reference)
})

test_that("chi-square test of independence: power matches pwr (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  probabilities <- matrix(c(0.20, 0.15, 0.10, 0.15, 0.25, 0.15), nrow = 3, byrow = TRUE)
  spec <- basic_spec("chi_square_independence", list(probabilities = probabilities), n = 200, seed = 108)
  reference <- pwr::pwr.chisq.test(
    w = pwr::ES.w2(probabilities), N = 200, df = 2, sig.level = 0.05
  )$power
  expect_power_near(engine_power(spec), reference)
})

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# Each test runs powerkit at the published total sample size and compares
# with the published "actual power" at that sample size.

test_that("independent t-test: matches the Faul et al. (2007) G*Power example (published)", {
  skip_unless_full_validation()
  # Source: Faul, Erdfelder, Lang & Buchner (2007), "G*Power 3: A flexible
  #   statistical power analysis program for the social, behavioral, and
  #   biomedical sciences", Behavior Research Methods, 39(2), 175-191:
  #   the worked example on p. 177 and Figure 1 (p. 178). Transcribe the
  #   inputs and the Output block.
  # Not the G*Power 3.1 manual: its Examples section for this test
  #   (section 21.3, June 2023 version) is empty.
  d <- TODO_PUBLISHED_VALUE # Effect size d
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  allocation_ratio <- TODO_PUBLISHED_VALUE # Allocation ratio N2/N1
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(d, alpha, tails, allocation_ratio, total_n, actual_power)

  spec <- basic_spec(
    "independent_t", list(d = d), n = total_n, seed = 201, alpha = alpha,
    alternative = if (tails == 1) "greater" else "two_sided",
    options = list(allocation_ratio = allocation_ratio)
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("paired t-test: matches G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 19.3
  #   ("t test: Means - Difference between two dependent means (matched
  #   pairs)"), p. 48: the post hoc analysis, whose output gives
  #   "Power (1-beta err prob)". Use the example's effect size dz (if the
  #   manual derives dz from means, SDs and a correlation, transcribe the
  #   dz it reports).
  dz <- TODO_PUBLISHED_VALUE # Effect size dz
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE
  total_n <- TODO_PUBLISHED_VALUE # Input: Total sample size (pairs)
  actual_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta err prob)
  skip_if_todo(dz, alpha, tails, total_n, actual_power)

  spec <- basic_spec(
    "paired_t", list(dz = dz), n = total_n, seed = 202, alpha = alpha,
    alternative = if (tails == 1) "greater" else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("correlation: matches the Faul et al. (2007) exact bivariate-normal example (published)", {
  skip_unless_full_validation()
  # Source: Faul, Erdfelder, Lang & Buchner (2007), Behavior Research
  #   Methods, 39(2), 175-191, footnote 4: the exact test of a bivariate
  #   normal correlation, two-tailed, H0: rho = 0.
  # Not the G*Power 3.1 manual, whose example tests against rho = 0.60
  #   (powerkit tests against 0), and not Faul, Erdfelder, Buchner & Lang
  #   (2009), Behavior Research Methods, 41(4), 1149-1160, which has no
  #   plain bivariate normal example.
  # The power is reported to two decimals: transcribe both decimals, as a
  #   string if the last one is 0 (e.g. "0.80"), so the rounding allowance
  #   (half a unit in the second decimal) is right.
  r <- TODO_PUBLISHED_VALUE # Correlation rho H1
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(r, alpha, tails, total_n, actual_power)

  spec <- basic_spec(
    "correlation", list(r = r), n = total_n, seed = 203, alpha = alpha,
    alternative = if (tails == 1) (if (r > 0) "greater" else "less") else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("two proportions: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: none yet; left TODO. There is no worked example for the z test
  #   of two independent proportions in the G*Power 3.1 manual (June 2023
  #   version) or in Faul et al. (2007, 2009).
  # Candidate: Cohen (1988), Statistical power analysis for the behavioral
  #   sciences (2nd ed.), chapter 6. Check that its test matches powerkit's
  #   (z test, no continuity correction) before using it.
  p1 <- TODO_PUBLISHED_VALUE # Proportion p1
  p2 <- TODO_PUBLISHED_VALUE # Proportion p2
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size (equal groups)
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(p1, p2, alpha, tails, total_n, actual_power)

  spec <- basic_spec(
    "two_proportions", list(p1 = p1, p2 = p2), n = total_n, seed = 204, alpha = alpha,
    alternative = if (tails == 1) (if (p2 > p1) "greater" else "less") else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

# 3. Direct-call agreement with Spower -----------------------------------------------

test_that("independent t-test: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- basic_spec("independent_t", list(d = 0.35), n = 200, seed = 301)
  direct <- direct_spower_t_test(
    type = "two.sample", n = 100, d = 0.35, alpha = 0.05,
    nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

test_that("paired t-test: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- basic_spec("paired_t", list(dz = 0.3), n = 70, seed = 302)
  direct <- direct_spower_t_test(
    type = "paired", n = 70, d = 0.3, alpha = 0.05,
    nrep = validation_nrep(), seed = 302
  )
  expect_power_agrees(engine_power(spec), direct)
})

test_that("correlation: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- basic_spec("correlation", list(r = 0.25), n = 100, seed = 303)
  direct <- direct_spower_correlation(n = 100, r = 0.25, alpha = 0.05, nrep = validation_nrep(), seed = 303)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("two proportions: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- basic_spec("two_proportions", list(p1 = 0.3, p2 = 0.45), n = 300, seed = 304)
  direct <- direct_spower_two_proportions(
    n = 150, p1 = 0.3, p2 = 0.45, alpha = 0.05,
    nrep = validation_nrep(), seed = 304
  )
  expect_power_agrees(engine_power(spec), direct)
})

test_that("chi-square test of independence: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  probabilities <- matrix(c(0.20, 0.15, 0.10, 0.15, 0.25, 0.15), nrow = 3, byrow = TRUE)
  spec <- basic_spec("chi_square_independence", list(probabilities = probabilities), n = 150, seed = 305)
  direct <- direct_spower_chisq(
    n = 150, probabilities = probabilities, alpha = 0.05,
    nrep = validation_nrep(), seed = 305
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error -----------------------------------------------------------------

test_that("independent t-test: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec("independent_t", list(d = 0), n = 100, seed = 401)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("independent t-test, unequal groups (Welch): Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec(
    "independent_t", list(d = 0), n = 90, seed = 402,
    options = list(allocation_ratio = 2)
  )
  spec$target_test$method <- "welch_t"
  expect_type1_near(engine_power(validate_spec(spec)), alpha = 0.05)
})

test_that("one-sample t-test: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec("one_sample_t", list(d = 0), n = 40, seed = 403)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("paired t-test: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec("paired_t", list(dz = 0), n = 40, seed = 404)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("correlation: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec("correlation", list(r = 0), n = 60, seed = 405)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("two proportions: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- basic_spec("two_proportions", list(p1 = 0.4, p2 = 0.4), n = 400, seed = 406)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("chi-square test of independence: Type I error is near alpha", {
  skip_unless_full_validation()
  independent <- outer(c(0.5, 0.3, 0.2), c(0.6, 0.4))
  spec <- basic_spec("chi_square_independence", list(probabilities = independent), n = 300, seed = 407)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
