# Backend adapter: non-inferiority tests by formula, via pwrss.
#
# A non-inferiority test asks whether a new condition is no worse than a
# comparison by more than a margin: a one-sided test of the difference
# against -margin (when higher scores are better) or +margin (when lower
# are better). pwrss's power.t.student() (two groups, paired data, one
# sample) and power.z.twoprops() (two proportions) take the margin
# directly ("For non-inferiority or superiority tests, add or subtract the
# margin from the null hypothesis value and use alternative = 'one.sided'",
# pwrss 0.3.1 help), testing H1: effect > margin.
#
# pwrss chooses the side of a one-sided test from the sign of the effect
# minus the margin, so powerkit passes the effect oriented so that better
# is positive and the margin as -margin, and the spec checks refuse an
# expected effect that isn't better than -margin (check_equivalence_test()):
# at or beyond the margin, the test would be run in the wrong direction.
#
# Orientation: the spec's d is group 2 minus group 1 (d_z: second minus
# first; one sample: mean minus the reference value), and p2 versus p1;
# group 2 (the second condition) is the new one. When lower is better, the
# effect's sign is reversed. pwrss's proportions are prob1 - prob2, so the
# new group is passed as prob1.

noninf_backend <- function(spec, seed = NULL) {
  inputs <- noninf_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) {
    out <- call_backend("pwrss", quietly(do.call(getExportedValue("pwrss", inputs$fun), inputs$args(n))))
    out$power
  }
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = paste0("pwrss::", inputs$fun)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() noninf_check_run(spec, inputs)
  )
}

# +1 when higher values are better, -1 when lower are.
noninf_sign <- function(spec) if (identical(spec$population$better, "lower")) -1 else 1

# The expected effect, better positive, in the spec's units.
noninf_effect <- function(spec) {
  pop <- spec$population
  raw <- switch(
    spec$template,
    noninf_paired = pop$dz,
    noninf_two_proportions = pop$p2 - pop$p1,
    pop$d
  )
  noninf_sign(spec) * raw
}

noninf_inputs <- function(spec) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  ratio <- spec$options$allocation_ratio %||% 1
  sizes <- function(n) {
    n1 <- round(n / (1 + ratio))
    c(n1, n - n1)
  }
  margin <- -pop$margin
  if (identical(spec$template, "noninf_two_proportions")) {
    better_higher <- noninf_sign(spec) > 0
    return(list(fun = "power.z.twoprops", effect = noninf_effect(spec), margin = margin, args = function(n) {
      s <- sizes(n)
      # prob1 - prob2 is tested against the margin: the better-is-positive
      # difference puts the new group (2) first when higher is better.
      list(
        prob1 = if (better_higher) pop$p2 else pop$p1, prob2 = if (better_higher) pop$p1 else pop$p2,
        margin = margin, n2 = if (better_higher) s[1] else s[2], n.ratio = if (better_higher) s[2] / s[1] else s[1] / s[2],
        alpha = alpha, alternative = "one.sided", verbose = 0
      )
    }))
  }
  design <- switch(spec$template, noninf_independent = "independent", noninf_paired = "paired", noninf_one_sample = "one.sample")
  list(fun = "power.t.student", effect = noninf_effect(spec), margin = margin, design = design, args = function(n) {
    common <- list(d = noninf_effect(spec), margin = margin, alpha = alpha, alternative = "one.sided", design = design, verbose = 0)
    if (identical(design, "independent")) {
      s <- sizes(n)
      c(common, list(n2 = s[2], n.ratio = s[1] / s[2]))
    } else {
      c(common, list(n2 = n))
    }
  })
}

# Check run: no simulated data; the check confirms what pwrss receives.
noninf_check_run <- function(spec, inputs) {
  args <- inputs$args(100)
  rows <- data.frame(
    parameter = c("margin passed to pwrss (minus the margin, better is positive)", "expected effect, better is positive"),
    specified = c(-spec$population$margin, noninf_effect(spec)),
    recovered = c(args$margin, if (is.null(args$d)) args$prob1 - args$prob2 else args$d)
  )
  rows$ok <- mapply(function(a, b) isTRUE(all.equal(a, b)), rows$specified, rows$recovered)
  rows
}

