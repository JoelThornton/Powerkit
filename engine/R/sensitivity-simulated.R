# The smallest detectable effect of a simulated test: Welch's F, when
# simulation is asked for (by default it is worked out by Levy's
# approximation, welch_levy_sensitivity()).
#
# As for the F test (superpower_sensitivity()), the pattern of means
# entered keeps its shape and its size (each mean's deviation from the
# grand mean) is scaled until the test reaches the target power at n. No
# package gives Welch's F's power by formula, so power at each scale is
# simulated with Spower, as for its power and sample size, and the scale is
# read from a probit curve fitted to the simulated rejections, as search_n()
# reads the sample size: for roughly normal test statistics power is close
# to pnorm(a + b * scale) near the target.

#' Find the smallest detectable effect by simulation
#'
#' For Welch's one-way ANOVA. The search starts from the F test's exact
#' answer (Superpower's `ANOVA_exact()`, with the root mean square of the
#' groups' SDs), which only places the grid, then simulates power at seven
#' scales of the pattern of means around it, each with `nrep`
#' replications, widening the grid if the target lies outside it. A probit
#' regression of the rejection counts on the scale, fitted to the points
#' within 20% of the estimate, gives the scale at which fitted power reaches
#' the target; its 95% interval runs between the scales at which the upper
#' and lower confidence limits of the curve reach it.
#'
#' @inheritParams search_n
#' @param n Total sample size.
#' @return A list with `sensitivity` (the scale, its interval, the scaled
#'   means, the effect as the largest difference between two means and its
#'   interval, a description, the fitted power and `simulated = TRUE`),
#'   `curve` (the target power at `n`, with the curve's standard error) and
#'   `simulations` (one row per simulated scale, with its `scale`).
#' @keywords internal
welch_f_sensitivity <- function(spec, n, power, nrep, seed, cores = 1L, level = 0.95) {
  means <- as.numeric(unlist(spec$population$means))
  grand_mean <- mean(means)
  mu_at <- function(scale) grand_mean + scale * (means - grand_mean)
  guess <- classical_f_scale(spec, n, power)

  points <- data.frame(scale = numeric(), seed = numeric(), rejections = numeric(), nrep = numeric(),
    attempted = numeric(), valid = numeric())
  simulate_at <- function(scales) {
    scales <- setdiff(signif(scales, 6), points$scale)
    for (scale in scales[scales > 0]) {
      scale_seed <- offset_seed(seed, 10007 * nrow(points))
      scaled <- spec
      scaled$population$means <- as.list(mu_at(scale))
      sim <- spower_backend(scaled)$simulate(n, nrep, scale_seed, cores)
      points[nrow(points) + 1, ] <<- c(scale, scale_seed, sim$rejections, sim$nrep,
        sim$attempted %||% sim$nrep, sim$valid %||% sim$nrep)
    }
  }
  simulate_at(guess * (1 + 0.08 * (-3:3)))
  for (attempt in 1:6) {
    estimate <- scale_from_curve(points, power, level)
    if (!is.na(estimate$scale) && !is.na(estimate$lower) && !is.na(estimate$upper)) break
    p <- points$rejections / points$nrep
    # The target is above every simulated point: larger scales; below
    # every point: smaller ones.
    if (all(p < power)) simulate_at(max(points$scale) * c(1.15, 1.35, 1.6))
    if (all(p >= power)) simulate_at(min(points$scale) / c(1.15, 1.35, 1.6))
    if (any(p < power) && any(p >= power)) simulate_at(range(points$scale) * c(0.85, 1.15))
  }
  fitted <- points$scale
  if (!is.na(estimate$scale)) {
    near <- function() points[abs(points$scale / estimate$scale - 1) <= 0.2, ]
    if (nrow(near()) < 5) simulate_at(estimate$scale * (1 + 0.05 * (-3:3)))
    fitted <- near()$scale
    estimate <- scale_from_curve(near(), power, level)
  }
  if (is.na(estimate$scale) || is.na(estimate$lower) || is.na(estimate$upper)) {
    abort_run("The search for the smallest detectable effect could not pin it down: the simulated power didn't settle near the target. Try more replications ('options > nrep') or another seed.")
  }

  points <- points[order(points$scale), ]
  spread <- max(means) - min(means)
  scaled <- mu_at(estimate$scale)
  record <- simulation_record(rep(n, nrow(points)), points$seed, points$rejections, points$nrep,
    points$scale %in% fitted, points$attempted, points$valid)
  record$scale <- points$scale
  list(
    sensitivity = list(
      scale = estimate$scale,
      scale_lower = estimate$lower,
      scale_upper = estimate$upper,
      means = scaled,
      effect = estimate$scale * spread,
      effect_lower = estimate$lower * spread,
      effect_upper = estimate$upper * spread,
      effect_description = sprintf(
        "the largest difference between two of the means of %s, with the pattern you entered kept and scaled (means %s)",
        spec$variables$Y$label %||% "the outcome", paste(vapply(scaled, function(x) format(signif(x, 3)), character(1)), collapse = ", ")
      ),
      power = power,
      simulated = TRUE
    ),
    curve = data.frame(n = n, power = power, mcse = 0),
    simulations = record
  )
}

# The F test's smallest detectable scale of the pattern of means, exactly
# (Superpower), with every group's SD the root mean square of the groups'
# SDs. A starting point for the simulated search only.
classical_f_scale <- function(spec, n, power) {
  f_test <- spec
  f_test$target_test$method <- "anova_f"
  f_test$population$sd <- sqrt(mean(welch_sds(spec)^2))
  f_test$population$sds <- NULL
  superpower_backend(f_test)$sensitivity(n, power)$scale
}

# The scale at which a probit curve of the rejections on the scale reaches
# the target, and the scales at which its upper and lower 95% confidence
# limits do (NA where they don't within the points simulated).
scale_from_curve <- function(points, target, level = 0.95) {
  if (nrow(points) < 3) {
    return(list(scale = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  fit <- suppressWarnings(stats::glm(
    cbind(rejections, nrep - rejections) ~ scale,
    family = stats::binomial(link = "probit"),
    data = points
  ))
  if (!isTRUE(stats::coef(fit)[["scale"]] > 0)) {
    return(list(scale = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  candidates <- data.frame(scale = seq(min(points$scale), max(points$scale), length.out = 2001))
  link <- stats::predict(fit, candidates, se.fit = TRUE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  first_reaching <- function(p) {
    hit <- which(p >= target)
    if (length(hit) == 0 || hit[1] == 1) NA_real_ else candidates$scale[hit[1]]
  }
  list(
    scale = first_reaching(stats::pnorm(link$fit)),
    lower = first_reaching(stats::pnorm(link$fit + z * link$se.fit)),
    upper = first_reaching(stats::pnorm(link$fit - z * link$se.fit))
  )
}
