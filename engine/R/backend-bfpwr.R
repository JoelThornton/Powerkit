# Backend adapter: Bayes factor t-tests (one sample, paired, two groups) by
# closed-form calculation, via bfpwr.
#
# bfpwr (Pawel & Held, 2025, the package's own citation()) computes the
# probability that the t-test Bayes factor passes a threshold, for a normal
# "design prior" on the true standardised effect, without simulation. The
# Bayes factor is the Jeffreys-Zellner-Siow (JZS) one: a Cauchy analysis
# prior centred on 0 (bfpwr's tbf01() help: "The Jeffreys-Zellner-Siow (JZS)
# Bayes factor (Rouder et al., 2009) is obtained as a special case by
# setting the location of the prior to zero and the prior degrees of
# freedom to one, which is the default"). powerkit keeps those defaults and
# lets the user set the prior's scale (bfpwr's default 1/sqrt(2)).
#
# bfpwr works with BF01 (evidence for no effect over an effect). powerkit
# states the threshold as BF10 = k, so:
#   power (strong evidence for an effect)   P(BF01 <= 1/k), under the design
#                                           prior N(effect, effect_sd^2):
#                                           powertbf01(k = 1/k, dpm, dpsd)
#   strong evidence for no effect, if       P(BF01 >= k) with no effect:
#   there is none                           ptbf01(k, dpm = 0, dpsd = 0,
#                                           lower.tail = FALSE)
#   misleading evidence for an effect, if   P(BF01 <= 1/k) with no effect:
#   there is none                           ptbf01(1/k, dpm = 0, dpsd = 0)
# n is per group for two groups (bfpwr takes equal groups only), and the
# number of people (or pairs) otherwise. A one-sided hypothesis truncates
# the analysis prior to that direction (bfpwr's `alternative`).

bayes_factor_test <- function(spec) {
  identical(spec$target_test$method, "bayes_factor")
}

bfpwr_type <- function(spec) {
  switch(
    spec$template,
    one_sample_t = "one.sample",
    paired_t = "paired",
    independent_t = "two.sample"
  )
}

bfpwr_alternative <- function(spec) {
  switch(
    spec$target_test$alternative %||% "two_sided",
    two_sided = "two.sided",
    greater = "greater",
    less = "less"
  )
}

bayes_defaults <- list(evidence_threshold = 10, prior_scale = 1 / sqrt(2), effect_sd = 0)

bayes_threshold <- function(spec) spec$target_test$evidence_threshold %||% bayes_defaults$evidence_threshold

bfpwr_backend <- function(spec, seed = NULL) {
  if (bfbin_test(spec)) {
    return(bfbin_backend(spec, seed))
  }
  if (bfcor_test(spec)) {
    return(bfcor_backend(spec, seed))
  }
  inputs <- bfpwr_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  power_at <- function(n) bfpwr_power(inputs, n)
  list(
    name = "bfpwr",
    packages = "bfpwr",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "bfpwr::powertbf01"),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfpwr_check_run(spec, inputs)
  )
}

# The arguments bfpwr is given, and the size it takes at total n.
bfpwr_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  type <- bfpwr_type(spec)
  list(
    type = type,
    effect = if (identical(type, "paired")) pop$dz else pop$d,
    effect_sd = pop$effect_sd %||% bayes_defaults$effect_sd,
    threshold = tt$evidence_threshold %||% bayes_defaults$evidence_threshold,
    prior_scale = tt$prior_scale %||% bayes_defaults$prior_scale,
    alternative = bfpwr_alternative(spec),
    size = function(n) if (identical(type, "two.sample")) n / 2 else n
  )
}

bfpwr_args <- function(inputs, n) {
  list(
    n = inputs$size(n), k = 1 / inputs$threshold, plocation = 0, pscale = inputs$prior_scale,
    pdf = 1, type = inputs$type, alternative = inputs$alternative,
    dpm = inputs$effect, dpsd = inputs$effect_sd
  )
}

bfpwr_power <- function(inputs, n) {
  out <- call_backend("bfpwr", quietly(do.call(bfpwr::powertbf01, bfpwr_args(inputs, n))))
  out$power
}

# What the same sample would show if there were no effect: the chance of
# strong evidence for no effect, and of misleading strong evidence for one.
bfpwr_null_side <- function(inputs, n) {
  args <- list(
    n = inputs$size(n), plocation = 0, pscale = inputs$prior_scale, pdf = 1,
    type = inputs$type, alternative = inputs$alternative, dpm = 0, dpsd = 0
  )
  for_null <- call_backend("bfpwr", quietly(do.call(
    bfpwr::ptbf01, c(list(k = inputs$threshold, lower.tail = FALSE), args)
  )))
  misleading <- call_backend("bfpwr", quietly(do.call(
    bfpwr::ptbf01, c(list(k = 1 / inputs$threshold), args)
  )))
  list(evidence_for_null = for_null, misleading_evidence = misleading)
}

