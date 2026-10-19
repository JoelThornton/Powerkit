# Backend adapter: two-way interactions in regression (Y ~ X + W + XW),
# with optional measurement error, via InteractionPoweR.
#
# Power is simulated with InteractionPoweR::power_interaction(), which
# generates data with the specified correlations and reliabilities, forms
# the product of the observed X and W, and tests its coefficient with OLS.
# InteractionPoweR's analytic power_interaction_r2() is used only to bracket
# the required n before simulating, not as the reported power (see
# docs/decisions.md).

interactionpower_backend <- function(spec, seed = NULL) {
  check_interaction_supported(spec)
  inputs <- interactionpower_inputs(spec)
  list(
    name = "InteractionPoweR",
    packages = "InteractionPoweR",
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "InteractionPoweR::power_interaction", analytic = "InteractionPoweR::power_interaction_r2"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    bracket_power = function(n) interactionpower_analytic(inputs, n)$pwr,
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        interactionpower_rejections(inputs, n, k, chunk_seed)
      })
    },
    # The smallest detectable effect uses the fixed-model formula
    # (power_interaction_r2()), not simulation: see interactionpower_sensitivity().
    sensitivity = function(n, power) interactionpower_sensitivity(inputs, n, power),
    sensitivity_method = "analytic",
    check_run = function() interactionpower_check_run(spec, inputs, seed)
  )
}

# Binary X or W would use InteractionPoweR's discretised variables (k.x1,
# k.x2 = 2), whose correlations are adjusted so the observed binary data
# have the specified correlations. That is a methodological choice still to
# be made (docs/decisions.md, open questions; docs/build-guide.md, section
# 8), so it isn't offered yet. Treating a binary variable as continuous
# isn't suggested: InteractionPoweR's analytic power is documented as valid
# only for continuous, normally distributed variables. A 2x2 ANOVA is
# suggested only when both X and W are binary.
check_interaction_supported <- function(spec) {
  binary <- vapply(c("X", "W"), function(v) identical(spec$variables[[v]]$type, "binary"), logical(1))
  if (any(binary)) {
    labels <- quote_list(vapply(names(binary)[binary], function(v) var_label(spec, v), character(1)), "and")
    abort_not_available(paste0(
      sprintf(
        "Regression interactions with a yes/no (binary) predictor or moderator aren't available yet (%s %s yes/no). Treating %s as continuous may give an inaccurate power estimate.",
        labels, if (sum(binary) == 1) "is" else "are", if (sum(binary) == 1) "it" else "them"
      ),
      if (all(binary)) " Because both are yes/no, you can use a 2x2 ANOVA design instead." else ""
    ))
  }
  invisible(TRUE)
}

# The spec uses InteractionPoweR's own parametrisation, so translation is a
# renaming: X is x1, W (the moderator) is x2.
interactionpower_inputs <- function(spec) {
  pop <- spec$population
  reliability <- function(role) spec$variables[[role]]$reliability %||% 1
  list(
    r.x1.y = pop$r_X_Y,
    r.x2.y = pop$r_W_Y,
    r.x1x2.y = pop$r_XW_Y,
    r.x1.x2 = pop$r_X_W,
    rel.x1 = reliability("X"),
    rel.x2 = reliability("W"),
    rel.y = reliability("Y"),
    alpha = spec$target_test$alpha
  )
}

interactionpower_analytic <- function(inputs, n, detailed_results = FALSE) {
  call_backend("InteractionPoweR", quietly(do.call(
    InteractionPoweR::power_interaction_r2,
    c(list(N = n, detailed_results = detailed_results), inputs)
  )))
}

