# Backend adapter: a quick estimate for simple mediation, by formula, via
# pwrss.
#
# The joint-significance test (target_test > method "joint_significance")
# counts the indirect effect X -> M -> Y as significant when both of its
# paths are: a (X -> M, in the regression of M on X) and b (M -> Y, in the
# regression of Y on X and M). pwrss's power.z.mediation(method = "joint")
# computes its power as the product of the two paths' z-test powers, from
# their large-sample standard errors (pwrss 1.3.3 help): a formula, so the
# answer is instant and has no simulation error. The two estimates are
# uncorrelated in large samples, which is what makes the product the joint
# power; the large-sample z tests make it optimistic: with paths of .3 and
# N = 100 it gives 75.0%, against 72.4% for a simulation of the joint test
# with regressions and 71.1% for the simulated Monte Carlo interval. powerkit offers it as a quick estimate for
# simple mediation (one mediator; E10 and E16), beside the Monte Carlo
# confidence interval that powerkit simulates for the plan to report.
#
# Paths are standardised, with X, M and Y of variance 1 (as power4mome
# takes them; a yes/no X is rescaled to SD 1). powerkit passes both
# R-squared values: R-squared of M is a^2, and of Y b^2 + c'^2 + 2 a b c'.
# pwrss's own default for Y leaves out the last term (the covariance of X
# and M, which is a), and so understates it when the direct path is not 0
# (docs/upstream-questions.md).

mediation_joint_test <- function(spec) {
  identical(spec$design, "mediation") && identical(spec$template, "process_4") &&
    identical(spec$target_test$method, "joint_significance")
}

mediation_joint_inputs <- function(spec) {
  paths <- spec$population$paths
  a <- as.numeric(paths[["X->M"]])
  b <- as.numeric(paths[["M->Y"]])
  cp <- as.numeric(paths[["X->Y"]] %||% 0)
  list(
    a = a, b = b, cp = cp,
    r2_m = a^2,
    r2_y = b^2 + cp^2 + 2 * a * b * cp,
    alpha = spec$target_test$alpha,
    args = function(n) list(
      beta.a = a, beta.b = b, beta.cp = cp, sd.predictor = 1, sd.mediator = 1, sd.outcome = 1,
      r.squared.mediator = a^2, r.squared.outcome = b^2 + cp^2 + 2 * a * b * cp,
      n = n, alpha = spec$target_test$alpha, alternative = "two.sided", method = "joint", verbose = 0
    )
  )
}

mediation_joint_backend <- function(spec, seed = NULL) {
  inputs <- mediation_joint_inputs(spec)
  power_at <- function(n) {
    call_backend("pwrss", quietly(do.call(pwrss::power.z.mediation, inputs$args(n))))$power
  }
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "pwrss::power.z.mediation(method = \"joint\")"),
    n_step = 1,
    # Two regressions with two predictors in the larger one.
    exact_min_n = max(minimum_n(spec), 5),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() mediation_joint_check_run(spec, inputs)
  )
}

# Check run: no simulated data; the check confirms what pwrss receives.
mediation_joint_check_run <- function(spec, inputs) {
  args <- inputs$args(100)
  paths <- spec$population$paths
  rows <- data.frame(
    parameter = c("path X -> M (a)", "path M -> Y (b)", "path X -> Y (direct)", "R-squared of M", "R-squared of Y"),
    specified = c(paths[["X->M"]], paths[["M->Y"]], paths[["X->Y"]] %||% 0, inputs$r2_m, inputs$r2_y),
    recovered = c(args$beta.a, args$beta.b, args$beta.cp, args$r.squared.mediator, args$r.squared.outcome)
  )
  rows$ok <- mapply(function(x, y) isTRUE(all.equal(as.numeric(x), as.numeric(y))), rows$specified, rows$recovered)
  rows
}

# The R script: the same pwrss call at each size powerkit computed.
mediation_joint_script <- function(spec, result) {
  inputs <- mediation_joint_inputs(spec)
  c(
    script_header(spec, result, "pwrss", "pwrss::power.z.mediation(method = \"joint\")"),
    "library(pwrss)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    sprintf("a <- %s # path X -> M (standardised)", r_code(inputs$a)),
    sprintf("b <- %s # path M -> Y (standardised)", r_code(inputs$b)),
    sprintf("cp <- %s # path X -> Y, the direct effect (standardised)", r_code(inputs$cp)),
    "",
    "# Power of the joint-significance test: both paths significant. X, M and",
    "# Y have variance 1; R-squared of Y includes the X-M covariance (a).",
    "power_at <- function(n_total) {",
    "  pwrss::power.z.mediation(beta.a = a, beta.b = b, beta.cp = cp,",
    "    sd.predictor = 1, sd.mediator = 1, sd.outcome = 1,",
    "    r.squared.mediator = a^2, r.squared.outcome = b^2 + cp^2 + 2 * a * b * cp,",
    "    n = n_total, alpha = alpha, alternative = \"two.sided\", method = \"joint\", verbose = 0)$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
