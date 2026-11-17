# Validation: replication plans (replication_planning()). Method: the
# normal-normal hierarchical model of Pawel, Consonni and Held (2026,
# refs.bib Pawel2026_replication), whose success probabilities
# BayesRepDesign computes in closed form; small telescopes (Simonsohn,
# 2015, refs.bib Simonsohn2015_telescopes) by the small-telescopes card's
# calculation (pwr and pwrss).
#   1. published examples (placeholders for the maintainer)
#   2. agreement with a simulation written separately: the true effect is
#      drawn from each design prior, the replication's estimate around it,
#      and each goal's success rule applied to the draws as the paper
#      defines it (a test statistic, a pooled estimate, an interval, a
#      Bayes factor from normal densities), so the check relies on none of
#      BayesRepDesign's success regions or closed forms
#   3. real data: two-group and paired studies simulated person by person
#      and analysed with t.test(), for the classical goal (the "as
#      reported" belief, significance), whose normal approximation is
#      measured against the t-test (a recorded convention), and the
#      small-telescopes test of Simonsohn (2015) on simulated data
# Not covered here: the sceptical Bayes factor (Pawel and Held, 2022), whose
# success region needs the Lambert W function and is left to the published
# example below, and the Bayes factor goals planned with bfpwr (for or
# against an effect), which the bayes chunk validates on their own cards.
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

replication_of <- function(...) engine_function("replication_planning")(...)

# 1. Published examples ---------------------------------------------------------

test_that("each goal's relative sample size matches the paper's worked example (published)", {
  skip_unless_full_validation()
  # Source: Pawel, Consonni & Held (2026), the worked example ("Labels"
  #   experiment) and its Figure 3, or BayesRepDesign's vignette for the
  #   same example. Transcribe the original's estimate and standard error
  #   (the scale the paper works on), tau, and for each goal and design
  #   prior the relative sample size n_r / n_o the paper gives. Give the
  #   relative sizes as a named list of named numbers, such as
  #   list(significance = c(as_reported = 1.2, uncertain = 2.1, shrunk = 3.4)),
  #   leaving out any goal the paper does not report.
  to <- TODO_PUBLISHED_VALUE
  so <- TODO_PUBLISHED_VALUE
  tau <- TODO_PUBLISHED_VALUE
  margin <- TODO_PUBLISHED_VALUE # the equivalence margin, on the same scale
  threshold <- TODO_PUBLISHED_VALUE # the Bayes factors' threshold (the paper's level is 1 / threshold)
  published_ratio <- TODO_PUBLISHED_VALUE
  skip_if_todo(to, so, tau, margin, threshold, published_ratio)
  # A generic effect: the replication's standard error is so * sqrt(n_o / n),
  # so n / n_o is the paper's relative sample size so^2 / sr^2. A large
  # original n keeps the rounding of n to whole people small.
  plan <- replication_of("generic", to, original_n = 10000, original_se = so, tau = tau,
    smallest_effect = margin, threshold = threshold)
  g <- plan$goals
  for (goal in names(published_ratio)) {
    for (prior in names(published_ratio[[goal]])) {
      ratio <- g$ratio[g$goal == goal & g$prior %in% prior]
      expect_equal(ratio, published_ratio[[goal]][[prior]], tolerance = 0.01,
        label = sprintf("n_r / n_o for %s, %s", goal, prior))
    }
  }
})

test_that("small telescopes' d33 and replication size match Simonsohn's example (published)", {
  skip_unless_full_validation()
  # Source: Simonsohn (2015), Psychological Science 26, 559-569: the worked
  #   example of an original two-group study (its sample size per group and
  #   d33), and the replication sample size the paper gives for 80% power
  #   to reject d33 when the true effect is 0 (one-sided, alpha = .05).
  n_per_group <- TODO_PUBLISHED_VALUE
  published_d33 <- TODO_PUBLISHED_VALUE
  published_n_per_group <- TODO_PUBLISHED_VALUE
  skip_if_todo(n_per_group, published_d33, published_n_per_group)
  plan <- replication_of("two_groups", published_d33 * 2, original_n1 = n_per_group, original_n2 = n_per_group)
  expect_equal(plan$telescope$effect, published_d33, tolerance = rounding_allowance(published_d33) + 1e-4)
  expect_equal(plan$goals$per_group[plan$goals$goal == "small_telescopes"], published_n_per_group, tolerance = 1)
})

