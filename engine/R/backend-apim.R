# Backend adapter: dyadic data, the actor-partner interdependence model
# (dyadic / apim, E44), via power4mome.
#
# Each member's X predicts their own Y (actor) and their partner's Y
# (partner); the members' X are correlated (r_x) and so are their Y
# residuals (r_y). All variables are standardised. power4mome generates
# the data from the population model and fits the APIM with lavaan in each
# replication; the chosen effect is tested by test_parameters(), lavaan's
# Wald z test. With indistinguishable members the actor effects are
# constrained equal, and so are the partner effects, as the model for
# exchangeable dyads is fitted; the population then has the same actor
# and partner effect for both members.

apim_paths <- function(spec) {
  pop <- spec$population
  if (isTRUE(pop$distinguishable)) {
    c(a1 = pop$actor_1, p21 = pop$partner_21, a2 = pop$actor_2, p12 = pop$partner_12)
  } else {
    c(a1 = pop$actor, p21 = pop$partner, a2 = pop$actor, p12 = pop$partner)
  }
}

# The share of each Y's variance the members' X explain (all standardised):
# for Y1 = a1 X1 + p21 X2 + e, a1^2 + p21^2 + 2 a1 p21 r_x.
apim_r_squared <- function(spec) {
  b <- apim_paths(spec)
  r <- spec$population$r_x
  c(Y1 = b[["a1"]]^2 + b[["p21"]]^2 + 2 * b[["a1"]] * b[["p21"]] * r,
    Y2 = b[["a2"]]^2 + b[["p12"]]^2 + 2 * b[["a2"]] * b[["p12"]] * r)
}

apim_inputs <- function(spec) {
  b <- apim_paths(spec)
  r2 <- apim_r_squared(spec)
  pop <- spec$population
  # power4mome's value for 'Y1 ~~ Y2' between endogenous variables is the
  # residual covariance (all observed variables standardised), so the
  # residual correlation is multiplied by the two residual SDs, as
  # power4mome_inputs() does for parallel mediators.
  residual_cov <- pop$r_y * sqrt((1 - r2[["Y1"]]) * (1 - r2[["Y2"]]))
  distinguishable <- isTRUE(pop$distinguishable)
  label <- switch(spec$target_test$effect, actor = "a1", partner = "p21", actor_1 = "a1", actor_2 = "a2",
    partner_12 = "p12", partner_21 = "p21")
  list(
    model = paste("Y1 ~ X1 + X2", "Y2 ~ X2 + X1", "X1 ~~ X2", "Y1 ~~ Y2", sep = "\n"),
    pop_es = paste(
      sprintf("Y1 ~ X1: %s", format_pop_value(b[["a1"]])), sprintf("Y1 ~ X2: %s", format_pop_value(b[["p21"]])),
      sprintf("Y2 ~ X2: %s", format_pop_value(b[["a2"]])), sprintf("Y2 ~ X1: %s", format_pop_value(b[["p12"]])),
      sprintf("X1 ~~ X2: %s", format_pop_value(pop$r_x)), sprintf("Y1 ~~ Y2: %s", format_pop_value(residual_cov)),
      sep = "\n"),
    fit_model = paste(c("Y1 ~ a1*X1 + p21*X2", "Y2 ~ a2*X2 + p12*X1",
      if (!distinguishable) c("a1 == a2", "p21 == p12"), "X1 ~~ X2", "Y1 ~~ Y2"), collapse = "\n"),
    label = label,
    distinguishable = distinguishable,
    paths = b,
    r_squared = r2,
    alpha = spec$target_test$alpha
  )
}

apim_backend <- function(spec, seed = NULL) {
  inputs <- apim_inputs(spec)
  list(
    name = "power4mome",
    packages = c("power4mome", "lavaan"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("power4mome::power4test with power4mome::test_parameters (pars = \"%s\")", inputs$label)),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) apim_rejections(inputs, n, k, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() apim_check_run(spec, inputs, seed)
  )
}

