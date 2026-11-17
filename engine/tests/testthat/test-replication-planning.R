# Replication planning (Labs): every goal judged against the original's
# effect is BayesRepDesign's (Pawel, Consonni & Held, 2026); small
# telescopes is the card's own calculation.

skip_if_not_installed("BayesRepDesign")

two_groups <- function(...) {
  replication_planning("two_groups", 0.7, original_n1 = 20, original_n2 = 20, smallest_effect = 0.2, ...)
}
goal_n <- function(plan, goal, prior = NA) {
  rows <- plan$goals[plan$goals$goal == goal, ]
  if (is.na(prior)) rows$n[1] else rows$n[rows$prior %in% prior]
}

test_that("the original's standard error is the paper's equation 9 for two groups, Fisher's z for r", {
  plan <- two_groups()
  expect_equal(plan$original$se, sqrt(40 / 400 + 0.49 / 80))
  r <- replication_planning("correlation", 0.3, original_n = 80)
  expect_equal(r$original$estimate, atanh(0.3))
  expect_equal(r$original$se, 1 / sqrt(77))
  expect_equal(replication_planning("paired", 0.5, original_n = 30)$original$se, 1 / sqrt(30))
})

test_that("each goal's sample size is BayesRepDesign's, converted from its standard error", {
  plan <- two_groups(tau = 0.1)
  so <- plan$original$se
  for (type in c(as_reported = "conditional", uncertain = "predictive", shrunk = "EB")) {
    prior <- names(which(c(as_reported = "conditional", uncertain = "predictive", shrunk = "EB") == type))
    dp <- BayesRepDesign::designPrior(to = 0.7, so = so, tau = if (type == "conditional") 0 else 0.1, type = type)
    sig <- BayesRepDesign::ssdSig(level = 0.025, dprior = dp, power = 0.8)
    expect_equal(goal_n(plan, "significance", prior), 2 * ceiling(4 / sig$sr^2 / 2))
    bfr <- BayesRepDesign::ssdBFr(level = 1 / 10, dprior = dp, power = 0.8)
    expect_equal(goal_n(plan, "bf_replication", prior), 2 * ceiling(4 / bfr$sr^2 / 2))
    meta <- BayesRepDesign::ssdMeta(level = 0.025^2, dprior = dp, power = 0.8, searchInt = c(1e-6, 10))
    expect_equal(goal_n(plan, "pooled", prior), 2 * ceiling(4 / meta$sr^2 / 2))
  }
  # A correlation's sample size is 1 / se^2 + 3, on Fisher's z.
  r <- replication_planning("correlation", 0.3, original_n = 80)
  dp <- BayesRepDesign::designPrior(to = atanh(0.3), so = 1 / sqrt(77), type = "conditional")
  expect_equal(goal_n(r, "significance", "as_reported"),
    ceiling(1 / BayesRepDesign::ssdSig(0.025, dp, 0.8)$sr^2 + 3))
})

test_that("the planned sample size reaches the chance aimed for, and one fewer does not", {
  plan <- two_groups(n = goal_n(two_groups(), "significance", "uncertain"))
  hit <- plan$at_n[plan$at_n$goal == "significance" & plan$at_n$prior %in% "uncertain", "chance"]
  expect_gte(hit, 0.8)
  below <- two_groups(n = goal_n(plan, "significance", "uncertain") - 2)
  expect_lt(below$at_n[below$at_n$goal == "significance" & below$at_n$prior %in% "uncertain", "chance"], 0.8)
})

test_that("uncertainty, shrinkage and variation between studies each ask for a larger replication", {
  plan <- two_groups()
  sig <- plan$goals[plan$goals$goal == "significance", ]
  expect_lt(sig$n[sig$prior == "as_reported"], sig$n[sig$prior == "uncertain"])
  expect_lt(sig$n[sig$prior == "uncertain"], sig$n[sig$prior == "shrunk"])
  varied <- two_groups(tau = 0.1)
  expect_gt(goal_n(varied, "significance", "uncertain"), goal_n(plan, "significance", "uncertain"))
  # The as-reported belief is a point at the estimate, with no variation.
  expect_equal(goal_n(varied, "significance", "as_reported"), goal_n(plan, "significance", "as_reported"))
})

