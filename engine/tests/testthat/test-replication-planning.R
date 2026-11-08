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
