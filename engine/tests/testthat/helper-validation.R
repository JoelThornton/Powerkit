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

# Replications per validation run (build guide section 6: "e.g., 5,000").
validation_nrep <- function() 5000L

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
  validate_spec(spec)
}

# Calling the engine ------------------------------------------------------------
#
# Contract assumed for the engine (build guide section 5), to be confirmed
# in build phase 2:
# * run_spec(spec) returns the standard result object;
# * result$curve is a data frame with columns n, power and mcse;
# * result$n_required is a list with n, lower and upper.

engine_function <- function(name) {
  ns <- asNamespace("powerkit")
  if (!exists(name, envir = ns, inherits = FALSE)) {
    stop(
      sprintf(
        paste(
          "powerkit's engine is not implemented yet: %s() is planned for",
          "build phase 2 (2x2 ANOVA) and phase 3 (mediation, interactions,",
          "basic tests). This validation test is expected to fail until then."
        ),
        name
      ),
      call. = FALSE
    )
  }
  get(name, envir = ns)
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
# value lies inside the 95% Monte Carlo interval of powerkit's estimate.

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
expect_power_near <- function(estimate, reference, reference_nrep = NULL, level = 0.95) {
  se <- estimate$mcse
  if (!is.null(reference_nrep)) {
    se <- sqrt(se^2 + reference * (1 - reference) / reference_nrep)
  }
  half_width <- z_for(level) * se
  lower <- estimate$power - half_width
  upper <- estimate$power + half_width
  expect(
    reference >= lower && reference <= upper,
    sprintf(
      "Reference power %.4f is outside the %d%% Monte Carlo interval [%.4f, %.4f] around powerkit's estimate %.4f (MCSE %.4f).",
      reference, round(100 * level), lower, upper, estimate$power, estimate$mcse
    )
  )
  invisible(estimate)
}

# Both values are simulation estimates: their difference must be within
# the combined Monte Carlo error.
expect_power_agrees <- function(estimate, reference, level = 0.95) {
  difference <- estimate$power - reference$power
  half_width <- z_for(level) * sqrt(estimate$mcse^2 + reference$mcse^2)
  expect(
    abs(difference) <= half_width,
    sprintf(
      "powerkit's estimate %.4f differs from the direct backend call %.4f by %.4f; the %d%% Monte Carlo tolerance is %.4f.",
      estimate$power, reference$power, difference, round(100 * level), half_width
    )
  )
  invisible(estimate)
}

# A published required n must lie inside powerkit's uncertainty interval
# for the required n.
expect_n_near <- function(n_required, published_n) {
  expect(
    published_n >= n_required$lower && published_n <= n_required$upper,
    sprintf(
      "Published n = %s is outside powerkit's interval [%s, %s] (estimate %s).",
      published_n, n_required$lower, n_required$upper, n_required$n
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