# Rejections in `nrep` replications at n dyads, and how many replications
# could be analysed (power4mome drops data sets whose model fails to fit).
apim_rejections <- function(inputs, n, nrep, seed) {
  result <- power4mome_call(
    inputs, n, nrep, seed,
    fit_model_args = list(model = inputs$fit_model),
    test_fun = power4mome::test_parameters,
    test_args = list(pars = inputs$label, level = 1 - inputs$alpha)
  )
  rates <- power4mome::rejection_rates(result)
  valid <- round(rates$pvalid[1] * nrep)
  c(round(rates$reject[1] * valid), valid)
}

# Check run: one large data set from power4mome's generator. Each member's
# Y regressed on both members' X by OLS recovers the four paths; every
# variable has variance 1; the X correlation and the residual Y
# correlation are recovered.
apim_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  sim <- power4mome_call(inputs, n, 1, seed, do_the_test = FALSE)
  data <- as.data.frame(power4mome::pool_sim_data(sim))
  fit1 <- stats::lm(Y1 ~ X1 + X2, data = data)
  fit2 <- stats::lm(Y2 ~ X2 + X1, data = data)
  c1 <- summary(fit1)$coefficients
  c2 <- summary(fit2)$coefficients
  b <- inputs$paths
  correlation_row <- function(label, specified, recovered) {
    data.frame(parameter = label, specified = specified, recovered = recovered,
      ok = abs(atanh(recovered) - atanh(specified)) <= 5 / sqrt(n - 3))
  }
  rows <- list(
    check_run_rows(c("actor, member 1 (X1->Y1)", "partner, member 2 on 1 (X2->Y1)"), b[c("a1", "p21")],
      c1[c("X1", "X2"), "Estimate"], c1[c("X1", "X2"), "Std. Error"]),
    check_run_rows(c("actor, member 2 (X2->Y2)", "partner, member 1 on 2 (X1->Y2)"), b[c("a2", "p12")],
      c2[c("X2", "X1"), "Estimate"], c2[c("X2", "X1"), "Std. Error"]),
    do.call(rbind, lapply(c("X1", "X2", "Y1", "Y2"), function(v) {
      squares <- (data[[v]] - mean(data[[v]]))^2
      check_run_rows(sprintf("variance of %s", v), 1, mean(squares), stats::sd(squares) / sqrt(n))
    })),
    correlation_row("X1<->X2", spec$population$r_x, stats::cor(data$X1, data$X2)),
    correlation_row("residual Y1<->Y2", spec$population$r_y, stats::cor(stats::residuals(fit1), stats::residuals(fit2)))
  )
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

# The standalone script: power4mome alone, with the same model and test.
apim_script <- function(spec, result) {
  inputs <- apim_inputs(spec)
  v <- spec$variables
  members <- unlist(spec$population$members %||% list("Member 1", "Member 2"))
  c(
    script_header(spec, result, "power4mome", sprintf("power4mome::power4test() with test_parameters(pars = \"%s\")", inputs$label)),
    "library(power4mome)",
    "",
    "# Inputs ----",
    sprintf("# X is %s and Y is %s, measured on both members of each pair (1: %s; 2: %s);",
      comment_text(v$X$label), comment_text(v$Y$label), comment_text(members[1]), comment_text(members[2])),
    "# every path standardised.",
    sprintf("population_model <- %s", r_code(inputs$model)),
    sprintf("population_values <- %s # residual covariance = r_y x both residual SDs", r_code(inputs$pop_es)),
    sprintf("fitted_model <- %s%s", r_code(inputs$fit_model),
      if (inputs$distinguishable) "" else " # indistinguishable members: equal actor and partner effects"),
    sprintf("tested <- %s # the effect tested", r_code(inputs$label)),
    goal_inputs(spec, result),
    "",
    "# One batch of simulated data sets: significant results and data sets analysed.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- power4test(nrep = batch_replications, model = population_model, pop_es = population_values,",
    "    n = batch_n, fit_model_args = list(model = fitted_model), test_fun = test_parameters,",
    "    test_args = list(pars = tested, level = 1 - alpha), iseed = batch_seed, parallel = FALSE, progress = FALSE)",
    "  rates <- rejection_rates(result)",
    "  valid <- round(rates$pvalid[1] * batch_replications)",
    "  c(round(rates$reject[1] * valid), valid)",
    "}",
    "",
    batch_section(result, "power4test()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}
