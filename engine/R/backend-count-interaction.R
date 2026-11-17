# Backend adapter: moderation of a count outcome (poisson_regression /
# interaction, E32).
#
# X and W are each a score (standard normal; two scores correlate r_xw) or
# a yes/no group coded 0 and 1 (x_prob, w_prob in the second group). The
# count has mean
#   base_rate * rate_ratio_x^x * rate_ratio_w^w * rate_ratio_xw^(x w)
# and is Poisson or, with target_test > method "negative_binomial" and
# population > dispersion, negative binomial with
# variance mu + dispersion mu^2 (stats::rnbinom(size = 1 / dispersion), as
# negative_binomial_data() draws it). Each study is fitted by glm(family =
# poisson()) or MASS::glm.nb() with y ~ x * w, and the X x W coefficient is
# tested by its Wald z test, as for moderation of a yes/no outcome
# (p_logistic_interaction()). Spower runs the experiment
# p_count_interaction(); a fit that fails counts as not significant.

count_interaction_inputs <- function(spec) {
  pop <- spec$population
  x_binary <- identical(spec$variables$X$type, "binary")
  w_binary <- identical(spec$variables$W$type, "binary")
  list(
    base_rate = as.numeric(pop$base_rate),
    rate_ratio_x = as.numeric(pop$rate_ratio_x),
    rate_ratio_w = as.numeric(pop$rate_ratio_w),
    rate_ratio_xw = as.numeric(pop$rate_ratio_xw),
    # 0 is Poisson; Spower reads NA as the value to solve for, so never NA.
    dispersion = if (identical(spec$target_test$method, "negative_binomial")) as.numeric(pop$dispersion) else 0,
    x_binary = x_binary,
    w_binary = w_binary,
    x_prob = as.numeric(pop$x_prob %||% 0.5),
    w_prob = as.numeric(pop$w_prob %||% 0.5),
    r = as.numeric(pop$r_xw %||% 0),
    # Spells R's alternatives: "two_sided" in a spec is "two.sided" here.
    alternative = sub("two_sided", "two.sided", spec$target_test$alternative %||% "two_sided", fixed = TRUE)
  )
}

# One study's data, drawn in this order: X, W, the counts.
count_interaction_data <- function(n, base_rate, rate_ratio_x, rate_ratio_w, rate_ratio_xw, dispersion, x_binary, w_binary,
                                   x_prob, w_prob, r) {
  if (!x_binary && !w_binary) {
    x <- stats::rnorm(n)
    w <- r * x + sqrt(1 - r^2) * stats::rnorm(n)
  } else {
    x <- if (x_binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
    w <- if (w_binary) as.numeric(stats::runif(n) < w_prob) else stats::rnorm(n)
  }
  mu <- base_rate * exp(log(rate_ratio_x) * x + log(rate_ratio_w) * w + log(rate_ratio_xw) * x * w)
  y <- if (dispersion > 0) stats::rnbinom(n, size = 1 / dispersion, mu = mu) else stats::rpois(n, mu)
  data.frame(x = x, w = w, y = y)
}

count_interaction_fit <- function(data, dispersion) {
  tryCatch(suppressWarnings(
    if (dispersion > 0) MASS::glm.nb(y ~ x * w, data = data) else stats::glm(y ~ x * w, family = stats::poisson(), data = data)
  ), error = function(e) NULL)
}

# The experiment Spower runs: the X x W coefficient's Wald z test p value
# (one-sided in the direction asked: "greater", X's rate ratio rising with
# W); 1 when the model can't be fitted.
p_count_interaction <- function(n, base_rate, rate_ratio_x, rate_ratio_w, rate_ratio_xw, dispersion, x_binary, w_binary,
                                x_prob, w_prob, r, alternative = "two.sided") {
  data <- count_interaction_data(n, base_rate, rate_ratio_x, rate_ratio_w, rate_ratio_xw, dispersion, x_binary, w_binary,
    x_prob, w_prob, r)
  fit <- count_interaction_fit(data, dispersion)
  if (is.null(fit)) return(1)
  z <- stats::coef(summary(fit))["x:w", "z value"]
  if (!is.finite(z)) return(1)
  switch(alternative,
    two.sided = 2 * stats::pnorm(-abs(z)),
    greater = stats::pnorm(z, lower.tail = FALSE),
    less = stats::pnorm(z)
  )
}

count_interaction_count <- function(inputs, n, nrep, alpha, seed) {
  result <- spower_eval(as.name("p_count_interaction"), c(list(n = n), inputs), nrep, alpha, seed)
  round(result$power * nrep)
}

count_interaction_backend <- function(spec, seed = NULL) {
  inputs <- count_interaction_inputs(spec)
  nb <- inputs$dispersion > 0
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", if (nb) "MASS"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("Spower::Spower(p_count_interaction()) (%s, the Wald z test of the X x W coefficient)",
      if (nb) "MASS::glm.nb()" else "stats::glm(family = poisson())")),
    n_step = 1L,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
        count_interaction_count(inputs, n, chunk, spec$target_test$alpha, chunk_seed)
      })
    },
    sensitivity = NULL,
    simulated_sensitivity = function(n, power, nrep, seed, cores) simulated_effect_sensitivity(spec, n, power, nrep, seed, cores),
    check_run = function() count_interaction_check_run(inputs, seed)
  )
}

