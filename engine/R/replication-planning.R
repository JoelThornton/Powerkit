# Replication planning (Labs): the sample size a replication needs for
# each of several goals, and the chance of reaching each goal at a chosen
# sample size, from the original study's effect and sample size.
#
# The goals follow Anderson and Maxwell (2016, refs.bib
# Anderson2016_replication): a replication can aim for more than a
# significant result in the original's direction. Every chance and sample
# size for a goal judged against the original's effect is BayesRepDesign's
# (Pawel, Consonni & Held, 2026, refs.bib Pawel2026_replication), which
# works on the normal-normal hierarchical model of that paper: the effect
# estimate is approximately normal with a known standard error, and the
# design prior (what the planner believes about the true effect, given the
# original study) is
#   as reported   designPrior(type = "conditional"): the true effect is
#                 the original estimate (a classical power analysis)
#   uncertain     designPrior(type = "predictive"): the original estimate
#                 with its own uncertainty (a flat initial prior)
#   shrunk        designPrior(type = "EB"): the original estimate shrunk
#                 towards zero, more so the weaker its evidence
# with `tau`, the standard deviation of the true effect between studies
# (paper, "Between-Study Heterogeneity"), for the uncertain and shrunk
# priors. The "as reported" prior is a point mass, so it has none.
#
# The effect scale: d for two groups and one sample, d_z for pairs, and
# Fisher's z for a correlation. Standard errors, as in the paper:
#   two groups (original)   eq. 9, sqrt(1/n1 + 1/n2 + d^2 / (2 (n1 + n2)))
#   two groups (replication) 2 / sqrt(N), N the total, two equal groups
#                           (unit SD 2, BayesRepDesign's se2n() default)
#   one sample or pairs     1 / sqrt(n) (unit SD 1: one person or pair)
#   correlation             1 / sqrt(n - 3), Fisher's z
# so the replication's sample size comes from its standard error.
#
# Any other design whose focal effect is one number ("generic", queue item
# 21; decisions.md, 12 November 2026): the original's estimate and its
# standard error, on a scale where the estimate is roughly normal (the log
# of a ratio, Fisher's z of a correlation, otherwise as reported). The
# standard error may be given, or found from a confidence interval or a z
# or t statistic. A replication of the same design with n people has
# standard error so * sqrt(n_original / n): BayesRepDesign's own relation
# between a standard error and a sample size, se = unitSD / sqrt(n) (its
# se2n() help), with the unit SD that the original's standard error and
# sample size imply. For one sample and pairs this is the exact entry's
# rule, so the two give the same table; for two groups and a correlation
# the exact entries stay (the original's standard error there carries a
# d^2 term, or n - 3, that plain scaling would carry into the
# replication; test-replication-planning.R shows the size). Small
# telescopes needs the original's own test, so it is planned on the
# design's card, not here.
#
# Two goals are planned for a true effect of zero instead: small
# telescopes (Simonsohn, 2015), with the card's own calculation (pwr and
# pwrss, small-telescopes.R) so the two give the same number, and showing
# the effect is too small to matter (TOST), BayesRepDesign's ssdTOST()
# with a design prior at zero.
#
# Success levels follow the paper's worked example ("Labels" experiment,
# its Figure 3): the two-trials rule at one-sided alpha / 2, the pooled
# (fixed-effect meta-analysis) estimate at (alpha / 2)^2, agreement with
# the original by a (1 - 2 alpha) confidence interval for the difference
# (90% at alpha = .05), and Bayes factors at 1 / threshold. Too small to
# matter is the usual TOST at alpha, two one-sided tests each at alpha,
# which is a (1 - 2 alpha) interval inside the margins: porsTOST() and
# ssdTOST() take the interval's level (they use qnorm(1 - level / 2)), so
# they are given 2 alpha, as ssdEqu() is.

replication_designs <- list(
  two_groups = list(template = "independent_t", effect = "d", unit_sd = 2),
  one_sample = list(template = "one_sample_t", effect = "d", unit_sd = 1),
  paired = list(template = "paired_t", effect = "d_z", unit_sd = 1),
  correlation = list(template = "correlation", effect = "r", unit_sd = 1),
  generic = list(template = NULL, effect = "estimate", unit_sd = NA_real_)
)

replication_scales <- c("none", "log", "fisher_z")

# How the original was analysed: a test (frequentist), a Bayes factor
# (t-tests only) or a posterior from a vague or default prior.
replication_analyses <- c("test", "bayes_factor", "posterior")

replication_priors <- c(as_reported = "conditional", uncertain = "predictive", shrunk = "EB")

replication_goal_ids <- c("significance", "pooled", "agreement", "bf_replication", "bf_sceptical",
  "small_telescopes", "negligible")