# The R script: the same pwrss call at each size powerkit computed.
noninf_script <- function(spec, result) {
  inputs <- noninf_inputs(spec)
  args <- inputs$args(100)
  fixed <- args[setdiff(names(args), c("n2", "n.ratio"))]
  arg_lines <- vapply(names(fixed), function(a) sprintf("    %s = %s,", a, r_code(fixed[[a]])), character(1))
  sizes <- if (identical(inputs$design, "independent") || identical(inputs$fun, "power.z.twoprops")) {
    ratio <- spec$options$allocation_ratio %||% 1
    first <- identical(inputs$fun, "power.t.student") || noninf_sign(spec) < 0
    c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1",
      if (first) "  sizes <- list(n2 = n2, n.ratio = n1 / n2) # pwrss's n2 is its second group" else
        "  sizes <- list(n2 = n1, n.ratio = n2 / n1) # the new group is pwrss's first, group 1 its second"
    )
  } else {
    "  sizes <- list(n2 = n_total)"
  }
  c(
    script_header(spec, result, "pwrss", paste0("pwrss::", inputs$fun, "(alternative = \"one.sided\", margin)")),
    "library(pwrss)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    "",
    "# Power of the one-sided non-inferiority test at a total sample size.",
    "# The effect is oriented so that better is positive, and the margin is",
    "# minus the largest difference in the wrong direction that is acceptable.",
    "power_at <- function(n_total) {",
    sizes,
    sprintf("  do.call(%s, c(list(", inputs$fun),
    sub(",$", "", paste(arg_lines, collapse = "\n")),
    "  ), sizes))$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# Minimum-effect tests ---------------------------------------------------------
#
# A minimum-effect test asks whether an effect is larger than a smallest
# effect of interest, not merely different from 0: the counterpart of an
# equivalence test. On the one-sample, paired and two-group t-test
# cards it is a test version (target_test > method "minimum_effect"),
# computed with the same pwrss function as non-inferiority,
# power.t.student(), with the margin on the effect's side of 0 ("For
# non-inferiority or superiority tests, add or subtract the margin from the
# null hypothesis value and use alternative = 'one.sided'", pwrss 1.3.3
# help):
#   one-sided ("greater" or "less"): alternative = "one.sided", margin =
#     +m or -m, so H1 is d > m (or d < -m);
#   two-sided: alternative = "two.one.sided" with margin = c(-m, m), whose
#     power pwrss computes as the chance the effect is shown to lie outside
#     both margins (each tail at alpha / 2) when the expected effect is
#     outside them.
# pwrss tests the t statistic of the mean difference against a noncentral
# t distribution centred on the margin (null.ncp = margin / SE): the exact
# test of a margin given in SD units. A margin fixed in the outcome's own
# units, tested with a shifted central t (as TOSTER's t_TOST(hypothesis =
# "MET") does), gives very slightly higher power (docs/conventions.md,
# Known difference 10).

minimum_effect_test <- function(spec) {
  identical(spec$target_test$method, "minimum_effect") &&
    identical(spec$design, "basic_test") &&
    spec$template %in% c("one_sample_t", "independent_t", "paired_t")
}

# The expected effect, in the spec's units (d, or d_z for pairs).
met_effect <- function(spec) {
  if (identical(spec$template, "paired_t")) spec$population$dz else spec$population$d
}

# The side the test is on: +1 (effect above the margin), -1 (below minus
# the margin), or 0 for two-sided (outside both).
met_side <- function(spec) {
  switch(spec$target_test$alternative %||% "two_sided", greater = 1, less = -1, 0)
}

met_inputs <- function(spec) {
  pop <- spec$population
  m <- pop$margin
  side <- met_side(spec)
  ratio <- spec$options$allocation_ratio %||% 1
  design <- switch(spec$template, independent_t = "independent", paired_t = "paired", one_sample_t = "one.sample")
  margin <- if (side == 0) c(-m, m) else side * m
  alternative <- if (side == 0) "two.one.sided" else "one.sided"
  sizes <- function(n) {
    if (!identical(design, "independent")) return(list(n2 = n))
    n1 <- round(n / (1 + ratio))
    list(n2 = n - n1, n.ratio = n1 / (n - n1))
  }
  list(
    fun = "power.t.student", design = design, margin = margin, alternative = alternative, side = side, sizes = sizes,
    args = function(n, d = met_effect(spec)) {
      c(list(d = d, margin = margin, alpha = spec$target_test$alpha, alternative = alternative, design = design, verbose = 0), sizes(n))
    }
  )
}

met_backend <- function(spec, seed = NULL) {
  inputs <- met_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) {
    call_backend("pwrss", quietly(do.call(pwrss::power.t.student, inputs$args(n))))$power
  }
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "pwrss::power.t.student"),
    n_step = step,
    # pwrss's t-tests need at least 3 degrees of freedom.
    exact_min_n = step * ceiling(max(minimum_n(spec), if (identical(inputs$design, "independent")) 6 else 4) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) met_sensitivity(spec, inputs, n, power),
    check_run = function() met_check_run(spec, inputs)
  )
}

