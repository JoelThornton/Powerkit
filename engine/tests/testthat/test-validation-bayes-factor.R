# Validation: Bayes factor t-tests (one sample, paired, two groups).
# Backend: bfpwr, which computes the probability that the JZS Bayes factor
# passes a threshold in closed form (Pawel & Held, 2025, the package's own
# citation()). Build guide section 6:
#   1. published examples (placeholders for the maintainer)
#   2. agreement with simulated Bayes factors: data drawn under the design
#      prior, the t statistic from stats::t.test(), and the Bayes factor
#      from bfpwr::tbf01(), so the check doesn't rely on bfpwr's power
#      formula
#   3. the no-effect side: strong evidence for no effect, and misleading
#      strong evidence for an effect, when there is none
#   4. the size of the difference at small samples: bfpwr treats the
#      effect estimate as normal with SE 1 / sqrt(effective n) (its
#      ptbf01() source), a large-sample approximation to the t statistic,
#      so with few degrees of freedom it gives a little less power than
#      the Bayes factor simulated directly (docs/conventions.md, "Known
#      differences", 6)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bayes_validation_spec <- function(template, effect, seed, n = NULL, target_power = NULL, effect_sd = 0,
                                  threshold = 10, prior_scale = 1 / sqrt(2), alternative = "two_sided") {
  v <- validation_variable
  variables <- switch(
    template,
    one_sample_t = list(Y = v("continuous", "Score")),
    paired_t = list(X = v("within_factor", "Time", levels = list("Before", "After")), Y = v("continuous", "Score")),
    independent_t = list(X = v("binary", "Group", levels = list("Control", "Treatment")), Y = v("continuous", "Score"))
  )
  population <- list(metric = "standardised", effect_sd = effect_sd)
  population[[if (template == "paired_t") "dz" else "d"]] <- effect
  validation_spec(
    design = "basic_test",
    template = template,
    variables = variables,
    population = population,
    target_test = list(
      effect = if (template == "one_sample_t") "mean" else "mean_difference",
      method = "bayes_factor", alternative = alternative,
      evidence_threshold = threshold, prior_scale = prior_scale
    ),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# The proportion of simulated studies whose BF10 reaches `threshold`
# (BF01 at most 1 / threshold), with the true effect drawn from the design
# prior N(effect, effect_sd^2) for each study. `n` is per group for two
# groups, and the number of people otherwise (pairs: the differences are
# drawn directly, with SD 1).
simulated_bayes_power <- function(type, n, effect, effect_sd, threshold, prior_scale,
                                  alternative, nrep, seed, evidence_for_null = FALSE) {
  set.seed(seed)
  hits <- vapply(seq_len(nrep), function(i) {
    delta <- stats::rnorm(1, effect, effect_sd)
    t <- if (type == "two.sample") {
      stats::t.test(stats::rnorm(n, delta), stats::rnorm(n), var.equal = TRUE)$statistic
    } else {
      stats::t.test(stats::rnorm(n, delta))$statistic
    }
    bf01 <- bfpwr::tbf01(t = t, n = n, pscale = prior_scale, type = type, alternative = alternative)
    if (evidence_for_null) bf01 >= threshold else bf01 <= 1 / threshold
  }, logical(1))
  mean(hits)
}

# 1. Published examples ------------------------------------------------------------

test_that("two groups, one-sided, fixed effect: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer. bfpwr's own help (ntbf01(),
  #   powertbf01()) works an example it attributes to Schönbrodt and
  #   Wagenmakers (2018, p. 135): BF threshold 6, power 0.95, d = 0.5,
  #   one-sided. Transcribe the published figures from that source, not
  #   from bfpwr: the design (one sample, paired or two groups), d, the
  #   threshold (as BF10), the prior scale, the direction, the sample size
  #   per group or in total, and the probability of strong evidence. If
  #   the published figure comes from a simulation, also transcribe its
  #   number of simulated studies.
  template <- TODO_PUBLISHED_VALUE # "independent_t", "paired_t" or "one_sample_t"
  d <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  prior_scale <- TODO_PUBLISHED_VALUE
  alternative <- TODO_PUBLISHED_VALUE # "greater", "less" or "two_sided"
  total_n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # NULL if not from a simulation
  skip_if_todo(template, d, threshold, prior_scale, alternative, total_n, published_power, reference_nrep)

  spec <- bayes_validation_spec(template, d, seed = 101, n = total_n, threshold = threshold,
                                prior_scale = prior_scale, alternative = alternative)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 2. Agreement with simulated Bayes factors ----------------------------------------

bayes_cases <- list(
  list("one_sample_t", "one.sample", n = 100, effect = 0.3, effect_sd = 0, alternative = "two_sided"),
  list("paired_t", "paired", n = 60, effect = 0.3, effect_sd = 0.1, alternative = "greater"),
  list("independent_t", "two.sample", n = 50, effect = 0.5, effect_sd = 0, alternative = "two_sided"),
  list("independent_t", "two.sample", n = 80, effect = 0.4, effect_sd = 0.2, alternative = "greater")
)

for (case in bayes_cases) {
  label <- sprintf("%s, n %s, effect %s (SD %s), %s", case[[1]], case$n, case$effect, case$effect_sd, case$alternative)
  test_that(paste0(label, ": matches simulated Bayes factors"), {
    skip_unless_full_validation()
    total <- if (case[[2]] == "two.sample") 2 * case$n else case$n
    spec <- bayes_validation_spec(case[[1]], case$effect, seed = 201, n = total,
                                  effect_sd = case$effect_sd, alternative = case$alternative)
    alternative <- if (case$alternative == "two_sided") "two.sided" else case$alternative
    nrep <- validation_nrep()
    simulated <- simulated_bayes_power(case[[2]], case$n, case$effect, case$effect_sd, 10, 1 / sqrt(2),
                                       alternative, nrep, seed = 201)
    expect_power_near(engine_power(spec), simulated, reference_nrep = nrep)
  })
}

# 3. The no-effect side ------------------------------------------------------------

test_that("two groups, no effect: the chance of strong evidence for no effect matches simulation", {
  skip_unless_full_validation()
  spec <- bayes_validation_spec("independent_t", 0.4, seed = 301, n = 400, threshold = 6)
  result <- engine_function("run_spec")(spec)
  nrep <- validation_nrep()
  for_null <- simulated_bayes_power("two.sample", 200, 0, 0, 6, 1 / sqrt(2), "two.sided", nrep,
                                    seed = 301, evidence_for_null = TRUE)
  misleading <- simulated_bayes_power("two.sample", 200, 0, 0, 6, 1 / sqrt(2), "two.sided", nrep, seed = 302)
  expect_power_near(exact_estimate(result$bayes$evidence_for_null), for_null, reference_nrep = nrep)
  expect_power_near(exact_estimate(result$bayes$misleading_evidence), misleading, reference_nrep = nrep)
})

# 4. The size of the difference at small samples ------------------------------------

for (n in c(20, 40)) {
  test_that(sprintf("one sample, n %s: bfpwr's normal approximation gives a little less power than simulation", n), {
    skip_unless_full_validation()
    spec <- bayes_validation_spec("one_sample_t", 0.4, seed = 401, n = n)
    nrep <- validation_nrep()
    simulated <- simulated_bayes_power("one.sample", n, 0.4, 0, 10, 1 / sqrt(2), "two.sided", nrep, seed = 401)
    approximate <- engine_power(spec)$power
    expect_lt(approximate, simulated)
    expect_lt(simulated - approximate, 0.06)
  })
}

# 5. The Labs planning tool (bayes_planning()) -------------------------------------
# The same simulation checks each of its outcomes: strong evidence for an
# effect under a design prior with spread, and both kinds of strong
# evidence when there is no effect.

test_that("Labs planning, two groups with an uncertain effect: every outcome matches simulated Bayes factors", {
  skip_unless_full_validation()
  plan <- bayes_planning(60, "two.sample", effect = 0.5, effect_sd = 0.2, threshold = 6)
  nrep <- validation_nrep()
  outcome <- function(truth, column) exact_estimate(plan$outcomes[plan$outcomes$truth == truth, column])
  expect_power_near(outcome("belief", "for_effect"),
    simulated_bayes_power("two.sample", 60, 0.5, 0.2, 6, 1 / sqrt(2), "two.sided", nrep, seed = 501), reference_nrep = nrep)
  expect_power_near(outcome("null", "for_null"),
    simulated_bayes_power("two.sample", 60, 0, 0, 6, 1 / sqrt(2), "two.sided", nrep, seed = 502, evidence_for_null = TRUE),
    reference_nrep = nrep)
  expect_power_near(outcome("null", "for_effect"),
    simulated_bayes_power("two.sample", 60, 0, 0, 6, 1 / sqrt(2), "two.sided", nrep, seed = 503), reference_nrep = nrep)
})

test_that("Labs planning, paired and one-sided with a wider prior: matches simulated Bayes factors", {
  skip_unless_full_validation()
  plan <- bayes_planning(80, "paired", effect = 0.3, effect_sd = 0.1, prior_scale = 1, threshold = 3, alternative = "greater")
  nrep <- validation_nrep()
  outcome <- function(truth, column) exact_estimate(plan$outcomes[plan$outcomes$truth == truth, column])
  expect_power_near(outcome("belief", "for_effect"),
    simulated_bayes_power("paired", 80, 0.3, 0.1, 3, 1, "greater", nrep, seed = 504), reference_nrep = nrep)
  expect_power_near(outcome("null", "for_null"),
    simulated_bayes_power("paired", 80, 0, 0, 3, 1, "greater", nrep, seed = 505, evidence_for_null = TRUE),
    reference_nrep = nrep)
})