test_that("the sceptical Bayes factor's chance matches a published example (published)", {
  skip_unless_full_validation()
  # Source: Pawel & Held (2022), JRSS A 185, 2022 ("The sceptical Bayes
  #   factor for the assessment of replication success"), or Pawel,
  #   Consonni & Held (2026): an original's estimate and standard error, a
  #   replication standard error, the level, and the probability of
  #   replication success under the conditional (as reported) design prior.
  to <- TODO_PUBLISHED_VALUE
  so <- TODO_PUBLISHED_VALUE
  sr <- TODO_PUBLISHED_VALUE
  level <- TODO_PUBLISHED_VALUE
  published_chance <- TODO_PUBLISHED_VALUE
  skip_if_todo(to, so, sr, level, published_chance)
  n_o <- 10000
  plan <- replication_of("generic", to, original_n = n_o, original_se = so, threshold = 1 / level,
    n = round(n_o * so^2 / sr^2))
  a <- plan$at_n
  expect_power_near(exact_estimate(a$chance[a$goal == "bf_sceptical" & a$prior == "as_reported"]), published_chance)
})

# 2. A simulation written separately --------------------------------------------

# The model (paper, "Between-Study Heterogeneity"): the overall effect theta
# has the design prior below; the replication's true effect is
# theta_r ~ N(theta, tau^2) and its estimate tr ~ N(theta_r, sr^2). With a
# flat initial prior, the original gives theta ~ N(to, so^2 + tau^2)
# ("uncertain"); the empirical Bayes prior shrinks that towards 0 by
# s = max(0, 1 - (so^2 + tau^2) / to^2) ("shrunk"); "as reported" is a point
# mass at to with no variation between studies.
draw_replications <- function(prior, to, so, tau, sr, nsim) {
  if (identical(prior, "as_reported")) {
    return(stats::rnorm(nsim, to, sr))
  }
  s <- if (identical(prior, "shrunk")) max(0, 1 - (so^2 + tau^2) / to^2) else 1
  theta <- stats::rnorm(nsim, s * to, sqrt(s * (so^2 + tau^2)))
  stats::rnorm(nsim, stats::rnorm(nsim, theta, tau), sr)
}

# Each goal's success rule, for an original with a positive estimate,
# applied to replication estimates `tr` (paper, "Analysis Methods"; the
# levels are replication_planning()'s, from the paper's worked example).
replication_success <- function(goal, tr, to, so, sr, alpha, margin, threshold, one_sided = FALSE) {
  level <- if (one_sided) alpha else alpha / 2
  switch(goal,
    # The two-trials rule: the replication alone, one-sided at alpha / 2
    # (at alpha for a one-sided replication).
    significance = tr / sr > stats::qnorm(1 - level),
    # The fixed-effect pooled estimate of both studies, one-sided at that
    # level squared.
    pooled = {
      w <- c(1 / so^2, 1 / sr^2)
      (w[1] * to + w[2] * tr) / sqrt(sum(w)) > stats::qnorm(1 - level^2)
    },
    # The (1 - 2 alpha) interval for the difference inside +- the margin.
    agreement = abs(tr - to) + stats::qnorm(1 - alpha) * sqrt(so^2 + sr^2) < margin,
    # The replication Bayes factor (Verhagen & Wagenmakers, 2014), in the
    # normal form the paper uses: the replication's estimate under no
    # effect against under the original's posterior from a flat prior.
    # Success: BF_0r at most 1 / threshold. As BayesRepDesign's default
    # (paradox = TRUE), which replication_planning() uses, a replication on
    # either side of zero counts.
    bf_replication = {
      log_bf0r <- stats::dnorm(tr, 0, sr, log = TRUE) - stats::dnorm(tr, to, sqrt(so^2 + sr^2), log = TRUE)
      log_bf0r <= -log(threshold)
    }
  )
}