test_that("as reported, the significance goal is a power analysis by the normal approximation", {
  # Two equal groups, SE 2 / sqrt(N): N = 4 (z_.975 + z_.8)^2 / d^2. A
  # t-test power analysis (pwr) asks for a little more: 68 against 66
  # here, the size of the difference recorded in docs/conventions.md.
  plan <- two_groups()
  normal <- 4 * (qnorm(0.975) + qnorm(0.8))^2 / 0.7^2
  expect_equal(goal_n(plan, "significance", "as_reported"), 2 * ceiling(normal / 2))
  t_test <- 2 * ceiling(pwr::pwr.t.test(d = 0.7, power = 0.8)$n)
  expect_equal(t_test - goal_n(plan, "significance", "as_reported"), 2)
})

test_that("too small to matter is the usual TOST at alpha, planned for no effect", {
  plan <- two_groups()
  # Each one-sided test at .05: N = 4 (z_.95 + z_.9)^2 / margin^2.
  expect_equal(goal_n(plan, "negligible"), 2 * ceiling(4 * (qnorm(0.95) + qnorm(0.9))^2 / 0.2^2 / 2), tolerance = 0.01)
  expect_true(is.na(plan$goals$prior[plan$goals$goal == "negligible"]))
})

test_that("small telescopes gives the card's number", {
  plan <- two_groups()
  expect_equal(goal_n(plan, "small_telescopes"), 102)
  expect_equal(plan$telescope$effect, 0.4959, tolerance = 1e-3)
  strict <- two_groups(alpha = 0.005)
  expect_gt(goal_n(strict, "small_telescopes"), 102)
  at <- two_groups(n = 102)
  expect_equal(at$at_n$chance[at$at_n$goal == "small_telescopes"], 0.8, tolerance = 0.02)
})

test_that("a goal no replication can reach says so, with the most it could reach", {
  # An original of 20 per group is too imprecise to show agreement within
  # 0.2 of it, however large the replication.
  plan <- two_groups()
  agree <- plan$goals[plan$goals$goal == "agreement", ]
  expect_true(all(is.na(agree$n)))
  expect_true(all(agree$reason == "not_reachable"))
  expect_true(all(agree$limit < 0.8))
  # With a wide margin it can.
  wide <- replication_planning("two_groups", 0.7, original_n1 = 200, original_n2 = 200, smallest_effect = 0.5)
  expect_false(anyNA(wide$goals$n[wide$goals$goal == "agreement"]))
  # Without a smallest effect, the two goals that need one are left out.
  plain <- replication_planning("two_groups", 0.7, original_n1 = 20, original_n2 = 20)
  expect_false(any(c("agreement", "negligible") %in% plain$goals$goal))
})

test_that("a goal met by even the smallest replication says so, not that it can't be reached", {
  # A strong original (z = 3.92) carries the pooled goal on its own: its
  # chance is above 90% for a replication of three people, so
  # BayesRepDesign's search has no sample size to find.
  plan <- replication_planning("generic", 0.74, original_n = 120, original_statistic = 3.92,
    power = 0.9)
  pooled <- plan$goals[plan$goals$goal == "pooled", ]
  expect_true(all(pooled$reason == "any_size"))
  expect_true(all(is.na(pooled$n)))
  for (p in pooled$prior) {
    dp <- BayesRepDesign::designPrior(to = 0.74, so = plan$original$se, tau = 0,
      type = c(as_reported = "conditional", uncertain = "predictive", shrunk = "EB")[[p]])
    small <- BayesRepDesign::porsMeta(level = 0.025^2, dprior = dp, sr = plan$original$se * sqrt(120 / 3))
    expect_equal(pooled$limit[pooled$prior == p], small)
    expect_gt(small, 0.9)
  }
  # A goal that really can't be reached keeps its own reason.
  agree <- two_groups()$goals
  expect_false(any(agree$reason[agree$goal == "agreement"] == "any_size"))
})

