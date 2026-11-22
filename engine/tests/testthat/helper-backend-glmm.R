# The spec the repeated-measures count, yes/no and ordered-outcome tests
# (test-backend-glmm*.R) start from: mixed_model / repeated_glmm, E75.

glmm_spec <- function(outcome = "poisson", x = "within_factor", levels = c("Usual", "With the programme"),
                      values = NULL, measurements = 3L, method = "wald", n = 40L, nrep = 100L) {
  spec <- example_spec("repeated_glmm")
  spec$variables$X$type <- x
  spec$variables$X$levels <- as.list(levels)
  pop <- list(sd_person = 0.5, measurements = measurements)
  if (outcome == "ordinal") {
    spec$variables$Y <- list(type = "categorical", label = "Mood", levels = list("Low", "Middle", "High", "Very high"))
    pop <- c(list(metric = "proportion", category_probabilities = list(0.2, 0.3, 0.3, 0.2),
      odds_ratios = as.list(values %||% c(1, seq(1.8, 1.4, length.out = length(levels) - 1)))), pop)
  } else if (outcome == "yes_no") {
    spec$variables$Y <- list(type = "binary", label = "Late")
    pop <- c(list(metric = "probability", probabilities = as.list(values %||% seq(0.3, 0.2, length.out = length(levels)))), pop)
  } else {
    pop <- c(list(metric = "rate", rates = as.list(values %||% seq(2, 1.6, length.out = length(levels)))), pop)
    if (outcome == "negative_binomial") pop$dispersion <- 0.4
  }
  spec$population <- pop
  spec$target_test <- list(effect = "condition", method = method, alpha = 0.05)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 5L)
  spec
}
