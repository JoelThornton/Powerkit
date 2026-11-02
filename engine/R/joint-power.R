#' Joint power for several outcomes of the same randomised comparison
#'
#' When a study compares the same randomised groups on several outcomes,
#' each analysis has its own power, but the chance that all of them are
#' significant together is lower and depends on how the outcomes are
#' correlated. This calculates it with PUMP's `pump_power()` (Hunter,
#' Miratrix and Porter, 2024), for specs that all describe the same design:
#' an independent t-test (PUMP's design `d1.1_m1c`), a cluster-randomised
#' trial (`d2.2_m2rc`, with the same group size and ICC) or a multisite
#' trial, people randomised within each group (`d2.1_m2fr`, the groups'
#' effects varying at random, as powertools' `multisite.cont()` assumes;
#' the same group size and ICCs). Each analysis
#' keeps its own effect size; the sample size is the one the study will
#' recruit, and each analysis is tested at its own significance level with
#' no further adjustment, as on its card. PUMP's complete power counts
#' replications in which every unadjusted test is significant, whichever
#' multiple-testing procedure is requested, so it is the joint power of
#' tests that are each run at their own level.
#'
#' PUMP tests the difference with a t-test that pools the two groups'
#' variances; an independent t-test card in powerkit uses Welch's test, so
#' each outcome's power can differ slightly from its card's (they agree
#' with equal groups to within simulation error). PUMP draws each test
#' statistic as a central t shifted by its noncentrality, as PowerUp!'s
#' formulas do, where powertools uses the noncentral t; with few groups
#' this gives a little less power than the card (docs/conventions.md, Known
#' difference 14).
#'
#' For a multisite trial, powertools' ICCs are shares of the total variance
#' (`icc` of the group means, `icc_effect` of the effect across groups, on
#' a condition coded -1/2 and 1/2), and PUMP's are shares of the variance
#' without the effect's: PUMP's `ICC.2` is `icc / (1 - icc_effect)`, its
#' `omega.2` (the effect's variance over the group means') is
#' `4 icc_effect / icc`, and its effect size is `d / sqrt(1 - icc_effect)`,
#' which gives the noncentrality `multisite.cont()` computes. A baseline
#' score divides d by `sqrt(1 - baseline_r2_within)`, as `multisite.cont()`
#' does with its `Rsq`.
#'
#' @param specs A list of two or more design specs.
#' @param rho The correlation between the outcomes (one number, assumed the
#'   same for every pair), between -1 and 1.
#' @param n The total sample size in people (for a cluster-randomised or
#'   multisite trial, a whole number of groups of `cluster_size`).
#' @param seed Seed for PUMP's simulated test statistics.
#' @param tnum Number of simulated test statistics.
#'
#' @return A list: `each` (each outcome's power), `complete` (the chance
#'   that all are significant), `n`, `rho`, `design` (PUMP's
#'   design code) and `provenance` (backend, function, seed, R and package
#'   versions).
#' @export
joint_power <- function(specs, rho, n, seed = 1L, tnum = 10000L) {
  if (!is.list(specs) || length(specs) < 2) {
    abort_run("Joint power needs two or more analyses.")
  }
  specs <- lapply(specs, function(s) withCallingHandlers(validate_spec(s), powerkit_spec_warning = function(w) invokeRestart("muffleWarning")))
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho <= -1 || rho >= 1) {
    abort_run("The correlation between the outcomes should be a number between -1 and 1.")
  }
  problem <- joint_power_problem(specs)
  if (!is.null(problem)) abort_run(problem)
  first <- specs[[1]]
  pop <- first$population
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 4) {
    abort_run("The sample size should be a whole number of at least 4.")
  }
  m <- length(specs)
  args <- list(
    # PUMP reports complete power only alongside a multiple-testing
    # procedure; it is computed from the unadjusted p-values (PUMP's
    # get_power_results()), so Bonferroni here changes nothing in it.
    MTP = "BF",
    MDES = vapply(specs, function(s) abs(s$population$d), numeric(1)),
    M = m,
    alpha = first$target_test$alpha,
    two.tailed = identical(first$target_test$alternative %||% "two_sided", "two_sided"),
    numCovar.1 = 0, R2.1 = 0,
    rho = rho, tnum = tnum
  )
  if (identical(first$template, "independent_t")) {
    ratio <- first$options$allocation_ratio %||% 1
    args <- c(args, list(d_m = "d1.1_m1c", nbar = n, J = 1, Tbar = ratio / (1 + ratio)))
  } else {
    groups <- n / pop$cluster_size
    if (abs(groups - round(groups)) > 1e-8) {
      abort_run(sprintf("For a %s trial, the sample size should be a whole number of groups of %s.",
        if (identical(first$template, "multisite")) "multisite" else "cluster-randomised", pop$cluster_size))
    }
    args <- c(args, if (identical(first$template, "multisite")) {
      joint_power_multisite_args(pop, round(groups), args$MDES)
    } else {
      list(d_m = "d2.2_m2rc", nbar = pop$cluster_size, J = round(groups), Tbar = 0.5,
        numCovar.2 = 0, R2.2 = 0, ICC.2 = pop$icc)
    })
    args$MDES <- args$MDES * (args$mdes_scale %||% 1)
    args$mdes_scale <- NULL
  }
  out <- with_seed(seed, suppressMessages(do.call(PUMP::pump_power, args)))
  table <- as.data.frame(out)
  none <- table[table$MTP == "None", , drop = FALSE]
  each <- vapply(seq_len(m), function(i) as.numeric(none[[paste0("D", i, "indiv")]]), numeric(1))
  list(
    each = each,
    complete = as.numeric(table$complete[table$MTP == "BF"]),
    n = n,
    rho = rho,
    design = args$d_m,
    provenance = list(
      backend = "PUMP",
      backend_function = "pump_power",
      spec_hashes = vapply(specs, spec_hash, character(1)),
      seed = seed,
      tnum = tnum,
      r_version = R.version.string,
      packages = as.list(package_versions(c("powerkit", "PUMP")))
    )
  )
}