test_that("an independent simulation of t-tests agrees with the uncertain belief's chance", {
  # True effects drawn from the design prior (mean 0.7, its SD), then two
  # groups of the planned size, then Student's t-test: the share
  # significant in the original's direction is the chance the planner gives.
  plan <- two_groups(n = 120)
  prior <- plan$priors[plan$priors$prior == "uncertain", ]
  set.seed(20261108)
  hits <- vapply(seq_len(4000), function(i) {
    delta <- rnorm(1, prior$mean, prior$sd)
    t <- stats::t.test(rnorm(60, delta), rnorm(60), var.equal = TRUE, alternative = "greater")
    t$p.value < 0.025
  }, logical(1))
  given <- plan$at_n$chance[plan$at_n$goal == "significance" & plan$at_n$prior %in% "uncertain"]
  expect_equal(mean(hits), given, tolerance = 0.03)
})

test_that("inputs that can't be planned get plain words", {
  expect_error(replication_planning("anova", 0.5, original_n = 30), "two_groups")
  expect_error(replication_planning("two_groups", 0, original_n1 = 20, original_n2 = 20), "not 0")
  expect_error(replication_planning("two_groups", 0.5, original_n1 = 20), "group sizes")
  expect_error(replication_planning("correlation", 1.2, original_n = 30), "between -1 and 1")
  expect_error(replication_planning("paired", 0.5, original_n = 30, tau = -1), "varies")
  expect_error(replication_planning("paired", 0.5, original_n = 30, original_alpha = 0.7), "original study's significance")
  expect_error(replication_planning("paired", 0.5, original_n = 30, smallest_effect = -0.2), "smallest effect")
})

test_that("the result records what calculated it", {
  plan <- two_groups()
  expect_setequal(vapply(plan$packages, `[[`, "", "name"), c("BayesRepDesign", "pwr", "pwrss"))
  expect_match(plan$functions_used[["significance"]], "ssdSig\\(level = 0.025\\)")
  expect_match(plan$functions_used[["negligible"]], "level = 0.1")
  expect_match(plan$functions_used[["small_telescopes"]], "pwr.t2n.test")
})

test_that("the R script gives the planner's numbers with the packages alone", {
  for (args in list(
    list("two_groups", 0.7, original_n1 = 20, original_n2 = 20, smallest_effect = 0.2, tau = 0.1),
    list("correlation", 0.3, original_n = 80, smallest_effect = 0.1),
    list("paired", -0.5, original_n = 30)
  )) {
    plan <- do.call(replication_planning, args)
    script <- replication_planning_script(plan)
    env <- new.env()
    results <- suppressWarnings(lapply(parse(text = script), eval, envir = env))
    table <- Filter(is.matrix, results)[[1]]
    for (goal in rownames(table)) {
      for (prior in colnames(table)) {
        expect_equal(unname(table[goal, prior]), goal_n(plan, goal, prior), info = paste(args[[1]], goal, prior))
      }
    }
    expect_equal(env$n, goal_n(plan, "small_telescopes"))
    if (!is.null(args$smallest_effect)) {
      expect_equal(results[[which(vapply(results, is.matrix, TRUE)) + 1]], goal_n(plan, "negligible"))
    }
  }
})

# Any design whose focal effect is one number (queue item 21): the
# original's standard error scaled by sqrt(n_original / n).
generic_goals <- function(plan) {
  g <- plan$goals[plan$goals$goal != "small_telescopes", c("goal", "prior", "n", "reason")]
  rownames(g) <- NULL
  g
}