#' Plan a replication for several goals
#'
#' What the Labs replication planner shows: for an original study's effect
#' and sample size, the sample size a replication needs for each goal
#' (a significant result in the same direction, a significant pooled
#' estimate, agreement with the original, a replication or sceptical Bayes
#' factor, small telescopes, and showing the effect is too small to
#' matter), under three beliefs about the true effect, and the chance of
#' reaching each goal at a chosen sample size. Calculated with
#' BayesRepDesign, except small telescopes (pwr and pwrss, as on the
#' cards).
#'
#' @param design `"two_groups"`, `"one_sample"`, `"paired"`,
#'   `"correlation"`, or `"generic"` for any other design whose focal
#'   effect is one number.
#' @param original_effect The original study's effect as reported: d, d_z
#'   or r; for `"generic"`, the estimate on its reported scale (a ratio as
#'   the ratio, a correlation as r). Not zero (not 1 for a ratio).
#' @param original_n The original study's number of people (or pairs),
#'   for one sample, pairs, a correlation and `"generic"`.
#' @param original_n1,original_n2 The original study's group sizes, for
#'   two groups.
#' @param original_se,original_ci,original_ci_level,original_statistic
#'   For `"generic"`, one of: the estimate's standard error on the
#'   analysis scale (the log of a ratio, Fisher's z of a correlation); its
#'   confidence interval as two numbers on the reported scale, with the
#'   interval's level (0.95 for a 95% interval); or its z or t statistic.
#' @param scale For `"generic"`: `"none"` (the estimate is planned as
#'   reported), `"log"` (a ratio: odds, risk, hazard, rate or variance
#'   ratio, planned on the log scale) or `"fisher_z"` (a correlation).
#' @param effect_name For `"generic"`, what the estimate is, in words (for
#'   the result and the script).
#' @param original_analysis How the original was analysed: `"test"` (a
#'   significance test, the default), `"bayes_factor"` (a default-prior
#'   Bayes factor t-test, for `"two_groups"`, `"one_sample"` and
#'   `"paired"`: its effect is read from `original_bf` and the sample size)
#'   or `"posterior"` (a posterior from a vague or default prior, whose mean
#'   is `original_effect` and whose SD is `original_se`, or whose credible
#'   interval is `original_ci`). Either Bayesian route leaves out small
#'   telescopes and, for a t-test, adds the original's Bayes factor test
#'   repeated (`bf_repeat`, bfpwr) and evidence for no effect (`bf_null`).
#' @param original_bf The original's Bayes factor, as BF10 (evidence for an
#'   effect over none).
#' @param original_prior_scale The scale of the original's Cauchy prior on
#'   the standardised effect (0.707 is the usual default), for reading its
#'   Bayes factor and for repeating its test.
#' @param original_prior For `"posterior"`: `"vague"` or `"default"`; an
#'   informative prior's posterior is refused.
#' @param original_alpha The original study's two-sided significance
#'   level (for small telescopes' d33).
#' @param alpha The replication's two-sided significance level.
#' @param power The chance of success the sample sizes aim for.
#' @param tau How much the true effect varies between studies (a standard
#'   deviation on the effect's scale; Fisher's z for a correlation), for
#'   the uncertain and shrunk beliefs.
#' @param smallest_effect The smallest effect that would matter (d, d_z or
#'   r, positive; for `"generic"`, on the reported scale, a ratio above 1
#'   for a ratio), for the agreement and too-small-to-matter goals; `NULL`
#'   leaves those goals out.
#' @param threshold The evidence threshold: the Bayes factor the replication should reach.
#' @param n A replication sample size (in total, people or pairs) at which
#'   to give the chance of each goal, or `NULL`.
#' @param max_n The largest sample size searched.
#' @return A list: `inputs`; `original` (estimate and standard error on the
#'   analysis scale, z and two-sided p); `priors` (mean and SD of each
#'   belief); `goals`, a data frame of `goal`, `prior` (`NA` for the goals
#'   planned for no effect), `n` (the total sample size needed, `NA` when
#'   not reachable), `per_group`, `ratio` (n over the original's), `limit`
#'   (the highest chance reachable, when the goal cannot reach `power`) and
#'   `reason`; `at_n` (the chance of each goal at `n`); `telescope` (d33
#'   and its calculation, `NULL` for a generic design or a Bayesian
#'   original); `sequential` (for a Bayesian t-test original, each belief as
#'   a design prior for [bayes_sequential()]); `functions_used`; and
#'   `packages`.
#' @export
#' @examples
#' if (requireNamespace("BayesRepDesign", quietly = TRUE)) {
#'   plan <- replication_planning("two_groups", 0.7, original_n1 = 20, original_n2 = 20,
#'     smallest_effect = 0.2)
#'   plan$goals
#'   # An odds ratio of 2.1 (95% CI 1.2 to 3.7) from a logistic regression of 150 people
#'   replication_planning("generic", 2.1, original_n = 150, original_ci = c(1.2, 3.7),
#'     scale = "log", effect_name = "odds ratio")$goals
#' }
replication_planning <- function(design, original_effect, original_n = NULL, original_n1 = NULL,
                                 original_n2 = NULL, original_alpha = 0.05, alpha = 0.05, power = 0.8,
                                 tau = 0, smallest_effect = NULL, threshold = 10, n = NULL,
                                 max_n = 1e5, original_se = NULL, original_ci = NULL,
                                 original_ci_level = 0.95, original_statistic = NULL,
                                 scale = "none", effect_name = NULL, original_analysis = "test",
                                 original_bf = NULL, original_prior_scale = 1 / sqrt(2),
                                 original_prior = NULL) {
  if (!requireNamespace("BayesRepDesign", quietly = TRUE)) {
    abort_run("The replication planner needs the R package BayesRepDesign. Install it with install.packages(\"BayesRepDesign\").")
  }
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x, low) one_number(x) && x == round(x) && x >= low && x <= 1e6
  if (!is.character(design) || length(design) != 1 || !design %in% names(replication_designs)) {
    abort_run("'design' should be \"two_groups\", \"one_sample\", \"paired\", \"correlation\" or \"generic\".")
  }
  rule <- replication_designs[[design]]
  generic <- identical(design, "generic")
  correlation <- identical(design, "correlation")
  if (!is.character(original_analysis) || length(original_analysis) != 1 ||
      !original_analysis %in% replication_analyses) {
    abort_run("'original_analysis' should be \"test\", \"bayes_factor\" or \"posterior\".")
  }
  bayes <- !identical(original_analysis, "test")
  from_bf <- identical(original_analysis, "bayes_factor")
  posterior <- identical(original_analysis, "posterior")
  t_test <- design %in% c("two_groups", "one_sample", "paired")
  if (from_bf && !t_test) {
    abort_run(paste("A Bayes factor gives the original's effect only for a t-test (two groups, one group or pairs).",
      "For another analysis, give its posterior, if its prior was vague or a default one, or its estimate with a standard error."))
  }
  if (bayes && t_test && (!one_number(original_prior_scale) || original_prior_scale <= 0 || original_prior_scale > 5)) {
    abort_run("The scale of the original's prior should be more than 0 and at most 5; 0.707 is the usual default.")
  }
  if (posterior) {
    if (!is.character(original_prior) || length(original_prior) != 1 || !original_prior %in% c("vague", "default")) {
      abort_run(paste("A posterior can stand in for the original's estimate only when its prior was vague or a default one:",
        "an informative prior's posterior mixes the prior's beliefs into the original's evidence.",
        "Plan from the original's estimate and standard error, or its Bayes factor, instead."))
    }
    if (!is.null(original_statistic) || (is.null(original_se) + is.null(original_ci)) != 1) {
      abort_run("Give the posterior's standard deviation or its credible interval, one of the two.")
    }
  }
  if (generic) {
    original <- replication_generic_original(original_effect, original_n, original_se, original_ci,
      original_ci_level, original_statistic, scale)
    tf <- replication_transform(scale)
  } else if (!from_bf && (!one_number(original_effect) || original_effect == 0 ||
      (correlation && abs(original_effect) >= 1) || abs(original_effect) > 5)) {
    abort_run(if (correlation) {
      "The original correlation should be between -1 and 1, and not 0."
    } else {
      "The original effect should be a standardised effect between -5 and 5, and not 0."
    })
  }
  if (generic) {
    NULL
  } else if (identical(design, "two_groups")) {
    if (!whole(original_n1, 2) || !whole(original_n2, 2)) {
      abort_run("The original study's two group sizes should be whole numbers, at least 2 each.")
    }
  } else if (!whole(original_n, if (correlation) 4 else 2)) {
    abort_run(sprintf("The original study's number of %s should be a whole number, at least %s.",
      if (identical(design, "paired")) "pairs" else "people", if (correlation) 4 else 2))
  }
  # A Bayes factor and the original's sample size give its t statistic,
  # and so its effect (Ly et al., 2018).
  converted <- if (from_bf) {
    replication_bf_to_t(original_bf, design, original_n, original_n1, original_n2, original_prior_scale)
  }
  if (from_bf) original_effect <- converted$d
  for (level in list(list(original_alpha, "original study's"), list(alpha, "replication's"))) {
    if (!one_number(level[[1]]) || level[[1]] <= 0 || level[[1]] >= 0.5) {
      abort_run(sprintf("The %s significance level should be between 0 and 0.5, for example 0.05.", level[[2]]))
    }
  }
  if (!one_number(power) || power <= alpha / 2 || power >= 1) {
    abort_run("The chance of success to aim for should be between the significance level and 1, for example 0.8.")
  }
  if (!one_number(tau) || tau < 0 || tau > 2) {
    abort_run("How much the effect varies between studies should be 0 or more, and at most 2.")
  }
  if (generic && !is.null(smallest_effect)) {
    if (!one_number(smallest_effect) || (identical(scale, "log") && smallest_effect <= 1) ||
        (!identical(scale, "log") && smallest_effect <= 0) || (identical(scale, "fisher_z") && smallest_effect >= 1)) {
      abort_run(switch(scale,
        log = "The smallest effect that would matter should be a ratio above 1, such as 1.2.",
        fisher_z = "The smallest effect that would matter should be a correlation between 0 and 1.",
        "The smallest effect that would matter should be more than 0, on the effect's own scale."))
    }
  } else if (!is.null(smallest_effect) && (!one_number(smallest_effect) || smallest_effect <= 0 ||
      (correlation && smallest_effect >= 1) || smallest_effect > 5)) {
    abort_run("The smallest effect that would matter should be more than 0 (and below 1 for a correlation).")
  }
  if (!one_number(threshold) || threshold <= 1 || threshold > 1000) {
    abort_run("The evidence threshold (the Bayes factor the replication should reach) should be above 1, and at most 1,000.")
  }
  if (!is.null(n) && !whole(n, if (correlation) 4 else 2)) {
    abort_run("The replication's sample size should be a whole number of people.")
  }

  # The original estimate and its standard error on the analysis scale.
  if (!generic) original <- if (identical(design, "two_groups")) {
    list(estimate = original_effect, n = original_n1 + original_n2,
      se = sqrt((original_n1 + original_n2) / (original_n1 * original_n2) +
        original_effect^2 / (2 * (original_n1 + original_n2))))
  } else if (correlation) {
    list(estimate = atanh(original_effect), n = original_n, se = 1 / sqrt(original_n - 3))
  } else {
    list(estimate = original_effect, n = original_n, se = 1 / sqrt(original_n))
  }
  # An original analysed with a vague or default prior: its posterior mean
  # and SD stand in for the estimate and its standard error (McLatchie,
  # Warmelink & Tkacheva, 2020). A correlation's SD is moved to Fisher's z.
  if (posterior && !generic) {
    post <- replication_generic_original(original_effect, original$n, original_se, original_ci,
      original_ci_level, NULL, if (correlation) "fisher_z" else "none")
    original$se <- if (correlation && identical(post$from, "se")) original_se / (1 - original_effect^2) else post$se
    original$from <- post$from
  }
  if (from_bf) original[c("bf", "t", "bf_from")] <- list(original_bf, converted$t, "bayes_factor")
  original$z <- original$estimate / original$se
  original$p <- 2 * stats::pnorm(-abs(original$z))
  on_scale <- if (generic) tf else function(x) if (correlation) atanh(x) else x
  margin <- if (!is.null(smallest_effect)) on_scale(smallest_effect)

  # Standard error and sample size, both ways (n is the total). A generic
  # design scales the original's standard error by sqrt(n_original / n).
  se_at <- function(n) {
    if (generic) original$se * sqrt(original$n / n) else if (correlation) 1 / sqrt(n - 3) else rule$unit_sd / sqrt(n)
  }
  n_at <- function(se) {
    raw <- if (generic) original$n * (original$se / se)^2 else if (correlation) 1 / se^2 + 3 else rule$unit_sd^2 / se^2
    if (identical(design, "two_groups")) 2 * ceiling(raw / 2 - 1e-9) else max(2, ceiling(raw - 1e-9))
  }

  priors <- lapply(replication_priors, function(type) {
    call_backend("BayesRepDesign", BayesRepDesign::designPrior(to = original$estimate, so = original$se,
      tau = if (identical(type, "conditional")) 0 else tau, type = type))
  })
  at_zero <- call_backend("BayesRepDesign", BayesRepDesign::designPrior(to = 0, so = original$se,
    type = "conditional"))

  # Each goal: its sample size search (ssd*) and chance at a standard error
  # (pors*), as the package's functions with the levels above.
  bf_level <- 1 / threshold
  rules <- list(
    significance = list(ssd = function(dp) BayesRepDesign::ssdSig(level = alpha / 2, dprior = dp, power = power),
      pors = function(dp, sr) BayesRepDesign::porsSig(level = alpha / 2, dprior = dp, sr = sr),
      call = sprintf("ssdSig(level = %s)", format(alpha / 2))),
    pooled = list(ssd = function(dp) BayesRepDesign::ssdMeta(level = (alpha / 2)^2, dprior = dp, power = power,
        searchInt = c(1e-6, 10)),
      pors = function(dp, sr) BayesRepDesign::porsMeta(level = (alpha / 2)^2, dprior = dp, sr = sr),
      call = sprintf("ssdMeta(level = %s)", format(signif((alpha / 2)^2, 4)))),
    agreement = if (!is.null(margin)) list(
      ssd = function(dp) BayesRepDesign::ssdEqu(level = 2 * alpha, dprior = dp, power = power, margin = margin),
      pors = function(dp, sr) BayesRepDesign::porsEqu(level = 2 * alpha, dprior = dp, margin = margin, sr = sr),
      call = sprintf("ssdEqu(level = %s, margin = %s)", format(2 * alpha), format(signif(margin, 4)))),
    bf_replication = list(ssd = function(dp) BayesRepDesign::ssdBFr(level = bf_level, dprior = dp, power = power),
      pors = function(dp, sr) BayesRepDesign::porsBFr(level = bf_level, dprior = dp, sr = sr),
      call = sprintf("ssdBFr(level = 1/%s)", format(threshold))),
    bf_sceptical = list(ssd = function(dp) BayesRepDesign::ssdBFs(level = bf_level, dprior = dp, power = power),
      pors = function(dp, sr) BayesRepDesign::porsBFs(level = bf_level, dprior = dp, sr = sr),
      call = sprintf("ssdBFs(level = 1/%s)", format(threshold)))
  )
  rules <- Filter(Negate(is.null), rules)

  # A search's sample size, or why there is none: the package warns when a
  # chance can't reach `power` however large the study, and says the most.
  search <- function(run, limit_of) {
    warned <- NULL
    out <- withCallingHandlers(
      tryCatch(run(), error = function(e) NULL),
      warning = function(w) {
        warned <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    )
    sr <- if (is.list(out)) out$sr else NA_real_
    if (is.numeric(sr) && length(sr) == 1 && is.finite(sr) && sr > 0) {
      size <- n_at(sr)
      if (size <= max_n) return(list(n = size, limit = NA_real_, reason = NA_character_))
      return(list(n = NA_real_, limit = NA_real_, reason = "over_max"))
    }
    # Not reachable: the chance with a very large replication.
    list(n = NA_real_, limit = limit_of(), reason = if (is.null(warned)) "not_found" else "not_reachable")
  }
  huge_se <- se_at(max_n)

  rows <- list()
  for (goal in names(rules)) {
    for (prior in names(priors)) {
      dp <- priors[[prior]]
      found <- search(function() rules[[goal]]$ssd(dp),
        function() tryCatch(rules[[goal]]$pors(dp, huge_se), error = function(e) NA_real_))
      rows[[length(rows) + 1]] <- data.frame(goal = goal, prior = prior, n = found$n,
        limit = found$limit, reason = found$reason)
    }
  }

  # Planned for no effect: showing the effect is too small to matter.
  negligible <- if (!is.null(margin)) {
    tost <- function(sr) BayesRepDesign::porsTOST(level = 2 * alpha, dprior = at_zero, margin = margin, sr = sr)
    found <- search(function() BayesRepDesign::ssdTOST(level = 2 * alpha, dprior = at_zero, power = power,
      margin = margin, searchInt = c(1e-6, 2)), function() tost(huge_se))
    rows[[length(rows) + 1]] <- data.frame(goal = "negligible", prior = NA_character_, n = found$n,
      limit = found$limit, reason = found$reason)
    tost
  }

  # Small telescopes: the card's calculation, so both give one number. A
  # generic design plans it on its own card, which knows the original's test.
  telescopes <- !generic && !bayes
  telescope <- if (telescopes) replication_telescope(design, original_effect, original_n,
    original_n1, original_n2, original_alpha, alpha, power)
  # An original analysed with Bayes factors (a t-test): its Bayes factor
  # test repeated, for an effect under each belief and for no effect, with
  # bfpwr (Pawel & Held). Counted in each group for two groups.
  bf_type <- switch(design, two_groups = "two.sample", one_sample = "one.sample", paired = "paired", NA_character_)
  per_unit <- if (identical(design, "two_groups")) 2 else 1
  bf_tests <- if (bayes && t_test) list(
    bf_repeat = function(dp, n, need = NULL) {
      args <- list(k = 1 / threshold, pscale = original_prior_scale, type = bf_type,
        dpm = dp$dpMean, dpsd = sqrt(dp$dpVar))
      if (is.null(need)) do.call(bfpwr::ptbf01, c(args, list(n = n / per_unit))) else
        do.call(bfpwr::ntbf01, c(args, list(power = need, nrange = c(2, max_n / per_unit))))
    },
    bf_null = function(dp, n, need = NULL) {
      args <- list(k = threshold, pscale = original_prior_scale, type = bf_type, dpm = 0, dpsd = 0,
        lower.tail = FALSE)
      if (is.null(need)) do.call(bfpwr::ptbf01, c(args, list(n = n / per_unit))) else
        do.call(bfpwr::ntbf01, c(args, list(power = need, nrange = c(2, max_n / per_unit))))
    }
  )
  bf_search <- function(test, dp) {
    warned <- FALSE
    out <- withCallingHandlers(tryCatch(test(dp, NULL, power), error = function(e) NA_real_),
      warning = function(w) {
        warned <<- TRUE
        invokeRestart("muffleWarning")
      })
    if (!warned && is.numeric(out) && length(out) == 1 && is.finite(out)) {
      return(list(n = per_unit * out, limit = NA_real_, reason = NA_character_))
    }
    list(n = NA_real_, limit = tryCatch(test(dp, max_n), error = function(e) NA_real_),
      reason = if (warned) "not_reachable" else "not_found")
  }
  for (goal in names(bf_tests)) {
    for (prior in if (identical(goal, "bf_null")) NA_character_ else names(priors)) {
      found <- bf_search(bf_tests[[goal]], if (is.na(prior)) NULL else priors[[prior]])
      rows[[length(rows) + 1]] <- data.frame(goal = goal, prior = prior, n = found$n,
        limit = found$limit, reason = found$reason)
    }
  }

  if (telescopes) rows[[length(rows) + 1]] <- data.frame(goal = "small_telescopes", prior = NA_character_, n = telescope$n,
    limit = NA_real_, reason = NA_character_)

  goals <- do.call(rbind, rows)
  goals$per_group <- if (identical(design, "two_groups")) goals$n / 2 else NA_real_
  goals$ratio <- goals$n / original$n

  at_n <- if (!is.null(n)) {
    sr <- se_at(n)
    chance <- list()
    for (goal in names(rules)) {
      for (prior in names(priors)) {
        chance[[length(chance) + 1]] <- data.frame(goal = goal, prior = prior,
          chance = call_backend("BayesRepDesign", rules[[goal]]$pors(priors[[prior]], sr)))
      }
    }
    if (is.function(negligible)) {
      chance[[length(chance) + 1]] <- data.frame(goal = "negligible", prior = NA_character_,
        chance = call_backend("BayesRepDesign", negligible(sr)))
    }
    for (goal in names(bf_tests)) {
      for (prior in if (identical(goal, "bf_null")) NA_character_ else names(priors)) {
        chance[[length(chance) + 1]] <- data.frame(goal = goal, prior = prior,
          chance = call_backend("bfpwr", bf_tests[[goal]](if (is.na(prior)) NULL else priors[[prior]], n)))
      }
    }
    if (telescopes) chance[[length(chance) + 1]] <- data.frame(goal = "small_telescopes", prior = NA_character_,
      chance = telescope$power_at(n))
    do.call(rbind, chance)
  }

  list(
    inputs = list(design = design, original_effect = original_effect, original_n = original_n,
      original_n1 = original_n1, original_n2 = original_n2, original_alpha = original_alpha, alpha = alpha,
      power = power, tau = tau, smallest_effect = smallest_effect, threshold = threshold, n = n,
      original_se = original_se, original_ci = original_ci, original_ci_level = original_ci_level,
      original_statistic = original_statistic, scale = scale, effect_name = effect_name,
      original_analysis = original_analysis, original_bf = original_bf,
      original_prior_scale = if (bayes && t_test) original_prior_scale, original_prior = original_prior),
    effect_name = if (generic) effect_name %||% "estimate" else rule$effect,
    scale = if (generic) switch(scale, log = "log", fisher_z = "Fisher's z", "as reported") else if (correlation) "Fisher's z" else rule$effect,
    original = original,
    priors = data.frame(prior = names(priors),
      mean = vapply(priors, function(dp) dp$dpMean, numeric(1)),
      sd = vapply(priors, function(dp) sqrt(dp$dpVar), numeric(1)),
      tau = vapply(priors, function(dp) dp$tau, numeric(1)), row.names = NULL),
    goals = goals,
    at_n = at_n,
    # The sequential Bayes factor design (bayes_sequential()) for the
    # replication: each belief as its design prior, on the original's prior.
    sequential = if (bayes && t_test) data.frame(prior = names(priors), type = bf_type,
      effect = vapply(priors, function(dp) dp$dpMean, numeric(1)),
      effect_sd = vapply(priors, function(dp) sqrt(dp$dpVar), numeric(1)),
      prior_scale = original_prior_scale, row.names = NULL),
    telescope = if (telescopes) telescope[c("effect", "effect_name", "function_used", "n")],
    functions_used = c(
      vapply(rules, function(r) paste0("BayesRepDesign::", r$call), character(1)),
      if (!is.null(margin)) c(negligible = sprintf("BayesRepDesign::ssdTOST(level = %s, margin = %s), design prior at 0",
        format(2 * alpha), format(signif(margin, 4)))),
      if (telescopes) c(small_telescopes = telescope$function_used),
      if (length(bf_tests)) c(
        bf_repeat = sprintf("bfpwr::ntbf01(k = 1/%s, pscale = %s, type = \"%s\"), design prior from each belief",
          format(threshold), format(signif(original_prior_scale, 4)), bf_type),
        bf_null = sprintf("bfpwr::ntbf01(k = %s, pscale = %s, type = \"%s\", dpm = 0, dpsd = 0, lower.tail = FALSE)",
          format(threshold), format(signif(original_prior_scale, 4)), bf_type))
    ),
    packages = c(
      list(list(name = "BayesRepDesign", version = as.character(utils::packageVersion("BayesRepDesign")))),
      if (telescopes) list(
        list(name = "pwr", version = as.character(utils::packageVersion("pwr"))),
        list(name = "pwrss", version = as.character(utils::packageVersion("pwrss")))),
      if (length(bf_tests)) list(
        list(name = "bfpwr", version = as.character(utils::packageVersion("bfpwr")))),
      if (from_bf) list(
        list(name = "BayesFactor", version = as.character(utils::packageVersion("BayesFactor"))))
    )
  )
}

