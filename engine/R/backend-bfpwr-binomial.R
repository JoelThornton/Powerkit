# Backend adapter: the Bayes factor test of one proportion (the binomial
# Bayes factor), by exact calculation, via bfpwr.
#
# The analysis prior on the proportion under the alternative is a beta
# distribution, Beta(a, b), Beta(1, 1) (uniform) by default: bfpwr's
# default (binbf01(a = 1, b = 1)) and JASP's (its Bayesian binomial test's
# "Beta prior: parameter a" and "b", both 1). The design prior is the
# expected proportion, exactly, or a beta distribution with that mean and
# the SD the planner gives (population > p_sd).
#
# The hypotheses (target_test > one_sided_null):
#   two-sided            H0: p = p0 against H1: p != p0, the prior on all of
#                        (0, 1). bfpwr's "point" test, the same Bayes factor
#                        as JASP's two-sided test. Power from bfpwr's
#                        pbinbf01(), which sums the binomial probabilities of
#                        the outcomes whose Bayes factor passes the threshold.
#   one-sided, "point"   H0: p = p0 against H1: p > p0 (or < p0), the prior
#   (the default)        truncated to that side: the test JASP's Bayesian
#                        binomial test runs when a direction is chosen.
#                        bfpwr has no function for it, so the Bayes factor
#                        is bfpwr's two-sided one times the ratio of the
#                        posterior to the prior probability of that side,
#                        which follows from the definition of the Bayes
#                        factor as a ratio of marginal likelihoods (checked
#                        against that definition, integrated numerically, in
#                        test-backend-bayes-binomial.R). Power is summed
#                        over the outcomes 0 to n, as pbinbf01() does.
#   one-sided,           H0: p <= p0 against H1: p > p0: bfpwr's "direction"
#   "directional"        test, the prior truncated to each side under each
#                        hypothesis. Power from pbinbf01(). For p < p0 the
#                        proportion of "no" is tested instead.
# With no effect, "no effect" is p = p0, under every version.
# n is the number of people (trials); no random numbers are drawn.

bfbin_test <- function(spec) bayes_factor_test(spec) && identical(spec$template, "one_proportion")

bfbin_defaults <- list(prior_a = 1, prior_b = 1, one_sided_null = "point", p_sd = 0)

bfbin_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  list(
    p = pop$p, p0 = pop$p0, p_sd = pop$p_sd %||% bfbin_defaults$p_sd,
    threshold = tt$evidence_threshold %||% bayes_defaults$evidence_threshold,
    prior_a = tt$prior_a %||% bfbin_defaults$prior_a, prior_b = tt$prior_b %||% bfbin_defaults$prior_b,
    alternative = bfpwr_alternative(spec),
    one_sided_null = tt$one_sided_null %||% bfbin_defaults$one_sided_null
  )
}

# The beta design prior with the planner's mean and SD (its shape
# parameters from the mean and variance of a beta distribution); NULL for
# exactly p.
bfbin_design_prior <- function(p, p_sd) {
  if (is.null(p_sd) || p_sd == 0) {
    return(NULL)
  }
  size <- p * (1 - p) / p_sd^2 - 1
  list(a = p * size, b = (1 - p) * size)
}

# The arguments bfpwr's pbinbf01() takes for a design that bfpwr covers:
# the two-sided test, and the "directional" one-sided test (mirrored for
# "less": the proportion of "no" against 1 - p0, the prior's a and b
# swapped).
bfbin_bfpwr_args <- function(inputs, n, p, p_sd) {
  less <- identical(inputs$alternative, "less")
  type <- if (identical(inputs$alternative, "two.sided")) "point" else "direction"
  flip <- function(x) if (less) 1 - x else x
  design <- bfbin_design_prior(flip(p), p_sd)
  c(
    list(n = n, p0 = flip(inputs$p0), type = type,
      a = if (less) inputs$prior_b else inputs$prior_a, b = if (less) inputs$prior_a else inputs$prior_b),
    if (is.null(design)) list(dp = flip(p)) else list(dp = NA, da = design$a, db = design$b, dl = 0, du = 1)
  )
}

bfbin_by_bfpwr <- function(inputs) {
  identical(inputs$alternative, "two.sided") || identical(inputs$one_sided_null, "directional")
}