# The smallest detectable effect: the correlation of the interaction XW
# with Y, the other correlations and the reliabilities kept as entered,
# searched with InteractionPoweR's fixed-model power_interaction_r2() (as
# search_n() searches n). Fixed-model power is slightly higher than the
# simulated power powerkit reports for n (conventions.md, Known
# difference 1), so this effect is slightly smaller than simulation would
# give; the app says so. With no interaction correlation given (zero), the
# result is positive.
interactionpower_sensitivity <- function(inputs, n, target) {
  direction <- if (inputs$r.x1x2.y < 0) -1 else 1
  power_at <- function(r) {
    trial <- inputs
    trial$r.x1x2.y <- direction * r
    # Correlations that are impossible together have no power.
    tryCatch(interactionpower_analytic(trial, n)$pwr[1], error = function(e) NA_real_)
  }
  lower <- 0
  upper <- NA_real_
  for (r in seq(0.01, 0.99, by = 0.01)) {
    p <- power_at(r)
    if (is.na(p)) break
    if (p >= target) {
      upper <- r
      break
    }
    lower <- r
  }
  if (is.na(upper)) {
    abort_run(paste0(
      "No correlation of the interaction with Y reaches the target power at this n ",
      "with the other correlations as given. Try a larger n or check the correlations."
    ))
  }
  r <- stats::uniroot(function(r) power_at(r) - target, lower = lower, upper = upper, tol = 1e-10)$root
  list(
    effect = direction * r, effect_name = "r_XW_Y",
    effect_description = "correlation of the interaction XW with Y (the other correlations kept as entered), by the fixed-model formula",
    power = power_at(r),
    approximation = TRUE
  )
}

# Rejections in `nrep` replications at n. power_interaction() has no seed
# argument and uses R's random-number generator when run on one core
# (cl = NULL), so it is run under the chunk's seed.
interactionpower_rejections <- function(inputs, n, nrep, seed) {
  result <- call_backend("InteractionPoweR", with_seed(seed, quietly(do.call(
    InteractionPoweR::power_interaction,
    c(list(n.iter = as.integer(nrep), N = n), inputs)
  ))))
  round(result$pwr[1] * nrep)
}

# Check run: one large data set from InteractionPoweR's generator.
# (a) With perfect reliability, the four correlations must match the spec:
#     this checks the renaming above.
# (b) With the specified reliabilities, the observed correlations must match
#     the attenuated values InteractionPoweR itself reports
#     (power_interaction_r2(detailed_results = TRUE)): this checks the
#     reliabilities reach the generator.
# Correlations are compared on Fisher's z scale (SE 1 / sqrt(n - 3)).
interactionpower_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  generate <- function(rel) {
    args <- inputs[c("r.x1.y", "r.x2.y", "r.x1x2.y", "r.x1.x2")]
    if (rel) args <- c(args, inputs[c("rel.x1", "rel.x2", "rel.y")])
    call_backend("InteractionPoweR", with_seed(seed, quietly(do.call(
      InteractionPoweR::generate_interaction, c(list(N = n), args)
    ))))
  }
  correlations <- function(data) {
    c(
      stats::cor(data$x1, data$y), stats::cor(data$x2, data$y),
      stats::cor(data$x1x2, data$y), stats::cor(data$x1, data$x2)
    )
  }
  names <- c("r_X_Y", "r_W_Y", "r_XW_Y", "r_X_W")
  compare <- function(parameter, specified, recovered) {
    data.frame(
      parameter = parameter, specified = specified, recovered = recovered,
      ok = abs(atanh(recovered) - atanh(specified)) <= 5 / sqrt(n - 3)
    )
  }
  true_scores <- compare(
    names,
    unlist(spec$population[names], use.names = FALSE),
    correlations(generate(rel = FALSE))
  )
  if (all(unlist(inputs[c("rel.x1", "rel.x2", "rel.y")]) == 1)) {
    return(true_scores)
  }
  expected <- interactionpower_analytic(inputs, n, detailed_results = TRUE)
  rbind(
    true_scores,
    compare(
      paste(names, "observed (with measurement error)"),
      unlist(expected[1, c("obs.r.x1.y", "obs.r.x2.y", "obs.r.x1x2.y", "obs.r.x1.x2")], use.names = FALSE),
      correlations(generate(rel = TRUE))
    )
  )
}