# The smallest effect the minimum-effect test detects with the target
# power: pwrss's own solution (d = NULL), on the side of the expected
# effect (positive when none is given, or for a two-sided test with a
# positive or zero effect).
met_sensitivity <- function(spec, inputs, n, power) {
  effect <- met_effect(spec) %||% 0
  negative <- inputs$side < 0 || (inputs$side == 0 && isTRUE(effect < 0))
  args <- inputs$args(n, d = NULL)
  args$power <- power
  args$req.sign <- if (negative) "-" else "+"
  found <- tryCatch(call_backend("pwrss", quietly(do.call(pwrss::power.t.student, args))), error = function(e) NULL)
  if (is.null(found) || !is.finite(found$d)) {
    abort_run("No effect beyond the smallest effect of interest reaches the target power at this n. Check the margin and the direction of the test.")
  }
  name <- if (identical(spec$template, "paired_t")) "d_z" else "d"
  list(
    effect = found$d, effect_name = name, power = found$power,
    effect_description = switch(spec$template,
      paired_t = "Cohen's d_z (mean of the differences, in SDs of the differences)",
      independent_t = "Cohen's d (group 2 minus group 1, in SDs)",
      "Cohen's d (mean minus the comparison value, in SDs)")
  )
}

# Check run: no simulated data; the check confirms what pwrss receives.
met_check_run <- function(spec, inputs) {
  args <- inputs$args(100)
  m <- spec$population$margin
  rows <- data.frame(
    parameter = c("smallest effect of interest (margin) passed to pwrss", "expected effect"),
    specified = c(if (inputs$side == 0) m else inputs$side * m, met_effect(spec) %||% NA_real_),
    recovered = c(if (inputs$side == 0) max(args$margin) else args$margin, args$d %||% NA_real_)
  )
  rows$ok <- mapply(function(a, b) isTRUE(all.equal(a, b)) || (is.na(a) && is.na(b)), rows$specified, rows$recovered)
  rows
}

