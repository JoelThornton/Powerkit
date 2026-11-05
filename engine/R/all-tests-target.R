#' Per-test power for a claim requiring all tests to succeed
#'
#' With independent rejection events, the equal per-test target is
#' `target^(1/tests)`. Without an independence assumption, the union bound
#' on failure events gives the sufficient target `1 - (1-target)/tests`.
#' Every test must reach at least that marginal power under the same
#' stipulated population. This is a bound, not an estimated joint power,
#' and it does not change significance levels or handle fit failures.
#'
#' @param target Desired probability that all tests succeed, strictly
#'   between zero and one.
#' @param tests Positive integer number of tests.
#' @param dependence `"independent"` or `"unknown"`.
#' @return The equal per-test power target.
#' @references Blitzstein and Hwang (2019), Introduction to Probability,
#'   second edition. doi:10.1201/9780429428357. See the union-bound
#'   derivation in docs/conventions.md.
#' @export
all_tests_target <- function(target, tests, dependence = c("independent", "unknown")) {
  dependence <- match.arg(dependence)
  if (!is.numeric(target) || length(target) != 1 || !is.finite(target) || target <= 0 || target >= 1) {
    abort_spec("The all-tests target must be a probability between 0 and 1.")
  }
  if (!is.numeric(tests) || length(tests) != 1 || !is.finite(tests) || tests < 1 || tests != floor(tests)) {
    abort_spec("The number of tests must be a positive whole number.")
  }
  if (tests == 1) return(target)
  p <- if (dependence == "unknown") 1 - (1 - target) / tests else target^(1 / tests)
  if (p >= 1) abort_spec("This target and number of tests are too close to certainty to represent. Use fewer tests or a lower joint target.")
  p
}