# BF10 at each number of "yes" x out of n, for the one-sided test against a
# point null: bfpwr's two-sided BF10 times P(side | data) / P(side) under
# the beta analysis prior and its posterior, Beta(a + x, b + n - x).
bfbin_point_one_sided_bf10 <- function(x, n, inputs) {
  a <- inputs$prior_a
  b <- inputs$prior_b
  upper <- identical(inputs$alternative, "greater")
  log_two_sided <- -bfpwr::binbf01(x = x, n = n, p0 = inputs$p0, type = "point", a = a, b = b, log = TRUE)
  log_posterior_side <- stats::pbeta(inputs$p0, a + x, b + n - x, lower.tail = !upper, log.p = TRUE)
  log_prior_side <- stats::pbeta(inputs$p0, a, b, lower.tail = !upper, log.p = TRUE)
  exp(log_two_sided + log_posterior_side - log_prior_side)
}

# The probability of each number of "yes" out of n: binomial at exactly p,
# beta-binomial under a beta design prior.
bfbin_outcome_probabilities <- function(n, p, p_sd) {
  x <- 0:n
  design <- bfbin_design_prior(p, p_sd)
  if (is.null(design)) {
    return(stats::dbinom(x, n, p))
  }
  exp(lchoose(n, x) + lbeta(x + design$a, n - x + design$b) - lbeta(design$a, design$b))
}

# The chance that BF10 is at least k (`for_effect = TRUE`), or BF01 above
# k, at n people when the proportion is p (or drawn from the design
# prior with SD p_sd).
bfbin_chance <- function(inputs, n, k, for_effect, p = inputs$p, p_sd = inputs$p_sd) {
  if (bfbin_by_bfpwr(inputs)) {
    # pbinbf01(k) is P(BF01 <= k); BF10 >= k is BF01 <= 1 / k.
    args <- c(bfbin_bfpwr_args(inputs, n, p, p_sd), if (for_effect) list(k = 1 / k) else list(k = k, lower.tail = FALSE))
    return(call_backend("bfpwr", quietly(do.call(bfpwr::pbinbf01, args))))
  }
  bf10 <- call_backend("bfpwr", bfbin_point_one_sided_bf10(0:n, n, inputs))
  # As pbinbf01(): BF10 at least k for an effect, BF01 above k for none.
  pass <- if (for_effect) bf10 >= k else 1 / bf10 > k
  sum(bfbin_outcome_probabilities(n, p, p_sd)[pass])
}

bfbin_power <- function(inputs, n) bfbin_chance(inputs, n, inputs$threshold, for_effect = TRUE)

bfbin_backend <- function(spec, seed = NULL) {
  inputs <- bfbin_inputs(spec)
  power_at <- function(n) bfbin_power(inputs, n)
  list(
    name = "bfpwr",
    packages = "bfpwr",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = if (bfbin_by_bfpwr(inputs)) "bfpwr::pbinbf01" else "bfpwr::binbf01"),
    n_step = 1,
    # Power goes up and down with n, as for any test of a count: the
    # sample size search checks every n below its answer (search_n_exact()).
    sawtooth = TRUE,
    exact_min_n = max(1, minimum_n(spec)),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfbin_check_run(spec, inputs)
  )
}

bfbin_null_side <- function(inputs, n) {
  list(
    evidence_for_null = bfbin_chance(inputs, n, inputs$threshold, for_effect = FALSE, p = inputs$p0, p_sd = 0),
    misleading_evidence = bfbin_chance(inputs, n, inputs$threshold, for_effect = TRUE, p = inputs$p0, p_sd = 0)
  )
}

bfbin_check_run <- function(spec, inputs) {
  row <- function(parameter, spec_value, passed) {
    data.frame(parameter = parameter, specified = spec_value, recovered = passed, ok = isTRUE(all.equal(spec_value, passed)))
  }
  design <- bfbin_design_prior(inputs$p, inputs$p_sd)
  design_mean <- if (is.null(design)) inputs$p else design$a / (design$a + design$b)
  design_sd <- if (is.null(design)) 0 else sqrt(design$a * design$b / ((design$a + design$b)^2 * (design$a + design$b + 1)))
  rbind(
    row("expected proportion: the mean of the design prior", inputs$p, design_mean),
    row("uncertainty about it: the SD of the beta design prior", inputs$p_sd, design_sd),
    row("fixed proportion tested against (p0)", inputs$p0, inputs$p0),
    row("evidence threshold BF10", inputs$threshold, inputs$threshold),
    row("analysis prior Beta(a, b): a", inputs$prior_a, inputs$prior_a),
    row("analysis prior Beta(a, b): b", inputs$prior_b, inputs$prior_b),
    row("probabilities of the outcomes 0 to 100 add up to 1", 1, sum(bfbin_outcome_probabilities(100, inputs$p, inputs$p_sd)))
  )
}