# A generic design's scale: the reported estimate to the analysis scale.
replication_transform <- function(scale) {
  switch(scale, log = log, fisher_z = atanh, function(x) x)
}

# A generic design's original estimate and standard error on the analysis
# scale, from a standard error, a confidence interval (on the reported
# scale) or a z or t statistic, checked.
replication_generic_original <- function(effect, n, se = NULL, ci = NULL, ci_level = 0.95, statistic = NULL,
                                         scale = "none") {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  if (!is.character(scale) || length(scale) != 1 || !scale %in% replication_scales) {
    abort_run("'scale' should be \"none\", \"log\" or \"fisher_z\".")
  }
  if (!one_number(effect) || !is.finite(effect) ||
      (identical(scale, "log") && (effect <= 0 || effect == 1)) ||
      (identical(scale, "fisher_z") && (abs(effect) >= 1 || effect == 0)) ||
      (identical(scale, "none") && effect == 0)) {
    abort_run(switch(scale,
      log = "The original ratio should be more than 0, and not 1 (no effect).",
      fisher_z = "The original correlation should be between -1 and 1, and not 0.",
      "The original effect should be a number, and not 0."))
  }
  if (!one_number(n) || n != round(n) || n < 2 || n > 1e6) {
    abort_run("The original study's sample size should be a whole number, at least 2.")
  }
  tf <- replication_transform(scale)
  estimate <- tf(effect)
  given <- c(se = !is.null(se), ci = !is.null(ci), statistic = !is.null(statistic))
  if (sum(given) != 1) {
    abort_run("Give one of the original estimate's standard error, its confidence interval, or its test statistic.")
  }
  if (given[["se"]]) {
    if (!one_number(se) || se <= 0 || !is.finite(se)) abort_run("The standard error should be more than 0.")
  } else if (given[["ci"]]) {
    if (!is.numeric(ci) || length(ci) != 2 || anyNA(ci) || ci[1] >= ci[2] ||
        (identical(scale, "log") && ci[1] <= 0) || (identical(scale, "fisher_z") && any(abs(ci) >= 1))) {
      abort_run(switch(scale,
        log = "The confidence interval should be two ratios above 0, the lower one first.",
        fisher_z = "The confidence interval should be two correlations between -1 and 1, the lower one first.",
        "The confidence interval should be two numbers, the lower one first."))
    }
    if (!one_number(ci_level) || ci_level <= 0.5 || ci_level >= 1) {
      abort_run("The interval's level should be between 0.5 and 1, for example 0.95 for a 95% interval.")
    }
    if (effect < ci[1] || effect > ci[2]) abort_run("The original estimate should lie inside its confidence interval.")
    se <- (tf(ci[2]) - tf(ci[1])) / (2 * stats::qnorm(1 - (1 - ci_level) / 2))
  } else {
    if (!one_number(statistic) || statistic == 0 || !is.finite(statistic)) {
      abort_run("The test statistic should be a number, and not 0.")
    }
    se <- abs(estimate / statistic)
  }
  list(estimate = estimate, n = n, se = se,
    from = names(given)[given])
}

