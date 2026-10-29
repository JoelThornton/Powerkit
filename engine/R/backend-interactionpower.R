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

# Three-way interactions (Y ~ X + W + Z + XW + XZ + WZ + XWZ), by
# InteractionPoweR::power_interaction_3way_r2(): analytic power from the
# change in R-squared when XWZ is added, valid for continuous, normally
# distributed variables (its help). InteractionPoweR has no simulation for
# three-way models, so this is the fixed-model formula alone, which gives
# slightly higher power than simulating with random predictors (as for
# two-way models: docs/conventions.md, Known difference 1).
#
# The spec uses InteractionPoweR's own parametrisation: X is x1, W is x2,
# Z is x3; correlations among the true scores, with the three-way effect
# as the standardised coefficient of x1x2x3 (b.x1x2x3).
interactionpower_3way_backend <- function(spec) {
  inputs <- interactionpower_3way_inputs(spec)
  power_at <- function(n) interactionpower_3way_power(spec, inputs, n)$pwr
  list(
    name = "InteractionPoweR",
    packages = "InteractionPoweR",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "InteractionPoweR::power_interaction_3way_r2"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() interactionpower_3way_check_run(spec, inputs)
  )
}

interactionpower_3way_inputs <- function(spec) {
  pop <- spec$population
  reliability <- function(role) spec$variables[[role]]$reliability %||% 1
  list(
    b.x1x2x3 = pop$b_XWZ,
    r.x1.y = pop$r_X_Y,
    r.x2.y = pop$r_W_Y,
    r.x3.y = pop$r_Z_Y,
    r.x1x2.y = pop$r_XW_Y,
    r.x1x3.y = pop$r_XZ_Y,
    r.x2x3.y = pop$r_WZ_Y,
    r.x1.x2 = pop$r_X_W,
    r.x1.x3 = pop$r_X_Z,
    r.x2.x3 = pop$r_W_Z,
    rel.x1 = reliability("X"),
    rel.x2 = reliability("W"),
    rel.x3 = reliability("Z"),
    rel.y = reliability("Y"),
    alpha = spec$target_test$alpha
  )
}

# InteractionPoweR returns no rows (with a warning) when the correlations
# can't hold together; that is refused here in plain English.
interactionpower_3way_power <- function(spec, inputs, n, detailed_results = FALSE) {
  out <- call_backend("InteractionPoweR", quietly(do.call(
    InteractionPoweR::power_interaction_3way_r2,
    c(list(N = n, detailed_results = detailed_results), inputs)
  )))
  if (!is.data.frame(out) || nrow(out) == 0) {
    abort_run(sprintf(
      paste0(
        "These correlations and the three-way effect are impossible together: ",
        "InteractionPoweR can't build a valid correlation matrix for %s, %s, %s, ",
        "their products and %s from them. Make the three-way effect or the ",
        "correlations with %s smaller, or change the correlations among the predictors."
      ),
      var_label(spec, "X"), var_label(spec, "W"), var_label(spec, "Z"),
      var_label(spec, "Y"), var_label(spec, "Y")
    ))
  }
  out
}

# Check run: there is no simulated data, so the check confirms that
# InteractionPoweR received the correlations and the three-way coefficient
# the spec gives (they come back in its detailed results).
interactionpower_3way_check_run <- function(spec, inputs) {
  out <- interactionpower_3way_power(spec, inputs, 1000, detailed_results = TRUE)
  received <- c(
    b_XWZ = "b.x1x2x3", r_X_Y = "r.y.x1", r_W_Y = "r.y.x2", r_Z_Y = "r.y.x3",
    r_XW_Y = "r.y.x1x2", r_XZ_Y = "r.y.x1x3", r_WZ_Y = "r.y.x2x3",
    r_X_W = "r.x1.x2", r_X_Z = "r.x1.x3", r_W_Z = "r.x2.x3"
  )
  specified <- vapply(names(received), function(k) as.numeric(spec$population[[k]]), numeric(1))
  recovered <- vapply(received, function(k) as.numeric(out[[k]][1]), numeric(1))
  data.frame(
    parameter = names(received),
    specified = unname(specified),
    recovered = unname(recovered),
    ok = abs(unname(recovered) - unname(specified)) < 1e-12
  )
}