# The cases: each design's own scale and variation between studies, with
# margins wide enough that agreement and too small to matter have chances
# between 0 and 1. `n` is the replication's total sample size.
replication_cases <- list(
  list(label = "two groups, d = 0.5, 40 per group", design = "two_groups", effect = 0.5,
    args = list(original_n1 = 40, original_n2 = 40), tau = 0.1, margin = 0.6, n = 160,
    so = sqrt(2 / 40 + 0.5^2 / (2 * 80)), sr = 2 / sqrt(160)),
  list(label = "pairs, d_z = 0.35, 50 pairs", design = "paired", effect = 0.35,
    args = list(original_n = 50), tau = 0.05, margin = 0.35, n = 120,
    so = 1 / sqrt(50), sr = 1 / sqrt(120)),
  list(label = "correlation, r = .3, n = 90", design = "correlation", effect = 0.3,
    args = list(original_n = 90), tau = 0.075, margin = 0.25, n = 250,
    so = 1 / sqrt(87), sr = 1 / sqrt(247)),
  list(label = "another design, odds ratio 1.8 (SE of the log 0.25), n = 200", design = "generic",
    effect = 1.8, args = list(original_n = 200, original_se = 0.25, scale = "log"), tau = 0.1,
    margin = 1.8, n = 500, so = 0.25, sr = 0.25 * sqrt(200 / 500))
)

# A closed-form chance from the engine against a simulated share: they
# must agree within the simulation's 99.9% Monte Carlo interval.
expect_chance_agrees <- function(simulated, nsim, engine, what) {
  half_width <- z_for(0.999) * sqrt(simulated * (1 - simulated) / nsim) + 0.0005
  expect(length(engine) == 1 && abs(simulated - engine) <= half_width,
    sprintf("%s: simulated %.4f, powerkit %s; the tolerance is %.4f.", what, simulated,
      paste(format(round(engine, 4)), collapse = ", "), half_width))
}

test_that("every goal's chance at a sample size agrees with a simulation of the paper's model", {
  skip_unless_full_validation()
  nsim <- 200000L
  alpha <- 0.05
  threshold <- 10
  set.seed(2026)
  for (case in replication_cases) {
    plan <- do.call(replication_of, c(list(case$design, case$effect), case$args,
      list(tau = case$tau, smallest_effect = case$margin, threshold = threshold, n = case$n)))
    to <- plan$original$estimate
    expect_equal(plan$original$se, case$so, tolerance = 1e-8, label = paste(case$label, "original SE"))
    margin <- switch(case$design, correlation = atanh(case$margin), generic = log(case$margin), case$margin)
    a <- plan$at_n
    one <- do.call(replication_of, c(list(case$design, case$effect), case$args,
      list(tau = case$tau, threshold = threshold, n = case$n, alternative = "one.sided")))$at_n
    for (prior in c("as_reported", "uncertain", "shrunk")) {
      tr <- draw_replications(prior, to, case$so, case$tau, case$sr, nsim)
      for (goal in c("significance", "pooled", "agreement", "bf_replication")) {
        simulated <- mean(replication_success(goal, tr, to, case$so, case$sr, alpha, margin, threshold))
        expect_chance_agrees(simulated, nsim, a$chance[a$goal == goal & a$prior == prior],
          sprintf("%s: %s, %s", case$label, goal, prior))
      }
      for (goal in c("significance", "pooled")) {
        simulated <- mean(replication_success(goal, tr, to, case$so, case$sr, alpha, margin, threshold, one_sided = TRUE))
        expect_chance_agrees(simulated, nsim, one$chance[one$goal == goal & one$prior %in% prior],
          sprintf("%s: %s, %s, one-sided", case$label, goal, prior))
      }
    }
    # Too small to matter: the replication alone, its (1 - 2 alpha)
    # interval inside +- the margin, when the true effect is 0.
    tr0 <- stats::rnorm(nsim, 0, case$sr)
    simulated <- mean(abs(tr0) + stats::qnorm(1 - alpha) * case$sr < margin)
    expect_chance_agrees(simulated, nsim, a$chance[a$goal == "negligible"],
      sprintf("%s: negligible", case$label))
  }
})

# 3. The normal approximation against real data ---------------------------------