# The script for a generic design: the goals judged against the original's
# effect, from its estimate and standard error (no small telescopes).
replication_generic_script <- function(plan, num, tf_call, margin) {
  i <- plan$inputs
  post <- identical(i$original_analysis, "posterior")
  so_line <- switch(plan$original$from,
    se = sprintf("so <- %s  # its %s, as reported", num(i$original_se), if (post) "posterior SD" else "standard error"),
    ci = sprintf("so <- (%s - %s) / (2 * qnorm(1 - (1 - %s) / 2))  # from its %s%% %s interval",
      tf_call(num(i$original_ci[2])), tf_call(num(i$original_ci[1])), num(i$original_ci_level), num(100 * i$original_ci_level),
      if (post) "credible" else "confidence"),
    statistic = sprintf("so <- abs(to / %s)  # from its test statistic", num(i$original_statistic)))
  c(
    "# Replication plan, from powerkit's replication plan.",
    "# Every goal judged against the original's effect: BayesRepDesign (Pawel, Consonni & Held, 2026).",
    sprintf("# The original's effect: %s, planned %s.", plan$effect_name,
      switch(i$scale, log = "on the log scale", fisher_z = "on Fisher's z scale", "as reported")),
    "# A replication of the same design with n people has standard error so * sqrt(n_original / n).",
    if (post) sprintf("# The original's posterior (%s prior) stands in for its estimate and standard error.", i$original_prior),
    sprintf("# Written by powerkit %s on %s.", as.character(utils::packageVersion("powerkit")), format(Sys.Date())),
    "library(BayesRepDesign)",
    "",
    "# The original study",
    sprintf("n_original <- %s", i$original_n),
    sprintf("to <- %s", tf_call(num(i$original_effect))),
    so_line,
    "n_from_se <- function(se) max(2, ceiling(n_original * (so / se)^2 - 1e-9))",
    sprintf("alpha <- %s; power <- %s; tau <- %s", num(i$alpha), num(i$power), num(i$tau)),
    if (!is.null(margin)) sprintf("margin <- %s  # the smallest effect that matters", margin),
    "",
    "# The three beliefs about the true effect (design priors)",
    "priors <- list(",
    "  as_reported = designPrior(to = to, so = so, type = \"conditional\"),",
    "  uncertain = designPrior(to = to, so = so, tau = tau, type = \"predictive\"),",
    "  shrunk = designPrior(to = to, so = so, tau = tau, type = \"EB\")",
    ")",
    "",
    "# The sample size for each goal and belief; NA when no replication can reach it",
    "size <- function(found) if (is.finite(found$sr)) n_from_se(found$sr) else NA",
    "sapply(priors, function(dp) c(",
    "  significance = size(ssdSig(level = alpha / 2, dprior = dp, power = power)),",
    "  pooled = size(ssdMeta(level = (alpha / 2)^2, dprior = dp, power = power, searchInt = c(1e-6, 10))),",
    if (!is.null(margin)) "  agreement = size(ssdEqu(level = 2 * alpha, dprior = dp, power = power, margin = margin)),",
    sprintf("  bf_replication = size(ssdBFr(level = 1/%s, dprior = dp, power = power)),", num(i$threshold)),
    sprintf("  bf_sceptical = size(ssdBFs(level = 1/%s, dprior = dp, power = power))", num(i$threshold)),
    "))",
    if (!is.null(margin)) c("",
      "# Too small to matter: the usual TOST at alpha (a 1 - 2 alpha interval), planned for no effect",
      "size(ssdTOST(level = 2 * alpha, dprior = designPrior(to = 0, so = so, type = \"conditional\"), power = power, margin = margin, searchInt = c(1e-6, 2)))")
  ) |> paste(collapse = "\n")
}

