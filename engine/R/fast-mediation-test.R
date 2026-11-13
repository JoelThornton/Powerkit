# Monte Carlo intervals for indirect effects, from manymome's own draws --------
#
# power4mome tests each simulated study's indirect effect (mediation), index
# of moderated mediation (PROCESS models 7, 8, 14) or difference between
# conditional indirect effects (models 58, 59, and the "difference" goal)
# with manymome, which builds the Monte Carlo interval from draws of the
# model's parameters (manymome::do_mc(), run by power4test()). manymome's
# general machinery formats labels for every one of the draws, which takes
# about 1.5 seconds per simulated study (measured for PROCESS model 7 at
# n = 300 with 1,000 draws, 93% of the time in index_of_mome(); specialist
# maths review, 13 November 2026), so a required-N search ran for hours.
#
# The functions below compute the same statistic from the same draws: each
# path's coefficient at the moderator's value (b + b_product * w), multiplied
# along the path, so the indirect effect at w; the index is the effect at
# w = 1 minus the effect at w = 0, and the difference the effect at w_to
# minus the effect at w_from, as manymome defines them. The interval is the
# percentile interval manymome itself computes, boot::boot.ci(type =
# "perc"), and a study is significant when it excludes 0, as in power4mome's
# tests. The result is the same to rounding error in every replication
# (test-fast-mediation-test.R), about ten times faster.
#
# Only the Monte Carlo interval of a lavaan fit is computed here. Anything
# else (a bootstrap interval, an OLS fit, a p-value rule), or any model the
# path can't be read from, goes to the original test unchanged.

# The indirect effect along `nodes` (X, the mediators in order, Y) in one
# parameter table, with each path's coefficient taken at w = w_value when a
# product with w moderates it.
mc_path_effect <- function(est, nodes, w = NULL, w_value = 0) {
  prod(vapply(seq_len(length(nodes) - 1), function(i) {
    from <- nodes[[i]]
    to <- nodes[[i + 1]]
    rows <- est$lhs == to & est$op == "~"
    b <- est$est[rows & est$rhs == from]
    if (length(b) != 1) stop("path not found", call. = FALSE)
    if (is.null(w)) return(b)
    product <- est$est[rows & est$rhs %in% c(paste0(from, ":", w), paste0(w, ":", from))]
    if (length(product) > 1) stop("ambiguous product term", call. = FALSE)
    b + if (length(product)) product * w_value else 0
  }, numeric(1)))
}

# The statistic each test reports, from one parameter table.
mc_statistic <- function(kind, est, nodes, w, w_from, w_to) {
  switch(kind,
    indirect = mc_path_effect(est, nodes),
    index = mc_path_effect(est, nodes, w, 1) - mc_path_effect(est, nodes, w, 0),
    difference = mc_path_effect(est, nodes, w, w_to) - mc_path_effect(est, nodes, w, w_from))
}

# A power4mome test function of the given kind that computes the Monte Carlo
# interval directly and hands every other case to `original`.
fast_mediation_test <- function(kind, original) {
  force(kind)
  force(original)
  function(fit = NULL, x = NULL, m = NULL, y = NULL, w = NULL, w_from = -1, w_to = 1,
           mc_ci = TRUE, mc_out = NULL, boot_ci = FALSE, boot_out = NULL,
           check_post_check = TRUE, test_method = "ci", level = 0.95, ...,
           fit_name = "fit", get_map_names = FALSE, get_test_name = FALSE) {
    args <- list(fit = fit, x = x, m = m, y = y, w = w, w_from = w_from, w_to = w_to, mc_ci = mc_ci,
      mc_out = mc_out, boot_ci = boot_ci, boot_out = boot_out, check_post_check = check_post_check,
      test_method = test_method, level = level, fit_name = fit_name,
      get_map_names = get_map_names, get_test_name = get_test_name)
    # The original's own arguments only (power4mome's index test passes
    # anything else on to manymome); `level` goes through its `...`.
    keep <- union(intersect(names(args), names(formals(original))), "level")
    use_original <- function() do.call(original, c(args[keep], list(...)))
    if (get_map_names || get_test_name || isTRUE(boot_ci) || !isTRUE(mc_ci) || is.null(mc_out) ||
        !inherits(fit, "lavaan") || !identical(test_method, "ci") || !requireNamespace("boot", quietly = TRUE)) {
      return(use_original())
    }
    empty <- c(est = NA_real_, cilo = NA_real_, cihi = NA_real_, sig = NA_real_, pvalue = NA_real_)
    fit_ok <- lavaan::lavInspect(fit, "converged") &&
      (suppressWarnings(lavaan::lavInspect(fit, "post.check")) || !check_post_check)
    if (!fit_ok) return(empty)
    nodes <- c(x, m, y)
    out <- tryCatch({
      t0 <- mc_statistic(kind, lavaan::parameterTable(fit), nodes, w, w_from, w_to)
      t <- vapply(mc_out, function(draw) mc_statistic(kind, draw$est, nodes, w, w_from, w_to), numeric(1))
      ci <- boot::boot.ci(list(t0 = t0, t = matrix(t, ncol = 1), R = length(t)), type = "perc", conf = level)$perc[4:5]
      c(est = t0, cilo = ci[1], cihi = ci[2], sig = as.numeric(ci[1] > 0 || ci[2] < 0), pvalue = NA_real_)
    }, error = function(e) NULL)
    if (is.null(out)) use_original() else out
  }
}
