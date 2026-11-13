# Backend adapter: Welch's one-way ANOVA (Welch's F) by Levy's noncentral F
# approximation, in base R's stats package.
#
# No package powerkit builds on gives Welch's F's power by formula; it was
# simulated with Spower, which is slower and carries random error. Levy
# (1978) approximated W's distribution under the alternative by putting the
# population means and variances in place of the sample ones in Welch's
# statistic: W is close to the noncentral F distribution with g - 1 and
# nu = (g^2 - 1) / (3 tau) degrees of freedom and noncentrality
# Lambda = sum(omega_i (mu_i - mu~)^2), where omega_i = N_i / sigma_i^2,
# mu~ = sum(omega_i mu_i) / sum(omega_i) and
# tau = sum((1 - omega_i / sum(omega))^2 / (N_i - 1)). Power is the chance
# that this noncentral F exceeds the central F's critical value with the
# same df. Jan and Shieh (2014, equations 2 and 4, with R code in their
# Appendices C and D) compared it with Luh and Guo's (2011) approximation
# across mean patterns, variance patterns and group sizes, found its power
# within .01 of simulation in every case, and recommend it for power and
# sample size. CLAUDE.md allows a published closed-form result where no
# package has one; the answers are checked against Jan and Shieh's
# published tables and against Spower's simulation of the same test
# (test-backend-welch-anova.R), which stays available with
# options > method = "simulation".

# Welch's F by formula: the default, unless simulation is asked for.
welch_levy_test <- function(spec) {
  welch_anova(spec) && identical(spec$template, "oneway_between") && !identical(spec$options$method, "simulation")
}

welch_anova_backend <- function(spec, seed = NULL) {
  inputs <- welch_levy_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(max(minimum_n(spec), 2 * inputs$groups) / step)
  power_at <- function(n) welch_levy_power(inputs, n)
  list(
    name = "stats",
    packages = "stats",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) welch_levy_sensitivity(spec, inputs, n, power),
    details = function(n) welch_levy_details(inputs, n),
    check_run = function() welch_levy_check_run(spec, inputs)
  )
}

welch_levy_inputs <- function(spec) {
  list(
    alpha = spec$target_test$alpha,
    groups = length(spec$variables$A$levels),
    means = as.numeric(unlist(spec$population$means)),
    sds = welch_sds(spec),
    description = "stats::pf() (Welch's F by Levy's noncentral F approximation, Jan & Shieh, 2014)"
  )
}

# The parts of Levy's approximation at a total n split equally between the
# groups (as Spower draws them), or at given group `sizes` (Jan and Shieh's
# unequal designs, for the tests): numerator and denominator df and the
# noncentrality.
welch_levy_parts <- function(inputs, n, means = inputs$means, sizes = rep(n / inputs$groups, inputs$groups)) {
  g <- inputs$groups
  omega <- sizes / inputs$sds^2
  weighted_mean <- sum(omega * means) / sum(omega)
  tau <- sum((1 - omega / sum(omega))^2 / (sizes - 1))
  list(df1 = g - 1, df2 = (g^2 - 1) / (3 * tau), ncp = sum(omega * (means - weighted_mean)^2))
}

welch_levy_power <- function(inputs, n, means = inputs$means, sizes = rep(n / inputs$groups, inputs$groups)) {
  parts <- welch_levy_parts(inputs, n, means, sizes)
  critical <- stats::qf(1 - inputs$alpha, parts$df1, parts$df2)
  stats::pf(critical, parts$df1, parts$df2, ncp = parts$ncp, lower.tail = FALSE)
}

welch_levy_details <- function(inputs, n) {
  parts <- welch_levy_parts(inputs, n)
  list(
    statistic = "F",
    df = c(parts$df1, parts$df2),
    critical = stats::qf(1 - inputs$alpha, parts$df1, parts$df2),
    ncp = parts$ncp,
    actual_alpha = NA_real_,
    source = sprintf("powerkit's formula, %s", sub(" \\(.*$", "", inputs$description))
  )
}

# The smallest detectable effect: as for the F test (superpower_sensitivity())
# and the simulated Welch's F (welch_f_sensitivity()), the pattern of means
# keeps its shape and its size about the grand mean is scaled until power
# reaches the target at n. Power rises with the scale, so uniroot() finds it.
welch_levy_sensitivity <- function(spec, inputs, n, target) {
  grand_mean <- mean(inputs$means)
  mu_at <- function(scale) grand_mean + scale * (inputs$means - grand_mean)
  power_at <- function(scale) welch_levy_power(inputs, n, mu_at(scale))
  upper <- 1
  while (power_at(upper) < target) {
    upper <- upper * 2
    if (upper > 1e4) {
      abort_run("No effect of this shape reaches the target power at this n. Check the population values.")
    }
  }
  scale <- stats::uniroot(function(k) power_at(k) - target, lower = 0, upper = upper, tol = 1e-10)$root
  scaled <- mu_at(scale)
  list(
    scale = scale,
    means = scaled,
    effect = max(scaled) - min(scaled),
    effect_description = sprintf(
      "the largest difference between two of the means of %s, with the pattern you entered kept and scaled (means %s)",
      spec$variables$Y$label %||% "the outcome", paste(vapply(scaled, function(x) format(signif(x, 3)), character(1)), collapse = ", ")
    ),
    power = power_at(scale)
  )
}

# Check run: there is no simulated data, so the check confirms that the
# formula uses the spec's means and SDs.
welch_levy_check_run <- function(spec, inputs) {
  means <- as.numeric(unlist(spec$population$means))
  sds <- welch_sds(spec)
  data.frame(
    parameter = c(sprintf("mean of group %d the formula uses", seq_along(means)), sprintf("SD of group %d the formula uses", seq_along(sds))),
    specified = c(means, sds),
    recovered = c(inputs$means, inputs$sds),
    ok = c(abs(inputs$means - means) < 1e-12, abs(inputs$sds - sds) < 1e-12)
  )
}