test_that("the generic route gives one sample's and pairs' exact tables", {
  for (design in c("one_sample", "paired")) {
    exact <- replication_planning(design, 0.45, original_n = 36, smallest_effect = 0.2, tau = 0.1, n = 70)
    generic <- replication_planning("generic", 0.45, original_n = 36, original_se = 1 / sqrt(36),
      smallest_effect = 0.2, tau = 0.1, n = 70)
    expect_equal(generic_goals(generic), generic_goals(exact))
    keep <- exact$at_n$goal != "small_telescopes"
    expect_equal(generic$at_n$chance, exact$at_n$chance[keep])
    expect_false("small_telescopes" %in% generic$goals$goal)
  }
})

test_that("for two groups and a correlation the generic route differs from the exact entry by a known amount", {
  # Two equal groups: the original's standard error (eq. 9) carries
  # d^2 / (2N), so scaling it asks for (1 + d^2 / 8) times as many people
  # as the exact entry (about 6% more at d = 0.7), which is why the exact
  # entries stay.
  exact <- replication_planning("two_groups", 0.7, original_n1 = 30, original_n2 = 30)
  generic <- replication_planning("generic", 0.7, original_n = 60, original_se = exact$original$se)
  ratio <- goal_n(generic, "significance", "shrunk") / goal_n(exact, "significance", "shrunk")
  expect_equal(ratio, 1 + 0.7^2 / 8, tolerance = 0.01)
  # A correlation: plain scaling gives n_original / (n_original - 3) times
  # the exact rule's n - 3, a few people more at this size (89 against 85).
  exact_r <- replication_planning("correlation", 0.3, original_n = 40)
  generic_r <- replication_planning("generic", 0.3, original_n = 40, original_se = 1 / sqrt(37), scale = "fisher_z")
  for (prior in c("as_reported", "uncertain", "shrunk")) {
    # Within a person and a half: each is rounded up to a whole person.
    expect_lte(abs(goal_n(generic_r, "significance", prior) - 40 / 37 * (goal_n(exact_r, "significance", prior) - 3)), 1.5)
  }
  expect_equal(goal_n(generic_r, "significance", "as_reported") - goal_n(exact_r, "significance", "as_reported"), 4)
})

test_that("a confidence interval or a test statistic gives the same standard error", {
  se <- 0.2
  by_se <- replication_planning("generic", exp(0.6), original_n = 120, original_se = se, scale = "log")
  ci <- exp(0.6 + c(-1, 1) * qnorm(0.975) * se)
  by_ci <- replication_planning("generic", exp(0.6), original_n = 120, original_ci = ci, scale = "log")
  by_z <- replication_planning("generic", exp(0.6), original_n = 120, original_statistic = 0.6 / se, scale = "log")
  expect_equal(by_ci$original$se, se)
  expect_equal(by_z$original$se, se)
  expect_equal(by_ci$goals, by_se$goals)
  # A 90% interval is narrower for the same standard error.
  ci90 <- exp(0.6 + c(-1, 1) * qnorm(0.95) * se)
  expect_equal(replication_planning("generic", exp(0.6), original_n = 120, original_ci = ci90,
    original_ci_level = 0.9, scale = "log")$original$se, se)
  # A ratio below 1 is planned like its inverse.
  inverse <- replication_planning("generic", exp(-0.6), original_n = 120, original_se = se, scale = "log")
  expect_equal(inverse$goals$n, by_se$goals$n)
})

test_that("the generic script redoes the planner's numbers", {
  plan <- replication_planning("generic", 2.1, original_n = 150, original_ci = c(1.2, 3.7), scale = "log",
    effect_name = "odds ratio")
  lines <- strsplit(replication_planning_script(plan), "\n")[[1]]
  expect_false(any(grepl("pwr", lines)))
  env <- new.env()
  table <- suppressWarnings(eval(parse(text = lines[!grepl("^library", lines)]), env))
  for (prior in c("as_reported", "uncertain", "shrunk")) {
    expect_equal(unname(table["significance", prior]), goal_n(plan, "significance", prior))
    expect_equal(unname(table["bf_replication", prior]), goal_n(plan, "bf_replication", prior))
  }
  expect_setequal(vapply(plan$packages, `[[`, "", "name"), "BayesRepDesign")
})

