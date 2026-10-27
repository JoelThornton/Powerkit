# Safeguard power (Perugini, Gallucci & Costantini, 2014): with
# effect_justification > safeguard, validate_spec() replaces the earlier
# study's estimate with the lower bound of a two-sided interval around it
# (the 60% interval for 80% protection), worked out by psych.

safeguard_spec <- function(name, safeguard, type = "pilot_study") {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$effect_justification <- list(type = type, safeguard = safeguard)
  spec$goal <- list(type = "power", n = 60)
  spec
}

test_that("independent groups: the lower end of the 60% interval from psych::cohen.d.ci", {
  spec <- safeguard_spec("independent_t", list(n1 = 20, n2 = 20))
  spec$population$d <- 0.5
  valid <- validate_spec(spec)
  lower <- psych::cohen.d.ci(0.5, n1 = 20, n2 = 20, alpha = 0.4)[1, "lower"]
  expect_equal(valid$population$d, unname(lower))
  expect_equal(valid$effect_justification$safeguard$estimate, 0.5)
  expect_equal(valid$effect_justification$safeguard$protection, 0.8)
  # Validating again changes nothing, so the hash is stable.
  expect_identical(spec_hash(validate_spec(valid)), spec_hash(valid))
  result <- run_spec(spec)
  expect_equal(result$safeguard$lower, unname(lower))
  expect_equal(result$safeguard$conf_level, 0.6)
  expect_equal(result$safeguard$package$name, "psych")
  expect_true("psych" %in% names(result$provenance$packages))
  # The safeguard effect is smaller, so power at the same N is lower.
  plain <- spec
  plain$effect_justification$safeguard <- NULL
  expect_lt(result$curve$power[1], suppressWarnings(run_spec(plain))$curve$power[1])
})

test_that("one sample, paired and correlation use the earlier study's n", {
  one <- safeguard_spec("one_sample_t", list(n = 30))
  one$population$d <- 0.5
  expect_equal(validate_spec(one)$population$d, unname(psych::cohen.d.ci(0.5, n1 = 30, alpha = 0.4)[1, "lower"]))

  paired <- safeguard_spec("paired_t", list(n = 30, protection = 0.95))
  paired$population$dz <- -0.6
  # A negative estimate keeps its sign; the bound is the one nearer zero.
  expect_equal(validate_spec(paired)$population$dz, -unname(psych::cohen.d.ci(0.6, n1 = 30, alpha = 0.1)[1, "lower"]))

  r <- safeguard_spec("correlation", list(n = 50), type = "prior_study")
  r$population$r <- 0.3
  expect_equal(validate_spec(r)$population$r, psych::r.con(0.3, 50, p = 0.6)[1])
})

test_that("plain-words errors when the earlier study can't give a safeguard effect", {
  wide <- safeguard_spec("independent_t", list(n1 = 8, n2 = 8))
  wide$population$d <- 0.2
  expect_error(validate_spec(wide), "includes zero")

  sizes <- safeguard_spec("independent_t", list(n = 40))
  expect_error(validate_spec(sizes), "group sizes")

  other <- safeguard_spec("two_proportions", list(n = 40))
  expect_error(validate_spec(other), "not for this design")

  smallest <- safeguard_spec("one_sample_t", list(n = 30), type = "smallest_effect_of_interest")
  expect_error(validate_spec(smallest))
})

test_that("a previous study needs an adjustment, or safeguard power", {
  spec <- example_spec("one_sample_t")
  spec$effect_justification <- list(type = "prior_study")
  expect_error(validate_spec(spec))
  spec$effect_justification$safeguard <- list(n = 40)
  expect_s3_class(validate_spec(spec), "powerkit_spec")
})

test_that("safeguard_effect() reports the interval it used", {
  out <- safeguard_effect(0.4, "correlation", n = 80, protection = 0.95)
  expect_equal(out$conf_level, 0.9)
  expect_equal(out$lower, psych::r.con(0.4, 80, p = 0.9)[1])
  expect_match(out$function_used, "psych::r.con", fixed = TRUE)
})