# Small telescopes for the planner: the small-telescopes card's own spec,
# run by run_spec(), so the planner and the card agree.
replication_telescope <- function(design, original_effect, original_n, original_n1, original_n2,
                                  original_alpha, alpha, power) {
  rule <- replication_designs[[design]]
  sizes <- if (identical(design, "two_groups")) list(n1 = original_n1, n2 = original_n2) else list(n = original_n)
  spec <- jsonlite::read_json(system.file("specs", paste0(rule$template, ".json"), package = "powerkit"))
  spec$population[[switch(design, paired = "dz", correlation = "r", "d")]] <- original_effect
  spec$effect_justification <- list(type = "prior_study", source = "The original study",
    small_telescopes = c(sizes, list(alpha = original_alpha)))
  if (identical(design, "two_groups")) spec$target_test$method <- "student_t"
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "sample_size", power = power)
  spec$options$attrition <- NULL
  result <- run_spec(spec)
  backend <- telescope_backend(spec)
  st <- result$small_telescopes
  list(
    n = result$n_required$n,
    effect = st$effect, effect_name = st$effect_name,
    function_used = sprintf("small telescopes: %s; %s", st$function_used, backend$functions[["exact"]]),
    power_at = function(n) backend$exact_power(n)
  )
}

#' R script for a replication plan
#'
#' A script that redoes [replication_planning()]'s numbers with
#' BayesRepDesign, pwr and pwrss alone, for the reader of a plan.
#'
#' @param plan What [replication_planning()] returned.
#' @return The script, as one string.
#' @export
#' @examples
#' if (requireNamespace("BayesRepDesign", quietly = TRUE)) {
#'   plan <- replication_planning("two_groups", 0.7, original_n1 = 20, original_n2 = 20,
#'     smallest_effect = 0.2)
#'   cat(replication_planning_script(plan))
#' }
replication_planning_script <- function(plan) {
  i <- plan$inputs
  num <- function(x) format(signif(x, 8))
  correlation <- identical(i$design, "correlation")
  two <- identical(i$design, "two_groups")
  generic <- identical(i$design, "generic")
  tf_call <- function(x) {
    if (generic) switch(i$scale, log = sprintf("log(%s)", x), fisher_z = sprintf("atanh(%s)", x), x)
    else if (correlation) sprintf("atanh(%s)", x) else x
  }
  margin <- if (!is.null(i$smallest_effect)) tf_call(num(i$smallest_effect))
  if (generic) {
    return(replication_generic_script(plan, num, tf_call, margin))
  }
  analysis <- i$original_analysis %||% "test"
  from_bf <- identical(analysis, "bayes_factor")
  post <- identical(analysis, "posterior")
  bayes <- from_bf || post
  bf_type <- switch(i$design, two_groups = "two.sample", one_sample = "one.sample", paired = "paired", NA_character_)
  # The original's effect: as reported, or read from its Bayes factor.
  to_lines <- if (from_bf) c(
    sprintf("bf10 <- %s; rscale <- %s  # the original's Bayes factor and its Cauchy prior scale", num(i$original_bf), num(i$original_prior_scale)),
    sprintf("log_bf <- function(t) BayesFactor::ttest.tstat(t, %s, rscale = rscale)$bf", if (two) "n1, n2" else sprintf("%s, 0", i$original_n)),
    "hi <- 1; while (log_bf(hi) < log(bf10)) hi <- 2 * hi",
    "t_original <- uniroot(function(t) log_bf(t) - log(bf10), c(0, hi), tol = 1e-10)$root  # its t statistic",
    sprintf("to <- t_original * %s  # its standardised effect", if (two) "sqrt(1 / n1 + 1 / n2)" else sprintf("1 / sqrt(%s)", i$original_n)))
  else sprintf("to <- %s", if (correlation) sprintf("atanh(%s)  # Fisher's z", num(i$original_effect)) else num(i$original_effect))
  # Its standard error: from the design, or the posterior's (vague or default prior).
  so_post <- if (post) {
    if (!is.null(i$original_ci)) {
      sprintf("so <- (%s - %s) / (2 * qnorm(1 - (1 - %s) / 2))  # from its %s%% credible interval",
        tf_call(num(i$original_ci[2])), tf_call(num(i$original_ci[1])), num(i$original_ci_level), num(100 * i$original_ci_level))
    } else if (correlation) {
      sprintf("so <- %s / (1 - %s^2)  # its posterior SD, moved to Fisher's z", num(i$original_se), num(i$original_effect))
    } else sprintf("so <- %s  # its posterior SD", num(i$original_se))
  }
  telescope_call <- switch(i$design,
    two_groups = sprintf("pwr::pwr.t2n.test(n1 = %s, n2 = %s, power = 1/3, sig.level = original_alpha)$d", i$original_n1, i$original_n2),
    correlation = sprintf("pwr::pwr.r.test(n = %s, power = 1/3, sig.level = original_alpha)$r", i$original_n),
    sprintf("pwr::pwr.t.test(n = %s, power = 1/3, sig.level = original_alpha, type = \"%s\")$d", i$original_n,
      if (identical(i$design, "paired")) "paired" else "one.sample"))
  telescope_power <- if (correlation) {
    "pwrss::power.z.onecor(rho = 0, null.rho = yardstick, n = n, alpha = alpha, alternative = \"one.sided\", verbose = 0)$power"
  } else if (two) {
    "pwrss::power.t.student(d = 0, margin = yardstick, n2 = n / 2, n.ratio = 1, alpha = alpha, alternative = \"one.sided\", design = \"independent\", verbose = 0)$power"
  } else {
    sprintf("pwrss::power.t.student(d = 0, margin = yardstick, n2 = n, alpha = alpha, alternative = \"one.sided\", design = \"%s\", verbose = 0)$power",
      if (identical(i$design, "paired")) "paired" else "one.sample")
  }
  c(
    "# Replication plan, from powerkit's replication plan.",
    "# Every goal judged against the original's effect: BayesRepDesign (Pawel, Consonni & Held, 2026).",
    if (!bayes) "# Small telescopes (Simonsohn, 2015): pwr for d33 (or r33) and pwrss for the replication's test.",
    if (from_bf) "# The original's effect from its Bayes factor and sample size (BayesFactor's ttest.tstat(), inverted).",
    if (post) sprintf("# The original's posterior (%s prior) stands in for its estimate and standard error.", i$original_prior),
    if (bayes && !is.na(bf_type)) "# The original's Bayes factor test repeated: bfpwr (Pawel & Held).",
    sprintf("# Written by powerkit %s on %s.", as.character(utils::packageVersion("powerkit")), format(Sys.Date())),
    "library(BayesRepDesign)",
    "",
    "# The original study",
    if (two) c(sprintf("n1 <- %s; n2 <- %s", i$original_n1, i$original_n2),
      to_lines,
      so_post %||% "so <- sqrt((n1 + n2) / (n1 * n2) + to^2 / (2 * (n1 + n2)))  # Pawel et al., eq. 9",
      "n_from_se <- function(se) 2 * ceiling(se2n(se, unitSD = 2) / 2 - 1e-9)  # two equal groups, in total")
    else if (correlation) c(to_lines,
      so_post %||% sprintf("so <- 1 / sqrt(%s - 3)", i$original_n),
      "n_from_se <- function(se) ceiling(1 / se^2 + 3 - 1e-9)")
    else c(to_lines, so_post %||% sprintf("so <- 1 / sqrt(%s)", i$original_n),
      "n_from_se <- function(se) ceiling(se2n(se, unitSD = 1) - 1e-9)"),
    if (bayes) sprintf("alpha <- %s; power <- %s; tau <- %s", num(i$alpha), num(i$power), num(i$tau))
    else sprintf("original_alpha <- %s; alpha <- %s; power <- %s; tau <- %s", num(i$original_alpha), num(i$alpha), num(i$power), num(i$tau)),
    if (!is.null(margin)) sprintf("margin <- %s  # the smallest effect that matters", margin),
    "",
    "# The three beliefs about the true effect (design priors)",
    "priors <- list(",
    "  as_reported = designPrior(to = to, so = so, type = \"conditional\"),",
    "  uncertain = designPrior(to = to, so = so, tau = tau, type = \"predictive\"),",
    "  shrunk = designPrior(to = to, so = so, tau = tau, type = \"EB\")",
    ")",
    "",
    "# The sample size (in total) for each goal and belief; NA when no replication can reach it",
    "size <- function(found) if (is.finite(found$sr)) n_from_se(found$sr) else NA",
    "sapply(priors, function(dp) c(",
    "  significance = size(ssdSig(level = alpha / 2, dprior = dp, power = power)),",
    "  pooled = size(ssdMeta(level = (alpha / 2)^2, dprior = dp, power = power, searchInt = c(1e-6, 10))),",
    if (!is.null(margin)) "  agreement = size(ssdEqu(level = 2 * alpha, dprior = dp, power = power, margin = margin)),",
    sprintf("  bf_replication = size(ssdBFr(level = 1/%s, dprior = dp, power = power)),", num(i$threshold)),
    sprintf("  bf_sceptical = size(ssdBFs(level = 1/%s, dprior = dp, power = power))", num(i$threshold)),
    "))",
    if (!is.null(margin)) c("",
      "# Too small to matter: the usual TOST at alpha (a 1 - 2 alpha interval), planned for no effect",
      "size(ssdTOST(level = 2 * alpha, dprior = designPrior(to = 0, so = so, type = \"conditional\"), power = power, margin = margin))"),
    if (!bayes) c("",
      "# Small telescopes: the smallest n with this power to show the effect is smaller than d33 when it is 0",
      sprintf("yardstick <- sign(%s) * %s", num(i$original_effect), telescope_call),
      sprintf("telescope_power <- function(n) %s", telescope_power),
      sprintf("n <- %s; while (telescope_power(n) < power) n <- n + %s", if (two) 6 else if (correlation) 5 else 5, if (two) 2 else 1),
      "n"),
    if (bayes && !is.na(bf_type)) c("",
      sprintf("# The original's Bayes factor test repeated (BF10 of at least %s), in total%s", num(i$threshold),
        if (two) ", from bfpwr's size per group" else ""),
      sprintf("bf_size <- function(...) %sbfpwr::ntbf01(pscale = %s, type = \"%s\", nrange = c(2, 1e5), ...)",
        if (two) "2 * " else "", num(i$original_prior_scale), bf_type),
      sprintf("sapply(priors, function(dp) bf_size(k = 1/%s, power = power, dpm = dp$dpMean, dpsd = sqrt(dp$dpVar)))", num(i$threshold)),
      sprintf("# Evidence for no effect (BF01 of at least %s) if there is none", num(i$threshold)),
      sprintf("bf_size(k = %s, power = power, dpm = 0, dpsd = 0, lower.tail = FALSE)", num(i$threshold)))
  ) |> paste(collapse = "\n")
}

