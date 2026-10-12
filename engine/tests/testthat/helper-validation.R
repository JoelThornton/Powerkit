# Helpers for the validation tests (test-validation-*.R).
#
# Validation tests check powerkit against published examples, analytic
# formulas and direct calls to the backend packages, plus a Type I error
# check (build guide, section 6). They use many replications, so they are
# skipped unless the environment variable POWERKIT_FULL_VALIDATION is "true"
# (set by the nightly CI job).
#
# Published numbers are transcribed by the maintainer. Until a number is
# filled in it is TODO_PUBLISHED_VALUE and the test that needs it is skipped.
#
# Everything that depends on how the engine or a backend package works
# lives in helper files (this one and helper-direct-calls.R), so that the
# test-validation-* files only hold designs and expected values.

# Placeholder for a number still to be transcribed from a published source.
TODO_PUBLISHED_VALUE <- structure(NA_real_, class = "powerkit_todo")

is_todo <- function(x) {
  inherits(x, "powerkit_todo") ||
    (is.list(x) && any(vapply(x, is_todo, logical(1))))
}

full_validation_requested <- function() {
  identical(tolower(Sys.getenv("POWERKIT_FULL_VALIDATION")), "true")
}

skip_unless_full_validation <- function() {
  skip_if_not(
    full_validation_requested(),
    "high-replication validation test; set POWERKIT_FULL_VALIDATION=true to run"
  )
}

skip_if_todo <- function(...) {
  if (any(vapply(list(...), is_todo, logical(1)))) {
    skip("published benchmark not transcribed yet (TODO_PUBLISHED_VALUE); see the source comment in this test")
  }
}

# Replications per validation run. Chosen so that, at the 99.9% tolerance,
# a real error of .03 in power still fails (build guide section 6). At the
# worst case (power near .5) with 10,000 replications:
# * against a published or exact value, the interval half-width is
#   3.29 * 0.005 = .016, so a .03 error fails about 99.7% of the time;
# * between two simulations (direct-call tests), it is
#   3.29 * 0.0071 = .023, so a .03 error fails about 83% of the time.
# With 5,000 replications the direct-call half-width would be .033, so a
# .03 error could pass.
validation_nrep <- function() 10000L

# Monte Carlo draws per confidence interval for indirect effects.
validation_ci_draws <- function() 1000L

# Building specs --------------------------------------------------------------

validation_variable <- function(type, label, ...) {
  list(type = type, label = label, ...)
}

# A complete, validated spec for a validation run, with the validation
# replication count and the given seed. The goal is power at a fixed `n`,
# or, if `target_power` is given, the sample size for that power.
validation_spec <- function(design, template, variables, population,
                            target_test, seed, n = NULL, target_power = NULL,
                            options = list()) {
  goal <- if (is.null(target_power)) {
    list(type = "power", n = n)
  } else {
    list(type = "sample_size", power = target_power)
  }
  spec <- list(
    spec_version = "0.1",
    design = design,
    template = template,
    variables = variables,
    population = population,
    effect_justification = list(
      type = "smallest_effect_of_interest",
      source = "powerkit validation benchmark (not a real study)"
    ),
    target_test = target_test,
    goal = goal,
    options = utils::modifyList(
      list(nrep = validation_nrep(), seed = seed),
      options
    )
  )
  spec <- validate_spec(spec)
  skip_if_no_backend(spec)
  spec
}

# Designs whose backend isn't built yet are skipped with a clear message,
# so that a red nightly run means a real problem.
skip_if_no_backend <- function(spec) {
  tryCatch(
    route_spec(spec),
    powerkit_not_available = function(e) {
      skip(paste("backend not built yet:", conditionMessage(e)))
    }
  )
  invisible(TRUE)
}

# Calling the engine ------------------------------------------------------------
#
# The engine's result object (build guide section 5):
# * run_spec(spec) returns one result object for every goal type;
# * result$curve is a data frame with columns n, power and mcse (a single
#   row for a fixed-n goal);
# * result$n_required is a list with n, lower and upper (NA unless the goal
#   is sample_size).

engine_function <- function(name) {
  get(name, envir = asNamespace("powerkit"))
}

# Estimated power (and its Monte Carlo SE) at the spec's fixed n.
engine_power <- function(spec) {
  result <- engine_function("run_spec")(spec)
  at_n <- result$curve[result$curve$n == spec$goal$n, , drop = FALSE]
  if (nrow(at_n) != 1) {
    stop("The engine's power curve has no single row for n = ", spec$goal$n, call. = FALSE)
  }
  list(power = at_n$power, mcse = at_n$mcse)
}

