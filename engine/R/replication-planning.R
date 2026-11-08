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
  correlation = list(template = "correlation", effect = "r", unit_sd = 1)
)

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
#' @param design `"two_groups"`, `"one_sample"`, `"paired"` or
#'   `"correlation"`.
#' @param original_effect The original study's effect as reported: d, d_z
#'   or r. Not zero.
#' @param original_n The original study's number of people (or pairs),
#'   for one sample, pairs and a correlation.
#' @param original_n1,original_n2 The original study's group sizes, for
#'   two groups.
#' @param original_alpha The original study's two-sided significance
#'   level (for small telescopes' d33).
#' @param alpha The replication's two-sided significance level.
#' @param power The chance of success the sample sizes aim for.
#' @param tau How much the true effect varies between studies (a standard
#'   deviation on the effect's scale; Fisher's z for a correlation), for
#'   the uncertain and shrunk beliefs.
#' @param smallest_effect The smallest effect that would matter (d, d_z or
#'   r, positive), for the agreement and too-small-to-matter goals; `NULL`
#'   leaves those goals out.
#' @param threshold The Bayes factor counted as strong evidence.
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
#'   and its calculation); `functions_used`; and `packages`.
#' @export
#' @examples
#' plan <- replication_planning("two_groups", 0.7, original_n1 = 20, original_n2 = 20,
#'   smallest_effect = 0.2)
#' plan$goals
replication_planning <- function(design, original_effect, original_n = NULL, original_n1 = NULL,
                                 original_n2 = NULL, original_alpha = 0.05, alpha = 0.05, power = 0.8,
                                 tau = 0, smallest_effect = NULL, threshold = 10, n = NULL,
                                 max_n = 1e5) {
  if (!requireNamespace("BayesRepDesign", quietly = TRUE)) {
    abort_run("The replication planner needs the R package BayesRepDesign. Install it with install.packages(\"BayesRepDesign\").")
  }
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  whole <- function(x, low) one_number(x) && x == round(x) && x >= low && x <= 1e6
  if (!is.character(design) || length(design) != 1 || !design %in% names(replication_designs)) {
    abort_run("'design' should be \"two_groups\", \"one_sample\", \"paired\" or \"correlation\".")
  }
  rule <- replication_designs[[design]]
  correlation <- identical(design, "correlation")
  if (!one_number(original_effect) || original_effect == 0 ||
      (correlation && abs(original_effect) >= 1) || abs(original_effect) > 5) {
    abort_run(if (correlation) {
      "The original correlation should be between -1 and 1, and not 0."
    } else {
      "The original effect should be a standardised effect between -5 and 5, and not 0."
    })
  }
  if (identical(design, "two_groups")) {
    if (!whole(original_n1, 2) || !whole(original_n2, 2)) {
      abort_run("The original study's two group sizes should be whole numbers, at least 2 each.")
    }
  } else if (!whole(original_n, if (correlation) 4 else 2)) {
    abort_run(sprintf("The original study's number of %s should be a whole number, at least %s.",
      if (identical(design, "paired")) "pairs" else "people", if (correlation) 4 else 2))
  }
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
  if (!is.null(smallest_effect) && (!one_number(smallest_effect) || smallest_effect <= 0 ||
      (correlation && smallest_effect >= 1) || smallest_effect > 5)) {
    abort_run("The smallest effect that would matter should be more than 0 (and below 1 for a correlation).")
  }
  if (!one_number(threshold) || threshold <= 1 || threshold > 1000) {
    abort_run("The Bayes factor counted as strong evidence should be above 1, and at most 1,000.")
  }
  if (!is.null(n) && !whole(n, if (correlation) 4 else 2)) {
    abort_run("The replication's sample size should be a whole number of people.")
  }

  # The original estimate and its standard error on the analysis scale.
  original <- if (identical(design, "two_groups")) {
    list(estimate = original_effect, n = original_n1 + original_n2,
      se = sqrt((original_n1 + original_n2) / (original_n1 * original_n2) +
        original_effect^2 / (2 * (original_n1 + original_n2))))
  } else if (correlation) {
    list(estimate = atanh(original_effect), n = original_n, se = 1 / sqrt(original_n - 3))
  } else {
    list(estimate = original_effect, n = original_n, se = 1 / sqrt(original_n))
  }
  original$z <- original$estimate / original$se
  original$p <- 2 * stats::pnorm(-abs(original$z))
  on_scale <- function(x) if (correlation) atanh(x) else x
  margin <- if (!is.null(smallest_effect)) on_scale(smallest_effect)

  # Standard error and sample size, both ways (n is the total).
  se_at <- function(n) if (correlation) 1 / sqrt(n - 3) else rule$unit_sd / sqrt(n)
  n_at <- function(se) {
    raw <- if (correlation) 1 / se^2 + 3 else rule$unit_sd^2 / se^2
    if (identical(design, "two_groups")) 2 * ceiling(raw / 2 - 1e-9) else ceiling(raw - 1e-9)
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

  # Small telescopes: the card's calculation, so both give one number.
  telescope <- replication_telescope(design, original_effect, original_n,
    original_n1, original_n2, original_alpha, alpha, power)
  rows[[length(rows) + 1]] <- data.frame(goal = "small_telescopes", prior = NA_character_, n = telescope$n,
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
    chance[[length(chance) + 1]] <- data.frame(goal = "small_telescopes", prior = NA_character_,
      chance = telescope$power_at(n))
    do.call(rbind, chance)
  }

  list(
    inputs = list(design = design, original_effect = original_effect, original_n = original_n,
      original_n1 = original_n1, original_n2 = original_n2, original_alpha = original_alpha, alpha = alpha,
      power = power, tau = tau, smallest_effect = smallest_effect, threshold = threshold, n = n),
    effect_name = rule$effect,
    scale = if (correlation) "Fisher's z" else rule$effect,
    original = original,
    priors = data.frame(prior = names(priors),
      mean = vapply(priors, function(dp) dp$dpMean, numeric(1)),
      sd = vapply(priors, function(dp) sqrt(dp$dpVar), numeric(1)),
      tau = vapply(priors, function(dp) dp$tau, numeric(1)), row.names = NULL),
    goals = goals,
    at_n = at_n,
    telescope = telescope[c("effect", "effect_name", "function_used", "n")],
    functions_used = c(
      vapply(rules, function(r) paste0("BayesRepDesign::", r$call), character(1)),
      if (!is.null(margin)) c(negligible = sprintf("BayesRepDesign::ssdTOST(level = %s, margin = %s), design prior at 0",
        format(2 * alpha), format(signif(margin, 4)))),
      small_telescopes = telescope$function_used
    ),
    packages = list(
      list(name = "BayesRepDesign", version = as.character(utils::packageVersion("BayesRepDesign"))),
      list(name = "pwr", version = as.character(utils::packageVersion("pwr"))),
      list(name = "pwrss", version = as.character(utils::packageVersion("pwrss")))
    )
  )
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
replication_planning_script <- function(plan) {
  i <- plan$inputs
  num <- function(x) format(signif(x, 8))
  correlation <- identical(i$design, "correlation")
  two <- identical(i$design, "two_groups")
  margin <- if (!is.null(i$smallest_effect)) if (correlation) sprintf("atanh(%s)", num(i$smallest_effect)) else num(i$smallest_effect)
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
    "# Replication plan, from powerkit's replication planner (Labs).",
    "# Every goal judged against the original's effect: BayesRepDesign (Pawel, Consonni & Held, 2026).",
    "# Small telescopes (Simonsohn, 2015): pwr for d33 (or r33) and pwrss for the replication's test.",
    sprintf("# Written by powerkit %s on %s.", as.character(utils::packageVersion("powerkit")), format(Sys.Date())),
    "library(BayesRepDesign)",
    "",
    "# The original study",
    if (two) c(sprintf("n1 <- %s; n2 <- %s", i$original_n1, i$original_n2),
      sprintf("to <- %s", num(i$original_effect)),
      "so <- sqrt((n1 + n2) / (n1 * n2) + to^2 / (2 * (n1 + n2)))  # Pawel et al., eq. 9",
      "n_from_se <- function(se) 2 * ceiling(se2n(se, unitSD = 2) / 2 - 1e-9)  # two equal groups, in total")
    else if (correlation) c(sprintf("to <- atanh(%s)  # Fisher's z", num(i$original_effect)),
      sprintf("so <- 1 / sqrt(%s - 3)", i$original_n),
      "n_from_se <- function(se) ceiling(1 / se^2 + 3 - 1e-9)")
    else c(sprintf("to <- %s", num(i$original_effect)), sprintf("so <- 1 / sqrt(%s)", i$original_n),
      "n_from_se <- function(se) ceiling(se2n(se, unitSD = 1) - 1e-9)"),
    sprintf("original_alpha <- %s; alpha <- %s; power <- %s; tau <- %s", num(i$original_alpha), num(i$alpha), num(i$power), num(i$tau)),
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
    "",
    "# Small telescopes: the smallest n with this power to show the effect is smaller than d33 when it is 0",
    sprintf("yardstick <- sign(%s) * %s", num(i$original_effect), telescope_call),
    sprintf("telescope_power <- function(n) %s", telescope_power),
    sprintf("n <- %s; while (telescope_power(n) < power) n <- n + %s", if (two) 6 else if (correlation) 5 else 5, if (two) 2 else 1),
    "n"
  ) |> paste(collapse = "\n")
}
