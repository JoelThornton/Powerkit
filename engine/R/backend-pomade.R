# Backend adapter: a planned meta-analysis in which each study gives several
# correlated effect sizes (meta_analysis/dependent_effects, E61), via
# POMADE's power_MADE() (Vembye, Pustejovsky and Pigott: citation("POMADE")).
#
# The model is POMADE's default and recommendation: the correlated and
# hierarchical effects (CHE) working model, its average effect tested with
# robust variance estimation (RVE, J - 1 degrees of freedom). The studies
# vary in their average true effect (tau, the SD between studies) and their
# effects vary within a study (omega, the SD within studies); a study's
# sampling errors are correlated rho. Every study is taken to have the same
# size and the same number of effects, as for E61's average effect, so each
# effect's sampling variance is that of a typical study, computed as
# metapower computes it (meta_study_model()). For r the analysis is on
# Fisher's z, so tau and omega are on that scale.
#
# n is the number of studies (J).

pomade_backend <- function(spec, seed = NULL) {
  inputs <- pomade_inputs(spec)
  # Each call to power_MADE() takes a few seconds, and the sample-size
  # search asks for some n more than once, so each n is worked out once.
  cache <- new.env(parent = emptyenv())
  power_at <- function(n) {
    vapply(n, function(one) {
      key <- as.character(one)
      if (is.null(cache[[key]])) cache[[key]] <- pomade_power(inputs, one)
      cache[[key]]
    }, numeric(1))
  }
  list(
    name = "POMADE",
    packages = "POMADE",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "POMADE::power_MADE"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() pomade_check_run(spec, inputs)
  )
}

# The arguments power_MADE() is given, on the analysis scale. Power is the
# same for an effect and its mirror image (the test is two-sided).
pomade_inputs <- function(spec) {
  pop <- spec$population
  model <- meta_study_model(spec)
  list(
    mu = abs(model$theta),
    tau = pop$tau,
    omega = pop$omega,
    rho = pop$rho,
    sigma2 = model$v,
    effects_per_study = pop$effects_per_study,
    alpha = spec$target_test$alpha,
    metric = pop$metric
  )
}

pomade_output <- function(inputs, n) {
  call_backend("POMADE", quietly(POMADE::power_MADE(
    J = n, mu = inputs$mu, tau = inputs$tau, omega = inputs$omega, rho = inputs$rho, alpha = inputs$alpha,
    model = "CHE", var_df = "RVE", sigma2_dist = inputs$sigma2, n_ES_dist = inputs$effects_per_study,
    warning = FALSE
  )))
}

pomade_power <- function(inputs, n) {
  as.numeric(pomade_output(inputs, n)$power)
}

# Check run: the values POMADE reports back are the ones powerkit gave it,
# and with no effect its power is alpha (a test of the right size).
pomade_check_run <- function(spec, inputs) {
  out <- pomade_output(inputs, 10)
  null <- inputs
  null$mu <- 0
  null_power <- pomade_power(null, 10)
  row <- function(label, specified, recovered) check_run_rows(label, specified, recovered, 1e-6)
  check <- rbind(
    row("average effect (analysis scale)", inputs$mu, out$mu),
    row("SD of studies' average effects (tau)", inputs$tau, out$tau),
    row("SD of effects within a study (omega)", inputs$omega, out$omega),
    row("correlation of a study's sampling errors (rho)", inputs$rho, out$rho),
    row("RVE degrees of freedom at 10 studies (J - 1)", 9, out$df),
    row("power with no effect at 10 studies (alpha)", inputs$alpha, null_power)
  )
  rownames(check) <- NULL
  check
}

# The standalone script: POMADE alone, with the same inputs.
pomade_script <- function(spec, result) {
  inputs <- pomade_inputs(spec)
  pop <- spec$population
  r_metric <- identical(inputs$metric, "r")
  c(
    script_header(spec, result, "POMADE", "POMADE::power_MADE() (CHE model, RVE test)"),
    "library(POMADE)",
    "",
    "# Inputs ----",
    sprintf("mu <- %s # the average effect%s", r_code(inputs$mu), if (r_metric) sprintf(" on Fisher's z (atanh(%s))", r_code(abs(pop$effect))) else " (Cohen's d)"),
    sprintf("tau <- %s # SD of the studies' average true effects", r_code(inputs$tau)),
    sprintf("omega <- %s # SD of the true effects within a study", r_code(inputs$omega)),
    sprintf("rho <- %s # correlation of a study's sampling errors", r_code(inputs$rho)),
    sprintf("sigma2 <- %s # each effect's sampling variance, from a typical study of %s (%s)", r_code(inputs$sigma2),
      format_number(pop$study_size), if (r_metric) "1 / (n - 3)" else "4 / n + d^2 / (2 n), as metapower computes it"),
    sprintf("effects_per_study <- %s", r_code(inputs$effects_per_study)),
    sprintf("alpha <- %s", r_code(inputs$alpha)),
    switch(
      spec$goal$type,
      sample_size = sprintf("target_power <- %s", r_code(spec$goal$power)),
      power = sprintf("n_total <- %s # the number of studies (J)", r_code(spec$goal$n))
    ),
    "# POMADE's approximation draws no random numbers here, so powerkit's seed isn't used.",
    "",
    "power_at <- function(J) {",
    "  power_MADE(J = J, mu = mu, tau = tau, omega = omega, rho = rho, alpha = alpha, model = \"CHE\",",
    "    var_df = \"RVE\", sigma2_dist = sigma2, n_ES_dist = effects_per_study, warning = FALSE)$power",
    "}",
    "",
    "# Below, n means the number of studies (J).",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