bfbin_hypotheses_words <- function(inputs) {
  if (identical(inputs$alternative, "two.sided")) {
    return(sprintf("p = %s against p != %s", format_number(inputs$p0), format_number(inputs$p0)))
  }
  side <- if (identical(inputs$alternative, "greater")) ">" else "<"
  if (identical(inputs$one_sided_null, "directional")) {
    sprintf("p %s %s against p %s %s", if (side == ">") "<=" else ">=", format_number(inputs$p0), side, format_number(inputs$p0))
  } else {
    sprintf("p = %s against p %s %s", format_number(inputs$p0), side, format_number(inputs$p0))
  }
}

# The R script for the binomial Bayes factor: the same calculation at each
# size powerkit computed (export_script()).
bfbin_script <- function(spec, result) {
  inputs <- bfbin_inputs(spec)
  design <- bfbin_design_prior(inputs$p, inputs$p_sd)
  by_bfpwr <- bfbin_by_bfpwr(inputs)
  less <- identical(inputs$alternative, "less")
  prior_lines <- c(
    sprintf("p <- %s # the expected proportion of 'yes'", r_code(inputs$p)),
    sprintf("p_sd <- %s # uncertainty about it (SD of a beta design prior; 0 = exactly p)", r_code(inputs$p_sd)),
    sprintf("p0 <- %s # the fixed proportion it is compared with", r_code(inputs$p0)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("a <- %s; b <- %s # the beta analysis prior, Beta(a, b)", r_code(inputs$prior_a), r_code(inputs$prior_b))
  )
  design_lines <- c(
    "# The beta design prior with mean p and SD p_sd (none when p_sd is 0).",
    "size <- if (p_sd > 0) p * (1 - p) / p_sd^2 - 1 else NA",
    "da <- p * size; db <- (1 - p) * size"
  )
  power_lines <- if (by_bfpwr) {
    if (less) {
      c(
        "# Fewer 'yes' than p0: bfpwr's directional test of the proportion of 'no'.",
        "power_at <- function(n) {",
        "  design <- if (p_sd > 0) list(dp = NA, da = db, db = da) else list(dp = 1 - p)",
        "  do.call(pbinbf01, c(list(k = 1 / threshold, n = n, p0 = 1 - p0, type = \"direction\", a = b, b = a), design))",
        "}"
      )
    } else {
      c(
        "power_at <- function(n) {",
        "  design <- if (p_sd > 0) list(dp = NA, da = da, db = db) else list(dp = p)",
        sprintf("  do.call(pbinbf01, c(list(k = 1 / threshold, n = n, p0 = p0, type = %s, a = a, b = b), design))",
          r_code(if (identical(inputs$alternative, "two.sided")) "point" else "direction")),
        "}"
      )
    }
  } else {
    c(
      sprintf("upper <- %s # the hypothesis: more 'yes' than p0 (TRUE) or fewer (FALSE)", r_code(!less)),
      "# BF10 for p = p0 against the one side: bfpwr's two-sided BF10 times the",
      "# ratio of the posterior to the prior probability of that side.",
      "bf10_at <- function(x, n) {",
      "  two_sided <- 1 / binbf01(x = x, n = n, p0 = p0, type = \"point\", a = a, b = b)",
      "  two_sided * pbeta(p0, a + x, b + n - x, lower.tail = !upper) / pbeta(p0, a, b, lower.tail = !upper)",
      "}",
      "power_at <- function(n) {",
      "  x <- 0:n",
      "  chance <- if (p_sd > 0) exp(lchoose(n, x) + lbeta(x + da, n - x + db) - lbeta(da, db)) else dbinom(x, n, p)",
      "  sum(chance[bf10_at(x, n) >= threshold])",
      "}"
    )
  }
  c(
    script_header(spec, result, "bfpwr", if (by_bfpwr) "bfpwr::pbinbf01" else "bfpwr::binbf01"),
    "library(bfpwr)",
    "",
    "# Inputs ----",
    prior_lines,
    bayes_goal_inputs(spec),
    design_lines,
    "",
    "# The probability that BF10 reaches the threshold with n people.",
    power_lines,
    "",
    if (identical(spec$goal$type, "sample_size")) sawtooth_goal_section(spec, result) else pwr_goal_section(spec, result),
    comparison_section()
  )
}

bfbin_design_description <- function(spec, label) {
  inputs <- bfbin_inputs(spec)
  sprintf(
    "Bayes factor test of the proportion of %s: %s, with a Beta(%s, %s) analysis prior; strong evidence is BF10 of at least %s",
    label("Y"), bfbin_hypotheses_words(inputs), format_number(inputs$prior_a), format_number(inputs$prior_b),
    format_number(inputs$threshold)
  )
}
