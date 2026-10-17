# Helpers for the run_spec() and backend tests. Simulation runs use few
# replications so the tests stay fast; accuracy is checked by the
# validation tests.

# Run without the "fewer than 1,000 replications" advice, which the small
# simulation runs here would otherwise trigger every time.
run_quietly <- function(spec) {
  withCallingHandlers(
    run_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
}

# An example spec with seed 7 and, for simulation, few replications;
# fields given in ... replace the example's fields whole.
small_run_spec <- function(name, method = NULL, nrep = 100, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  if (identical(method, "simulation")) {
    spec$options$method <- "simulation"
    spec$options$nrep <- nrep
  }
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

# An example spec for a simulation-only design (every design except the
# 2x2 ANOVAs), with seed 7 and few replications; fields given in ...
# replace the example's fields whole.
sim_spec <- function(name, nrep = 100, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7, nrep = nrep)
  # Basic tests default to pwr's exact formula; these specs simulate (Spower).
  if (spec$design == "basic_test") {
    spec$options$method <- "simulation"
  }
  if (spec$design %in% c("mediation", "moderated_mediation")) {
    spec$options$ci_draws <- 100
  }
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

# Remove what mediation backends don't support yet (binary X or W,
# reliability) from an example spec.
continuous_and_reliable <- function(spec) {
  for (role in names(spec$variables)) {
    spec$variables[[role]]$reliability <- NULL
    if (identical(spec$variables[[role]]$type, "binary")) {
      spec$variables[[role]]$type <- "continuous"
      spec$variables[[role]]$levels <- NULL
    }
  }
  spec
}

# validate_spec() without the "fewer than 1,000 replications" advice.
validate_quietly <- function(spec) {
  withCallingHandlers(
    validate_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
}