test_that("a generic original that can't be planned gets plain words", {
  expect_error(replication_planning("generic", 2, original_n = 100, scale = "log"), "Give one of")
  expect_error(replication_planning("generic", 2, original_n = 100, original_se = 0.2, original_statistic = 3), "Give one of")
  expect_error(replication_planning("generic", 1, original_n = 100, original_se = 0.2, scale = "log"), "not 1")
  expect_error(replication_planning("generic", 2, original_n = 100, original_ci = c(2.5, 4), scale = "log"), "inside")
  expect_error(replication_planning("generic", 2, original_n = 100, original_ci = c(-1, 4), scale = "log"), "above 0")
  expect_error(replication_planning("generic", 0.3, original_n = 1, original_se = 0.1), "whole number")
  expect_error(replication_planning("generic", 2, original_n = 100, original_se = 0.2, scale = "log",
    smallest_effect = 0.8), "ratio above 1")
  expect_error(replication_planning("generic", 0.3, original_n = 100, original_se = 0.1, scale = "probit"), "scale")
})

test_that("an original Bayes factor gives back its t statistic", {
  skip_if_not_installed("BayesFactor")
  for (case in list(list("two_groups", n1 = 30, n2 = 24, n = NULL), list("one_sample", n = 40),
                    list("paired", n = 18))) {
    for (t in c(1.2, 2.5, 4.8)) {
      for (rscale in c(0.5, 1 / sqrt(2), 1)) {
        bf <- exp(BayesFactor::ttest.tstat(t, case$n1 %||% case$n, case$n2 %||% 0, rscale = rscale)$bf)
        back <- replication_bf_to_t(bf, case[[1]], case$n, case$n1, case$n2, rscale)
        expect_equal(back$t, t, tolerance = 1e-6)
        expect_equal(back$d, if (identical(case[[1]], "two_groups")) t * sqrt(1 / case$n1 + 1 / case$n2) else t / sqrt(case$n),
          tolerance = 1e-6)
      }
    }
  }
  # bfpwr's Bayes factor, which repeats the test, is BayesFactor's.
  expect_equal(1 / bfpwr::tbf01(t = 2.5, n1 = 30, n2 = 24, type = "two.sample"),
    exp(BayesFactor::ttest.tstat(2.5, 30, 24)$bf), tolerance = 1e-4)
})

test_that("a Bayes factor original is planned at its effect, with the Bayes factor goals", {
  skip_if_not_installed("BayesFactor")
  skip_if_not_installed("bfpwr")
  bf <- exp(BayesFactor::ttest.tstat(2.5, 30, 30)$bf)
  plan <- replication_planning("two_groups", original_n1 = 30, original_n2 = 30,
    original_analysis = "bayes_factor", original_bf = bf, n = 120)
  d <- 2.5 * sqrt(2 / 30)
  as_test <- replication_planning("two_groups", d, original_n1 = 30, original_n2 = 30)
  shared <- c("significance", "pooled", "bf_replication", "bf_sceptical")
  expect_equal(plan$goals[plan$goals$goal %in% shared, "n"], as_test$goals[as_test$goals$goal %in% shared, "n"])
  expect_false("small_telescopes" %in% plan$goals$goal)
  expect_null(plan$telescope)
  # The repeated test and evidence for no effect are bfpwr's, in total.
  dp <- plan$priors[plan$priors$prior == "uncertain", ]
  expect_equal(goal_n(plan, "bf_repeat", "uncertain"),
    2 * bfpwr::ntbf01(k = 1 / 10, power = 0.8, type = "two.sample", dpm = dp$mean, dpsd = dp$sd))
  expect_equal(plan$goals$n[plan$goals$goal == "bf_null"],
    2 * bfpwr::ntbf01(k = 10, power = 0.8, type = "two.sample", dpm = 0, dpsd = 0, lower.tail = FALSE))
  expect_true(all(c("bf_repeat", "bf_null") %in% plan$at_n$goal))
  expect_equal(plan$sequential$effect, plan$priors$mean)
  expect_setequal(vapply(plan$packages, `[[`, "", "name"), c("BayesRepDesign", "bfpwr", "BayesFactor"))
  # Evidence for no effect needs more people than evidence for an effect
  # (McLatchie, Warmelink & Tkacheva, 2020).
  expect_gt(plan$goals$n[plan$goals$goal == "bf_null"], goal_n(plan, "bf_repeat", "as_reported"))
})

