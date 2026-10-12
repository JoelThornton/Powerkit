# Spec builders shared by the mediation and moderated-mediation validation
# tests. `paths` is a named list of standardised paths, e.g.
# list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1).

mediation_spec <- function(template, mediators, paths, path, seed, n = NULL,
                           residual_correlations = NULL,
                           method = "monte_carlo_ci", alpha = 0.05,
                           target_power = NULL) {
  variables <- c(
    list(X = validation_variable("continuous", "Predictor")),
    stats::setNames(
      lapply(seq_along(mediators), function(i) {
        validation_variable("continuous", paste("Mediator", mediators[i]))
      }),
      mediators
    ),
    list(Y = validation_variable("continuous", "Outcome"))
  )
  population <- list(metric = "standardised", paths = paths)
  if (!is.null(residual_correlations)) {
    population$residual_correlations <- residual_correlations
  }
  validation_spec(
    design = "mediation",
    template = template,
    variables = variables,
    population = population,
    target_test = list(effect = "indirect_effect", path = path, method = method, alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = list(ci_draws = validation_ci_draws())
  )
}

moderated_mediation_spec <- function(template, paths, seed, n = NULL,
                                     r_x_w = NULL, method = "monte_carlo_ci",
                                     alpha = 0.05, target_power = NULL) {
  population <- list(metric = "standardised", paths = paths)
  if (!is.null(r_x_w)) {
    population$correlations <- list("X<->W" = r_x_w)
  }
  validation_spec(
    design = "moderated_mediation",
    template = template,
    variables = list(
      X = validation_variable("continuous", "Predictor"),
      W = validation_variable("continuous", "Moderator"),
      M = validation_variable("continuous", "Mediator"),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = population,
    target_test = list(effect = "index_of_moderated_mediation", method = method, alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = list(ci_draws = validation_ci_draws())
  )
}