# Check run: one large data set, fitted as each simulated one is; the
# starting rate and the three rate ratios recovered on the log scale.
count_interaction_check_run <- function(inputs, seed) {
  args <- inputs[setdiff(names(inputs), "alternative")]
  data <- call_backend("Spower", with_seed(seed %||% 1L, do.call(count_interaction_data, c(list(n = check_run_n()), args))))
  fit <- count_interaction_fit(data, inputs$dispersion)
  if (is.null(fit)) abort_run("The check run's count model could not be fitted.")
  est <- stats::coef(summary(fit))
  specified <- log(c(inputs$base_rate, inputs$rate_ratio_x, inputs$rate_ratio_w, inputs$rate_ratio_xw))
  rows <- check_run_rows(
    c("count at the starting point (checked on the log scale)", "rate ratio for X (checked on the log scale)",
      "rate ratio for W (checked on the log scale)", "ratio of rate ratios for X x W (checked on the log scale)"),
    specified, est[, "Estimate"], est[, "Std. Error"]
  )
  rows$specified <- exp(specified)
  rows$recovered <- exp(est[, "Estimate"])
  rownames(rows) <- NULL
  rows
}

check_count_interaction <- function(spec) {
  pop <- spec$population
  v <- spec$variables
  problems <- character()
  for (role in c("X", "W")) {
    field <- paste0(tolower(role), "_prob")
    if (!is.null(pop[[field]]) && !identical(v[[role]]$type, "binary")) {
      problems <- c(problems, sprintf("'population > %s' is the proportion in the second group of a yes/no %s, but %s is a score; remove it, or make %s binary.",
        field, role, var_label(spec, role), role))
    }
  }
  if (!is.null(pop$r_xw) && (identical(v$X$type, "binary") || identical(v$W$type, "binary"))) {
    problems <- c(problems, "'population > r_xw' (the correlation between X and W) is only used when both are scores: powerkit draws a yes/no X or W on its own. Remove it.")
  }
  problems
}