test_that("a posterior from a vague or default prior stands in for the estimate", {
  plan <- replication_planning("one_sample", 0.4, original_n = 50, original_analysis = "posterior",
    original_prior = "default", original_se = 0.14)
  expect_equal(plan$original$se, 0.14)
  expect_false("small_telescopes" %in% plan$goals$goal)
  expect_true("bf_repeat" %in% plan$goals$goal)
  r <- replication_planning("correlation", 0.3, original_n = 80, original_analysis = "posterior",
    original_prior = "vague", original_se = 0.1)
  expect_equal(r$original$se, 0.1 / (1 - 0.3^2))
  expect_false(any(c("bf_repeat", "small_telescopes") %in% r$goals$goal))
  by_ci <- replication_planning("correlation", 0.3, original_n = 80, original_analysis = "posterior",
    original_prior = "vague", original_ci = c(0.09, 0.49))
  expect_equal(by_ci$original$se, (atanh(0.49) - atanh(0.09)) / (2 * qnorm(0.975)))
})

test_that("the script redoes a Bayesian original's numbers", {
  skip_if_not_installed("BayesFactor")
  skip_if_not_installed("bfpwr")
  plans <- list(
    replication_planning("paired", original_n = 25, original_analysis = "bayes_factor", original_bf = 8,
      original_prior_scale = 0.5),
    replication_planning("correlation", 0.3, original_n = 80, original_analysis = "posterior",
      original_prior = "vague", original_se = 0.1))
  for (plan in plans) {
    lines <- strsplit(replication_planning_script(plan), "\n")[[1]]
    expect_false(any(grepl("pwrss|telescope", lines)))
    env <- new.env()
    code <- lines[!grepl("^library", lines)]
    table_end <- max(grep("^\\)\\)$", code))
    table <- suppressWarnings(eval(parse(text = c("library(BayesRepDesign)", code[seq_len(table_end)])), env))
    for (prior in c("as_reported", "uncertain", "shrunk")) {
      expect_equal(unname(table["significance", prior]), goal_n(plan, "significance", prior))
    }
    if ("bf_repeat" %in% plan$goals$goal) {
      rest <- code[-seq_len(table_end)]
      repeated <- eval(parse(text = rest[grepl("^bf_size <-|^sapply", rest)]), env)
      expect_equal(unname(repeated[["as_reported"]]), goal_n(plan, "bf_repeat", "as_reported"))
      expect_equal(eval(parse(text = rest[grepl("^bf_size\\(k", rest)]), env),
        plan$goals$n[plan$goals$goal == "bf_null"])
    }
  }
})

test_that("a Bayesian original that can't be planned gets plain words", {
  expect_error(replication_planning("correlation", 0.3, original_n = 80, original_analysis = "bayes_factor",
    original_bf = 5), "only for a t-test")
  expect_error(replication_planning("one_sample", original_n = 50, original_analysis = "bayes_factor",
    original_bf = 0.05), "BF01")
  expect_error(replication_planning("one_sample", original_n = 50, original_analysis = "bayes_factor",
    original_bf = -1), "above 0")
  expect_error(replication_planning("one_sample", 0.4, original_n = 50, original_analysis = "posterior",
    original_prior = "informative", original_se = 0.1), "vague or a default")
  expect_error(replication_planning("one_sample", 0.4, original_n = 50, original_analysis = "posterior",
    original_prior = "vague"), "posterior's standard deviation")
  expect_error(replication_planning("one_sample", original_n = 50, original_analysis = "bayes_factor",
    original_bf = 5, original_prior_scale = 0), "scale")
  expect_error(replication_planning("one_sample", 0.4, original_n = 50, original_analysis = "bayesian"),
    "original_analysis")
})