# Estimated required n (with its uncertainty interval) for a spec whose
# goal is a sample size.
engine_n_required <- function(spec) {
  engine_function("run_spec")(spec)$n_required
}

# Expectations --------------------------------------------------------------------
#
# Tolerance rule (build guide section 6): a test passes if the reference
# value lies inside the 99.9% Monte Carlo interval of powerkit's estimate.
# (99.9% rather than 95% so that a correct engine rarely fails one of the
# many validation tests by chance.)

# An estimate from a simulation with `nrep` replications.
binomial_estimate <- function(power, nrep) {
  list(power = power, mcse = sqrt(power * (1 - power) / nrep))
}

# A value with no Monte Carlo error (analytic or exact).
exact_estimate <- function(power) {
  list(power = power, mcse = 0)
}

z_for <- function(level) stats::qnorm(1 - (1 - level) / 2)

# `reference` is a published or analytic power value. If it came from a
# simulation itself, give its replication count as `reference_nrep` so its
# own Monte Carlo error is allowed for.
#
# Published values are rounded (e.g. 0.8816 for 88.16%). A value given to d
# decimal places is treated as exact to +/- half a unit in its last place,
# added to the Monte Carlo half-width. This matters for exact results, whose
# Monte Carlo error is 0.
expect_power_near <- function(estimate, reference, reference_nrep = NULL, level = 0.999) {
  se <- estimate$mcse
  if (!is.null(reference_nrep)) {
    se <- sqrt(se^2 + reference * (1 - reference) / reference_nrep)
  }
  half_width <- z_for(level) * se + rounding_allowance(reference)
  lower <- estimate$power - half_width
  upper <- estimate$power + half_width
  expect(
    reference >= lower && reference <= upper,
    sprintf(
      "Reference power %.4f is outside the interval [%.4f, %.4f] around powerkit's estimate %.4f (MCSE %.4f, %g%% Monte Carlo interval plus rounding of the reference).",
      reference, lower, upper, estimate$power, estimate$mcse, 100 * level
    )
  )
  invisible(estimate)
}

# Half a unit in the last decimal place of `x` as written (0.8816 -> 0.00005).
rounding_allowance <- function(x) {
  digits <- format(x, digits = 15, scientific = FALSE)
  decimals <- if (grepl(".", digits, fixed = TRUE)) nchar(sub(".*\\.", "", digits)) else 0
  0.5 * 10^-decimals
}

# Both values are simulation estimates: their difference must be within
# the combined Monte Carlo error.
expect_power_agrees <- function(estimate, reference, level = 0.999) {
  difference <- estimate$power - reference$power
  half_width <- z_for(level) * sqrt(estimate$mcse^2 + reference$mcse^2)
  expect(
    abs(difference) <= half_width,
    sprintf(
      "powerkit's estimate %.4f differs from the direct backend call %.4f by %.4f; the %g%% Monte Carlo tolerance is %.4f.",
      estimate$power, reference$power, difference, 100 * level, half_width
    )
  )
  invisible(estimate)
}

# A published required n must lie inside powerkit's uncertainty interval
# for the required n.
#
# z-approximation allowance (maintainer's decision, docs/decisions.md):
# sources that compute n with the normal (z) approximation always
# underestimate the exact F-test n. For tests marked
# `z_approximation = TRUE` only, the published n may also be up to 3% below
# powerkit's interval.
expect_n_near <- function(n_required, published_n, z_approximation = FALSE) {
  lower <- n_required$lower
  if (z_approximation) {
    lower <- lower * (1 - 0.03)
  }
  expect(
    published_n >= lower && published_n <= n_required$upper,
    sprintf(
      "Published n = %s is outside powerkit's interval [%s, %s] (estimate %s)%s.",
      published_n, n_required$lower, n_required$upper, n_required$n,
      if (z_approximation) ", even allowing 3% for the z-approximation" else ""
    )
  )
  invisible(n_required)
}

# Rejection rate with no true effect must sit near alpha: between 0.8 and
# 1.2 times alpha (build guide section 6: ".04 to .06 at alpha = .05").
expect_type1_near <- function(estimate, alpha) {
  lower <- 0.8 * alpha
  upper <- 1.2 * alpha
  expect(
    estimate$power >= lower && estimate$power <= upper,
    sprintf(
      "Type I error rate %.4f is outside [%.3f, %.3f] for alpha = %s.",
      estimate$power, lower, upper, alpha
    )
  )
  invisible(estimate)
}
