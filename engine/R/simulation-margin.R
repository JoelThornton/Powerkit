#' How precise a simulated power is
#'
#' The half-width of a 95% interval around a power (or any chance)
#' estimated from `nrep` simulated studies, `1.96 * sqrt(p * (1 - p) / nrep)`:
#' the usual normal approximation to a binomial proportion's standard
#' error. At the default `power = 0.5` it is the widest the interval can
#' be for that many studies, so a sentence that says "within about" holds
#' whatever the power turns out to be. The app and the engine's advice
#' both take their precision from here, so the same number of studies is
#' never described two ways.
#'
#' @param nrep Number of simulated studies.
#' @param power The power the margin is stated at, between 0 and 1.
#'   0.5 (the default) gives the widest margin.
#' @return The margin, as a proportion (0.031 is 3.1 percentage points).
#' @export
#' @examples
#' simulation_margin(1000)
#' simulation_margin(1000, power = 0.8)
simulation_margin <- function(nrep, power = 0.5) {
  stopifnot(is.numeric(nrep), all(nrep > 0), is.numeric(power), all(power >= 0 & power <= 1))
  1.96 * sqrt(power * (1 - power) / nrep)
}