# The Bayes factor settings and the no-effect side, for the result
# (run_spec()); NULL for every other test.
bayes_summary <- function(spec, n) {
  if (!bayes_factor_test(spec) || is.null(n) || is.na(n)) {
    return(NULL)
  }
  if (bfbin_test(spec)) {
    inputs <- bfbin_inputs(spec)
    return(c(
      list(evidence_threshold = inputs$threshold, prior_a = inputs$prior_a, prior_b = inputs$prior_b,
        effect_sd = inputs$p_sd, n = n, hypotheses = bfbin_hypotheses_words(inputs)),
      bfbin_null_side(inputs, n)
    ))
  }
  if (bfcor_test(spec)) {
    inputs <- bfcor_inputs(spec)
    return(c(
      list(evidence_threshold = inputs$threshold, prior_width = inputs$prior_width,
        effect_sd = inputs$r_sd, n = n, hypotheses = bfcor_hypotheses_words(inputs)),
      bfcor_null_side(inputs, n)
    ))
  }
  inputs <- bfpwr_inputs(spec)
  c(
    list(
      evidence_threshold = inputs$threshold,
      prior_scale = inputs$prior_scale,
      effect_sd = inputs$effect_sd,
      n = n
    ),
    bfpwr_null_side(inputs, n)
  )
}

# Check run: no data are simulated, so the check confirms bfpwr receives
# the effect, the prior and the threshold the spec gives.
bfpwr_check_run <- function(spec, inputs) {
  args <- bfpwr_args(inputs, 100)
  name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  row <- function(parameter, spec_value, passed) {
    data.frame(
      parameter = parameter, specified = spec_value, recovered = passed,
      ok = isTRUE(all.equal(spec_value, passed))
    )
  }
  rbind(
    row(sprintf("expected effect (%s) passed to bfpwr as the design prior's mean (dpm)", name), inputs$effect, args$dpm),
    row("uncertainty about the effect passed as the design prior's SD (dpsd)", inputs$effect_sd, args$dpsd),
    row("evidence threshold BF10, passed as the BF01 threshold k = 1 / BF10", inputs$threshold, 1 / args$k),
    row("scale of the Cauchy analysis prior (pscale)", inputs$prior_scale, args$pscale),
    row(
      "size bfpwr is given at a total of 100 (per group for two groups)",
      if (identical(inputs$type, "two.sample")) 50 else 100, args$n
    )
  )
}

# The R script for a Bayes factor t-test: the same bfpwr calls at each size
# powerkit computed (export_script()).
bfpwr_script <- function(spec, result) {
  if (bfbin_test(spec)) {
    return(bfbin_script(spec, result))
  }
  if (bfcor_test(spec)) {
    return(bfcor_script(spec, result))
  }
  inputs <- bfpwr_inputs(spec)
  effect_name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  size_line <- if (identical(inputs$type, "two.sample")) {
    "  n <- n_total / 2 # bfpwr takes the size of each group (equal groups)"
  } else {
    "  n <- n_total"
  }
  c(
    script_header(spec, result, "bfpwr", "bfpwr::powertbf01"),
    "library(bfpwr)",
    "",
    "# Inputs ----",
    sprintf("effect <- %s # the expected effect, as %s", r_code(inputs$effect), effect_name),
    sprintf("effect_sd <- %s # uncertainty about it (SD of the normal design prior; 0 = exactly this effect)", r_code(inputs$effect_sd)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this (BF01 at most 1 / threshold)", r_code(inputs$threshold)),
    sprintf("prior_scale <- %s # scale of the Cauchy analysis prior (the JZS Bayes factor)", r_code(inputs$prior_scale)),
    sprintf("type <- %s", r_code(inputs$type)),
    sprintf("alternative <- %s", r_code(inputs$alternative)),
    bayes_goal_inputs(spec),
    "",
    "# The probability that BF10 reaches the threshold at a total sample size.",
    "power_at <- function(n_total) {",
    size_line,
    "  powertbf01(",
    "    n = n, k = 1 / threshold, plocation = 0, pscale = prior_scale, pdf = 1,",
    "    type = type, alternative = alternative, dpm = effect, dpsd = effect_sd",
    "  )$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# The goal's inputs for a Bayes factor test: no alpha.
bayes_goal_inputs <- function(spec) {
  goal <- spec$goal
  c(
    switch(
      goal$type,
      sample_size = sprintf("target_power <- %s # target probability that BF10 reaches the threshold", r_code(goal$power)),
      power = sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(goal$n))
    ),
    "# bfpwr's calculations draw no random numbers, so powerkit's seed isn't used."
  )
}

# The design line of the script header for a Bayes factor t-test.
bayes_design_description <- function(spec, label, levels) {
  if (bfbin_test(spec)) {
    return(bfbin_design_description(spec, label))
  }
  if (bfcor_test(spec)) {
    return(bfcor_design_description(spec, label))
  }
  inputs <- bfpwr_inputs(spec)
  test <- switch(
    inputs$type,
    one.sample = sprintf("one-sample Bayes factor t-test of %s", label("Y")),
    paired = sprintf("paired Bayes factor t-test of %s between the conditions of %s (%s)", label("Y"), label("X"), levels("X")),
    two.sample = sprintf("two-group Bayes factor t-test of %s between the groups of %s (%s)", label("Y"), label("X"), levels("X"))
  )
  sprintf(
    "%s: JZS Bayes factor with a Cauchy prior of scale %s%s; strong evidence is BF10 of at least %s",
    test, format_number(signif(inputs$prior_scale, 4)),
    if (identical(inputs$alternative, "two.sided")) "" else sprintf(" (one-sided, %s)", inputs$alternative),
    format_number(inputs$threshold)
  )
}