# An original Bayes factor t-test's t statistic and effect, from its BF10,
# sample size and Cauchy prior scale: BayesFactor::ttest.tstat() inverted
# (BF10 grows with |t|, so one positive root). Ly et al. (2018) give the
# forward relation; the effect is read as positive.
replication_bf_to_t <- function(bf, design, n, n1, n2, rscale) {
  if (!is.numeric(bf) || length(bf) != 1 || is.na(bf) || !is.finite(bf) || bf <= 0) {
    abort_run("The original's Bayes factor should be a number above 0, as BF10 (evidence for an effect over none).")
  }
  if (!requireNamespace("BayesFactor", quietly = TRUE)) {
    abort_run("Reading an original Bayes factor needs the R package BayesFactor. Install it with install.packages(\"BayesFactor\").")
  }
  sizes <- if (identical(design, "two_groups")) c(n1, n2) else c(n, 0)
  log_bf <- function(t) BayesFactor::ttest.tstat(t, sizes[1], sizes[2], rscale = rscale)$bf
  floor_bf <- exp(log_bf(0))
  if (bf <= floor_bf * (1 + 1e-6)) {
    abort_run(sprintf(paste("With this sample size and prior, a t-test's BF10 is at least %s, so a BF10 of %s can't come from it.",
      "Check that the Bayes factor is BF10 (for an effect), not BF01 (for no effect): BF10 = 1 / BF01."),
      format(signif(floor_bf, 3)), format(signif(bf, 3))))
  }
  hi <- 1
  while (log_bf(hi) < log(bf) && hi < 1e3) hi <- 2 * hi
  if (log_bf(hi) < log(bf)) abort_run("The original's Bayes factor is too large to read a t statistic from.")
  t <- stats::uniroot(function(t) log_bf(t) - log(bf), c(0, hi), tol = 1e-10)$root
  d <- if (identical(design, "two_groups")) t * sqrt(1 / n1 + 1 / n2) else t / sqrt(n)
  if (d > 5) abort_run("The original's Bayes factor implies a standardised effect above 5; check it and the sample size.")
  list(t = t, d = d, floor = floor_bf)
}