# PUMP's arguments for a multisite trial (d2.1_m2fr), from powertools'
# parameters (see joint_power()). With no variation in the group means
# (icc 0), PUMP's ICC.2 is set just above 0 and omega.2 scaled to keep their
# product, the effect's variance, so the noncentrality is unchanged.
joint_power_multisite_args <- function(pop, groups, mdes) {
  icc1 <- pop$icc_effect %||% 0
  icc2 <- max(pop$icc / (1 - icc1), 1e-8)
  list(
    d_m = "d2.1_m2fr", nbar = pop$cluster_size, J = groups, Tbar = 0.5,
    ICC.2 = icc2, omega.2 = 4 * icc1 / (1 - icc1) / icc2,
    mdes_scale = 1 / sqrt((1 - icc1) * (1 - (pop$baseline_r2_within %||% 0)))
  )
}

# NULL when joint_power() can calculate for these specs, otherwise why not
# (a plain sentence). Used by the app to decide whether to offer it.
joint_power_problem <- function(specs) {
  key <- function(s) paste(s$design, s$template, sep = "/")
  keys <- vapply(specs, key, character(1))
  if (!all(keys %in% c("basic_test/independent_t", "cluster_trial/cluster_randomised", "cluster_trial/multisite"))) {
    return("Joint power is calculated only when every analysis compares the same two randomised groups on a different outcome, with an independent t-test, a cluster-randomised trial or a multisite trial.")
  }
  if (length(unique(keys)) > 1) {
    return("Joint power needs every analysis to have the same design.")
  }
  same <- function(f) length(unique(vapply(specs, function(s) format(f(s) %||% NA), character(1)))) == 1
  if (!same(function(s) s$target_test$alpha) || !same(function(s) s$target_test$alternative %||% "two_sided")) {
    return("Joint power needs every analysis to use the same significance level and the same direction of test.")
  }
  if (!same(function(s) s$options$allocation_ratio %||% 1)) {
    return("Joint power needs every analysis to split people between the groups in the same way.")
  }
  if (!all(vapply(specs, function(s) identical(s$population$metric, "standardised") || identical(s$population$metric, "raw"), logical(1)))) {
    return("Joint power needs each analysis's effect as a difference between the groups' means.")
  }
  if (keys[[1]] %in% c("cluster_trial/cluster_randomised", "cluster_trial/multisite")) {
    if (!same(function(s) s$population$cluster_size) || !same(function(s) s$population$icc) ||
        !same(function(s) s$population$icc_effect)) {
      return("Joint power needs every outcome to have the same group size and intraclass correlations.")
    }
    if (any(vapply(specs, function(s) (s$population$cluster_size_sd %||% 0) > 0, logical(1)))) {
      return("Joint power is calculated for groups of equal size only.")
    }
    # PUMP's covariate model differs from powertools' design effect for a
    # cluster-randomised trial, so a baseline score isn't passed on there.
    if (keys[[1]] == "cluster_trial/cluster_randomised" && any(vapply(specs, has_baseline, logical(1)))) {
      return("Joint power for a cluster-randomised trial is calculated without a baseline score for now: remove it from each analysis to calculate it.")
    }
    if (!same(function(s) s$population$baseline_r2_within)) {
      return("Joint power needs every outcome to have the same baseline score's share of variance explained.")
    }
  }
  NULL
}
