#' Find the sample size for a target power by simulation
#'
#' Searches for the smallest total sample size whose power reaches `power`,
#' following the build guide (section 5): a coarse pass brackets the answer
#' with the backend's exact method, then simulations at several sample sizes
#' around it, each with `nrep` replications, refine it. (With the exact
#' method, [search_n_exact()] is used instead.)
#'
#' The simulated power values are smoothed with a probit regression of the
#' rejection counts on sqrt(n), fitted to the points within 20% of the
#' estimate (for roughly normal test statistics, power is close to
#' pnorm(a + b * sqrt(n))). The required n is the smallest valid n whose
#' fitted power reaches the target. Its 95% interval runs from the smallest
#' n whose upper confidence limit reaches the target to the smallest n whose
#' lower limit does.
#'
#' @param spec A validated spec.
#' @param backend The backend adapter from `route_spec()`.
#' @param power Target power.
#' @param nrep Replications per simulated sample size.
#' @param seed Base seed; each simulated sample size uses a seed derived
#'   from it.
#' @param cores Cores to spread replications over.
#' @param level Confidence level for the interval around the required n.
#'
#' @return A list with `n_required` (list of `n`, `lower`, `upper`) and
#'   `curve` (data frame of `n`, `power` and `mcse` at each simulated n).
#' @keywords internal
search_n <- function(spec, backend, power, nrep, seed, cores = 1L, level = 0.95) {
  step <- backend$n_step
  n_min <- ceiling(minimum_n(spec) / step) * step
  n_start <- ceiling(max(n_min, backend$exact_min_n) / step) * step
  n_guess <- bracket_n(backend$exact_power, power, n_start, step)

  spacing <- step * max(1, round(0.05 * n_guess / step))
  grid <- pmax(n_min, n_guess + spacing * (-3:3))
  points <- data.frame(n = numeric(), rejections = numeric(), nrep = numeric())
  simulate_at <- function(ns) {
    ns <- setdiff(unique(ns), points$n)
    for (n in ns) {
      sim <- backend$simulate(n, nrep, offset_seed(seed, 10007 * nrow(points)), cores)
      points[nrow(points) + 1, ] <<- c(n, sim$rejections, sim$nrep)
    }
  }
  simulate_at(grid)

  # Widen the grid if the interval runs off either end of it, by up to half
  # its edge value each time, so a poor first guess is still recovered.
  to_step <- function(n) pmax(n_min, step * round(n / step))
  for (attempt in 1:6) {
    estimate <- n_from_curve(points, power, step, level)
    high_edge <- is.na(estimate$upper)
    low_edge <- !is.na(estimate$lower) && estimate$lower <= min(points$n) &&
      min(points$n) > n_min
    if (!low_edge && !high_edge) {
      break
    }
    if (high_edge) simulate_at(to_step(max(points$n) * c(1.1, 1.25, 1.5)))
    if (low_edge) simulate_at(to_step(min(points$n) / c(1.1, 1.25, 1.5)))
  }
  # The smooth curve is trusted only near the target: re-centre a local grid
  # on the estimate if needed, and fit to the points within 20% of it.
  estimate <- n_from_curve(points, power, step, level)
  if (!is.na(estimate$n)) {
    near <- function() points[abs(points$n / estimate$n - 1) <= 0.2, ]
    if (nrow(near()) < 5) {
      simulate_at(to_step(estimate$n * (1 + 0.05 * (-3:3))))
    }
    estimate <- n_from_curve(near(), power, step, level)
  }
  if (is.na(estimate$upper)) {
    abort_run("The sample size search could not pin down the required n. Try more replications (options > nrep).")
  }

  points <- points[order(points$n), ]
  p <- points$rejections / points$nrep
  list(
    n_required = estimate,
    curve = data.frame(n = points$n, power = p, mcse = sqrt(p * (1 - p) / points$nrep))
  )
}

# Smallest valid n (a multiple of `step`, at least `n_min`) whose power
# reaches the target: doubling, then bisection.
bracket_n <- function(power_at, target, n_min, step, n_max = 1e5) {
  if (power_at(n_min) >= target) {
    return(n_min)
  }
  low <- n_min
  high <- n_min
  while (power_at(high) < target) {
    low <- high
    high <- high * 2
    if (high > n_max) {
      abort_run(sprintf(
        "Even with %s participants the power stays below %s, so this effect is too small to detect in practice. Check the population values.",
        format(n_max, big.mark = ","), target
      ))
    }
  }
  while (high - low > step) {
    mid <- low + step * floor((high - low) / step / 2)
    if (power_at(mid) >= target) high <- mid else low <- mid
  }
  high
}

n_from_curve <- function(points, target, step, level) {
  fit <- suppressWarnings(stats::glm(
    cbind(rejections, nrep - rejections) ~ sqrt(n),
    family = stats::binomial(link = "probit"),
    data = points
  ))
  candidates <- data.frame(n = seq(min(points$n), max(points$n), by = step))
  link <- stats::predict(fit, candidates, se.fit = TRUE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  first_reaching <- function(p) {
    hit <- which(p >= target)
    if (length(hit) == 0) NA_real_ else candidates$n[hit[1]]
  }
  list(
    n = first_reaching(stats::pnorm(link$fit)),
    lower = first_reaching(stats::pnorm(link$fit + z * link$se.fit)),
    upper = first_reaching(stats::pnorm(link$fit - z * link$se.fit))
  )
}

#' Find the sample size for a target power exactly
#'
#' The smallest valid total sample size whose exact power reaches `power`.
#' There is no Monte Carlo uncertainty, so the interval is the single value.
#'
#' @inheritParams search_n
#' @return As for [search_n()]; `curve` holds exact power (MCSE 0) at the
#'   required n and three valid sizes either side.
#' @keywords internal
search_n_exact <- function(spec, backend, power) {
  step <- backend$n_step
  n_min <- ceiling(minimum_n(spec) / step) * step
  n_start <- ceiling(max(n_min, backend$exact_min_n) / step) * step
  n <- bracket_n(backend$exact_power, power, n_start, step)
  if (n == n_start && n_start > n_min) {
    abort_run(sprintf(
      "This effect reaches the target power with %d or fewer participants, and exact calculation can't go lower here. Set 'options > method' to 'simulation' to find the smallest n.",
      n_start
    ))
  }
  ns <- n + step * (-3:3)
  ns <- ns[ns >= n_start]
  list(
    n_required = list(n = n, lower = n, upper = n),
    curve = data.frame(n = ns, power = vapply(ns, backend$exact_power, numeric(1)), mcse = 0)
  )
}