test_that("the app's starting variation (tau 0.05) against BayesRepDesign's default of none", {
  # The size of the departure recorded in docs/conventions.md ("Variation
  # between studies in replication plans"): for an original d = 0.7 with
  # 20 per group, the significance goal asks for 106 with no variation and
  # 110 with tau 0.05 under the uncertain belief, 200 and 210 shrunk; the
  # as-reported belief has no variation either way (66).
  none <- two_groups(tau = 0)
  small <- two_groups(tau = 0.05)
  expect_equal(goal_n(none, "significance", "as_reported"), goal_n(small, "significance", "as_reported"))
  expect_equal(c(goal_n(none, "significance", "uncertain"), goal_n(small, "significance", "uncertain")), c(106, 110))
  expect_equal(c(goal_n(none, "significance", "shrunk"), goal_n(small, "significance", "shrunk")), c(200, 210))
})

test_that("a reported t or repeated-measures d becomes the design's d (Lakens, 2013)", {
  # Pairs: d_z = t / sqrt(n); a d_rm (or d_av with equal SDs) divided by sqrt(2(1 - r)).
  from_t <- replication_planning("paired", 1.99, original_n = 60, original_effect_type = "t")
  expect_equal(from_t$original$estimate, 1.99 / sqrt(60))
  expect_equal(from_t$goals$n, replication_planning("paired", 1.99 / sqrt(60), original_n = 60)$goals$n)
  from_rm <- replication_planning("paired", 0.4, original_n = 40, original_effect_type = "d_rm", original_r = 0.7)
  expect_equal(from_rm$original$estimate, 0.4 / sqrt(2 * 0.3))
  # A correlation of .5 leaves d_rm and d_z equal.
  expect_equal(replication_planning("paired", 0.4, original_n = 40, original_effect_type = "d_rm",
    original_r = 0.5)$original$estimate, 0.4)
  # Two groups: d = t sqrt(1/n1 + 1/n2); one sample: t / sqrt(n).
  expect_equal(replication_planning("two_groups", 2.5, original_n1 = 20, original_n2 = 30,
    original_effect_type = "t")$original$estimate, 2.5 * sqrt(1 / 20 + 1 / 30))
  expect_equal(replication_planning("one_sample", 3, original_n = 25,
    original_effect_type = "t")$original$estimate, 3 / 5)
  # The inputs say what was reported, and the script redoes the conversion.
  expect_identical(from_rm$inputs$original_effect_type, "d_rm")
  expect_equal(from_rm$inputs$original_reported, 0.4)
  for (plan in list(from_t, from_rm)) {
    env <- new.env()
    results <- suppressWarnings(lapply(parse(text = replication_planning_script(plan)), eval, envir = env))
    expect_equal(env$to, plan$original$estimate)
  }
  # Refused where it doesn't apply, in plain words.
  expect_error(replication_planning("correlation", 2, original_n = 50, original_effect_type = "t"), "t-test original only")
  expect_error(replication_planning("two_groups", 0.4, original_n1 = 20, original_n2 = 20,
    original_effect_type = "d_rm", original_r = 0.5), "applies to pairs")
  expect_error(replication_planning("paired", 0.4, original_n = 40, original_effect_type = "d_rm"), "correlation between")
})

test_that("an F with one numerator df gives another design's test statistic", {
  # Shnabel et al. (2009), Study 1: the role by message interaction,
  # F(1, 118) = 15.38, a contrast of 0.74 scale points.
  from_f <- replication_planning("generic", 0.74, original_n = 120, original_f = 15.38)
  from_t <- replication_planning("generic", 0.74, original_n = 120, original_statistic = sqrt(15.38))
  expect_equal(from_f$original$se, from_t$original$se)
  expect_equal(from_f$goals$n, from_t$goals$n)
  expect_error(replication_planning("generic", 0.74, original_n = 120, original_f = -1), "above 0")
  expect_error(replication_planning("paired", 0.5, original_n = 30, original_f = 4), "another design")
})