# The standalone script (export_script()).
count_interaction_script <- function(spec, result) {
  inputs <- count_interaction_inputs(spec)
  nb <- inputs$dispersion > 0
  header <- script_header(spec, result, "Spower", if (nb) "Spower::Spower, MASS::glm.nb" else "Spower::Spower, stats::glm")
  c(
    header,
    "library(Spower)",
    "",
    "# Inputs ----",
    sprintf("base_rate <- %s # mean count with X and W at their averages, or in their first groups", r_code(inputs$base_rate)),
    sprintf("rate_ratio_x <- %s # rate ratio for X (per SD, or second group against first)", r_code(inputs$rate_ratio_x)),
    sprintf("rate_ratio_w <- %s # rate ratio for W", r_code(inputs$rate_ratio_w)),
    sprintf("rate_ratio_xw <- %s # the interaction: how many times X's rate ratio is multiplied per SD (or group) of W", r_code(inputs$rate_ratio_xw)),
    sprintf("dispersion <- %s # 0: Poisson counts; above 0: negative binomial, variance mu + dispersion * mu^2", r_code(inputs$dispersion)),
    sprintf("x_binary <- %s; w_binary <- %s # TRUE for a yes/no group coded 0 and 1, FALSE for a score", r_code(inputs$x_binary), r_code(inputs$w_binary)),
    sprintf("x_prob <- %s; w_prob <- %s # share in the second group of a yes/no X or W", r_code(inputs$x_prob), r_code(inputs$w_prob)),
    sprintf("r <- %s # correlation of X and W when both are scores", r_code(inputs$r)),
    sprintf("alternative <- %s", r_code(inputs$alternative)),
    goal_inputs(spec, result),
    "",
    "# One simulated study: X, W and the counts drawn from the model, then the",
    "# count regression with the X x W product and its coefficient's Wald z",
    "# test. A model that can't be fitted counts as not significant.",
    "p_count_interaction <- function(n) {",
    "  if (!x_binary && !w_binary) {",
    "    x <- rnorm(n)",
    "    w <- r * x + sqrt(1 - r^2) * rnorm(n)",
    "  } else {",
    "    x <- if (x_binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else rnorm(n)",
    "    w <- if (w_binary) as.numeric(runif(n) < w_prob) else rnorm(n)",
    "  }",
    "  mu <- base_rate * exp(log(rate_ratio_x) * x + log(rate_ratio_w) * w + log(rate_ratio_xw) * x * w)",
    "  y <- if (dispersion > 0) rnbinom(n, size = 1 / dispersion, mu = mu) else rpois(n, mu)",
    "  fit <- tryCatch(suppressWarnings(",
    "    if (dispersion > 0) MASS::glm.nb(y ~ x * w) else glm(y ~ x * w, family = poisson())",
    "  ), error = function(e) NULL)",
    "  if (is.null(fit)) return(1)",
    "  z <- coef(summary(fit))[\"x:w\", \"z value\"]",
    "  if (!is.finite(z)) return(1)",
    "  switch(alternative, two.sided = 2 * pnorm(-abs(z)), greater = pnorm(z, lower.tail = FALSE), less = pnorm(z))",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_count_interaction(n = batch_n), sig.level = alpha, replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, 1L),
    comparison_section()
  )
}

# Simulated-data code (simulated_data()): the same data as the simulation,
# written out as sim_logistic_interaction_code() writes the yes/no case.
sim_count_interaction_code <- function(spec, n) {
  inputs <- count_interaction_inputs(spec)
  xb <- inputs$x_binary
  wb <- inputs$w_binary
  c(
    if (!xb && !wb) {
      c(sprintf("x <- stats::rnorm(%d) # standardised", n),
        sprintf("w <- %s * x + sqrt(1 - %s^2) * stats::rnorm(%d) # standardised, correlation %s with X", r_code(inputs$r), r_code(inputs$r), n, format_number(inputs$r)))
    } else {
      c(if (xb) sprintf("x <- sample(rep(c(0, 1), c(%d, %d))) # 1 = %s", n - round(n * inputs$x_prob), round(n * inputs$x_prob), sim_levels(spec, "X")[2]) else sprintf("x <- stats::rnorm(%d) # standardised", n),
        if (wb) sprintf("w <- as.numeric(stats::runif(%d) < %s) # 1 = %s", n, r_code(inputs$w_prob), sim_levels(spec, "W")[2]) else sprintf("w <- stats::rnorm(%d) # standardised", n))
    },
    sprintf("mu <- %s * exp(log(%s) * x + log(%s) * w + log(%s) * x * w)", r_code(inputs$base_rate), r_code(inputs$rate_ratio_x),
      r_code(inputs$rate_ratio_w), r_code(inputs$rate_ratio_xw)),
    if (inputs$dispersion > 0) sprintf("y <- stats::rnbinom(%d, size = 1 / %s, mu = mu)", n, r_code(inputs$dispersion)) else sprintf("y <- stats::rpois(%d, mu)", n),
    sprintf("simulated <- data.frame(%s = %s, %s = %s, %s = y)",
      sim_label(spec, "X"), if (xb) sprintf("%s[x + 1]", r_code(sim_levels(spec, "X"))) else "x",
      sim_label(spec, "W"), if (wb) sprintf("%s[w + 1]", r_code(sim_levels(spec, "W"))) else "w",
      sim_label(spec, "Y"))
  )
}
