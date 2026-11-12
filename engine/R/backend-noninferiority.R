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
  ratio <- allocation_ratio(spec)
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
  # The t-tests: the margin is a fixed amount in the outcome's own units,
  # so the analysis is an ordinary one-sided t-test of the difference from
  # -margin (t.test(mu = -margin)), a central t under its null. Its power
  # is that of a one-sided t-test of the effect plus the margin against 0
  # (Julious, 2004; G*Power's shifted-null t-tests), which is what pwrss
  # receives. pwrss's own `margin` argument instead holds the margin fixed
  # in SD units (a noncentral t under the null), a different test whose
  # power is slightly higher: it gave sample sizes about two too small for
  # the test researchers run.
  shifted <- noninf_effect(spec) - margin
  list(fun = "power.t.student", effect = noninf_effect(spec), margin = margin, shifted = shifted, design = design, args = function(n) {
    common <- list(d = shifted, margin = 0, alpha = alpha, alternative = "one.sided", design = design, verbose = 0)
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
    # The t-tests receive the effect minus the margin against 0 (noninf_inputs()).
    recovered = if (is.null(args$d)) c(args$margin, args$prob1 - args$prob2) else c(inputs$effect - args$d, inputs$effect)
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
    ratio <- allocation_ratio(spec)
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
    if (identical(inputs$fun, "power.t.student")) c(
      "# The effect is oriented so that better is positive. The test is an ordinary",
      "# one-sided t-test of the difference from minus the margin, so d below is the",
      sprintf("# expected effect (%s) plus the margin (%s), tested against 0.", format_number(inputs$effect), format_number(-inputs$margin))
    ) else c(
      "# The effect is oriented so that better is positive, and the margin is",
      "# minus the largest difference in the wrong direction that is acceptable."),
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
# equivalence test. On the one-sample, paired and two-group t-tests it is
# a test version (target_test > method "minimum_effect").
#
# The test researchers run holds the margin fixed in the outcome's own
# units and tests the mean difference against it with an ordinary t-test
# (t.test(mu = margin); TOSTER's t_TOST(hypothesis = "MET")): a central t
# shifted by the margin. Its power is that of a one-sided t-test of the
# expected effect minus the margin against 0, which pwrss's
# power.t.student() computes when given d = effect - margin and margin = 0,
# exactly as for non-inferiority (noninf_inputs()):
#   one-sided ("greater" or "less"): the effect minus the margin on that
#     side, alternative = "one.sided" at alpha;
#   two-sided: the effect is shown to lie outside both margins, alpha / 2
#     in each tail. The tail on the effect's side is pwrss's one-sided
#     power at alpha / 2; the other tail (the chance of a significant
#     result on the wrong side, almost always negligible) is pwr's
#     one-sided t-test power in that direction, which pwrss's one-sided
#     test cannot give because it always tests the direction of d.
# Until 12 November 2026 powerkit passed the margin through pwrss's own
# `margin` argument, which holds the margin fixed in SD units (a
# noncentral t under the null): a different test with slightly lower
# power, so its sample sizes were a few too large (docs/conventions.md,
# Known difference 10, retired).

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
  alpha <- spec$target_test$alpha
  ratio <- allocation_ratio(spec)
  design <- switch(spec$template, independent_t = "independent", paired_t = "paired", one_sample_t = "one.sample")
  sizes <- function(n) {
    if (!identical(design, "independent")) return(list(n2 = n))
    n1 <- round(n / (1 + ratio))
    list(n2 = n - n1, n.ratio = n1 / (n - n1))
  }
  # The side the effect is tested on: the test's side, or for a two-sided
  # test the side of the expected effect.
  effect_side <- function(d) if (side != 0) side else if (isTRUE(d < 0)) -1 else 1
  tail_alpha <- if (side == 0) alpha / 2 else alpha
  # pwrss's arguments for the tail on the effect's side: the effect minus
  # the margin on that side, tested against 0.
  args <- function(n, d = met_effect(spec)) {
    c(list(d = d - effect_side(d) * m, margin = 0, alpha = tail_alpha, alternative = "one.sided",
           design = design, verbose = 0), sizes(n))
  }
  # Two-sided only: the chance of a significant result beyond the margin
  # on the other side, from pwr's one-sided t-test in that direction.
  far_tail <- function(n, d = met_effect(spec)) {
    if (side != 0) return(0)
    s <- effect_side(d)
    far_d <- d + s * m
    direction <- if (s > 0) "less" else "greater"
    out <- if (identical(design, "independent")) {
      z <- sizes(n)
      n1 <- round(z$n2 * z$n.ratio)
      quietly(pwr::pwr.t2n.test(n1 = n1, n2 = z$n2, d = far_d, sig.level = alpha / 2, alternative = direction))
    } else {
      quietly(pwr::pwr.t.test(n = n, d = far_d, sig.level = alpha / 2, type = "one.sample", alternative = direction))
    }
    out$power
  }
  power <- function(n, d = met_effect(spec)) {
    main <- call_backend("pwrss", quietly(do.call(pwrss::power.t.student, args(n, d))))$power
    main + if (side == 0) call_backend("pwr", far_tail(n, d)) else 0
  }
  list(
    fun = "power.t.student", design = design, margin = m, side = side, sizes = sizes, alpha = alpha,
    tail_alpha = tail_alpha, effect_side = effect_side, args = args, far_tail = far_tail, power = power
  )
}

met_backend <- function(spec, seed = NULL) {
  inputs <- met_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) inputs$power(n)
  two_sided <- inputs$side == 0
  list(
    name = "pwrss",
    packages = if (two_sided) c("pwrss", "pwr") else "pwrss",
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
# power, on the side of the expected effect (positive when none is given,
# or for a two-sided test with a positive or zero effect): the effect
# whose power is the target, found by root-finding beyond the margin.
met_sensitivity <- function(spec, inputs, n, power) {
  effect <- met_effect(spec) %||% 0
  negative <- inputs$side < 0 || (inputs$side == 0 && isTRUE(effect < 0))
  s <- if (negative) -1 else 1
  m <- inputs$margin
  gap <- function(d) inputs$power(n, s * d) - power
  found <- tryCatch({
    upper <- m + 1
    while (gap(upper) < 0 && upper < m + 50) upper <- upper * 2
    stats::uniroot(gap, c(m + 1e-9, upper), tol = 1e-10)$root
  }, error = function(e) NULL)
  if (is.null(found) || !is.finite(found)) {
    abort_run("No effect beyond the smallest effect of interest reaches the target power at this n. Check the margin and the direction of the test.")
  }
  name <- if (identical(spec$template, "paired_t")) "d_z" else "d"
  list(
    effect = s * found, effect_name = name, power = inputs$power(n, s * found),
    effect_description = switch(spec$template,
      paired_t = "Cohen's d_z (mean of the differences, in SDs of the differences)",
      independent_t = "Cohen's d (group 2 minus group 1, in SDs)",
      "Cohen's d (mean minus the comparison value, in SDs)")
  )
}

# Check run: no simulated data; the check confirms what pwrss receives.
met_check_run <- function(spec, inputs) {
  d <- met_effect(spec)
  args <- inputs$args(100, d %||% 0)
  m <- spec$population$margin
  side <- inputs$effect_side(d %||% 0)
  rows <- data.frame(
    parameter = c("smallest effect of interest (margin), on the tested side",
                  "expected effect minus the margin, passed to pwrss as d against 0"),
    specified = c(side * m, if (is.null(d)) NA_real_ else d - side * m),
    recovered = c((d %||% 0) - args$d, if (is.null(d)) NA_real_ else args$d)
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
  effect <- if (identical(spec$template, "paired_t")) "dz" else "d"
  sensitivity <- identical(spec$goal$type, "sensitivity")
  two_sided <- inputs$side == 0
  independent <- identical(inputs$design, "independent")
  sizes <- if (independent) {
    ratio <- allocation_ratio(spec)
    c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1"
    )
  } else {
    character()
  }
  side_text <- switch(as.character(inputs$side), "1" = "above the margin", "-1" = "below minus the margin",
    "outside both margins (two-sided, alpha / 2 in each tail)")
  side_line <- if (two_sided) {
    "  side <- if (es < 0) -1 else 1 # the side of the expected effect"
  } else {
    sprintf("  side <- %d # the side the test is on", inputs$side)
  }
  pwrss_call <- sprintf(
    "  main <- pwrss::power.t.student(d = es - side * margin, margin = 0, alpha = %s, alternative = \"one.sided\",\n    design = %s, %s, verbose = 0)$power",
    if (two_sided) "alpha / 2" else "alpha", r_code(inputs$design),
    if (independent) "n2 = n2, n.ratio = n1 / n2" else "n2 = n_total"
  )
  far_call <- if (!two_sided) character() else c(
    "  # The other tail: a significant result beyond the margin on the wrong",
    "  # side (pwr's one-sided t-test in that direction; almost always tiny).",
    if (independent) {
      "  far <- pwr::pwr.t2n.test(n1 = n1, n2 = n2, d = es + side * margin, sig.level = alpha / 2,"
    } else {
      "  far <- pwr::pwr.t.test(n = n_total, d = es + side * margin, sig.level = alpha / 2, type = \"one.sample\","
    },
    "    alternative = if (side > 0) \"less\" else \"greater\")$power"
  )
  goal <- if (sensitivity) {
    s <- result$sensitivity
    sign <- if (s$effect < 0) -1 else 1
    c(
      "# Smallest detectable effect ----",
      "# The effect beyond the margin whose power is the target, by root-finding.",
      sprintf("%s <- %s * stats::uniroot(function(x) power_at(n_total, %s * x) - target_power,", effect, sign, sign),
      "  c(margin + 1e-9, margin + 10), tol = 1e-10)$root",
      sprintf("power <- power_at(n_total, %s)", effect),
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
    script_header(spec, result, "pwrss", "pwrss::power.t.student()"),
    "library(pwrss)",
    if (two_sided) "library(pwr)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    if (!sensitivity) sprintf("%s <- %s # the expected effect", effect, r_code(met_effect(spec))),
    sprintf("margin <- %s # the smallest effect of interest, in the same SD units", r_code(inputs$margin)),
    "",
    sprintf("# Power of the minimum-effect test: the effect is shown to lie %s.", side_text),
    "# The test is t.test(mu = margin): a t-test of the effect minus the margin",
    "# against 0 (a central t shifted by the margin).",
    sprintf("power_at <- function(n_total, es = %s) {", if (sensitivity) "NULL" else effect),
    sizes,
    side_line,
    pwrss_call,
    far_call,
    if (two_sided) "  main + far" else "  main",
    "}",
    "",
    goal,
    comparison_section()
  )
}