# Minimum-effect tests: the margin must be given, and the expected effect
# must lie beyond it on the tested side (at or inside it, the study would
# be unlikely to show the effect is larger, however many took part).
check_minimum_effect <- function(spec) {
  met <- identical(spec$target_test$method, "minimum_effect")
  margin <- spec$population$margin
  if (!met) {
    if (!is.null(margin) && spec$template %in% c("one_sample_t", "independent_t", "paired_t")) {
      return("'population > margin' is only used by a minimum-effect test: remove it, or set 'target_test > method' to 'minimum_effect'.")
    }
    return(character())
  }
  if (is.null(margin)) {
    return("A minimum-effect test needs the smallest effect of interest ('population > margin', or 'population > raw > margin' in the outcome's own units).")
  }
  if (!is.null(spec$options$method) && !identical(spec$options$method, "exact")) {
    return("A minimum-effect test is computed by pwrss's formula only; remove 'options > method'.")
  }
  effect <- met_effect(spec)
  if (identical(spec$goal$type, "sensitivity") || is.null(effect)) {
    return(character())
  }
  side <- met_side(spec)
  beyond <- switch(as.character(side), "1" = effect > margin, "-1" = effect < -margin, abs(effect) > margin)
  if (isTRUE(beyond)) {
    return(character())
  }
  where <- switch(as.character(side), "1" = "above the smallest effect of interest", "-1" = "below minus the smallest effect of interest",
    "further from 0 than the smallest effect of interest")
  paste0(
    "The effect you expect is not ", where, ", so the study would be unlikely to show the effect is larger than ",
    "the smallest effect of interest however many people took part. Check the expected effect, the margin and ",
    "the direction of the test."
  )
}

# The R script: the same pwrss call at each size powerkit computed, or
# pwrss's own solution for the smallest detectable effect.
met_script <- function(spec, result) {
  inputs <- met_inputs(spec)
  args <- inputs$args(100)
  effect <- if (identical(spec$template, "paired_t")) "dz" else "d"
  sensitivity <- identical(spec$goal$type, "sensitivity")
  fixed <- args[setdiff(names(args), c("n2", "n.ratio", "d", "alpha"))]
  arg_lines <- vapply(names(fixed), function(a) sprintf("    %s = %s,", a, r_code(fixed[[a]])), character(1))
  sizes <- if (identical(inputs$design, "independent")) {
    ratio <- spec$options$allocation_ratio %||% 1
    c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1",
      "  sizes <- list(n2 = n2, n.ratio = n1 / n2)"
    )
  } else {
    "  sizes <- list(n2 = n_total)"
  }
  side <- switch(as.character(inputs$side), "1" = "above the margin", "-1" = "below minus the margin",
    "outside both margins (two-sided, alpha / 2 in each tail)")
  call <- function(effect_arg, extra = NULL) c(
    sprintf("  do.call(pwrss::power.t.student, c(list(d = %s, alpha = alpha,", effect_arg),
    sub(",$", "", paste(arg_lines, collapse = "\n")),
    if (!is.null(extra)) paste0("    , ", extra),
    "  ), sizes))"
  )
  goal <- if (sensitivity) {
    s <- result$sensitivity
    c(
      "# Smallest detectable effect ----",
      "# pwrss finds the effect itself when d = NULL, beyond the margin on the",
      "# side given by req.sign.",
      "smallest <- function(n_total) {",
      sizes,
      call("NULL", sprintf("power = target_power, req.sign = %s", r_code(if (s$effect < 0) "-" else "+"))),
      "}",
      sprintf("%s <- smallest(n_total)$d", effect),
      "power <- power_at(n_total)",
      sprintf("cat(sprintf(\"Smallest detectable effect: %s = %%.4g (power %%.4f)\\n\", %s, power))", effect, effect),
      "",
      sprintf("reproduced <- list(effect = %s, power = power)", effect),
      sprintf("powerkit_result <- list(effect = %s, power = %s)", r_code(s$effect), r_code(s$power)),
      ""
    )
  } else {
    pwr_goal_section(spec, result)
  }
  c(
    script_header(spec, result, "pwrss", "pwrss::power.t.student(margin)"),
    "library(pwrss)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    if (!sensitivity) sprintf("%s <- %s # the expected effect", effect, r_code(met_effect(spec))),
    "",
    sprintf("# Power of the minimum-effect test: the effect is shown to lie %s,", side),
    "# the smallest effect of interest, in the same SD units as the effect.",
    "power_at <- function(n_total) {",
    sizes,
    (function(x) { x[length(x)] <- paste0(x[length(x)], "$power"); x })(call(effect)),
    "}",
    "",
    goal,
    comparison_section()
  )
}