# The planner's model takes the replication's standard error as known, so
# its significance chance is a z-test's, where the t-test cards use the t
# distribution: it is slightly higher at small samples (conventions.md, "The
# normal approximation against the t-test cards"). The simulation must
# agree with the t-test's exact power, and the planner may exceed that by
# at most 2 points here, the size recorded there.
expect_normal_gap <- function(engine, simulated, nsim, exact, what) {
  expect_chance_agrees(simulated, nsim, exact, paste(what, "(the simulation against the exact t-test power)"))
  gap <- engine - exact
  expect(gap >= 0 && gap <= 0.02,
    sprintf("%s: the planner's chance %.4f exceeds the t-test's %.4f by %.4f; at most 0.02 is recorded.",
      what, engine, exact, gap))
}

test_that("the as-reported significance chance is the t-test's, up to the normal approximation", {
  skip_unless_full_validation()
  nsim <- validation_nrep()
  alpha <- 0.05
  set.seed(2027)
  # Two groups: the replication's one-sided t-test at alpha / 2 when the
  # true d is the original's.
  plan <- replication_of("two_groups", 0.5, original_n1 = 40, original_n2 = 40, n = 130)
  hits <- vapply(seq_len(nsim), function(i) {
    stats::t.test(stats::rnorm(65, 0.5), stats::rnorm(65), alternative = "greater", var.equal = TRUE)$p.value < alpha / 2
  }, logical(1))
  a <- plan$at_n
  expect_normal_gap(a$chance[a$goal == "significance" & a$prior == "as_reported"], mean(hits), nsim,
    stats::power.t.test(n = 65, delta = 0.5, sig.level = alpha / 2, alternative = "one.sided")$power, "two groups")
  # Pairs.
  plan <- replication_of("paired", 0.35, original_n = 50, n = 80)
  hits <- vapply(seq_len(nsim), function(i) {
    stats::t.test(stats::rnorm(80, 0.35), alternative = "greater")$p.value < alpha / 2
  }, logical(1))
  a <- plan$at_n
  expect_normal_gap(a$chance[a$goal == "significance" & a$prior == "as_reported"], mean(hits), nsim,
    stats::power.t.test(n = 80, delta = 0.35, sig.level = alpha / 2, type = "one.sample", alternative = "one.sided")$power,
    "pairs")
})

# d33: the effect the original study had a third of the power to detect in a
# two-sided t-test at its own level, from the noncentral t.
d33_of <- function(df, scale, alpha) {
  crit <- stats::qt(1 - alpha / 2, df)
  power <- function(d) stats::pt(crit, df, d * scale, lower.tail = FALSE) + stats::pt(-crit, df, d * scale)
  stats::uniroot(function(d) power(d) - 1 / 3, c(0, 10), tol = 1e-10)$root
}

test_that("small telescopes' chance at a sample size agrees with t-tests on simulated people", {
  skip_unless_full_validation()
  nsim <- validation_nrep()
  alpha <- 0.05
  set.seed(2015)
  # Simonsohn's test: the replication's t statistic against the noncentral
  # t that d33 implies, one-sided at alpha, when the true effect is 0.
  plan <- replication_of("two_groups", 0.6, original_n1 = 20, original_n2 = 20, n = 100)
  d33 <- d33_of(38, sqrt(20 * 20 / 40), 0.05)
  expect_equal(plan$telescope$effect, d33, tolerance = 1e-4)
  hits <- vapply(seq_len(nsim), function(i) {
    t <- stats::t.test(stats::rnorm(50), stats::rnorm(50), var.equal = TRUE)$statistic
    stats::pt(t, 98, d33 * sqrt(50 * 50 / 100)) < alpha
  }, logical(1))
  a <- plan$at_n
  expect_power_near(binomial_estimate(mean(hits), nsim), a$chance[a$goal == "small_telescopes"])
  # Pairs.
  plan <- replication_of("paired", 0.5, original_n = 25, n = 60)
  d33 <- d33_of(24, sqrt(25), 0.05)
  expect_equal(plan$telescope$effect, d33, tolerance = 1e-4)
  hits <- vapply(seq_len(nsim), function(i) {
    t <- stats::t.test(stats::rnorm(60))$statistic
    stats::pt(t, 59, d33 * sqrt(60)) < alpha
  }, logical(1))
  a <- plan$at_n
  expect_power_near(binomial_estimate(mean(hits), nsim), a$chance[a$goal == "small_telescopes"])
})
